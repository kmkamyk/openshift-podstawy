# Moduł 10: CI/CD – Kompletne Spojrzenie. Raport Architektoniczny

## Wprowadzenie: Ewolucja Automatyzacji w Ekosystemie OpenShift

Niniejszy raport stanowi wyczerpującą analizę techniczną współczesnych paradygmatów Continuous Integration (CI) i Continuous Delivery (CD) w ramach platformy Red Hat OpenShift. Struktura tego dokumentu odzwierciedla celową ewolucję metodologii automatyzacji, którą przeszła branża, przechodząc od tradycyjnych, scentralizowanych narzędzi do w pełni deklaratywnych, natywnych dla chmury przepływów pracy.

Analiza rozpoczyna się od metody "Legacy" (Lekcja 10.1), skoncentrowanej na Jenkinsie, ilustrując, jak scentralizowany serwer automatyzacji został zintegrowany – a ostatecznie zastąpiony – w ekosystemie Kubernetes. Następnie raport przechodzi do metody "Cloud-Native" (Lekcja 10.2), badając OpenShift Pipelines (Tekton). Ta sekcja analizuje fundamentalną zmianę architektoniczną w kierunku "bezserwerowego" CI/CD, w którym sam klaster staje się silnikiem wykonawczym potoku. Wreszcie, raport kulminuje w metodzie "GitOps" (Lekcja 10.3), skupiając się na OpenShift GitOps (ArgoCD) jako nowym standardzie dla Continuous Delivery.

Kluczowym wnioskiem architektonicznym wynikającym z tej ewolucji jest fundamentalny podział odpowiedzialności. Narzędzia takie jak Tekton są optymalizowane pod kątem imperatywnych zadań CI: budowania, testowania i tworzenia artefaktów.[1, 2] Z drugiej strony, narzędzia takie jak ArgoCD są wyspecjalizowane *wyłącznie* w CD [3]: deklaratywnym uzgadnianiu pożądanego stanu klastra ze stanem zdefiniowanym w repozytorium Git.

Nowoczesny, dojrzały stos CI/CD na OpenShift nie polega na wyborze "Tekton *kontra* ArgoCD". Polega on na strategicznym połączeniu "Tekton *dla CI*" oraz "ArgoCD *dla CD*", co jest tematem przewodnim analizy w Lekcjach 10.4 i 10.5. Ten połączony model rozwiązuje kluczowe wyzwania związane z bezpieczeństwem, skalowalnością i zarządzaniem "dryfem" konfiguracji, które były nieodłączną cechą poprzednich paradygmatów.

## Lekcja 10.1: Metoda "Legacy": Jenkins (Integracja)

Chociaż Jenkins jest często postrzegany jako narzędzie poprzedniej generacji w kontekście Kubernetes, jego wszechobecność sprawiła, że konieczne stało się opracowanie natywnych metod zarządzania nim w OpenShift. Ta lekcja analizuje historyczną i obecną integrację Jenkinsa z platformą, jego mechanizmy komunikacyjne oraz przyczyny, dla których podejście to jest obecnie uznawane za przestarzałe.

### Instalacja i Zarządzanie: Wdrażanie Operatora Jenkins na OpenShift

Zarządzanie Jenkinsem, aplikacją z natury stanową (przechowującą zadania, historię, pluginy i konfigurację), jest nietrywialnym zadaniem w efemerycznym środowisku Kubernetes. Ręczne zarządzanie `Deployment` i `PersistentVolumeClaim` (PVC) dla Jenkinsa jest podatne na błędy.

Rozwiązaniem tego problemu jest Model Operatora. Operator Jenkins [4] to natywny dla Kubernetes kontroler, który hermetyzuje i automatyzuje pełen cykl życia instancji Jenkins.[4] Zamiast ręcznie zarządzać komponentami, administrator deklaruje pożądany stan instancji Jenkins za pomocą `Custom Resource` (CR), a Operator podejmuje działania w celu osiągnięcia tego stanu. Obejmuje to automatyczne tworzenie PVC, zarządzanie plikami konfiguracyjnymi, takimi jak `config.xml` [5] oraz obsługę instalacji pluginów.[6]

W OpenShift instalacja może odbywać się na dwa sposoby:

1.  **OperatorHub:** Standardowa, ogólnoklastrowa instalacja "Jenkins Operator" z OperatorHub [6] daje administratorom platformy pełną kontrolę nad cyklem życia i konfiguracją.[7]
2.  **Developer Catalog:** Uproszczona metoda, w której deweloper wybiera "Jenkins" z katalogu deweloperskiego.[8] Ta akcja zazwyczaj wdraża wstępnie skonfigurowaną instancję (opartą na szablonie lub uproszczonym operatorze) bezpośrednio w projekcie dewelopera.[9]

Adoptowanie Operatora dla Jenkinsa pokazuje, że nawet tradycyjne, monolityczne aplikacje muszą przyjąć natywny dla chmury model zarządzania, aby skutecznie funkcjonować w OpenShift.

### Architektura `BuildConfig`: Strategia `Pipeline` i `Jenkinsfile`

Historycznie, w OpenShift w wersji 3, platforma próbowała stworzyć ujednolicony interfejs API dla wszystkich typów zadań budowania za pomocą zasobu `BuildConfig`.[10] Obok strategii takich jak `Source-to-Image` (S2I) czy `Docker`, istniała strategia `type: JenkinsPipeline`.[11]

Ta strategia pozwalała na zdefiniowanie `BuildConfig`, który wskazywał na `Jenkinsfile` [12], zazwyczaj umieszczony w repozytorium kodu źródłowego.[10] Kiedy `BuildConfig` był uruchamiany (np. przez `oc start-build` lub webhook), OpenShift komunikował się ze skonfigurowanym serwerem Jenkins, polecając mu wykonanie zadania zdefiniowanego w tym `Jenkinsfile`.

To podejście, choć innowacyjne w swoim czasie, okazało się "nieszczelną abstrakcją". Deweloperzy nadal musieli zarządzać logiką w `Jenkinsfile` oraz serwerem Jenkins, podczas gdy `BuildConfig` działał jedynie jako powierzchowny wyzwalacz. Stwarzało to niejasności co do tego, gdzie faktycznie znajduje się definicja potoku.

W rezultacie, strategia `Pipeline` oparta na `BuildConfig` jest **jawnie przestarzała (deprecated)** w OpenShift 4.[10] Oficjalna dokumentacja Red Hat stwierdza, że "równoważna i ulepszona funkcjonalność jest obecna w OpenShift Container Platform Pipelines (Tekton)" [10], kierując użytkowników w stronę prawdziwie natywnego dla chmury rozwiązania.

### Most Komunikacyjny: Integracja Jenkins z API OpenShift

Kluczowym elementem funkcjonalnym Jenkinsa w OpenShift jest jego zdolność do komunikacji z API klastra. Odbywa się to za pośrednictwem dedykowanej wtyczki "OpenShift Pipeline DSL Plug-in" [13], która jest domyślnie dołączona do oficjalnego obrazu Jenkinsa dostarczanego przez Red Hat.[13]

Wtyczka ta udostępnia bogaty zestaw kroków Groovy DSL [14], które mogą być używane w `Jenkinsfile`. Kroki te, takie jak `openshiftBuild` czy `openshiftDeploy` [11, 15], są w rzeczywistości wygodnymi wrapperami na polecenia klienta `oc`.[13] Na przykład, wywołanie `openshiftBuild(bldCfg: 'my-app')` w `Jenkinsfile` jest funkcjonalnym odpowiednikiem wykonania `oc start-build my-app`.[15] Wtyczka pozwala również na przekazywanie zaawansowanych parametrów, takich jak ID commita (`--commit`) czy zmienne środowiskowe (`-e`).[15]

