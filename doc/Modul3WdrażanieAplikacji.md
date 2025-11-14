# Moduł 3: Wdrażanie Aplikacji (Deployment)

## Wprowadzenie: Ewolucja Wdrożeń Aplikacji na Platformie OpenShift

### Kontekst: Kubernetes jako Fundament, OpenShift jako Platforma Wartości Dodanej

U podstaw OpenShift Container Platform (OCP) leży Kubernetes – de facto standard orkiestracji kontenerów.[7] Jednak we wczesnych fazach rozwoju Kubernetesa brakowało wielu funkcji niezbędnych do stworzenia kompletnego, przyjaznego dla programistów środowiska Platform-as-a-Service (PaaS). OpenShift w wersji 3 (OCP 3) wypełnił tę lukę, dostarczając zintegrowane środowisko, które uzupełniało "surowy" K8s o kluczowe komponenty, takie jak wbudowane przepływy CI/CD, zarządzanie obrazami i uproszczone obiekty wdrożeniowe.[8, 9, 10]

### Historyczna Dychotomia: Powstanie `DeploymentConfig`

Centralnym elementem tej wartości dodanej był `DeploymentConfig` (DC), obiekt "pierwszej klasy" w ekosystemie OpenShift.[8, 10] Został on stworzony, aby zapewnić kluczowe funkcjonalności, których brakowało ówczesnym natywnym obiektom K8s. Funkcje te obejmowały:

1.  **Automatyczne Triggery:** Możliwość automatycznego uruchamiania nowego wdrożenia w odpowiedzi na zmianę obrazu w rejestrze (poprzez `ImageChangeTrigger`) lub zmianę konfiguracji.[9, 11, 12]
2.  **Haki Cyklu Życia (Lifecycle Hooks):** Zdolność do uruchamiania skryptów lub zadań w kluczowych fazach procesu wdrażania (np. `pre` i `post` hooks).[9, 11, 12]
3.  **Automatyczne Wycofanie (Rollback):** Wbudowany mechanizm automatycznego powrotu do poprzedniej, stabilnej wersji w przypadku niepowodzenia nowego wdrożenia.[9]

### Współczesna Konwergencja i Status `DeploymentConfig`

Z biegiem lat natywny obiekt `Deployment` (Deploy) w Kubernetes dojrzał, wchłaniając wiele zaawansowanych koncepcji (takich jak `RollingUpdate`) i stając się solidnym, deklaratywnym standardem zarządzania aplikacjami.[13, 14] W rezultacie, wiele funkcji `DeploymentConfig` stało się redundantnych lub miało swoje odpowiedniki w ekosystemie K8s.

Doprowadziło to do kluczowej zmiany w strategii OpenShift. Jak podaje oficjalna dokumentacja (począwszy od OKD 4.14 / OCP 4.14), **obiekt `DeploymentConfig` jest oficjalnie przestarzały (Deprecated)**.[3, 15] Nie jest on zalecany dla nowych instalacji, a jego wsparcie ogranicza się do krytycznych poprawek bezpieczeństwa.[3] Oficjalna rekomendacja Red Hat jest jasna: należy używać natywnych obiektów `Deployment` dla wszystkich nowych aplikacji, chyba że istnieje absolutna konieczność wykorzystania specyficznej, historycznej funkcji `DeploymentConfig`, której nie można replikować w `Deployment`.[10, 16]

Ta deprecjacja to nie tylko techniczna wymiana. Sygnalizuje ona fundamentalną zmianę strategii produktu OpenShift. Oznacza to przejście od *zastępowania* i *rozszerzania* K8s za pomocą własnych, konkurencyjnych obiektów API (model OCP 3, np. `apps.openshift.io/v1` [10]) do *pełnego przyjęcia* natywnego API K8s (np. `apps/v1` [2, 10]) i skupienia się na *ulepszaniu* go za pomocą dodatkowych, luźno powiązanych kontrolerów i adnotacji. Takie podejście drastycznie poprawia kompatybilność z szerokim ekosystemem narzędzi K8s (np. GitOps) i pozycjonuje OCP jako w pełni zgodną z upstream dystrybucję K8s, a nie odrębną gałąź.

## Lekcja 3.1: `Deployment` (K8s) vs `DeploymentConfig` (OCP) – Kiedy używać którego?

*(Na podstawie Lekcji 3.1: `Deployment` (K8s) vs `DeploymentConfig` (OCP))*

### 1.1. Filozofia Projektowa: Deklaratywny GitOps (`Deployment`) vs. Imperatywny Model Zdarzeniowy (`DeploymentConfig`)

Różnica między `Deployment` a `DeploymentConfig` nie jest tylko techniczna; jest fundamentalnie filozoficzna i dotyczy sposobu, w jaki zarządzamy stanem aplikacji.

*   **`Deployment` (K8s): Model Deklaratywny (Zorientowany na Stan)**
    Obiekt `Deployment` opisuje *pożądany stan końcowy* systemu.[2, 17] Użytkownik definiuje w manifeście YAML: "Chcę, aby 10 replik aplikacji X, używając obrazu Y, było uruchomionych". Pętla kontrolera Kubernetesa (Deployment Controller) nieustannie pracuje w tle, aby *uzgodnić* (reconcile) *rzeczywisty stan* klastra z tym *pożądanym stanem*. Każda zmiana w manifeście, np. aktualizacja tagu obrazu w `spec.template`, jest automatycznie traktowana jako nowa definicja pożądanego stanu, co niejawnie uruchamia proces wdrożenia (rollout).[1, 16, 18]

    Ten model jest fundamentem praktyk **GitOps**. W podejściu GitOps, repozytorium Git staje się jedynym, autorytatywnym źródłem prawdy (Single Source of Truth) dla pożądanego stanu.[17, 19] Narzędzia takie jak Argo CD lub Flux monitorują Git i automatycznie stosują deklaratywne manifesty `Deployment` do klastra, aby nieustannie korygować jego stan.

*   **`DeploymentConfig` (OCP): Model Imperatywny (Zorientowany na Zdarzenia)**
    Obiekt `DeploymentConfig` opisuje *szablon* (`template`) aplikacji [12, 20] oraz *triggery* (wyzwalacze), które mają *inicjować* proces wdrożenia.[9, 11, 12] Sam manifest `DC` nie uruchamia wdrożenia; jest on "uśpiony" lub "martwy", dopóki nie zostanie aktywowany przez *zdarzenie* – takie jak zmiana obrazu w `ImageStream`, zmiana w `ConfigMap` (jeśli skonfigurowano) lub ręczne polecenie `oc rollout latest`.[15, 21] Jak zauważono, podejście imperatywne może wydawać się bardziej reaktywne, dając "natychmiastowe rezultaty".[22]

    Ten model imperatywny był historycznie bardziej intuicyjny dla deweloperów przyzwyczajonych do tradycyjnych, sekwencyjnych potoków CI/CD (np. Jenkins), które działają na zasadzie "Krok 1: Zbuduj, Krok 2: Przetestuj, Krok 3: Wdróż".[23, 24] W tym modelu, zdarzenie "zakończenie budowania" (reprezentowane przez aktualizację `ImageStream`) *bezpośrednio wyzwala* zdarzenie "rozpocznij wdrażanie".[15]

    Jednak ten model, choć prosty koncepcyjnie, jest architektonicznie mniej solidny niż model deklaratywny. Model imperatywny jest wrażliwy na utracone zdarzenia. Co więcej, jest podatny na "dryf stanu" (state drift) – jeśli administrator ręcznie zmieni stan klastra, `DeploymentConfig` (który nie został wyzwolony) nie skoryguje tej zmiany automatycznie. Model deklaratywny (`Deployment` + GitOps) jest znacznie solidniejszy, ponieważ nie opiera się na zdarzeniach. Kontroler GitOps będzie nieustannie korygował dryf stanu, aby dopasować go do definicji w Git, niezależnie od tego, czy "trigger" został pomyślnie obsłużony. Przejście branży z `DC` na `Deploy` odzwierciedla zatem dojrzewanie od "automatyzacji opartej na zdarzeniach" do "zarządzania opartego na stanie".

### 1.2. Architektura Pętli Sterowania: `ReplicaSet` vs. `ReplicationController`

Pod maską, `Deployment` i `DeploymentConfig` używają różnych, fundamentalnych obiektów K8s do zarządzania replikami podów.