Aby ta komunikacja była możliwa, Pod Jenkinsa (lub jego dynamiczny agent [16]) musi działać z uprawnieniami określonego konta serwisowego (Service Account) w OpenShift.[5] To konto serwisowe musi mieć nadane odpowiednie role (np. `edit` lub szersze) w projektach, którymi ma zarządzać.

Ten model architektoniczny jest klasycznym przykładem **modelu "Push"**.[17] Serwer Jenkins aktywnie *wypycha* zmiany konfiguracyjne do klastra. Stwarza to fundamentalne wyzwanie bezpieczeństwa: serwer CI/CD staje się centralnym punktem o wysokich uprawnieniach. Kompromitacja serwera Jenkins (który często jest wystawiony na zewnątrz w celu odbierania webhooków) może dać atakującemu dostęp administracyjny do całego klastra. Ta słabość architektoniczna jest jednym z głównych powodów, dla których branża migruje w kierunku modelu "Pull" (GitOps), omówionego w Lekcji 10.3.

## Lekcja 10.2: Metoda "Cloud Native": OpenShift Pipelines (Tekton)

W odpowiedzi na ograniczenia modelu "Legacy", społeczność Kubernetes opracowała Tekton jako fundamentalnie nowy, natywny dla chmury silnik CI/CD. W OpenShift, Tekton jest dostarczany jako "OpenShift Pipelines". Ta lekcja bada jego filozofię, architekturę i podstawowe komponenty.

### Instalacja Operatora OpenShift Pipelines

Instalacja OpenShift Pipelines odbywa się poprzez OperatorHub i wymaga uprawnień administratora klastra.[18, 19] Administrator wyszukuje "Red Hat OpenShift Pipelines" [19] i zatwierdza instalację.

Kluczowym wyborem podczas instalacji jest "Tryb instalacji". Domyślnie wybrany jest "All namespaces on the cluster (default)".[18, 20] Ten wybór nie jest przypadkowy i odzwierciedla filozofię Tektona. W przeciwieństwie do Jenkinsa, który jest często wdrażany jako instancja na poziomie projektu, Tekton jest fundamentalną *zdolnością* (capability) rozszerzającą klastra. Kontrolery Tekton, instalowane centralnie w przestrzeni nazw `openshift-pipelines` [21], muszą mieć uprawnienia do "obserwowania" (`watch`) zasobów `PipelineRun` i `TaskRun` we *wszystkich* projektach użytkowników. Gdy deweloper tworzy `PipelineRun` w swoim projekcie, centralny kontroler Tekton wykrywa go i uruchamia odpowiednie Pody w projekcie tego dewelopera.

### Filozofia "Bezserwerowego" CI/CD: Architektura Oparta na Podach

Tekton jest często opisywany jako "bezserwerowy" (serverless) system CI/CD.[2] Ten termin odnosi się do faktu, że nie istnieje centralny, stale działający "serwer Tekton", który trzeba zarządzać, patchować, aktualizować czy backupować (w przeciwieństwie do Jenkinsa). "Serwerem" jest sam kontroler i API Kubernetes.[22]

Architektura wykonawcza Tektona jest następująca [23]:

1.  Użytkownik tworzy zasób `PipelineRun` (uruchomienie potoku).
2.  Kontroler `PipelineRun` odczytuje definicję `Pipeline` i dla pierwszego `Task` w grafie tworzy zasób `TaskRun` (uruchomienie zadania).
3.  Kontroler `TaskRun` odczytuje definicję `Task` i tworzy `Pod` Kubernetes w celu wykonania tego zadania.
4.  Każdy `Step` (krok) zdefiniowany w `Task` jest uruchamiany jako osobny kontener *wewnątrz tego samego Poda*.[23]
5.  Kontenery `Step` są uruchamiane sekwencyjnie. Dopiero gdy kontener `Step 1` zakończy się pomyślnie (z kodem wyjścia 0), uruchamiany jest kontener `Step 2`.

Ten model ma fundamentalne zalety w porównaniu z architekturą scentralizowaną:

  * **Izolacja:** Każde uruchomienie potoku (`PipelineRun`) i każde zadanie (`TaskRun`) jest całkowicie odizolowane w swoim własnym Podzie. Nie ma problemów z "zanieczyszczonym" workspace'm z poprzedniego budowania.
  * **Skalowalność:** Skalowalność systemu CI/CD jest tożsama ze skalowalnością klastra Kubernetes. Jeśli trzeba uruchomić 100 potoków równolegle, Tekton po prostu zażąda utworzenia 100 Podów.
  * **Efektywność Zasobów:** Zasoby (CPU, pamięć) są konsumowane tylko wtedy, gdy potok jest faktycznie uruchomiony. Nie ma bezczynnego serwera Jenkinsa zużywającego zasoby.
  * **Współdzielenie w Podzie:** Fakt, że `Steps` działają jako kontenery w jednym Podzie [23], pozwala im na łatwe współdzielenie danych (np. przez wolumen `emptyDir`) oraz komunikację przez `localhost`.

### Kluczowe Komponenty Architektury Tekton

Architektura Tektona opiera się na kilku kluczowych `Custom Resource Definitions` (CRD), które działają jak "klocki Lego" do budowania potoków [24, 25, 26]:

  * `Task`: Definicja atomowej, reużywalnej jednostki pracy. `Task` definiuje parametry wejściowe, wymagane `Workspaces` oraz listę `Steps` (kontenerów) do wykonania. Przykład: `Task` o nazwie `git-clone`.[27]
  * `Pipeline`: Definicja potoku, która organizuje `Task` w graf (DAG). `Pipeline` określa kolejność wykonywania zadań (za pomocą `runAfter`) lub ich równoległość.[23, 28]
  * `PipelineRun`: Instancja wykonawcza `Pipeline`. Jest to zasób, który *uruchamia* potok, dostarczając konkretne wartości dla parametrów (np. URL repozytorium Git) oraz definicje fizycznej pamięci masowej dla `Workspaces`.[2, 26]
  * `Workspace`: Abstrakcyjna definicja współdzielonej pamięci masowej.[26]

Kluczową koncepcją jest **oddzielenie definicji od wykonania**.[2, 25] `Task` i `Pipeline` są szablonami, definiowanymi raz i przeznaczonymi do wielokrotnego użytku. `TaskRun` i `PipelineRun` są instancjami tych szablonów, tworzonymi przy każdym uruchomieniu.

To oddzielenie jest szczególnie widoczne w przypadku `Workspaces`.[29] `Task` (definicja) mówi tylko: "Potrzebuję katalogu o nazwie `source`, aby przechować sklonowany kod".[30] `PipelineRun` (wykonanie) decyduje, co zostanie tam podmontowane. Może to być `PersistentVolumeClaim` (PVC) [31, 32], `ConfigMap`, `Secret`, a nawet efemeryczny `emptyDir`.[29, 30] Ta elastyczność pozwala na ponowne użycie tego samego `Task` w różnych potokach z różnymi strategiami przechowywania danych.

## Lekcja 10.3: Metoda "GitOps": OpenShift GitOps (ArgoCD)

Podczas gdy Tekton rewolucjonizuje CI (budowanie i testowanie), OpenShift GitOps (oparty na ArgoCD) rewolucjonizuje CD (wdrażanie i zarządzanie). Ta lekcja analizuje filozofię GitOps, jej architekturę "Pull" oraz sposób, w jaki rozwiązuje ona fundamentalny problem "dryfu konfiguracji".

### Instalacja Operatora OpenShift GitOps

Podobnie jak w przypadku OpenShift Pipelines, instalacja "Red Hat OpenShift GitOps" odbywa się przez OperatorHub.[33, 34] Proces ten jest prosty dla administratora klastra, który wybiera operatora i zatwierdza instalację w trybie "All namespaces".[34] Kluczową zaletą jest to, że Operator nie tylko instaluje kontrolery, ale także automatycznie wdraża w pełni funkcjonalną instancję ArgoCD w dedykowanej przestrzeni nazw `openshift-gitops`.[34, 35] Zapewnia to natychmiastowy dostęp do interfejsu użytkownika i API ArgoCD bez dodatkowej konfiguracji.

### Paradygmat GitOps: Git jako Jedyne Źródło Prawdy

GitOps to praktyka operacyjna, która przyjmuje Git jako *jedyne źródło prawdy* (Single Source of Truth) dla pożądanego stanu systemu.[36, 37, 38] W tym modelu cała infrastruktura i konfiguracja aplikacji są zdefiniowane *deklaratywnie* (np. w postaci plików YAML Kubernetes) i przechowywane w repozytorium Git.[39]

GitOps to jednak coś więcej niż tylko Infrastructure as Code (IaC).[37] Podczas gdy IaC (np. skrypt `oc apply -f...` uruchamiany przez Jenkinsa) jest częścią GitOps, prawdziwa różnica polega na dodaniu **aktywnej pętli uzgadniania**.[39, 40] W modelu GitOps, agent (ArgoCD) działający na klastrze *stale* porównuje stan rzeczywisty klastra ze stanem pożądanym zadeklarowanym w Git.[39] Wszystkie zmiany w systemie, w tym aktualizacje i rollbacki, są wprowadzane wyłącznie poprzez commity i Pull Requesty w Git.[36]

### Model "Pull" (ArgoCD) vs Model "Push" (Jenkins/Tekton)

Architektura GitOps opiera się na **modelu "Pull" (ściągania)**, co stanowi fundamentalną zmianę w stosunku do tradycyjnego modelu "Push" (wypychania) używanego przez Jenkinsa czy Tektona.[17]

  * **Model "Push" (Jenkins/Tekton):** Narzędzie CI (Jenkins lub Tekton) znajduje się *poza* klastrem docelowym (lub przynajmniej poza projektem produkcyjnym). Po pomyślnym zbudowaniu i przetestowaniu, potok CI *aktywne wypycha* zmiany do klastra, wykonując polecenia `oc apply` lub `kubectl patch`.[17] Wymaga to, aby system CI posiadał wysoko uprzywilejowane konto serwisowe z prawami zapisu do API klastra produkcyjnego.[1]
  * **Model "Pull" (ArgoCD):** Agent ArgoCD jest zainstalowany *wewnątrz* klastra docelowego. Agent ten *aktywne monitoruje* repozytorium Git. Gdy wykryje różnicę między stanem w Git a stanem na klastrze, *automatycznie ściąga* zmiany i stosuje je lokalnie.[17, 41] W tym modelu system CI (Tekton) *nigdy* nie komunikuje się z klastrem produkcyjnym. Jego jedyną odpowiedzialnością jest zbudowanie obrazu i (potencjalnie) *wypchnięcie* zmiany do *repozytorium Git*.[3]

Ta zmiana architektoniczna ma kluczowe implikacje, szczególnie w zakresie bezpieczeństwa. Model "Pull" tworzy "szczelinę powietrzną" (air gap) między środowiskiem CI a środowiskiem produkcyjnym CD. Kompromitacja systemu CI nie daje atakującemu bezpośredniego dostępu do klastra produkcyjnego, ponieważ system CI nie posiada do niego żadnych poświadczeń.

Poniższa tabela szczegółowo porównuje te dwa modele operacyjne.

**Tabela 1: Porównanie modeli operacyjnych: Push vs. Pull**

| Kryterium | Model Push (np. Jenkins, Tekton) | Model Pull (np. ArgoCD) |
| :--- | :--- | :--- |
| **Mechanizm** | Skrypty/potoki wysyłają polecenia `kubectl`/`oc` do API klastra.[17] | Agent w klastrze monitoruje Git i uzgadnia stan (reconciliation).[17] |
| **Źródło Inicjacji** | Zewnętrzne (zdarzenie CI, np. zakończenie budowania).[17] | Wewnętrzne (wykrycie zmiany w Git lub interwał odpytywania).[17, 41] |
| **Wymagane Uprawnienia (System CI)** | Wysokie (zapis do API Kubernetes, często admin).[1] | Niskie (tylko odczyt z Git i zapis do repozytorium obrazów).[3] |
| **Wymagane Uprawnienia (Agent CD)** | Nie dotyczy. | Wysokie (agent w klastrze potrzebuje uprawnień do zarządzania zasobami, ale są one ograniczone do *wewnątrz* klastra). |
| **Wykrywanie Dryfu** | Brak (model "fire-and-forget"). | Podstawowa funkcja (ciągłe monitorowanie).[41] |

### Wykrywanie i Zarządzanie "Dryfem" Konfiguracji

Kluczową wartością ArgoCD jest rozwiązanie problemu **"dryfu" (drift) konfiguracji**.[42] Dryf ma miejsce, gdy stan rzeczywisty zasobów na klastrze różni się od stanu zdefiniowanego w Git.[41] Jest to niemal zawsze wynikiem ręcznych, nieśledzonych zmian (np. inżynier wykonujący `kubectl edit deployment...` w celu szybkiej naprawy na produkcji).[41]

ArgoCD *stale* porównuje manifesty z Git (stan pożądany) z zasobami na żywo na klastrze (stan rzeczywisty).[41] Jeśli wykryje jakąkolwiek różnicę, natychmiast oznacza aplikację w interfejsie użytkownika jako `OutOfSync`.[41] Co więcej, integracja Operatora OpenShift GitOps ze stosem monitorowania OpenShift pozwala na generowanie alertów Prometheus, gdy aplikacje stają się niezsynchronizowane.[43]

ArgoCD oferuje dwie strategie radzenia sobie z dryfem:

1.  **Tryb Ręczny:** ArgoCD tylko raportuje dryf, a operator musi ręcznie zdecydować, czy przywrócić stan z Git (nadpisując ręczną zmianę), czy zaktualizować Git (zaakceptować ręczną zmianę).
2.  **Automatyczne Samoleczenie (Self-Heal):** Jeśli aplikacja jest skonfigurowana z `syncPolicy.automated.selfHeal: true` [44], ArgoCD *automatycznie* i natychmiastowo przywróci stan zdefiniowany w Git, nadpisując każdą ręczną zmianę.[45]

Chociaż `selfHeal` może wydawać się restrykcyjny, wymusza on fundamentalną dyscyplinę organizacyjną. Zmusza zespoły do porzucenia ręcznych interwencji na rzecz dokonywania *wszystkich* zmian poprzez proces Git (Pull Request, recenzja, merge), co tworzy doskonały, audytowalny ślad każdej zmiany w systemie.[39, 41]

## Lekcja 10.4: Testowanie Aplikacji w Pipeline (Tekton)

Po ustanowieniu Tektona jako natywnego silnika CI, kolejnym krokiem jest integracja krytycznych procesów walidacji, takich jak testy jednostkowe i integracyjne. W Tektonie testowanie nie jest specjalną funkcją, ale po prostu kolejnym `Task` w potoku.

### Testy jako `Task`: Integracja Testów w Potoku Tekton

W typowym potoku CI (Clone -\> Test -\> Build), `Task` testujący jest umieszczany po sklonowaniu kodu, a przed budowaniem obrazu kontenerowego.[46] Kluczowym elementem umożliwiającym ten przepływ są `Workspaces`.[31]