*   **`DeploymentConfig` (OCP) używa `ReplicationController` (RC)**
    `DeploymentConfig` jest historycznie powiązany ze starszym obiektem `ReplicationController` (RC).[1, 3, 8, 11, 16, 25, 26] `ReplicationController` to obiekt K8s (obecnie w dużej mierze zastąpiony), który zapewnia, że określona liczba replik podów jest uruchomiona.[26, 27] Kluczowym ograniczeniem `ReplicationController` jest to, że wspiera on **tylko selektory oparte na równości** (equality-based selectors), np. `label: 'frontend'`.[25, 28]

*   **`Deployment` (K8s) używa `ReplicaSet` (RS)**
    Z kolei `Deployment` zarządza swoimi podami za pośrednictwem nowocześniejszego obiektu `ReplicaSet` (RS).[1, 3, 13, 14, 16] `ReplicaSet` jest bezpośrednim następcą i ewolucją `ReplicationController`.[7, 13, 14, 27, 28] Kluczową przewagą `ReplicaSet` jest wsparcie dla **selektorów opartych na zbiorach** (set-based selectors), np. `app in (frontend, backend)` lub `!version`.[14, 25, 28] Daje to znacznie większą elastyczność w definiowaniu, które pody "należą" do danego wdrożenia.

### 1.3. Mechanika Procesu Rolloutu: Dedykowany Pod Wdrażający (Deployer Pod) vs. Pętla Kontrolera

Najbardziej znacząca różnica architektoniczna leży w *sposobie* przeprowadzania samego rolloutu.

*   **`DeploymentConfig` (OCP): Proces Zarządzany przez "Deployer Pod"**
    Gdy `DeploymentConfig` jest wyzwalany, platforma OCP tworzy nowy `ReplicationController` (np. `myapp-v2`) oraz specjalny, efemeryczny **"Deployer Pod"** (np. `myapp-v2-deploy`).[11, 12] Ten Deployer Pod jest *aktywnym, imperatywnym procesem*, który *orchiestruje* całe wdrożenie.[11, 12] Jego zadania, wykonywane sekwencyjnie, to:
    1.  Uruchomienie haka `pre` (jeśli zdefiniowany).
    2.  Skalowanie nowego `ReplicationController` (`myapp-v2`) w górę.
    3.  Skalowanie starego `ReplicationController` (`myapp-v1`) w dół.
    4.  Uruchomienie haka `post` (jeśli zdefiniowany).[11, 12, 16]
    Ograniczeniem tego podejścia jest to, że w danym momencie może działać co najwyżej *jeden* Deployer Pod dla danego `DC`. Ma to na celu zapobieganie konfliktom, ale oznacza, że w danym momencie mogą być aktywne tylko *dwa* `ReplicationController` (stary i nowy).[3, 26]

*   **`Deployment` (K8s): Proces Zarządzany przez Kontroler (Controller Loop)**
    Rollout obiektu `Deployment` jest zarządzany przez wbudowany, asynchroniczny **Deployment Controller Manager**, działający jako część płaszczyzny sterowania (control plane) Kubernetesa.[26] Gdy manifest `Deployment` jest aktualizowany, kontroler tworzy nowy `ReplicaSet` (np. `myapp-rs-abc`). Następnie, w asynchronicznej pętli uzgadniania, kontroler *równolegle i proporcjonalnie* zarządza skalowaniem starego `ReplicaSet` w dół i nowego `ReplicaSet` w górę.[26]
    Przewaga jest znacząca: nie ma pojedynczego "Deployer Poda", który mógłby ulec awarii i zatrzymać proces. Proces jest asynchroniczną pętlą uzgadniania. Pozwala to na jednoczesne istnienie *wielu* `ReplicaSet` (np. podczas szybkiego rolloutu i natychmiastowego rollbacku), co ostatecznie przekłada się na szybsze i bardziej odporne na błędy wdrożenia.[26]

Wybór `ReplicationController` (z jego prostymi selektorami równościowymi [25]) dla `DeploymentConfig` nie był przypadkiem. Był on *konieczny* dla imperatywnej logiki `Deployer Pod`. `Deployer Pod` [26] wykonuje prosty skrypt: "znajdź stary RC, stwórz nowy RC, skaluj". Potrzebuje prostego sposobu na odróżnienie "starego" od "nowego". Bardziej złożone, oparte na zbiorach selektory `ReplicaSet` [28] są zaprojektowane dla świata, w którym pętla kontrolera asynchronicznie zarządza *wieloma* nakładającymi się zestawami replik.[26] Ta elastyczność jest niekompatybilna z prostą, imperatywną logiką `Deployer Pod`.

### 1.4. Implikacje Teoremu CAP: Dostępność (`Deployment`) vs. Spójność (`DeploymentConfig`)

Ta różnica w mechanice rolloutu ma bezpośrednie przełożenie na gwarancje systemowe, co dokumentacja Red Hat opisuje w kontekście kompromisu między dostępnością a spójnością.[1]

*   **`DeploymentConfig` (Priorytet: Spójność - Consistency)**
    Jeśli węzeł, na którym działa `Deployer Pod`, ulegnie awarii, ten pod *nie zostanie zastąpiony*.[1] Cały proces wdrożenia zostaje *zatrzymany* i czeka na powrót węzła lub ręczną interwencję administratora.[1] System OCP wybiera spójność ponad dostępność. Zapobiega to scenariuszowi "split-brain", w którym mogłyby działać *dwa* `Deployer Pody` (stary i nowy, zastępczy), które jednocześnie próbowałyby zarządzać skalowaniem tych samych `ReplicationController`, prowadząc do niespójnego stanu i chaosu.[26] System woli "bezpiecznie" zatrzymać proces niż ryzykować niespójny stan.[1, 2, 29]

*   **`Deployment` (Priorytet: Dostępność - Availability)**
    Deployment Controller Manager działa jako wysoce dostępny proces na wielu węzłach master (płaszczyzny sterowania).[26] Jeśli aktywny kontroler ulegnie awarii, inny natychmiast przejmuje jego rolę dzięki mechanizmowi "leader election".[26] Co najważniejsze, pętla uzgadniania jest *idempotentna*. Nowy kontroler po prostu sprawdzi aktualny stan (np. "stary RS ma 5 replik, nowy RS ma 3 repliki") i będzie kontynuował proces skalowania od miejsca, w którym został przerwany. System wybiera kontynuowanie procesu wdrażania (dostępność).[1, 2, 29]

### 1.5. Tabela 1: Porównanie Funkcji i Architektury: `Deployment` vs. `DeploymentConfig`

Poniższa tabela syntetyzuje kluczowe różnice architektoniczne i funkcjonalne między tymi dwoma obiektami.

| Cecha (Feature) | `Deployment` (Kubernetes Native) | `DeploymentConfig` (OpenShift Legacy) | Źródła |
| :--- | :--- | :--- | :--- |
| **Grupa API** | `apps/v1` | `apps.openshift.io/v1` | [7, 10] |
| **Podstawowy Kontroler** | `ReplicaSet` (RS) | `ReplicationController` (RC) | [1, 8, 16, 25] |
| **Typ Selektora Podów** | Oparty na zbiorach (Set-based) | Oparty na równości (Equality-based) | [25, 28] |
| **Mechanizm Rolloutu** | Asynchroniczna pętla kontrolera | Synchroniczny `Deployer Pod` | [11, 12, 26] |
| **Priorytet (CAP)** | Dostępność (Availability) | Spójność (Consistency) | [1, 2, 29] |
| **Natywne Triggery** | Brak (tylko niejawna zmiana `spec.template`) | `ImageChange`, `ConfigChange` | [9, 12, 16, 30] |
| **Haki Cyklu Życia** | Brak (używa `Pod.spec.lifecycle`) | `pre`, `mid`, `post` (specyficzne dla strategii) | [9, 11, 12, 16] |
| **Automatyczny Rollback** | Nie (tylko ręczny `kubectl rollout undo`) | Tak (wbudowany po niepowodzeniu wdrożenia) | [9, 16, 21] |
| **Wersjonowanie** | Poprzez zarządzanie historią `ReplicaSet` | Poprzez kolejne `ReplicationController` (np. `myapp-1`, `myapp-2`) | [20, 26, 31] |
| **Status (OCP 4.14+)** | **Rekomendowany** | **Przestarzały (Deprecated)** | [3, 10, 15, 16] |

### 1.6. Rekomendacja Strategiczna: Zrozumieć Przeszłość, Implementować Przyszłość

Na podstawie powyższej analizy, wytyczne strategiczne są klarowne:

*   **Dla Nowych Aplikacji:** Kategorycznie należy używać natywnych obiektów `Deployment` (`apps/v1`).[3, 10, 16] Są one zgodne ze standardem K8s, wspierane przez cały ekosystem (w tym narzędzia GitOps) i mają bardziej odporną na błędy, wysoko dostępną architekturę rolloutu. Najnowsze wersje narzędzi OCP, takie jak `oc new-app`, domyślnie tworzą obiekty `Deployment`.[32]
*   **Dla Istniejących (Legacy) Aplikacji:** Dogłębne zrozumienie mechaniki `DeploymentConfig` jest absolutnie kluczowe do utrzymania, debugowania i ostatecznie planowania migracji starszych aplikacji.[10] Należy je zachować only wtedy, gdy aplikacja krytycznie polega na specyficznych funkcjach, takich jak niestandardowe (`custom`) strategie wdrażania lub złożone haki cyklu życia (`pre`/`post` hooks), które nie mają bezpośredniego odpowiednika w `Deployment`.[9, 16, 29]

## Lekcja 3.2: Triggery w `DeploymentConfig` (np. automatyczne wdrożenie po zmianie obrazu)

*(Na podstawie Lekcji 3.2: Triggery w `DeploymentConfig`)*

### 2.1. Główny Powód Popularności `DC`: Analiza Mechanizmów Triggerów

Historycznie, głównym powodem, dla którego deweloperzy i administratorzy preferowali `DeploymentConfig`, była jego natywna integracja z automatyzacją CI/CD poprzez system triggerów.[8, 9] Triggery te "automatycznie napędzają tworzenie nowych wdrożeń" w odpowiedzi na zdarzenia w klastrze.[11, 12, 15, 21]

Dwa najważniejsze typy triggerów to:

1.  **`ConfigChangeTrigger`:** Ten trigger automatycznie uruchamia nowe wdrożenie za każdym razem, gdy zostanie wykryta zmiana w `spec.template` (szablonie poda) obiektu `DeploymentConfig`.[1, 9, 16, 18, 33, 34] Jest to trigger dodawany domyślnie, jeśli żaden inny nie jest zdefiniowany.[1, 16, 21, 34] Warto zauważyć, że natywne `Deployment` K8s mają to zachowanie wbudowane z definicji – każda zmiana w `spec.template` jest traktowana jako nowy "pożądany stan" i rozpoczyna rollout.[1, 16, 18]
2.  **`ImageChangeTrigger`:** To była kluczowa i najbardziej ceniona funkcja "magii" OpenShift.[9] Ten trigger uruchamia nowe wdrożenie, gdy "zawartość tagu `ImageStream` ulegnie zmianie" [12, 15, 33, 34, 35] – czyli, gdy tag (np. `myapp:latest`) zacznie wskazywać na nowy, unikalny identyfikator (SHA) obrazu. W konfiguracji `DC` (w sekcji `spec.triggers`) definiuje się, który `ImageStreamTag` ma być monitorowany i który kontener w szablonie poda ma być aktualizowany tym nowym obrazem.[12, 20]

### 2.2. Kluczowy Obiekt OCP: Demistyfikacja `ImageStream`

Aby zrozumieć `ImageChangeTrigger`, kluczowe jest zrozumienie obiektu `ImageStream`.

*   **Czym Jest `ImageStream`?** Jest to obiekt API specyficzny dla OpenShift (`image.openshift.io/v1`).[36]
*   **Czym *Nie* Jest `ImageStream`?** Wbrew mylącej nazwie, *nie* jest to rejestr kontenerów. *Nie* przechowuje on fizycznie warstw obrazu ani danych binarnych.[11, 36, 37, 38]
*   **Jak Działa?** `ImageStream` to wirtualny wskaźnik, abstrakcja lub zbiór metadanych.[11, 36, 37] Prezentuje on "wirtualny widok powiązanych obrazów".[37] Działa jak tablica mapująca, tworząc powiązanie między przyjaznymi dla człowieka "tagami" (np. `myapp:latest`, `myapp:1.2.0`) a konkretnymi, niezmiennymi identyfikatorami obrazów (SHA digest, np. `sha256:abc...`) w *rzeczywistym* rejestrze kontenerów. Rejestr ten może być wewnętrznym rejestrem OCP lub dowolnym rejestrem zewnętrznym (jak Quay.io, Artifactory, Docker Hub).[36, 37, 39]
*   **Dlaczego jest Użyteczny?**
    1.  **Abstrakcja:** Obiekty takie jak `DeploymentConfig` lub `BuildConfig` odwołują się do *tagu `ImageStream`* (np. `myapp:latest`), a nie do pełnej, zahardkodowanej ścieżki rejestru (np. `rejestr.firma.com/prod/myapp:latest`).[37, 38]
    2.  **Przenośność:** Jeśli zespół zdecyduje się przenieść swoje obrazy z rejestru deweloperskiego do produkcyjnego, wystarczy, że zaktualizuje definicję `ImageStream` (pole `spec.tags.from`), aby wskazywała na nową lokalizację. *Żaden* z dziesiątek `DeploymentConfig` odwołujących się do tego strumienia nie wymaga modyfikacji.[38]
    3.  **Wyzwalanie (Triggers):** Co najważniejsze, platforma OCP *aktywnie monitoruje* tagi w `ImageStream`. Pozwala to wykrywać "nowe" obrazy (nowe SHA) i automatycznie uruchamiać powiązane procesy, takie jak Buildy lub Deploymenty.[33, 37, 40, 41]

### 2.3. Mechanika Integracji: Jak `DeploymentConfig` "Słucha" `ImageStream`

Proces ten oparty jest na architekturze "obserwatora" (watcher) zaimplementowanej w kontrolerach OpenShift.

1.  W obiekcie `DeploymentConfig`, w definicji `ImageChangeTrigger` [12, 20], administrator "subskrybuje" określony `ImageStreamTag`.
2.  W tle działa specjalizowany kontroler OpenShift (tzw. `imagechangetrigger controller` [42]), który monitoruje *wszystkie* obiekty `ImageStream` w klastrze.[42]
3.  Gdy `ImageStream` jest aktualizowany – na przykład `BuildConfig` wypycha nowy obraz lub administrator ręcznie importuje obraz (`oc import-image`) – kontroler wykrywa tę zmianę (fakt, że tag wskazuje na nowy SHA).[34, 37]
4.  Kontroler następnie przeszukuje klaster w poszukiwaniu wszystkich obiektów (np. `DeploymentConfig`), które subskrybują ten konkretny, zmieniony tag.[42, 43]
5.  Dla każdego znalezionego `DC`, kontroler wykonuje operację *PATCH* na obiekcie `DC`, aktualizując pole `spec.template.spec.containers.image`. Wstawia tam *nowy, niezmienny SHA* obrazu (np. `image-registry.openshift-image-registry.svc:5000/myproject/myapp@sha256:abc...`).[11, 39]
6.  Ta aktualizacja `spec.template` jest następnie wykrywana przez (zazwyczaj również obecny) `ConfigChangeTrigger` [16, 44], co w końcu inicjuje nowy rollout.

### 2.4. Kompletna Pętla CI/CD (Model "Klasyczny" OCP): Od Kodu do Poda

Ten mechanizm triggerów był fundamentem "magicznego", w pełni zintegrowanego przepływu CI/CD w OCP 3.[23, 24] Przepływ ten wyglądał następująco:

1.  **Krok 1: `git push`**: Deweloper wypycha zmiany w kodzie aplikacji do repozytorium Git.[23, 24]
2.  **Krok 2: Uruchomienie `BuildConfig`**: Skonfigurowany w Git Webhook wysyła żądanie do API OpenShift.[24, 33, 45] Ten webhook jest powiązany z obiektem OCP `BuildConfig`.[46]
3.  **Krok 3: Budowanie Obrazu (np. S2I)**: `BuildConfig` uruchamia proces budowania.[46] W popularnym trybie Source-to-Image (S2I) [24, 47, 48], OCP pobiera kod źródłowy z Git [49] i łączy go z obrazem budującym (np. `python:3.9`), kompilując i tworząc finalny, uruchamialny obraz aplikacji.[46]
4.  **Krok 4: Aktualizacja `ImageStream`**: `BuildConfig` ma zdefiniowaną sekcję `output` [35], która wskazuje na `ImageStreamTag` (np. `myapp:latest`).[45, 48] Po pomyślnym zbudowaniu, nowy obraz jest wypychany do wewnętrznego rejestru OCP, a `ImageStreamTag` `myapp:latest` jest automatycznie aktualizowany, aby wskazywać na SHA tego nowego obrazu.[23, 37]
5.  **Krok 5: Uruchomienie `DeploymentConfig`**: `DeploymentConfig` danej aplikacji [45] ma skonfigurowany `ImageChangeTrigger` [12], który "słucha" tego samego `ImageStreamTag` `myapp:latest`.[40, 41]
6.  **Krok 6: Wdrożenie Nowych Podów**: Trigger zostaje aktywowany (jak opisano w sekcji 2.3). `DeploymentConfig` rozpoczyna nowy proces wdrażania (tworząc Deployer Pod i nowy RC), który wdraża pody z nowym obrazem aplikacji.[12, 15, 45]