Potok (`Pipeline`) definiuje `Workspace` (np. o nazwie `shared-data`), który jest wspierany przez `PersistentVolumeClaim` (PVC).[32] Ten sam `Workspace` jest następnie przekazywany zarówno do `Task` `git-clone`, jak i do `Task` `run-tests`. `Task` `git-clone` zapisuje kod źródłowy w `Workspace`. `Task` `run-tests` odczytuje ten kod z tego samego `Workspace` i wykonuje na nim testy.[31]

### Implementacja Testów: Przykłady YAML

Definicja `Task` testującego zależy od stosu technologicznego projektu.

**Dla `pytest` (Python):**
Tworzony jest `Task`, który używa obrazu bazowego Pythona, np. `image: python:3.9-slim`.[23] `Step` wewnątrz tego `Task` wykonuje dwa polecenia w `workingDir: $(workspaces.source.path)` [23]:

1.  Instalacja zależności: `pip install -r requirements.txt`.[47]
2.  Uruchomienie testów: `pytest` lub (jak w przykładzie) `nosetests`.[23, 48]

<!-- end list -->

```yaml
# Przykład Task dla pytest/nosetests [23]
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: python-tests
spec:
  workspaces:
  - name: source
  steps:
  - name: run-tests
    image: python:3.9-slim
    workingDir: $(workspaces.source.path)
    script: |
      #!/bin/sh
      pip install -r requirements.txt
      echo "Running Tests..."
      pytest
```

**Dla `mvn test` (Java):**
Zamiast tworzyć własny `Task`, powszechną praktyką jest użycie gotowego `ClusterTask` (globalnie dostępnego `Task`) o nazwie `maven`.[49] Ten `Task` akceptuje parametr `GOALS`, w którym można określić cele Maven do wykonania.[50]

Aby uruchomić testy, `Pipeline` przekazuje do `Task` `maven` parametr `GOALS` z wartością `["test"]` lub `["clean", "package"]`.[50, 51] Użycie `package` uruchomi testy jako część cyklu życia budowania.

```yaml
# Fragment Pipeline używający Task 'maven' do testowania [51]
#...
tasks:
- name: run-maven-tests
  taskRef:
    name: maven
    kind: ClusterTask
  params:
  - name: GOALS
    value: ["clean", "package"] # lub po prostu ["test"]
  workspaces:
  - name: source
    workspace: shared-data
```

Ważną optymalizacją dla `maven` jest dodanie drugiego `Workspace` (np. `maven-repo-cache`) wspieranego przez PVC i podmontowanego do `/root/.m2`. Pozwala to na buforowanie pobranych zależności Maven między uruchomieniami potoku, drastycznie skracając czas budowania.[52]

### Obsługa Błędów i Zatrzymanie Potoku

Domyślne zachowanie Tektona jest idealne dla CI: działa na zasadzie **"fail-fast"**.[53]

1.  Skrypt testowy (np. `pytest` lub `mvn test`) jest uruchamiany jako `Step`.
2.  Jeśli choć jeden test jednostkowy się nie powiedzie, narzędzie testowe (Maven, Pytest) zakończy działanie z kodem wyjścia innym niż 0.
3.  Kontroler Tektona wykrywa ten kod błędu i natychmiast oznacza ten `Step` jako zakończony niepowodzeniem (`Failed`).[53]
4.  Ponieważ `Step` zawiódł, cały `TaskRun` jest oznaczany jako `Failed`.[53]
5.  Kontroler `PipelineRun` wykrywa, że `TaskRun` zawiódł, i *natychmiast zatrzymuje cały potok*.[54] Żadne kolejne `Task` (np. budowanie obrazu) nie zostaną uruchomione.

To domyślne zachowanie jest dokładnie tym, czego oczekuje się od procesu CI – zapobiega budowaniu i wdrażaniu wadliwego kodu.

W przypadkach, gdy wymagane jest wykonanie pewnych kroków *zawsze*, niezależnie od powodzenia lub porażki (np. wysłanie powiadomienia na Slack, usunięcie tymczasowej bazy danych testowej), Tekton dostarcza klauzulę `finally`.[55] `Task` zdefiniowane w sekcji `finally` potoku zostaną wykonane po zakończeniu wszystkich innych `Task`, gwarantując wykonanie kroków sprzątających.[56]

## Lekcja 10.5: Warsztat End-to-End: Rollback i Strategia Canary z ArgoCD

Ta lekcja syntetyzuje koncepcje GitOps (Lekcja 10.3) i CI (Lekcja 10.4), aby zbudować kompletny, odporny na błędy przepływ pracy, który obejmuje zaawansowane strategie wdrażania i mechanizmy rollback.

### Konfiguracja Aplikacji ArgoCD: Śledzenie Repozytorium Git

Sercem zarządzania aplikacją w ArgoCD jest zasób `kind: Application`.[44] Ten pojedynczy manifest YAML jest deklaratywną definicją, która łączy repozytorium Git z docelowym środowiskiem na klastrze.

Kluczowe pola w `spec` to:

  * `spec.source` [44]: Definiuje "skąd" pochodzi konfiguracja.
      * `repoURL`: Adres URL repozytorium Git.[44]
      * `path`: Ścieżka wewnątrz repozytorium, gdzie znajdują się manifesty YAML.[44]
      * `targetRevision`: Wersja do śledzenia (np. gałąź, tag lub hash commita).[44]
  * `spec.destination` [44]: Definiuje "gdzie" aplikacja ma być wdrożona.
      * `server`: Adres URL klastra (domyślnie `https://kubernetes.default.svc` dla lokalnego klastra).[44]
      * `namespace`: Docelowa przestrzeń nazw na klastrze.[44]

ArgoCD może być również skonfigurowane do łączenia się z prywatnymi repozytoriami Git przy użyciu `Secrets` Kubernetes.[57, 58]

Kluczową decyzją architektoniczną jest `targetRevision`.[59] Ustawienie `HEAD` [44] (lub nazwy głównej gałęzi) oznacza "zawsze wdrażaj najnowszą wersję" – typowe dla środowisk deweloperskich. Ustawienie statycznego tagu (np. `v1.2.0`) oznacza "przypnij to środowisko do tej konkretnej wersji" – kluczowe dla stabilności środowisk produkcyjnych.

### Automatyczne Wdrożenie po Zmianie w Git

Połączenie potoku CI (Tekton) z potokiem CD (ArgoCD) tworzy kompletny przepływ pracy [60]:

1.  Deweloper wypycha kod do repozytorium `app-source-code`.
2.  Trigger Tekton uruchamia `PipelineRun` CI.
3.  Potok Tekton klonuje kod, uruchamia testy (`mvn test`) i buduje obraz kontenera (np. `my-app:v2.0`).
4.  Potok Tekton klonuje *drugie* repozytorium, `app-config`.[60, 61]
5.  Używając narzędzia (np. `kustomize edit set image...` [60]), potok Tekton aktualizuje tag obrazu w manifeście YAML w repozytorium `app-config`.
6.  Potok Tekton wykonuje `git commit` i `git push` do repozytorium `app-config`.[60]
7.  ArgoCD, które monitoruje repozytorium `app-config`, wykrywa nowy commit.
8.  ArgoCD *pobiera* zmieniony manifest (z nowym tagiem obrazu) i stosuje go do klastra, uruchamiając aktualizację.

Zdecydowanie najlepszą praktyką jest utrzymywanie dwóch oddzielnych repozytoriów.[61] Repozytorium `app-source` zawiera kod aplikacji, a `app-config` zawiera wyłącznie manifesty Kubernetes. Zapewnia to czystą separację odpowiedzialności i doskonały ślad audytowy dla wdrożeń – każdy commit w `app-config` odpowiada wdrożeniu.[61]

Alternatywą dla kroku 5 i 6 jest `ArgoCD Image Updater`.[62] Jest to narzędzie, które monitoruje *rejestr obrazów*. Gdy wykryje nowy tag, automatycznie wykonuje commit i push do repozytorium `app-config`, zwalniając potok CI z tej odpowiedzialności.[62]

### Strategie Rollback w GitOps

W modelu GitOps, gdzie Git jest źródłem prawdy [63], istnieją dwa różne podejścia do wycofywania zmian, o drastycznie różnych implikacjach:

1.  **Poprawny Rollback (oparty na Git): `git revert`**
    W tym podejściu operator wykonuje `git revert <bad-commit-sha>` i `git push`.[63] Z punktu widzenia ArgoCD, nie jest to "cofanie", ale "wdrażanie do przodu" *nowego* commita (commita cofającego). ArgoCD pobiera ten nowy stan, który przywraca stary, dobry kod. Stan klastra i stan Git pozostają w idealnej synchronizacji (`Synced`).
2.  **Rollback Awaryjny (oparty na UI/CLI): `argocd app rollback`**
    ArgoCD UI/CLI dostarcza polecenie `rollback`.[63, 64] To polecenie mówi ArgoCD: "Natychmiast zignoruj Git i wdróż poprzednią, znaną-dobrą konfigurację, którą masz w swojej historii". Jest to *przycisk awaryjny* do natychmiastowej naprawy produkcji. Jednak po jego użyciu stan klastra (naprawiony) *różni się* od stanu w Git (nadal zepsuty). ArgoCD natychmiast zgłosi stan `OutOfSync`.[65] Jest to sygnał dla zespołu: "Produkcja jest tymczasowo stabilna, ale teraz musicie naprawić stan w Git (np. poprzez `git revert`)".

### Wprowadzenie do `Argo Rollouts`: Zaawansowane Wdrożenia Progresywne

Standardowa strategia wdrażania Kubernetes, `RollingUpdate`, jest często niewystarczająca dla krytycznych aplikacji. Ma ona ograniczoną kontrolę nad prędkością, nie zarządza aktywnie ruchem, nie wykonuje analizy metryk i nie potrafi automatycznie wycofać wdrożenia w przypadku problemów.[66]

**Argo Rollouts** to dedykowany kontroler Kubernetes, który zastępuje standardowy zasób `Deployment` nowym zasobem `kind: Rollout`.[67] Ten nowy zasób rozszerza możliwości wdrożeń o zaawansowane strategie, takie jak Blue-Green i Canary.[68]

Kluczowe jest zrozumienie podziału ról:

  * **ArgoCD (GitOps Engine):** Odpowiada za to, *co* jest na klastrze. Jego zadaniem jest wykrycie zmiany w `kind: Rollout` w Git i zastosowanie (`apply`) tej zmiany na klastrze.
  * **Argo Rollouts (Deployment Engine):** Odpowiada za to, *jak* ta zmiana jest wdrażana. Kontroler `Argo Rollouts` "widzi" zmianę w zasobie `Rollout` i przejmuje proces, inteligentnie zarządzając starymi i nowymi `ReplicaSet` oraz manipulując ruchem.[67]

### Analiza Strategii Canary (Wdrożenie Kanarkowe)

Strategia Canary (kanarkowa) polega na stopniowym wprowadzaniu nowej wersji aplikacji dla małego podzbioru użytkowników, co ogranicza "promień rażenia" (blast radius) ewentualnego błędu.[69, 70]

W manifeście `Rollout`, deweloper definiuje `spec.strategy.canary.steps`.[70] Typowy przepływ może wyglądać następująco:

1.  `setWeight: 10`: Kontroler `Argo Rollouts` tworzy Pody z nową wersją i konfiguruje sieć (np. Ingress, Service Mesh), aby 10% ruchu trafiało do nowej wersji, a 90% do starej.[69, 70]
2.  `pause: {}`: Potok jest wstrzymywany na czas nieokreślony.[70] W tym momencie system czeka na walidację.
3.  *Walidacja:* Zespół monitoruje metryki. Jeśli nowa wersja działa poprawnie, operator ręcznie promuje wdrożenie poleceniem `oc argo rollouts promote <rollout-name>`.[70]
4.  `setWeight: 50`: Ruch jest zwiększany do 50%.[71]
5.  `pause: { duration: 30s }`: Automatyczna pauza na 30 sekund.[71]
6.  `setWeight: 100`: Cały ruch jest przenoszony na nową wersję, a stare Pody są usuwane.

Zamiast ręcznej promocji (`pause: {}`), `Argo Rollouts` może integrować się z dostawcami metryk, takimi jak Prometheus.[68, 72] Pozwala to na zdefiniowanie `AnalysisRun` [68], który automatycznie wykonuje zapytania (np. "jaki jest wskaźnik błędów HTTP 500 dla nowej wersji?") i automatycznie promuje lub wycofuje wdrożenie na podstawie zdefiniowanych KPI.[72]

Poniższa tabela podsumowuje kluczowe strategie wdrażania dostępne w OpenShift.

**Tabela 2: Przegląd strategii wdrażania**

| Strategia | Podstawowy Mechanizm | Zarządzanie Ruchem | Ryzyko / "Blast Radius" | Czas Wdrożenia | Koszt Zasobów |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Rolling Update** (Standard) [66] | Powolna wymiana Podów (jeden po drugim). | Kontrolowane przez `maxSurge`/`maxUnavailable`. | Średnie. Użytkownicy widzą obie wersje. | Średni. | Niewielki (1+ `maxSurge` Podów). |
| **Blue-Green** (Argo Rollouts) [68] | Wdraża pełną nową wersję ("Green") obok starej ("Blue").[68] | Natychmiastowe przełączenie ruchu 0% -\> 100%.[68] | Niski. Natychmiastowy rollback przez przełączenie ruchu. | Szybki (po wdrożeniu "Green"). | Wysoki (2x zasobów).[68] |
| **Canary** (Argo Rollouts) [68] | Stopniowe wdrażanie nowej wersji i stopniowe przesuwanie ruchu.[69] | Precyzyjna kontrola (np. 10% -\> 50% -\> 100%).[70, 71] | Najniższy. Wpływa tylko na mały % użytkowników.[69] | Wolny (celowo wstrzymywany).[70] | Średni (stopniowo skaluje w górę i w dół). |

## Podsumowanie i Rekomendacje Architektoniczne

Analiza trzech paradygmatów CI/CD w OpenShift – "Legacy" (Jenkins), "Cloud-Native" (Tekton) i "GitOps" (ArgoCD) – ujawnia klarowną ścieżkę ewolucyjną w kierunku bardziej bezpiecznego, skalowalnego i deklaratywnego modelu automatyzacji. Zamiast traktować te narzędzia jako konkurencyjne, architekci platform powinni postrzegać je jako komplementarne komponenty "złotego standardu" nowoczesnego potoku.

Rekomendowana architektura "Złotego Standardu" CI/CD na OpenShift łączy mocne strony każdego z nowoczesnych narzędzi:

1.  **Repozytoria (Zasada GitOps):** Należy stosować dwa oddzielne repozytoria Git [61]:
      * `app-source-repo`: Zawiera kod źródłowy aplikacji (zarządzane przez deweloperów).
      * `app-config-repo`: Zawiera *wyłącznie* manifesty Kubernetes (np. Kustomize, Helm) definiujące aplikację (zarządzane przez proces CI i zespół platformy).