Ten zintegrowany przepływ był niezwykle potężny. Jedna komenda `oc new-app <git-repo>` [45] potrafiła automatycznie stworzyć *wszystkie* te obiekty (`BuildConfig`, `ImageStream`, `DeploymentConfig`, `Service`) i połączyć je ze sobą, tworząc w pełni funkcjonalny potok CI/CD "z kodu do poda" w kilka sekund.[23, 24] Było to kwintesencją doświadczenia PaaS.[9]

Jednakże ta ścisła integracja była jednocześnie największą słabością. Cały przepływ opierał się wyłącznie na obiektach *specyficznych dla OpenShift* (`BC`, `IS`, `DC`) [10, 46], tworząc silne uzależnienie od platformy ("vendor lock-in"). Zewnętrzne narzędzia CI (Jenkins, GitLab CI) i co ważniejsze, nowoczesne narzędzia GitOps (Argo CD, Flux) nie rozumieją, czym są te obiekty.[30] W miarę jak rynek standaryzował się wokół zewnętrznych, agnostycznych narzędzi CI/CD (np. Tekton [19]) i GitOps [17, 19], ten monolityczny, zamknięty model OCP stał się obciążeniem.

### 2.5. Zaawansowany Wgląd: Jak Osiągnąć Funkcjonalność Triggerów w Nowoczesnych `Deployment` K8s

Powstał dylemat: Jak pogodzić oficjalną rekomendację "używaj `Deployment`" [3] z faktem, że deweloperzy *potrzebują* automatycznych triggerów z `ImageStream` [9], których `Deployment` natywnie nie posiada?[16, 30]

Rozwiązaniem OpenShift jest "pomost" architektoniczny: adnotacja `image.openshift.io/triggers`.[4, 5, 41, 50, 51, 52, 53]

Mechanizm ten jest genialny w swojej prostocie i demonstruje nową filozofię OCP:

1.  Użytkownik tworzy w 100% *natywny* manifest `Deployment` (`apps/v1`).
2.  Do sekcji `metadata.annotations` dodaje specjalną adnotację `image.openshift.io/triggers`.[4, 5, 41]
3.  Wartość tej adnotacji to fragment JSON, który definiuje:
    *   **Co monitorować:** `from.kind: "ImageStreamTag"` i `from.name: "myapp:latest"`.[4, 41, 50]
    *   **Co aktualizować:** `fieldPath: "spec.template.spec.containers[?(@.name=='web')].image"` (JSONPath wskazujący na pole obrazu w kontenerze 'web').[4, 41, 50]
4.  Ten sam kontroler OCP (`imagechangetrigger controller` [42]), który wcześniej monitorował `DC`, monitoruje również te adnotacje w rdzennych obiektach K8s (w tym `Deployment`, `StatefulSet`, `CronJob` itd.).[41, 50, 51]
5.  Gdy `ImageStreamTag` `myapp:latest` jest aktualizowany, kontroler OCP *edytuje* (PATCH) obiekt `Deployment` i *bezpośrednio wstrzykuje* nowy SHA obrazu w pole wskazane przez `fieldPath`.[41, 50]
6.  Ta edycja `Deployment` to zmiana w `spec.template`.
7.  *Natywny* kontroler `Deployment` Kubernetesa (który nie wie nic o OCP) wykrywa tę zmianę i automatycznie rozpoczyna standardowy, natywny rollout.[41, 50]

Administratorzy nie muszą pisać tego JSONa ręcznie. Komenda `oc set triggers` została zaktualizowana i działa teraz również na obiektach `Deployment`:
`oc set triggers deploy/my-deploy --from-image=myapp:latest -c web`.[4, 41, 50, 53]

Ten model jest architektonicznie *znacznie lepszy* niż `DeploymentConfig`. Obiekt `Deployment` pozostaje w 100% zgodny ze standardem K8s [4, 5] (zwykły klaster K8s po prostu zignorowałby tę adnotację). Specjalny kontroler OCP [42] działa w tle, *obserwuje* tę adnotację i *reaguje* na nią.[41, 51] Jest to dokładnie Wzorzec Operatora (Operator Pattern) w działaniu. Logika rolloutu (`Deployment` controller) jest całkowicie oddzielona (decoupled) od logiki triggerów (`ImageTrigger` controller).[50] Manifest `Deployment` jest w pełni przenośny – na OCP zyskuje "supermoc" automatycznego triggera; na każdym innym klastrze K8s po prostu działa.

## Lekcja 3.3: Strategie Wdrożeniowe (Rolling, Recreate, Blue-Green)

*(Na podstawie Lekcji 3.3: Strategie Wdrożeniowe)*

Zarówno `Deployment`, jak i `DeploymentConfig` wspierają definiowanie strategii, czyli sposobu, w jaki nowa wersja aplikacji zastępuje starą. Wybór strategii ma kluczowy wpływ na dostępność usługi i wykorzystanie zasobów.

### 3.1. Tabela 2: Przegląd Strategii Wdrożeniowych

Poniższa tabela przedstawia kluczowe kompromisy między najczęściej używanymi strategiami.

| Strategia | Mechanizm | Przestoje (Downtime) | Kluczowy Przypadek Użycia | Wymagane Zasoby | Źródła |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`Rolling` (Domyślna)** | Stopniowa wymiana podów (nowe w górę, stare w dół) | **Zero** (przy poprawnej konfiguracji `Readiness Probe`) | Aplikacje bezstanowe, zdolne do obsługi wielu wersji | N + `maxSurge` (np. 125%) | [2, 6, 54, 55] |
| **`Recreate`** | Zatrzymaj wszystkie stare pody, następnie uruchom wszystkie nowe | **Tak** (gwarantowany, krótki przestój) | Aplikacje stanowe z wolumenem `ReadWriteOnce` (RWO) | N (brak dodatkowych zasobów) | [2, 6, 26, 56, 57] |
| **`Blue-Green`** | Dwa równoległe środowiska (Blue, Green), przełączenie ruchu na poziomie `Route`/`Service` | **Zero** (natychmiastowe przełączenie ruchu) | Aplikacje krytyczne, testowanie A/B, potrzeba natychmiastowego rollbacku | **2N** (podwójne zasoby) | [54, 56, 58, 59, 60] |

### 3.2. Strategia `Rolling` (Domyślna): Wdrożenia bez Przestojów

Strategia `Rolling` (lub `RollingUpdate`) jest domyślną strategią zarówno dla `Deployment`, jak i `DeploymentConfig`.[2, 18] Jej celem jest osiągnięcie wdrożenia bez przestojów (zero downtime) [6, 54, 55] poprzez stopniowe, kontrolowane zastępowanie podów starej wersji podami nowej wersji.[2, 6]

Proces ten jest kontrolowany przez dwa kluczowe parametry:

*   `maxSurge`: (Maksymalny wzrost) Definiuje, ile *dodatkowych* podów (ponad liczbę `spec.replicas`) można utworzyć podczas rolloutu. Może być liczbą stałą (np. `1`) lub procentem (np. `20%`).[2, 54, 55] Użycie `maxSurge` przyspiesza wdrożenia, ale wymaga dodatkowych zasobów.[16, 55]
*   `maxUnavailable`: (Maksymalna niedostępność) Definiuje, ile podów (poniżej liczby `spec.replicas`) może być *niedostępnych* podczas rolloutu. Może być liczbą stałą (np. `1`) lub procentem (np. `10%`).[2, 54, 55] Jest to opcja dla środowisk z ograniczonymi zasobami, gdzie nie można pozwolić sobie na `maxSurge`.[16, 55] Ustawienie `maxUnavailable: 0` gwarantuje, że pełna pojemność (liczona jako suma starych i nowych podów) jest utrzymana przez cały czas trwania rolloutu.[61]