2.  **CI (Continuous Integration) - Tekton:** Należy używać OpenShift Pipelines (Tekton) do wszystkich zadań CI.[2] `Trigger` Tekton powinien monitorować `app-source-repo`. Po `git push` dewelopera, `PipelineRun` powinien wykonać następujące `Task`:
      * `Task 1`: Klonowanie kodu (`git-clone`).
      * `Task 2`: Walidacja i testy (`pytest` / `mvn test`) [23, 51], używając `Workspaces`.[31] W przypadku niepowodzenia testów, potok jest automatycznie zatrzymywany.[53, 54]
      * `Task 3`: Budowanie obrazu (`buildah`).
      * `Task 4`: Aktualizacja manifestu w `app-config-repo` (np. `kustomize edit set image...` [60]) i `git push`.[60]
3.  **CD (Continuous Delivery) - ArgoCD:** Należy używać OpenShift GitOps (ArgoCD) jako silnika CD. Zasób `Application` [44] w ArgoCD powinien monitorować *wyłącznie* `app-config-repo`.
4.  **Wdrożenie Progresywne - Argo Rollouts:** Manifesty w `app-config-repo` *nie* powinny używać standardowego `kind: Deployment`. Zamiast tego powinny definiować `kind: Rollout`.[67, 68]
5.  **Pełen Przepływ:** Zmiana w `app-config-repo` (dokonana przez Tektona) jest wykrywana przez ArgoCD. ArgoCD stosuje (`apply`) zaktualizowany manifest `Rollout` na klastrze. Kontroler `Argo Rollouts` [68] przejmuje kontrolę, wykrywa zmianę i rozpoczyna bezpieczne, stopniowe wdrożenie Canary [70], potencjalnie weryfikując je automatycznie za pomocą metryk Prometheus.[72]

Ta połączona architektura (Tekton + ArgoCD + Argo Rollouts) w pełni realizuje obietnicę natywnego dla chmury CI/CD. Tworzy ona bezpieczną separację między procesami CI i CD, egzekwuje Git jako jedyne źródło prawdy dla operacji oraz zastępuje ryzykowne wdrożenia "big bang" kontrolowanymi, progresywnymi rolloutami.
#### **Cytowane prace**