Krytycznym wymogiem dla sukcesu strategii `Rolling` jest poprawna implementacja sondy `Readiness Probe` (gotowości) w aplikacji.[2, 6] System musi wiedzieć, kiedy nowy pod jest *faktycznie gotowy* do przyjmowania ruchu, zanim będzie mógł bezpiecznie wyłączyć stary pod.[6] Ponadto aplikacja musi być w stanie obsłużyć dwie różne wersje działające jednocześnie (np. pod kątem kompatybilności schematu bazy danych).[6, 54]

### 3.3. Strategia `Recreate`: Świadome Zarządzanie Przestojem dla Aplikacji Stanowych

Strategia `Recreate` implementuje prosty, ale brutalny mechanizm `Stop-Before-Start`.[2, 56]

1.  Najpierw wszystkie pody starej wersji są zatrzymywane (skalowane do 0).[26, 56]
2.  *Dopiero gdy* wszystkie stare pody zostaną zakończone, uruchamiane są pody nowej wersji (skalowane do N).[56]

Skutkiem jest gwarantowany, choć zazwyczaj krótki, przestój (downtime), podczas którego aplikacja nie jest dostępna.[26, 56]

Choć na pierwszy rzut oka wydaje się to niepożądane, strategia `Recreate` jest *niezbędna* i jest kluczowym przypadkiem użycia dla aplikacji stanowych, które korzystają z wolumenów trwałych (Persistent Volumes) w trybie dostępu `ReadWriteOnce` (RWO).[6] Wiele popularnych typów pamięci masowej (np. AWS EBS [57], Azure Disk, GCE Persistent Disk) wspiera tylko tryb RWO, co oznacza, że dany wolumen może być podmontowany *tylko do jednego węzła klastra* w danym momencie.[6]

Wyobraźmy sobie próbę wdrożenia strategią `Rolling` aplikacji (np. z `replicas: 1` [62]) używającej wolumenu RWO:
1.  `Pod-v1` działa na `Node-A` i ma podmontowany wolumen RWO.
2.  Rozpoczyna się `Rolling` update (z `maxSurge: 1`). Kontroler tworzy `Pod-v2`.
3.  Scheduler K8s umieszcza `Pod-v2` na `Node-B`.
4.  `Pod-v2` próbuje się uruchomić i żąda podmontowania tego samego wolumenu RWO.
5.  System operacyjny na `Node-B` zwraca błąd, ponieważ wolumen jest już zablokowany i używany przez `Node-A`.
6.  `Pod-v2` utyka w pętli `ContainerCreating` lub `Pending`, czekając na zwolnienie wolumenu. Jego `Readiness Probe` nigdy nie przechodzi.
7.  Ponieważ `Pod-v2` nie jest "Ready", kontroler `Rolling` (z np. `maxUnavailable: 0`) *nigdy* nie zabije `Pod-v1`.
8.  Cały proces wdrożenia utknął w martwym punkcie (deadlock).

Strategia `Recreate` rozwiązuje ten problem:
1.  Kontroler najpierw zabija `Pod-v1`.[56]
2.  `Pod-v1` kończy działanie, a `Node-A` zwalnia blokadę na wolumenie RWO.
3.  *Dopiero teraz* kontroler tworzy `Pod-v2`.
4.  `Pod-v2` (niezależnie od tego, na którym węźle wyląduje) pomyślnie podmontowuje zwolniony wolumen RWO i uruchamia się.

Strategia `Recreate` nie jest więc "gorsza" – jest to niezbędne narzędzie do zapewnienia spójności i uniknięcia zakleszczenia podczas wdrażania aplikacji stanowych, które nie są zaprojektowane jako "cloud-native" (tj. nie używają pamięci `ReadWriteMany` (RWX) lub nie zarządzają replikacją na poziomie aplikacji).

### 3.4. Strategia `Blue-Green`: Natychmiastowe Przełączanie Ruchu (Traffic Switching)

Strategia `Blue-Green` nie jest wbudowanym typem strategii w `spec.strategy.type` (jak `Rolling` czy `Recreate`), ale *wzorcem projektowym* [1, 55], który platforma OpenShift niezwykle ułatwia dzięki obiektom `Route`.[56, 60]

Koncepcja polega na utrzymywaniu dwóch identycznych, równoległych środowisk produkcyjnych [54, 58, 59, 63, 64]:
*   **"Blue"**: Obecna, stabilna wersja produkcyjna, obsługująca ruch użytkowników.
*   **"Green"**: Nowa, zweryfikowana wersja, działająca równolegle, ale początkowo nieobsługująca ruchu produkcyjnego.

**Implementacja w OpenShift (Mechanizm Krok po Kroku):**

1.  **Stan Początkowy:**
    *   Istnieje `Deployment` "Blue" (np. `myapp-blue`).[60, 65]
    *   Istnieje `Service` "Blue" (np. `myapp-blue-svc`), który kieruje ruch do podów `myapp-blue`.[60, 65]
    *   Istnieje *publiczna* `Route` (np. `myapp.example.com`), która w `spec.to.name` wskazuje na `myapp-blue-svc`.[60, 66, 67] Cały ruch produkcyjny trafia do wersji "Blue".
2.  **Wdrożenie Wersji "Green":**
    *   Wdrażany jest *całkowicie nowy, niezależny* `Deployment` "Green" (np. `myapp-green`) z nowym obrazem aplikacji.[60, 63, 65]
    *   Tworzony jest *drugi, niezależny* `Service` "Green" (np. `myapp-green-svc`), który kieruje ruch do podów `myapp-green`.[60, 65]
    *   W tym momencie wersja "Green" działa, ale nie przyjmuje ruchu produkcyjnego. Zespół może przeprowadzić testy "smoke" na tym środowisku, np. używając wewnętrznego adresu serwisu lub tworząc tymczasową trasę testową.[64, 67]
3.  **Przełączenie Ruchu (The Cut-Over):**
    *   Gdy zespół jest pewny, że wersja "Green" działa poprawnie, wykonuje jedną, atomową operację: *modyfikuje* (patch) publiczną `Route`, aby wskazywała na serwis "Green".[56, 60, 65, 67, 68, 69, 70]
    *   Komenda CLI wygląda następująco:
        `oc patch route/myapp -p '{"spec":{"to":{"name":"myapp-green-svc"}}}'` [60, 66, 67, 69, 70]
    *   Router OpenShift (działający w oparciu o HAProxy) natychmiast, na poziomie Warstwy 7 (L7), zaczyna kierować *cały nowy* ruch do serwisu "Green".
4.  **Stan Końcowy:** Użytkownicy widzą nową wersję "Green". Wersja "Blue" nadal działa, nie przyjmując ruchu, i pozostaje w gotowości jako natychmiastowa opcja rollbacku.[59, 63]

**Zalety:**
*   Natychmiastowy rollout (z punktu widzenia użytkownika).[54, 63]
*   Natychmiastowy rollback: W przypadku problemów, wystarczy ponownie wykonać `oc patch`, aby skierować ruch z powrotem na `myapp-blue-svc`.[59, 60, 63, 68]

**Wady:**
*   Podwójne zużycie zasobów (CPU/Pamięć), ponieważ obie wersje (Blue i Green) działają jednocześnie w pełnej skali.[54, 58, 59, 64]
*   Wymaga starannego zarządzania zmianami w warstwie danych (np. schemacie bazy), które muszą być kompatybilne wstecz i w przód.[64]

Warto zauważyć, że ta metoda przełączania ruchu (na poziomie `Route`, L7) jest architektonicznie lepsza dla aplikacji webowych niż alternatywna metoda natywna dla K8s. W K8s można by mieć *jeden* `Service` i *dwa* `Deployment` (z etykietami `version: blue` i `version: green`) [71], a przełączenie polegałoby na modyfikacji `spec.selector` w `Service` z `version: blue` na `version: green`.[71] Jest to jednak przełączenie na Warstwie 4 (L4, TCP), które jest "twarde" i może powodować przerywanie istniejących, długotrwałych połączeń. Metoda OCP, polegająca na modyfikacji `Route` [60], to przełączenie na Warstwie 7 (L7, HTTP). Router HAProxy jest w stanie obsłużyć to bardziej elegancko, np. pozwalając istniejącym połączeniom z "Blue" na naturalne zakończenie ("connection draining"), jednocześnie kierując wszystkie *nowe* żądania HTTP do "Green", co zapewnia płynniejsze i bezpieczniejsze przełączenie dla użytkownika.

## Zakończenie: Synteza Nowoczesnej Strategii Wdrożeniowej na Platformie OpenShift

Analiza ewolucji od `DeploymentConfig` do `Deployment` na platformie OpenShift ujawnia dojrzałość zarówno samego Kubernetesa, jak i strategii produktu OpenShift.

*   **Podsumowanie Ewolucji:**
    Platforma przeszła od specyficznego dla OCP, imperatywnego, opartego na triggerach modelu (`DeploymentConfig`), który używał `ReplicationController` i `Deployer Pod`, faworyzując spójność kosztem dostępności [1, 2, 9, 11, 26], do natywnego dla K8s, deklaratywnego, opartego na stanie modelu (`Deployment`), który używa `ReplicaSet` i pętli kontrolera, faworyzując dostępność.[1, 2, 17, 26]

*   **Dominujący Model Nowoczesny:**
    Standardem branżowym jest obecnie natywny `Deployment` K8s, zarządzany przez deklaratywne potoki GitOps.[17, 19] Deweloperzy i architekci powinni kategorycznie priorytetyzować ten model dla wszystkich nowych aplikacji wdrażanych na OpenShift.[3, 16]

*   **Nowa Rola Wartości Dodanej OCP:**
    Wartość dodana OpenShift nie polega już na *zastępowaniu* rdzennych obiektów K8s, ale na *inteligentnym ich rozszerzaniu*. Mechanizm adnotacji `image.openshift.io/triggers` [4, 5, 41] jest tego najlepszym przykładem. Dostarcza on cenioną przez deweloperów funkcjonalność triggerów z `ImageStream` (historycznie dostępną tylko w `DC`) bez naruszania zgodności obiektu `Deployment` ze standardem K8s. Jest to luźno powiązane rozszerzenie, zgodne z filozofią Operator Pattern.

*   **Końcowa Rekomendacja:**
    Architekci i deweloperzy powinni w pełni przyjąć natywny obiekt `Deployment` jako podstawę swoich wdrożeń. Należy zachować dogłębną wiedzę na temat `DeploymentConfig` w celu zarządzania i migracji systemów "legacy". Zaleca się wykorzystanie specyficznych dla OCP "pomostów", takich jak adnotacje triggerów `ImageStream` dla `Deployment`, aby uprościć wewnętrzne przepływy CI/CD, jednocześnie budując całą logikę wokół przenośnych, natywnych dla K8s, deklaratywnych pryncypiów. Ostatecznie, wybór strategii wdrożeniowej (Rolling, Recreate, Blue-Green) musi być świadomą decyzją architektoniczną, opartą na konkretnych wymaganiach aplikacji (stanowość, RWO) i celach biznesowych (tolerancja na przestoje, koszt zasobów).
#### **Cytowane prace**