1. Argo CD vs Jenkins: 5 Key Differences and Using Them Together | Codefresh, otwierano: listopada 15, 2025, [https://codefresh.io/learn/argo-cd/argo-cd-vs-jenkins-5-key-differences-and-using-them-together/](https://codefresh.io/learn/argo-cd/argo-cd-vs-jenkins-5-key-differences-and-using-them-together/)  
2. Chapter 3\. Understanding OpenShift Pipelines \- Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/red\_hat\_openshift\_pipelines/1.12/html/about\_openshift\_pipelines/understanding-openshift-pipelines](https://docs.redhat.com/en/documentation/red_hat_openshift_pipelines/1.12/html/about_openshift_pipelines/understanding-openshift-pipelines)  
3. Argo CD Explained: GitOps Deployment for Kubernetes at Scale \- Baytech Consulting, otwierano: listopada 15, 2025, [https://www.baytechconsulting.com/blog/argo-cd-2025-overview-business-impact-and-comparison-with-jenkins](https://www.baytechconsulting.com/blog/argo-cd-2025-overview-business-impact-and-comparison-with-jenkins)  
4. Jenkins Operator, otwierano: listopada 15, 2025, [https://www.jenkins.io/projects/jenkins-operator/](https://www.jenkins.io/projects/jenkins-operator/)  
5. OpenShift Container Platform 4.16 Jenkins \- Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/documentation/openshift\_container\_platform/4.16/pdf/jenkins/index](https://docs.redhat.com/documentation/openshift_container_platform/4.16/pdf/jenkins/index)  
6. Jenkins Operator \- OperatorHub.io, otwierano: listopada 15, 2025, [https://operatorhub.io/operator/jenkins-operator](https://operatorhub.io/operator/jenkins-operator)  
7. Jenkins | OpenShift Container Platform | 4.14 \- Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.14/html-single/jenkins/index](https://docs.redhat.com/en/documentation/openshift_container_platform/4.14/html-single/jenkins/index)  
8. How to use continuous integration with Jenkins on OpenShift | Red ..., otwierano: listopada 15, 2025, [https://developers.redhat.com/articles/2023/02/28/how-use-continuous-integration-jenkins-openshift](https://developers.redhat.com/articles/2023/02/28/how-use-continuous-integration-jenkins-openshift)  
9. Chapter 1\. Configuring Jenkins images | Jenkins | OpenShift Container Platform | 4.12 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.12/html/jenkins/images-other-jenkins](https://docs.redhat.com/en/documentation/openshift_container_platform/4.12/html/jenkins/images-other-jenkins)  
10. Chapter 2\. Builds | CI/CD | OpenShift Container Platform | 4.9 | Red ..., otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.9/html/cicd/builds](https://docs.redhat.com/en/documentation/openshift_container_platform/4.9/html/cicd/builds)  
11. How to define BuildConfig object with Jenkins and openshift \- Stack ..., otwierano: listopada 15, 2025, [https://stackoverflow.com/questions/52337851/how-to-define-buildconfig-object-with-jenkins-and-openshift](https://stackoverflow.com/questions/52337851/how-to-define-buildconfig-object-with-jenkins-and-openshift)  
12. Lab 2 OpenShift Pipeline \- Jenkins 101 \- IBM, otwierano: listopada 15, 2025, [https://ibm.github.io/jenkins101/lab-02/](https://ibm.github.io/jenkins101/lab-02/)  
13. OpenShift Client \- Jenkins Plugins, otwierano: listopada 15, 2025, [https://plugins.jenkins.io/openshift-client/](https://plugins.jenkins.io/openshift-client/)  
14. openshift/jenkins-plugin \- GitHub, otwierano: listopada 15, 2025, [https://github.com/openshift/jenkins-plugin](https://github.com/openshift/jenkins-plugin)  
15. OpenShift Pipeline Jenkins Plugin, otwierano: listopada 15, 2025, [https://www.jenkins.io/doc/pipeline/steps/openshift-pipeline/](https://www.jenkins.io/doc/pipeline/steps/openshift-pipeline/)  
16. Chapter 5\. Jenkins | CI/CD | OpenShift Container Platform | 4.11 \- Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.11/html/cicd/jenkins](https://docs.redhat.com/en/documentation/openshift_container_platform/4.11/html/cicd/jenkins)  
17. Choosing Between Pull vs. Push-Based GitOps | Aviator, otwierano: listopada 15, 2025, [https://www.aviator.co/blog/choosing-between-pull-vs-push-based-gitops/](https://www.aviator.co/blog/choosing-between-pull-vs-push-based-gitops/)  
18. Installing the Pipelines Operator, otwierano: listopada 15, 2025, [https://openshift.github.io/pipelines-docs/docs/0.7/proc\_installing-pipelines-operator.html](https://openshift.github.io/pipelines-docs/docs/0.7/proc_installing-pipelines-operator.html)  
19. Chapter 2\. Installing OpenShift Pipelines \- Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.6/html/pipelines/installing-pipelines](https://docs.redhat.com/en/documentation/openshift_container_platform/4.6/html/pipelines/installing-pipelines)  
20. Chapter 1\. Installing OpenShift Pipelines \- Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/red\_hat\_openshift\_pipelines/1.14/html/installing\_and\_configuring/installing-pipelines](https://docs.redhat.com/en/documentation/red_hat_openshift_pipelines/1.14/html/installing_and_configuring/installing-pipelines)  
21. Install Tekton Pipelines, otwierano: listopada 15, 2025, [https://tekton.dev/docs/pipelines/install/](https://tekton.dev/docs/pipelines/install/)  
22. How Tekton Simplifies Your CI/CD Workflow on Kubernetes | by Kenneth Brast | Medium, otwierano: listopada 15, 2025, [https://kennybrast.medium.com/how-tekton-simplifies-your-ci-cd-workflow-on-kubernetes-1819e5e6b6ac](https://kennybrast.medium.com/how-tekton-simplifies-your-ci-cd-workflow-on-kubernetes-1819e5e6b6ac)  
23. Tekton Pipelines: A Practical Guide from Git to Kubernetes ..., otwierano: listopada 15, 2025, [https://pranavmahindru.medium.com/tekton-pipelines-a-practical-guide-from-git-to-kubernetes-deployment-08e054f1afaa](https://pranavmahindru.medium.com/tekton-pipelines-a-practical-guide-from-git-to-kubernetes-deployment-08e054f1afaa)  
24. Concept model | Tekton, otwierano: listopada 15, 2025, [https://tekton.dev/docs/concepts/concept-model/](https://tekton.dev/docs/concepts/concept-model/)  
25. A step-by-step tutorial showing OpenShift Pipelines \- GitHub, otwierano: listopada 15, 2025, [https://github.com/openshift/pipelines-tutorial](https://github.com/openshift/pipelines-tutorial)  
26. Chapter 1\. Understanding OpenShift Pipelines | Pipelines ..., otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.6/html/pipelines/understanding-openshift-pipelines](https://docs.redhat.com/en/documentation/openshift_container_platform/4.6/html/pipelines/understanding-openshift-pipelines)  
27. Cloud Native CI/CD with Tekton and ArgoCD on AWS | Containers, otwierano: listopada 15, 2025, [https://aws.amazon.com/blogs/containers/cloud-native-ci-cd-with-tekton-and-argocd-on-aws/](https://aws.amazon.com/blogs/containers/cloud-native-ci-cd-with-tekton-and-argocd-on-aws/)  
28. Specifying Pipelines in PipelineTasks \- Tekton, otwierano: listopada 15, 2025, [https://tekton.dev/docs/pipelines/pipelines/](https://tekton.dev/docs/pipelines/pipelines/)  
29. Tekton, otwierano: listopada 15, 2025, [https://tekton.dev/docs/pipelines/workspaces/](https://tekton.dev/docs/pipelines/workspaces/)  
30. Tekton CI, part II, sharing information \- DEV Community, otwierano: listopada 15, 2025, [https://dev.to/leandronsp/tekton-ci-part-ii-sharing-information-j81](https://dev.to/leandronsp/tekton-ci-part-ii-sharing-information-j81)  
31. Workspaces :: Tekton Tutorial, otwierano: listopada 15, 2025, [https://redhat-scholars.github.io/tekton-tutorial/tekton-tutorial/workspaces.html](https://redhat-scholars.github.io/tekton-tutorial/tekton-tutorial/workspaces.html)  
32. Persistance storage sharing between the task in Tekton pipeline \- Stack Overflow, otwierano: listopada 15, 2025, [https://stackoverflow.com/questions/72668881/persistance-storage-sharing-between-the-task-in-tekton-pipeline](https://stackoverflow.com/questions/72668881/persistance-storage-sharing-between-the-task-in-tekton-pipeline)  
33. Red Hat OpenShift GitOps \- IBM DevOps Solution Workbench, otwierano: listopada 15, 2025, [https://fswb-documentation.knowis.net/4.1.0/setting-up-the-product/installing/install-gitops.html](https://fswb-documentation.knowis.net/4.1.0/setting-up-the-product/installing/install-gitops.html)  
34. Chapter 2\. Installing Red Hat OpenShift GitOps | Installing GitOps ..., otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/red\_hat\_openshift\_gitops/1.15/html/installing\_gitops/installing-openshift-gitops](https://docs.redhat.com/en/documentation/red_hat_openshift_gitops/1.15/html/installing_gitops/installing-openshift-gitops)  
35. Chapter 2\. Installing Red Hat OpenShift GitOps, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/red\_hat\_openshift\_gitops/1.10/html/installing\_gitops/installing-openshift-gitops](https://docs.redhat.com/en/documentation/red_hat_openshift_gitops/1.10/html/installing_gitops/installing-openshift-gitops)  
36. What is GitOps? \- GitLab, otwierano: listopada 15, 2025, [https://about.gitlab.com/topics/gitops/](https://about.gitlab.com/topics/gitops/)  
37. What is GitOps? \- ARMO, otwierano: listopada 15, 2025, [https://www.armosec.io/glossary/gitops/](https://www.armosec.io/glossary/gitops/)  
38. Blog | GitOps: Making Git your single source of truth \- Toro Cloud \- Lonti, otwierano: listopada 15, 2025, [https://www.lonti.com/blog/defining-gitops-making-git-a-single-source-of-truth](https://www.lonti.com/blog/defining-gitops-making-git-a-single-source-of-truth)  
39. What is GitOps? \- Red Hat, otwierano: listopada 15, 2025, [https://www.redhat.com/en/topics/devops/what-is-gitops](https://www.redhat.com/en/topics/devops/what-is-gitops)  
40. Configuration drift- why it's bad and how to solve it with GitOps and ArgoCD \- Open Liberty, otwierano: listopada 15, 2025, [https://openliberty.io/blog/2024/04/26/argocd-drift-pt1.html](https://openliberty.io/blog/2024/04/26/argocd-drift-pt1.html)  
41. Solving configuration drift using GitOps with Argo CD | CNCF, otwierano: listopada 15, 2025, [https://www.cncf.io/blog/2020/12/17/solving-configuration-drift-using-gitops-with-argo-cd/](https://www.cncf.io/blog/2020/12/17/solving-configuration-drift-using-gitops-with-argo-cd/)  
42. Integrating Argo CD with OpenShift Pipelines: A Practical Guide | Codefresh, otwierano: listopada 15, 2025, [https://codefresh.io/learn/argo-cd/integrating-argo-cd-with-openshift-pipelines-a-practical-guide/](https://codefresh.io/learn/argo-cd/integrating-argo-cd-with-openshift-pipelines-a-practical-guide/)  
43. Chapter 2\. Monitoring | Observability | Red Hat OpenShift GitOps | 1.9, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/red\_hat\_openshift\_gitops/1.9/html/observability/monitoring](https://docs.redhat.com/en/documentation/red_hat_openshift_gitops/1.9/html/observability/monitoring)  
44. Implementing GitOps with ArgoCD: A Step-by-Step Guide | by ..., otwierano: listopada 15, 2025, [https://medium.com/@kalimitalha8/implementing-gitops-with-argocd-a-step-by-step-guide-b79f723b1a43](https://medium.com/@kalimitalha8/implementing-gitops-with-argocd-a-step-by-step-guide-b79f723b1a43)  
45. Configuration Drift Prevention in OpenShift: Resource Locker Operator \- Red Hat, otwierano: listopada 15, 2025, [https://www.redhat.com/en/blog/configuration-drift-prevention-in-openshift-resource-locker-operator](https://www.redhat.com/en/blog/configuration-drift-prevention-in-openshift-resource-locker-operator)  
46. How can I make a Tekton Task's command execution wait until the previous Task's spun up pod is ready for requests \- Stack Overflow, otwierano: listopada 15, 2025, [https://stackoverflow.com/questions/67722457/how-can-i-make-a-tekton-tasks-command-execution-wait-until-the-previous-tasks](https://stackoverflow.com/questions/67722457/how-can-i-make-a-tekton-tasks-command-execution-wait-until-the-previous-tasks)  
47. pytest \- Tekton Hub, otwierano: listopada 15, 2025, [https://hub.tekton.dev/tekton/task/pytest](https://hub.tekton.dev/tekton/task/pytest)  
48. pytest 0.1.0 \- Tekton Tasks \- Artifact Hub, otwierano: listopada 15, 2025, [https://artifacthub.io/packages/tekton-task/tekton-tasks/pytest](https://artifacthub.io/packages/tekton-task/tekton-tasks/pytest)  
49. Maven \- Tekton Hub, otwierano: listopada 15, 2025, [https://hub.tekton.dev/tekton/task/maven](https://hub.tekton.dev/tekton/task/maven)  
50. maven 0.2.0 · test-hub-org/tekton-tasks \- Artifact Hub, otwierano: listopada 15, 2025, [https://artifacthub.io/packages/tekton-task/tekton-tasks/maven](https://artifacthub.io/packages/tekton-task/tekton-tasks/maven)  
51. brightzheng100/tekton-pipeline-example: A very simple but ... \- GitHub, otwierano: listopada 15, 2025, [https://github.com/brightzheng100/tekton-pipeline-example](https://github.com/brightzheng100/tekton-pipeline-example)  
52. Speed up Maven builds in Tekton Pipelines \- Red Hat Developer, otwierano: listopada 15, 2025, [https://developers.redhat.com/blog/2020/02/26/speed-up-maven-builds-in-tekton-pipelines](https://developers.redhat.com/blog/2020/02/26/speed-up-maven-builds-in-tekton-pipelines)  
53. Tasks \- Tekton, otwierano: listopada 15, 2025, [https://tekton.dev/docs/pipelines/tasks/](https://tekton.dev/docs/pipelines/tasks/)  
54. Pipeline stuck running after task failure · Issue \#4840 · tektoncd/pipeline \- GitHub, otwierano: listopada 15, 2025, [https://github.com/tektoncd/pipeline/issues/4840](https://github.com/tektoncd/pipeline/issues/4840)  
55. Add finally tasks to Tekton pipelines \- IBM Developer, otwierano: listopada 15, 2025, [https://developer.ibm.com/blogs/add-finally-to-tekton-pipelines/](https://developer.ibm.com/blogs/add-finally-to-tekton-pipelines/)  
56. Continue Tekton pipeline after failure (similar to jenkins pipeline catchError behaviour) \- Stack Overflow, otwierano: listopada 15, 2025, [https://stackoverflow.com/questions/61749975/continue-tekton-pipeline-after-failure-similar-to-jenkins-pipeline-catcherror-b](https://stackoverflow.com/questions/61749975/continue-tekton-pipeline-after-failure-similar-to-jenkins-pipeline-catcherror-b)  
57. argocd-repositories.yaml example \- Argo CD \- Declarative GitOps CD for Kubernetes, otwierano: listopada 15, 2025, [https://argo-cd.readthedocs.io/en/stable/operator-manual/argocd-repositories-yaml/](https://argo-cd.readthedocs.io/en/stable/operator-manual/argocd-repositories-yaml/)  
58. Private Repositories \- Argo CD \- Declarative GitOps CD for Kubernetes, otwierano: listopada 15, 2025, [https://argo-cd.readthedocs.io/en/stable/user-guide/private-repositories/](https://argo-cd.readthedocs.io/en/stable/user-guide/private-repositories/)  
59. Tracking and Deployment Strategies \- Argo CD \- Declarative GitOps CD for Kubernetes, otwierano: listopada 15, 2025, [https://argo-cd.readthedocs.io/en/latest/user-guide/tracking\_strategies/](https://argo-cd.readthedocs.io/en/latest/user-guide/tracking_strategies/)  
60. Automation from CI Pipelines \- Argo CD \- Declarative GitOps CD for ..., otwierano: listopada 15, 2025, [https://argo-cd.readthedocs.io/en/stable/user-guide/ci\_automation/](https://argo-cd.readthedocs.io/en/stable/user-guide/ci_automation/)  
61. Best Practices \- Argo CD \- Declarative GitOps CD for Kubernetes \- Read the Docs, otwierano: listopada 15, 2025, [https://argo-cd.readthedocs.io/en/stable/user-guide/best\_practices/](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)  
62. Automating Continuous Delivery with ArgoCD Image Updater | by ..., otwierano: listopada 15, 2025, [https://medium.com/@CloudifyOps/automating-continuous-delivery-with-argocd-image-updater-bcd4a84ff858](https://medium.com/@CloudifyOps/automating-continuous-delivery-with-argocd-image-updater-bcd4a84ff858)  
63. Automated Deployment Rollbacks with GitOps Using ArgoCD and ..., otwierano: listopada 15, 2025, [https://medium.com/@bavicnative/automating-deployment-rollbacks-with-gitops-3887a81e1b2a](https://medium.com/@bavicnative/automating-deployment-rollbacks-with-gitops-3887a81e1b2a)  
64. How do you manage rollbacks in a GitOps environment using ArgoCD? \- Reddit, otwierano: listopada 15, 2025, [https://www.reddit.com/r/kubernetes/comments/1cjw033/how\_do\_you\_manage\_rollbacks\_in\_a\_gitops/](https://www.reddit.com/r/kubernetes/comments/1cjw033/how_do_you_manage_rollbacks_in_a_gitops/)  
65. Argo rollouts rollback is being reverted by argo cd auto sync policy : r/kubernetes \- Reddit, otwierano: listopada 15, 2025, [https://www.reddit.com/r/kubernetes/comments/1hy3xrx/argo\_rollouts\_rollback\_is\_being\_reverted\_by\_argo/](https://www.reddit.com/r/kubernetes/comments/1hy3xrx/argo_rollouts_rollback_is_being_reverted_by_argo/)  
66. Argo Rollouts, otwierano: listopada 15, 2025, [https://argoproj.github.io/rollouts/](https://argoproj.github.io/rollouts/)  
67. Argo Rollouts: Quick Guide to Concepts, Setup & Operations \- Codefresh, otwierano: listopada 15, 2025, [https://codefresh.io/learn/argo-rollouts/](https://codefresh.io/learn/argo-rollouts/)  
68. Chapter 1\. Argo Rollouts overview | Argo Rollouts | Red Hat ..., otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/red\_hat\_openshift\_gitops/1.13/html/argo\_rollouts/argo-rollouts-overview](https://docs.redhat.com/en/documentation/red_hat_openshift_gitops/1.13/html/argo_rollouts/argo-rollouts-overview)  
69. Canary deployment strategy with Argo Rollouts and OpenShift Service Mesh, otwierano: listopada 15, 2025, [https://developers.redhat.com/articles/2024/05/28/canary-deployment-strategy-argo-rollouts-and-openshift-service-mesh](https://developers.redhat.com/articles/2024/05/28/canary-deployment-strategy-argo-rollouts-and-openshift-service-mesh)  
70. Chapter 3\. Getting started with Argo Rollouts \- Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/red\_hat\_openshift\_gitops/1.13/html/argo\_rollouts/getting-started-with-argo-rollouts](https://docs.redhat.com/en/documentation/red_hat_openshift_gitops/1.13/html/argo_rollouts/getting-started-with-argo-rollouts)  
71. Canary deployment strategy with Argo Rollouts | Red Hat Developer, otwierano: listopada 15, 2025, [https://developers.redhat.com/articles/2024/05/01/canary-deployment-strategy-argo-rollouts](https://developers.redhat.com/articles/2024/05/01/canary-deployment-strategy-argo-rollouts)  
72. Chapter 1\. Using Argo Rollouts for progressive deployment delivery, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/red\_hat\_openshift\_gitops/1.11/html/argo\_rollouts/using-argo-rollouts-for-progressive-deployment-delivery](https://docs.redhat.com/en/documentation/red_hat_openshift_gitops/1.11/html/argo_rollouts/using-argo-rollouts-for-progressive-deployment-delivery)