1. Chapter 8\. Deployments | Building applications | OpenShift Container Platform | 4.11 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.11/html/building\_applications/deployments](https://docs.redhat.com/en/documentation/openshift_container_platform/4.11/html/building_applications/deployments)  
2. Red Hat OpenShift \* Deployment Strategy | by Pravin More \- Medium, otwierano: listopada 14, 2025, [https://medium.com/@morepravin1989/red-hat-openshift-deployment-strategy-24759685c652](https://medium.com/@morepravin1989/red-hat-openshift-deployment-strategy-24759685c652)  
3. Understanding deployments \- Deployments | Building applications | OKD 4, otwierano: listopada 14, 2025, [https://docs.okd.io/latest/applications/deployments/what-deployments-are.html](https://docs.okd.io/latest/applications/deployments/what-deployments-are.html)  
4. Chapter 8\. Triggering updates on image stream changes | Images | OpenShift Container Platform | 4.10 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.10/html/images/triggering-updates-on-imagestream-changes](https://docs.redhat.com/en/documentation/openshift_container_platform/4.10/html/images/triggering-updates-on-imagestream-changes)  
5. You Can Use OpenShift's ImageStreams With Deployments...Here's How \- Austin Dewey, otwierano: listopada 14, 2025, [https://austindewey.com/2020/10/25/you-can-use-openshifts-imagestreams-with-deployments-heres-how/](https://austindewey.com/2020/10/25/you-can-use-openshifts-imagestreams-with-deployments-heres-how/)  
6. How can I change the deployment strategy being used? \- OpenShift Cookbook, otwierano: listopada 14, 2025, [https://cookbook.openshift.org/application-lifecycle-management/how-can-i-change-the-deployment-strategy-being-used.html](https://cookbook.openshift.org/application-lifecycle-management/how-can-i-change-the-deployment-strategy-being-used.html)  
7. Deployments | Kubernetes, otwierano: listopada 14, 2025, [https://kubernetes.io/docs/concepts/workloads/controllers/deployment/](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)  
8. What is the different between openshift deploymentconfig and kubernetes deployment, otwierano: listopada 14, 2025, [https://stackoverflow.com/questions/49916103/what-is-the-different-between-openshift-deploymentconfig-and-kubernetes-deployme](https://stackoverflow.com/questions/49916103/what-is-the-different-between-openshift-deploymentconfig-and-kubernetes-deployme)  
9. Openshift Tutorials for DeploymentConfigs \- DevOpsSchool.com, otwierano: listopada 14, 2025, [https://www.devopsschool.com/blog/openshift-tutorials-for-deploymentconfigs/](https://www.devopsschool.com/blog/openshift-tutorials-for-deploymentconfigs/)  
10. Openshift: Difference Between DeploymentConfig and Deployment \- DevOpsSchool.com, otwierano: listopada 14, 2025, [https://www.devopsschool.com/blog/openshift-difference-between-deploymentconfig-and-deployment/](https://www.devopsschool.com/blog/openshift-difference-between-deploymentconfig-and-deployment/)  
11. Chapter 3\. Core Concepts | Architecture | OpenShift Container Platform | 3.11, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.11/html/architecture/core-concepts](https://docs.redhat.com/en/documentation/openshift_container_platform/3.11/html/architecture/core-concepts)  
12. Chapter 5\. Deployments | Applications | OpenShift Container Platform | 4.1 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.1/html/applications/deployments](https://docs.redhat.com/en/documentation/openshift_container_platform/4.1/html/applications/deployments)  
13. Replication Controller VS Deployment in Kubernetes \- Stack Overflow, otwierano: listopada 14, 2025, [https://stackoverflow.com/questions/37423117/replication-controller-vs-deployment-in-kubernetes](https://stackoverflow.com/questions/37423117/replication-controller-vs-deployment-in-kubernetes)  
14. Kubernetes Replication Controller, Replica Set & Deployments \- Mirantis, otwierano: listopada 14, 2025, [https://www.mirantis.com/blog/kubernetes-replication-controller-replica-set-and-deployments-understanding-replication-options/](https://www.mirantis.com/blog/kubernetes-replication-controller-replica-set-and-deployments-understanding-replication-options/)  
15. DeploymentConfig \[apps.openshift.io/v1\] \- Workloads APIs | API reference | OKD 4, otwierano: listopada 14, 2025, [https://docs.okd.io/latest/rest\_api/workloads\_apis/deploymentconfig-apps-openshift-io-v1.html](https://docs.okd.io/latest/rest_api/workloads_apis/deploymentconfig-apps-openshift-io-v1.html)  
16. Chapter 7\. Deployments | Building applications | OpenShift Container Platform | 4.9 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.9/html/building\_applications/deployments](https://docs.redhat.com/en/documentation/openshift_container_platform/4.9/html/building_applications/deployments)  
17. Understanding GitOps: Principles, Workflow, and Deployment Types | Spot.io, otwierano: listopada 14, 2025, [https://spot.io/resources/gitops/understanding-gitops-principles-workflows-deployment-types/](https://spot.io/resources/gitops/understanding-gitops-principles-workflows-deployment-types/)  
18. Understanding deployments \- Deployments | Building applications | OKD 4.14, otwierano: listopada 14, 2025, [https://docs.okd.io/4.14/applications/deployments/what-deployments-are.html](https://docs.okd.io/4.14/applications/deployments/what-deployments-are.html)  
19. Chapter 5\. GitOps | CI/CD | OpenShift Container Platform | 4.8 \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/cicd/gitops](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/cicd/gitops)  
20. Chapter 11\. Deployments | Developer Guide | OpenShift Container Platform | 3.1 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/documentation/openshift\_container\_platform/3.1/html/developer\_guide/dev-guide-deployments](https://docs.redhat.com/documentation/openshift_container_platform/3.1/html/developer_guide/dev-guide-deployments)  
21. Basic Deployment Operations \- Deployments | Developer Guide | OpenShift Container Platform Branch Build \- Fedora People, otwierano: listopada 14, 2025, [https://miminar.fedorapeople.org/\_preview/openshift-enterprise/registry-redeploy/dev\_guide/deployments/basic\_deployment\_operations.html](https://miminar.fedorapeople.org/_preview/openshift-enterprise/registry-redeploy/dev_guide/deployments/basic_deployment_operations.html)  
22. Leveraging the strengths of the declarative and imperative ways of Kubernetes for your team, otwierano: listopada 14, 2025, [https://devenes.medium.com/leveraging-the-strengths-of-the-declarative-and-imperative-ways-of-kubernetes-for-your-team-e0cb7cbb509b](https://devenes.medium.com/leveraging-the-strengths-of-the-declarative-and-imperative-ways-of-kubernetes-for-your-team-e0cb7cbb509b)  
23. OpenShift BuildConfig Tutorial \- DevOpsSchool.com, otwierano: listopada 14, 2025, [https://www.devopsschool.com/blog/openshift-buildconfig-tutorial/](https://www.devopsschool.com/blog/openshift-buildconfig-tutorial/)  
24. Enable continuous deployment using Red Hat OpenShift S2I and GitHub webhooks, otwierano: listopada 14, 2025, [https://developer.ibm.com/tutorials/continuous-deployment-s2i-and-webhooks/](https://developer.ibm.com/tutorials/continuous-deployment-s2i-and-webhooks/)  
25. Deployment Config vs Kubernetes Deployment \- KodeKloud Notes, otwierano: listopada 14, 2025, [https://notes.kodekloud.com/docs/OpenShift-4/Concepts-Builds-and-Deployments/Deployment-Config-vs-Kubernetes-Deployment](https://notes.kodekloud.com/docs/OpenShift-4/Concepts-Builds-and-Deployments/Deployment-Config-vs-Kubernetes-Deployment)  
26. Chapter 6\. Deployments | Building Applications | OpenShift Container Platform | 4.8 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/building\_applications/deployments](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/building_applications/deployments)  
27. ReplicationController \- Kubernetes, otwierano: listopada 14, 2025, [https://kubernetes.io/docs/concepts/workloads/controllers/replicationcontroller/](https://kubernetes.io/docs/concepts/workloads/controllers/replicationcontroller/)  
28. Kubernetes: Difference Between ReplicaSet and Replication Controller | by Manoj Kumar, otwierano: listopada 14, 2025, [https://medium.com/@manojkumar\_41904/kubernetes-difference-between-replicaset-and-replication-controller-c2a14e44be34](https://medium.com/@manojkumar_41904/kubernetes-difference-between-replicaset-and-replication-controller-c2a14e44be34)  
29. Deployment vs Deployment Config : r/openshift \- Reddit, otwierano: listopada 14, 2025, [https://www.reddit.com/r/openshift/comments/n4fs73/deployment\_vs\_deployment\_config/](https://www.reddit.com/r/openshift/comments/n4fs73/deployment_vs_deployment_config/)  
30. image cicd and imagestream : r/openshift \- Reddit, otwierano: listopada 14, 2025, [https://www.reddit.com/r/openshift/comments/fr7e3g/image\_cicd\_and\_imagestream/](https://www.reddit.com/r/openshift/comments/fr7e3g/image_cicd_and_imagestream/)  
31. Chapter 9\. DeploymentConfig \[apps.openshift.io/v1\] | Workloads APIs | OpenShift Container Platform | 4.17 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.17/html/workloads\_apis/deploymentconfig-apps-openshift-io-v1](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/workloads_apis/deploymentconfig-apps-openshift-io-v1)  
32. Can oc new-app create a Deployment instead of a DeploymentConfig? \- Stack Overflow, otwierano: listopada 14, 2025, [https://stackoverflow.com/questions/65148976/can-oc-new-app-create-a-deployment-instead-of-a-deploymentconfig](https://stackoverflow.com/questions/65148976/can-oc-new-app-create-a-deployment-instead-of-a-deploymentconfig)  
33. Openshift Build Triggers Webhook Image Change Configuration Change \- KodeKloud Notes, otwierano: listopada 14, 2025, [https://notes.kodekloud.com/docs/OpenShift-4/Concepts-Builds-and-Deployments/Openshift-Build-Triggers-Webhook-Image-Change-Configuration-Change](https://notes.kodekloud.com/docs/OpenShift-4/Concepts-Builds-and-Deployments/Openshift-Build-Triggers-Webhook-Image-Change-Configuration-Change)  
34. Chapter 9\. DeploymentConfig \[apps.openshift.io/v1\] | Workloads APIs | OpenShift Container Platform | 4.15 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.15/html/workloads\_apis/deploymentconfig-apps-openshift-io-v1](https://docs.redhat.com/en/documentation/openshift_container_platform/4.15/html/workloads_apis/deploymentconfig-apps-openshift-io-v1)  
35. OpenShift: How to update app based on ImageStream \- Stack Overflow, otwierano: listopada 14, 2025, [https://stackoverflow.com/questions/63935275/openshift-how-to-update-app-based-on-imagestream](https://stackoverflow.com/questions/63935275/openshift-how-to-update-app-based-on-imagestream)  
36. Creating and Managing Image Streams in Red Hat OpenShift | by Pravin More | Medium, otwierano: listopada 14, 2025, [https://medium.com/@morepravin1989/creating-and-managing-image-streams-in-red-hat-openshift-b78c8befddfc](https://medium.com/@morepravin1989/creating-and-managing-image-streams-in-red-hat-openshift-b78c8befddfc)  
37. Chapter 6\. Managing image streams | Images | OpenShift Container Platform | 4.10, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.10/html/images/managing-image-streams](https://docs.redhat.com/en/documentation/openshift_container_platform/4.10/html/images/managing-image-streams)  
38. Image Streams in OpenShift: What You Need to Know \- Tutorial Works, otwierano: listopada 14, 2025, [https://www.tutorialworks.com/openshift-imagestreams/](https://www.tutorialworks.com/openshift-imagestreams/)  
39. Variations on imagestreams in OpenShift 4 | by Balazs Szeti \- ITNEXT, otwierano: listopada 14, 2025, [https://itnext.io/variations-on-imagestreams-in-openshift-4-f8ee5e8be633](https://itnext.io/variations-on-imagestreams-in-openshift-4-f8ee5e8be633)  
40. Chapter 8\. Triggering updates on image stream changes | Images | OpenShift Container Platform | 4.9 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.9/html/images/triggering-updates-on-imagestream-changes](https://docs.redhat.com/en/documentation/openshift_container_platform/4.9/html/images/triggering-updates-on-imagestream-changes)  
41. Chapter 8\. Triggering updates on image stream changes | Images | OpenShift Container Platform | 4.8 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/images/triggering-updates-on-imagestream-changes](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/images/triggering-updates-on-imagestream-changes)  
42. cannot reference imagestream name and tag from StatefulSet image field, only DeploymentConfig in OCP 4.10.3 \#339 \- GitHub, otwierano: listopada 14, 2025, [https://github.com/openshift/openshift-apiserver/issues/339](https://github.com/openshift/openshift-apiserver/issues/339)  
43. Can I have an OpenShift build trigger a sync of an ImageStream from an external Docker Repository? \- Stack Overflow, otwierano: listopada 14, 2025, [https://stackoverflow.com/questions/58308290/can-i-have-an-openshift-build-trigger-a-sync-of-an-imagestream-from-an-external](https://stackoverflow.com/questions/58308290/can-i-have-an-openshift-build-trigger-a-sync-of-an-imagestream-from-an-external)  
44. Openshift ImageChange trigger gets deleted in Deploymentconfig when applying templage, otwierano: listopada 14, 2025, [https://stackoverflow.com/questions/54293217/openshift-imagechange-trigger-gets-deleted-in-deploymentconfig-when-applying-tem](https://stackoverflow.com/questions/54293217/openshift-imagechange-trigger-gets-deleted-in-deploymentconfig-when-applying-tem)  
45. S2I Deployments \- Red Hat OpenShift Service on AWS, otwierano: listopada 14, 2025, [https://www.rosaworkshop.io/ostoy/10-deployment\_s2i/](https://www.rosaworkshop.io/ostoy/10-deployment_s2i/)  
46. Chapter 2\. Builds | CI/CD | OpenShift Container Platform | 4.8 \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/cicd/builds](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/cicd/builds)  
47. Chapter 5\. Using build strategies | Builds | OpenShift Container Platform | 4.2, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.2/html/builds/build-strategies](https://docs.redhat.com/en/documentation/openshift_container_platform/4.2/html/builds/build-strategies)  
48. Chapter 2\. Source-to-Image (S2I) | Using Images | OpenShift Container Platform | 3.11, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.11/html/using\_images/source-to-image-s2i](https://docs.redhat.com/en/documentation/openshift_container_platform/3.11/html/using_images/source-to-image-s2i)  
49. Chapter 6\. Managing image streams | Images | OpenShift Container Platform | 4.7, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.7/html/images/managing-image-streams](https://docs.redhat.com/en/documentation/openshift_container_platform/4.7/html/images/managing-image-streams)  
50. Triggering updates on image stream changes \- OKD Documentation, otwierano: listopada 14, 2025, [https://docs.okd.io/4.18/openshift\_images/triggering-updates-on-imagestream-changes.html](https://docs.okd.io/4.18/openshift_images/triggering-updates-on-imagestream-changes.html)  
51. Chapter 13\. Managing Images | Developer Guide | OpenShift Container Platform | 3.11 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.11/html/developer\_guide/dev-guide-managing-images](https://docs.redhat.com/en/documentation/openshift_container_platform/3.11/html/developer_guide/dev-guide-managing-images)  
52. Trigger build in OpenShift on change in Gitlab container registry \- Stack Overflow, otwierano: listopada 14, 2025, [https://stackoverflow.com/questions/74465064/trigger-build-in-openshift-on-change-in-gitlab-container-registry](https://stackoverflow.com/questions/74465064/trigger-build-in-openshift-on-change-in-gitlab-container-registry)  
53. Chapter 8\. Triggering updates on image stream changes | Images | OpenShift Container Platform | 4.14 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.14/html/images/triggering-updates-on-imagestream-changes](https://docs.redhat.com/en/documentation/openshift_container_platform/4.14/html/images/triggering-updates-on-imagestream-changes)  
54. Managing rolling deployments to update your apps \- IBM Cloud Docs, otwierano: listopada 14, 2025, [https://cloud.ibm.com/docs/openshift?topic=openshift-update\_app](https://cloud.ibm.com/docs/openshift?topic=openshift-update_app)  
55. 3.3. Using deployment strategies | Applications | OpenShift Container Platform | 4.5, otwierano: listopada 14, 2025, [https://docs.redhat.com/zh-cn/documentation/openshift\_container\_platform/4.5/html/applications/deployment-strategies](https://docs.redhat.com/zh-cn/documentation/openshift_container_platform/4.5/html/applications/deployment-strategies)  
56. Building Deployment Strategies \- Openshift Tutorial \- School of Devops, otwierano: listopada 14, 2025, [https://openshift-tutorial.schoolofdevops.com/vote-deployement\_strategies/](https://openshift-tutorial.schoolofdevops.com/vote-deployement_strategies/)  
57. Chapter 2\. Understanding persistent storage | Storage | OpenShift Container Platform | 4.5, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.5/html/storage/understanding-persistent-storage](https://docs.redhat.com/en/documentation/openshift_container_platform/4.5/html/storage/understanding-persistent-storage)  
58. Chapter 4\. Blue-Green Deployments | Upgrading Clusters | OpenShift Container Platform | 3.9 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.9/html/upgrading\_clusters/upgrading-blue-green-deployments](https://docs.redhat.com/en/documentation/openshift_container_platform/3.9/html/upgrading_clusters/upgrading-blue-green-deployments)  
59. Chapter 3\. Performing blue-green cluster upgrades \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.11/html/upgrading\_clusters/upgrading-blue-green-deployments](https://docs.redhat.com/en/documentation/openshift_container_platform/3.11/html/upgrading_clusters/upgrading-blue-green-deployments)  
60. Using route-based deployment strategies \- Deployments | Building applications | OKD 4.18, otwierano: listopada 14, 2025, [https://docs.okd.io/4.18/applications/deployments/route-based-deployment-strategies.html](https://docs.okd.io/4.18/applications/deployments/route-based-deployment-strategies.html)  
61. How can I prevent downtime for my service, when I have only 1 replica? \- Reddit, otwierano: listopada 14, 2025, [https://www.reddit.com/r/kubernetes/comments/ccvyqs/how\_can\_i\_prevent\_downtime\_for\_my\_service\_when\_i/](https://www.reddit.com/r/kubernetes/comments/ccvyqs/how_can_i_prevent_downtime_for_my_service_when_i/)  
62. If a deployment uses a PVC with ReadWriteOnce access mode, does it ever make sense to use RollingUpdate deployment strategy vs. Recreate? : r/kubernetes \- Reddit, otwierano: listopada 14, 2025, [https://www.reddit.com/r/kubernetes/comments/rfo8y2/if\_a\_deployment\_uses\_a\_pvc\_with\_readwriteonce/](https://www.reddit.com/r/kubernetes/comments/rfo8y2/if_a_deployment_uses_a_pvc_with_readwriteonce/)  
63. Implementing Blue-Green Deployment in Kubernetes: A Step-by-Step Guide | by JABERI Mohamed Habib | Medium, otwierano: listopada 14, 2025, [https://medium.com/@jaberi.mohamedhabib/implementing-blue-green-deployment-in-kubernetes-a-step-by-step-guide-071e6cf1d27e](https://medium.com/@jaberi.mohamedhabib/implementing-blue-green-deployment-in-kubernetes-a-step-by-step-guide-071e6cf1d27e)  
64. Blue/green deployment strategy with OpenShift Pipelines \- Red Hat Developer, otwierano: listopada 14, 2025, [https://developers.redhat.com/articles/2023/12/04/bluegreen-deployment-strategy-openshift-pipelines](https://developers.redhat.com/articles/2023/12/04/bluegreen-deployment-strategy-openshift-pipelines)  
65. Using route-based deployment strategies \- Deployments | Building applications | OKD 4, otwierano: listopada 14, 2025, [https://docs.okd.io/latest/applications/deployments/route-based-deployment-strategies.html](https://docs.okd.io/latest/applications/deployments/route-based-deployment-strategies.html)  
66. dudash/openshiftexamples-bluegreen: :memo: Example showcasing a blue/green deployment on OpenShift \- GitHub, otwierano: listopada 14, 2025, [https://github.com/dudash/openshiftexamples-bluegreen](https://github.com/dudash/openshiftexamples-bluegreen)  
67. Blue-Green Deployments on Openshift/Kubernetes | by Jose Pacheco | Medium, otwierano: listopada 14, 2025, [https://medium.com/@icheko/blue-green-deployments-on-openshift-okd-dc0f7df8ffcd](https://medium.com/@icheko/blue-green-deployments-on-openshift-okd-dc0f7df8ffcd)  
68. The Blue/Green Deployment Pattern | Red Hat Developer, otwierano: listopada 14, 2025, [https://developers.redhat.com/learning/learn:openshift:perform-place-kubernetes-updates-bluegreen-deployment/resource/resources:bluegreen-deployment-pattern](https://developers.redhat.com/learning/learn:openshift:perform-place-kubernetes-updates-bluegreen-deployment/resource/resources:bluegreen-deployment-pattern)  
69. Chapter 8\. Deployments | Building applications | OpenShift Container Platform | 4.13 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.13/html/building\_applications/deployments](https://docs.redhat.com/en/documentation/openshift_container_platform/4.13/html/building_applications/deployments)  
70. 3.4. Using route-based deployment strategies | Applications | OpenShift Container Platform | 4.5 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/zh-cn/documentation/openshift\_container\_platform/4.5/html/applications/route-based-deployment-strategies](https://docs.redhat.com/zh-cn/documentation/openshift_container_platform/4.5/html/applications/route-based-deployment-strategies)  
71. Zero Downtime Deployments with Blue-Green Strategy using kubernetes: | by Raj Kancherla, otwierano: listopada 14, 2025, [https://medium.com/@rajkancherla/zero-downtime-deployments-with-blue-green-strategy-using-kubernetes-8db5102c2285](https://medium.com/@rajkancherla/zero-downtime-deployments-with-blue-green-strategy-using-kubernetes-8db5102c2285)
    
