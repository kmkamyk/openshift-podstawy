# **Moduł 2: Zaawansowane Zarządzanie Obrazami i Wzorcami Budowania Aplikacji w OpenShift Container Platform**

## **Lekcja 2.1: Architektura i Zarządzanie Zintegrowanym Rejestrem Obrazów OCP**

\`\#\# Lekcja 2.1: Zintegrowany Rejestr Obrazów (Internal Registry)

### 1.1. Wewnętrzny Mechanizm Rejestru: Analiza Usługi `image-registry.openshift-image-registry.svc:5000`

Platforma OpenShift Container Platform (OCP) jest wyposażona w zintegrowany, wewnętrzny rejestr obrazów kontenerów. Nie jest to jedynie dodatek, ale fundamentalny komponent ekosystemu, zaprojektowany do lokalnego zarządzania obrazami, które są budowane i wdrażane w klastrze.[1, 2] Rejestr ten jest w pełni zarządzany przez dedykowany `Image Registry Operator`, który działa w przestrzeni nazw `openshift-image-registry`.[1, 3, 4, 5, 6]

Domyślnie, rejestr ten jest dostępny *wyłącznie* z wnętrza klastra. Komunikacja z rejestrem odbywa się za pośrednictwem wewnętrznej nazwy usługi (Service) Kubernetes. W pełni kwalifikowana nazwa domenowa (FQDN) tej usługi to `image-registry.openshift-image-registry.svc:5000`.[3, 7, 8, 9, 10, 11, 12, 13, 14] Analiza tej nazwy dostarcza wglądu w architekturę:

  * `image-registry`: Nazwa obiektu `Service`, który eksponuje pody rejestru.
  * `openshift-image-registry`: Przestrzeń nazw (`Namespace`), w której działają zarówno usługa, jak i pody operatora oraz samego rejestru.
  * `svc`: Standardowy sufix dla wewnętrznego DNS Kubernetes, oznaczający, że jest to usługa klastrowa.
  * `5000`: Port, na którym usługa rejestru nasłuchuje.

Ta wewnętrzna nazwa DNS jest rozwiązywalna tylko przez pody działające w klastrze, w tym przez węzły robocze (do ściągania obrazów) oraz przez pody budujące (do wypychania nowo utworzonych obrazów).[10, 11]

Kluczowym aspektem operacyjnym rejestru jest jego zależność od trwałej pamięci masowej (persistent storage). Chociaż `Image Registry Operator` jest instalowany domyślnie, na wielu platformach (szczególnie on-premise lub bare-metal) jego stan zarządzania (`managementState`) jest początkowo ustawiony na `Removed`.[1, 6] Oznacza to, że rejestr nie zostanie wdrożony, dopóki administrator platformy jawnie nie skonfiguruje dla niego pamięci masowej, zazwyczaj poprzez utworzenie `PersistentVolumeClaim` (PVC) i zaktualizowanie konfiguracji operatora, aby z niej korzystał.[1, 6] Na niektórych platformach chmury publicznej, jak AWS, operator może automatycznie aprowizować odpowiedni zasób (np. bucket S3).[4]

### 1.2. Wystawianie Rejestru na Zewnątrz: Konfiguracja `Route` i Względy Bezpieczeństwa

Domyślna, wewnętrzna konfiguracja rejestru jest niewystarczająca dla deweloperów lub zewnętrznych systemów CI/CD, które muszą wypychać (push) obrazy ze swoich lokalnych maszyn lub serwerów budujących spoza klastra OCP.[1, 10]

Wystawienie rejestru na zewnątrz w OCP 4.x jest doskonałym przykładem filozofii zarządzania przez operatora. Zamiast ręcznie tworzyć obiekt `Route` (co byłoby podejściem imperatywnym), administrator musi zadeklarować *intencję* w zasobie niestandardowym (CR) operatora rejestru. Operator, monitorując swój CR, zareaguje na zmianę i sam wykona niezbędne czynności.

Procedura polega na modyfikacji zasobu `configs.imageregistry.operator.openshift.io/cluster` i ustawieniu flagi `defaultRoute` na `true`. Można to osiągnąć za pomocą jednego polecenia `oc patch`:

$$
oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge
$$[1, 5, 10]

To polecenie instruuje `Image Registry Operator` (we współpracy z `Ingress Operator` [5]), aby automatycznie utworzył i skonfigurował bezpieczny (zazwyczaj z terminacją `reencrypt`) obiekt `Route` o nazwie `default-route` w przestrzeni nazw `openshift-image-registry`.[1, 10]

Względy bezpieczeństwa są tu kluczowe. Utworzona trasa jest domyślnie szyfrowana (TLS).[1, 5, 15] Jeśli klaster OCP używa domyślnych, samo-podpisanych certyfikatów dla routera Ingress, klienci (jak `podman` czy `docker`) na maszynach zewnętrznych zgłoszą błąd weryfikacji certyfikatu (`x509: certificate signed by unknown authority`).[10] Wymaga to albo dodania klastrowego CA do zaufanych certyfikatów na kliencie, albo (w środowiskach deweloperskich) obejścia weryfikacji.

### 1.3. Uwierzytelnianie i Dostęp: Proces Logowania `podman login` z Użyciem Tokenów `oc`

Architektura uwierzytelniania zintegrowanego rejestru OCP jest jego najbardziej elegancką i potężną cechą. Rejestr *nie* posiada własnej, oddzielnej bazy danych użytkowników ani mechanizmu haseł. Zamiast tego, w pełni deleguje uwierzytelnianie i autoryzację do głównego serwera API OpenShift.

Kiedy użytkownik próbuje się zalogować, używa swojego standardowego tokena OCP jako hasła. Proces ten różni się w zależności od tego, czy logowanie odbywa się z wewnątrz, czy z zewnątrz klastra.

**Scenariusz 1: Logowanie Wewnętrzne (np. z Węzła Klastra)**
Używane głównie do celów administracyjnych lub debugowania. Wymaga dostępu do węzła (np. przez `oc debug node/<node_name>`) i zmiany kontekstu na system hosta (`chroot /host`).[7, 11] Logowanie odbywa się przy użyciu *wewnętrznej* nazwy usługi i tokena użytkownika (np. `kubeadmin`):
$$podman login -u kubeadmin -p $(oc whoami -t) image-registry.openshift-image-registry.svc:5000$$
[7, 11]

**Scenariusz 2: Logowanie Zewnętrzne (przez Wystawioną `Route`)**
Jest to standardowy przepływ dla deweloperów i systemów CI.

1.  **Pobranie Hosta Trasy:** Adres URL rejestru jest unikalny dla każdego klastra, dlatego należy go pobrać dynamicznie:
$$

```
$$HOST=$(oc get route default-route -n openshift-image-registry --template='{{.spec.host }}')
$$
$$[1]
```

2.  **Logowanie `podman` / `docker`:** Następnie użytkownik loguje się przy użyciu pobranego hosta, swojej nazwy użytkownika OCP i swojego tokena OCP [16] jako hasła:
    $$
    $$$$podman login -u $(oc whoami) -p $(oc whoami -t) $HOST
    $$
    $$$$[1, 10]
3.  **Obsługa Błędów Certyfikatów:** W przypadku wspomnianego wcześniej błędu `x509` [10], konieczne może być dodanie flagi `--tls-verify=false`.[1, 10, 17]

**Model Uwierzytelniania i Autoryzacji (RBAC)**
Fakt, że `$(oc whoami -t)` działa jako hasło [1, 11], jest kluczowy. Oznacza to, że rejestr jest skonfigurowany do przeprowadzania operacji `TokenReview` (weryfikacji tokena) względem serwera API OCP. To bezpośrednio łączy uwierzytelnianie rejestru z centralnym dostawcą tożsamości (IDP) skonfigurowanym dla klastra (np. LDAP, HTPasswd).[7]

Co więcej, samo pomyślne zalogowanie (uwierzytelnienie) nie gwarantuje uprawnień (autoryzacji). Rejestr wykorzystuje standardowy mechanizm RBAC platformy OpenShift. Aby móc wykonywać operacje, użytkownik musi posiadać odpowiednie role w danym projekcie (przestrzeni nazw):

  * `registry-viewer`: Umożliwia ściąganie (pull) obrazów z projektu.[7, 14]
  * `registry-editor`: Umożliwia wypychanie (push) obrazów do projektu.[7, 11, 14]

Ten zunifikowany model drastycznie upraszcza zarządzanie bezpieczeństwem. Administratorzy używają tych samych poleceń `oc policy add-role-to-user` do zarządzania dostępem do obrazów, co do zarządzania dostępem do podów czy deploymentów, zamiast zarządzać osobnym zestawem uprawnień w rejestrze.

## Lekcja 2.2: `ImageStream` i `ImageStreamTag` – Kluczowy koncept OCP

### 2.1. Geneza i Cel `ImageStream`: Rozwiązanie Problemów Czystego Kubernetes

Jedną z najbardziej fundamentalnych różnic architektonicznych między OpenShift a standardowym Kubernetes jest wprowadzenie zasobu `ImageStream` (IS). Jego stworzenie było bezpośrednią odpowiedzią na ograniczenia i problemy wynikające z podejścia Kubernetes do zarządzania obrazami.[18]

W standardowym Kubernetes, zasoby takie jak `Deployment` odnoszą się do obrazów za pomocą statycznego, dosłownego ciągu znaków, np. `image: registry.com/my-org/my-app:latest`. Takie podejście generuje trzy kluczowe problemy:

1.  **Problem Kruchości (Brittleness):** Definicja obrazu jest "na sztywno" wpisana w konfigurację aplikacji. Jeśli organizacja zdecyduje się na migrację do innego rejestru, wymaga to znalezienia i zaktualizowania *każdego* pliku YAML w *każdej* aplikacji, która odnosiła się do starej ścieżki.[18]
2.  **Problem Modyfikowalnych Tagów (Mutable Tags):** Tagi, zwłaszcza `latest`, są z natury modyfikowalne. Nowy `docker push` do tego samego taga nadpisuje go. Kubernetes (z `imagePullPolicy: Always`) może nieświadomie pobrać nową, potencjalnie niestabilną lub uszkodzoną wersję obrazu, powodując nieoczekiwaną awarię aplikacji.[18, 19] Brakuje koncepcji "znanej, dobrej" (known-good) referencji.
3.  **Brak Reaktywności:** Kubernetes nie posiada wbudowanego mechanizmu, który by "zauważył", że obraz w rejestrze został zaktualizowany. Nie potrafi automatycznie zareagować na nowy obraz (np. z łatką bezpieczeństwa) i uruchomić nowego deploymentu.[18, 20, 21]

`ImageStream` rozwiązuje wszystkie te trzy problemy, wprowadzając warstwę abstrakcji (indirection) między definicjami zasobów a faktycznymi obrazami w rejestrze.[18, 19, 22] `ImageStream` można zwizualizować jako "wirtualne repozytorium" lub "katalog" zarządzany wewnątrz OCP. Wewnątrz tego katalogu znajdują się `ImageStreamTag`, które działają jak "symlinki".[18, 22]

Kluczowe korzyści tego podejścia są następujące [18, 19, 20, 21]:

  * **Abstrakcja:** `DeploymentConfig` nie odnosi się już do `registry.com/my-org/my-app:latest`, ale do wewnętrznego zasobu `my-app:latest`. To `ImageStream` mapuje tę abstrakcyjną nazwę na rzeczywisty obraz.[18, 19]
  * **Stabilność:** `ImageStreamTag` (symlink) nie wskazuje na *modyfikowalny tag* w rejestrze. Wskazuje na *konkretny, niezmienny (immutable) identyfikator obrazu* (np. `sha256:...`).[18, 23, 24] To rozwiązuje problem "mutable tags", gwarantując, że deployment jest zawsze powiązany ze "znaną dobrą" wersją.
  * **Reaktywność:** Ponieważ `ImageStream` jest zasobem OCP, każda zmiana w nim (np. aktualizacja taga) generuje zdarzenie (Event) w klastrze. Na te zdarzenia mogą nasłuchywać triggery (np. `ImageChangeTrigger`), co pozwala na automatyczne uruchamianie buildów lub deploymentów.[18, 20, 21, 23]

### 2.2. Dogłębna Analiza Obiektów: Różnice i Współdziałanie `ImageStream` (IS) vs. `ImageStreamTag` (IST)

Aby w pełni zrozumieć mechanizm, należy rozróżnić trzy powiązane ze sobą obiekty:

  * **`ImageStream` (IS):** Jest to główny zasób (np. `is/my-app`). Definiuje nazwę "wirtualnego repozytorium" w ramach projektu OCP. Przechowuje listę wszystkich tagów oraz historię obrazów (SHA), które kiedykolwiek były powiązane z tym streamem.[18, 19, 22] Sam w sobie nie zawiera danych obrazu.[18, 22]
  * **`ImageStreamTag` (IST):** Jest to wskaźnik lub "symlink" wewnątrz `ImageStream` (np. `my-app:latest` lub `my-app:v1.2`).[19, 20] To właśnie do tego obiektu odnoszą się zasoby takie jak `DeploymentConfig`.
  * **`ImageStreamImage` (ISI):** Jest to rzadziej widywany, ale krytyczny obiekt, który tworzy niezmienne powiązanie między `ImageStream` a *konkretnym ID obrazu (SHA)*. Nazwa tego obiektu ma format `<image-stream-name>@<image-id>` (np. `my-app@sha256:47463d94eb...`).[23, 24] Obiekty te są tworzone automatycznie przez OCP za każdym razem, gdy nowy obraz jest tagowany lub importowany do `ImageStream`.[23, 24]

Przepływ działania jest następujący [19, 23]:

1.  Użytkownik (lub `oc new-app`) tworzy `ImageStream` o nazwie `my-app`.
2.  Proces budowania (lub importu) tworzy obraz o unikalnym identyfikatorze `sha256:abc...`.
3.  OCP automatycznie tworzy `ImageStreamImage` (ISI) o nazwie `my-app@sha256:abc...`, aby zarejestrować ten obraz w historii streamu.
4.  Następnie OCP tworzy (lub aktualizuje) `ImageStreamTag` (IST) `my-app:latest`, aby "wskazywał" na ten konkretny `ImageStreamImage`.
5.  `DeploymentConfig`, który nasłuchuje na `ImageStreamTag` `my-app:latest`, widzi tę zmianę i rozpoczyna nowy deployment, używając *dokładnego* obrazu `sha256:abc...`.

Należy zaznaczyć, że tag `latest` w `ImageStream` nie jest "magiczny". Nie jest automatycznie aktualizowany, aby wskazywać na "najnowszy" obraz w sensie chronologicznym, jak ma to miejsce w Docker Hub. Jest to po prostu tag, który musi być *jawnie* zaktualizowany przez proces budowania lub importu, aby wskazywał na nowy obraz.[23, 25]

### 2.3. Śledzenie Rejestrów Zewnętrznych: Konfiguracja Importu i Synchronizacji (np. z Docker Hub)

`ImageStream` może śledzić nie tylko obrazy budowane lokalnie i przechowywane w wewnętrznym rejestrze, ale także obrazy w dowolnych rejestrach zewnętrznych (np. Docker Hub, Quay.io, `registry.redhat.io`).[19, 25]

**Import Jednorazowy:** Polecenie `oc import-image` może być użyte do stworzenia `ImageStream` (jeśli nie istnieje) i jednorazowego zaimportowania metadanych (SHA) obrazu z zewnętrznego rejestru.[26] Na przykład:
$$oc import-image my-apache --from=docker.io/bitnami/apache:latest --confirm$$

**Import/Synchronizacja Okresowa:** To jest kluczowy mechanizm utrzymywania aktualności obrazów bazowych. `ImageStream` można skonfigurować tak, aby *okresowo* (np. co 15 minut) sprawdzał zewnętrzny rejestr pod kątem aktualizacji tagu. Osiąga się to poprzez ustawienie flagi `--scheduled` podczas tagowania lub importowania.[19]
$$oc tag docker.io/python:3.6 python:3.6 --scheduled$$
[19]

Mechanizm działania jest następujący [19, 27, 28]:

1.  `ImageStream` `python:3.6` (ze skonfigurowanym `--scheduled`) okresowo odpytuje Docker Hub.
2.  Porównuje SHA, na który wskazuje jego *lokalny* `ImageStreamTag` `python:3.6`, z SHA, na który wskazuje tag `3.6` w Docker Hub.
3.  Jeśli SHA są różne (co oznacza, że obraz nadrzędny został zaktualizowany, np. z łatką bezpieczeństwa):
    a. OCP "ściąga" (pull) nowy obraz (blob) z Docker Hub i *kopiuje go do wewnętrznego rejestru OCP*.[27, 28]
    b. Tworzy nowy `ImageStreamImage` z nowym SHA.
    c. Aktualizuje lokalny `ImageStreamTag` `python:3.6`, aby wskazywał na ten nowy SHA.
    d. Ta aktualizacja `ImageStreamTag` uruchamia `ImageChangeTrigger` (patrz poniżej).

Funkcjonalność kopiowania obrazu do wewnętrznego rejestru [27, 28] ma kluczowe implikacje. Po pierwsze, działa jak **wewnętrzna pamięć podręczna (cache)**. Gdy 1000 podów w klastrze musi pobrać obraz `python:3.6`, wszystkie 1000 pobiera go z szybkiego, wewnętrznego rejestru, a nie obciąża 1000 razy zewnętrznego łącza do Docker Hub. Zwiększa to wydajność i odporność (klaster może nadal wdrażać aplikacje, nawet jeśli Docker Hub jest niedostępny).

Po drugie, tworzy to **"śluza bezpieczeństwa" (airlock)**. Administratorzy mogą zablokować bezpośredni dostęp do zewnętrznych rejestrów (np. używając polityki `allowedRegistriesForImport` [8]) i zezwolić jedynie na używanie obrazów, które zostały *zaimportowane* przez `ImageStream`. Te zaimportowane, wewnętrzne kopie mogą być następnie skanowane pod kątem bezpieczeństwa, zanim zostaną dopuszczone do użytku, co jest kluczowe dla środowisk o wysokim stopniu bezpieczeństwa i zgodności (compliance).

### 2.4. Rola `ImageChangeTrigger` (Zajawka)

`ImageChangeTrigger` (ICT) jest "konsumentem" zdarzeń generowanych przez `ImageStream`.[18, 20, 23] Jest to klej, który łączy abstrakcję `ImageStream` z automatyzacją CI/CD.

`ImageChangeTrigger` można umieścić w dwóch kluczowych zasobach:

1.  **W `BuildConfig`:** Trigger jest skonfigurowany tak, aby obserwował *bazowy* obraz (np. `python:3.6`). Kiedy `ImageStream` (śledzący Docker Hub) zaktualizuje tag `python:3.6`, ten trigger automatycznie uruchomi *nowy build* aplikacji, aby wchłonąć zaktualizowany obraz bazowy.[18, 29, 30]
2.  **W `DeploymentConfig`:** Trigger jest skonfigurowany tak, aby obserwował *obraz aplikacji* (np. `my-app:latest`). Kiedy `BuildConfig` (powyżej) zakończy budowanie i zaktualizuje tag `my-app:latest` w `ImageStream`, ten trigger automatycznie uruchomi *nowy deployment* (rollout) aplikacji na produkcję.[18, 31, 32, 33]

Ta kombinacja `ImageStream` (ze śledzeniem okresowym) i dwóch `ImageChangeTrigger` (w `BuildConfig` i `DeploymentConfig`) tworzy potężny, w pełni zautomatyzowany potok, który potrafi przenieść łatkę bezpieczeństwa z obrazu bazowego w Docker Hub aż do działającej aplikacji produkcyjnej, bez żadnej ręcznej interwencji.

Co więcej, `ImageStream` w genialny sposób oddziela proces Ciągłej Integracji (CI – budowanie) od Ciągłego Wdrażania (CD – deployment). `BuildConfig` (CI) kończy swoją pracę, *produkując* (aktualizując) `ImageStreamTag`.[34] `DeploymentConfig` (CD) *konsumuje* ten tag.[31] Daje to punkt kontrolny: można wstrzymać wdrożenia (CD) poprzez tymczasowe wyłączenie `ImageChangeTrigger` w `DeploymentConfig`, podczas gdy procesy CI (buildy) nadal działają, aktualizując `ImageStream`. `ImageStream` staje się buforem i rejestrem wersji. Umożliwia to również "promocję obrazu" między środowiskami. Zamiast przebudowywać obraz dla `stage`, proces CI po prostu wykonuje `oc tag my-app:dev my-app:stage`.[20] To błyskawicznie kopiuje wskaźnik `ImageStreamTag`, promując *dokładnie ten sam, niezmienny artefakt (SHA)* do następnego środowiska i uruchamiając jego deployment.

## Lekcja 2.3: `BuildConfig` – Mózg procesu budowania

### 3.1. Anatomia Obiektu `BuildConfig` (BC)

Obiekt `BuildConfig` (BC) jest zasobem niestandardowym (CRD) specyficznym dla OpenShift, który służy jako definicja całego procesu budowania.[35, 36, 37] Można go traktować jako "mózg" lub "przepis" [38, 39], który informuje OCP, skąd pobrać kod, jak go zbudować i gdzie umieścić wynikowy obraz.

`BuildConfig` jest szablonem lub definicją. Kiedy build jest faktycznie uruchamiany (ręcznie lub przez trigger), tworzony jest obiekt `Build`, który reprezentuje to konkretne, historyczne wykonanie.[35, 39] Ten obiekt `Build` z kolei uruchamia standardowego Poda (zwanego "build pod"), który wykonuje logikę budowania (np. S2I lub Docker).

Kluczowe komponenty definicji `BuildConfig` (w YAML) to:

  * `spec.source`: Definiuje, *co* ma być zbudowane. Najczęściej jest to repozytorium Git, określone przez `type: Git` i `uri`.[29, 38]
  * `spec.strategy`: Definiuje, *jak* budować. Określa typ strategii, np. `type: Source` (dla S2I) lub `type: Docker`.[36, 38, 40]
  * `spec.output`: Definiuje, *gdzie* umieścić wynik. Zazwyczaj jest to `to: { kind: "ImageStreamTag", name: "my-app:latest" }`, co instruuje build do wypchnięcia obrazu do wewnętrznego `ImageStream`.[34, 38]
  * `spec.triggers`: Definiuje, *kiedy* budowanie ma być uruchamiane automatycznie. Jest to lista triggerów.[38, 41]

Wprowadzenie `BuildConfig` jako obiektu pierwszej klasy w OCP jest strategiczną decyzją architektoniczną. Oddziela ona obowiązki dewelopera od obowiązków platformy. W tradycyjcyjnych systemach CI (np. Jenkins), deweloper musi zdefiniować *wszystko* w `Jenkinsfile`: jakiego agenta budującego użyć, jak uwierzytelnić się w rejestrze, gdzie wypchnąć obraz. W OCP, `BuildConfig` [35, 38] abstrahuje większość z tego. Platforma dostarcza pod budujący (S2I), platforma automatycznie uwierzytelnia się we własnym rejestrze. Deweloper musi dostarczyć tylko `source.git.uri` [29] i `strategy`. To obniża obciążenie poznawcze dewelopera i daje centralną kontrolę administratorom platformy, którzy mogą zarządzać i aktualizować obrazy bazowe S2I dla całego klastra.

### 3.2. Triggery Budowania (Część 1): Webhooki `GitHub` i `Generic`

Webhooki umożliwiają systemom zewnętrznym (zazwyczaj systemom kontroli wersji SCM) powiadamianie OCP o konieczności uruchomienia nowego builda, np. po `git push`.[29, 42, 43]

OCP obsługuje kilka typów webhooków [42, 43]:

  * `GitHub`: Specjalnie zaprojektowany do integracji z GitHub, rozumie jego format payloadu `push`.
  * `GitLab`: Analogiczny dla GitLab.
  * `Bitbucket`: Analogiczny dla Bitbucket.
  * `Generic`: Akceptuje prosty, ogólny payload HTTP POST, co pozwala na integrację z dowolnym systemem zdolnym do wysłania żądania webowego.

Kluczowym elementem webhooków OCP jest mechanizm bezpieczeństwa. Ponieważ endpoint webhooka jest publicznie dostępny przez HTTP, musi być zabezpieczony przed nieautoryzowanym wywołaniem. OCP realizuje to poprzez włączenie losowego, "tajnego" ciągu znaków bezpośrednio do adresu URL webhooka.[42, 43, 44, 45]
Przykładowy URL wygląda następująco: `.../webhooks/<secret_value>/github`.[43, 45]

`BuildConfig` przechowuje ten tajny ciąg (lub referencję do obiektu `Secret`, który go zawiera [42, 43]). OCP odrzuci każde wywołanie, którego URL nie zawiera dokładnie tego samego ciągu, co czyni URL "nieodgadywalnym".[42, 43]

**Konfiguracja `GitHub` Webhook:**

1.  Po utworzeniu `BuildConfig` (często automatycznie przez `oc new-app` [42, 43]), pobierz pełny URL webhooka za pomocą polecenia: `oc describe bc/my-app`.[43, 45]
2.  W repozytorium GitHub, przejdź do `Settings` -\> `Webhooks` -\> `Add webhook`.
3.  Wklej skopiowany URL w pole `Payload URL`.[43, 44]
4.  Zmień `Content type` na `application/json`.[43, 44]
5.  Zapisz webhook. Od teraz, każde zdarzenie `push` (pasujące do gałęzi skonfigurowanej w `BuildConfig` [42, 43]) automatycznie uruchomi nowy build w OCP.

### 3.3. Triggery Budowania (Część 2): Reaktywne Potoki z `ImageChange` i `ConfigChange`

**`ImageChangeTrigger` (ICT):**
Jest to prawdopodobnie najważniejszy i najpotężniejszy trigger w OCP, kluczowy dla automatyzacji. `ImageChangeTrigger` automatycznie uruchamia nowy `Build`, gdy monitorowany przez niego `ImageStreamTag` zostanie zaktualizowany.[29, 43]

Główny scenariusz użycia to automatyczne przebudowywanie aplikacji w odpowiedzi na aktualizację obrazu bazowego. Przepływ jest następujący:

1.  `BuildConfig` dla `my-app` jest oparty na obrazie bazowym S2I, np. `python:3.9` (który sam w sobie jest `ImageStreamTag`).
2.  `BuildConfig` `my-app` zawiera `ImageChangeTrigger` skonfigurowany do monitorowania `ImageStreamTag` `python:3.9`.[46]
3.  Administratorzy platformy (lub okresowy import) aktualizują `ImageStreamTag` `python:3.9`, aby wskazywał na nową wersję z łatkami bezpieczeństwa.
4.  Aktualizacja `ImageStreamTag` `python:3.9` jest wykrywana.
5.  `ImageChangeTrigger` w `BuildConfig` `my-app` zostaje aktywowany.
6.  Automatycznie uruchamiany jest nowy `Build` `my-app`, który pobiera nowy, bezpieczny obraz bazowy.[29, 43]

Ten mechanizm zapewnia, że aplikacje są zawsze budowane na najnowszych, zatwierdzonych obrazach bazowych, co jest kluczowe dla bezpieczeństwa i zgodności. Trigger można tymczasowo wyłączyć (np. podczas prac konserwacyjnych) ustawiając `paused: true` w jego definicji.[31, 42]

**`ConfigChangeTrigger`:**
Jest to prostszy trigger, który zapewnia wygodę deweloperską. Powoduje on automatyczne uruchomienie nowego `Build` za każdym razem, gdy sam obiekt `BuildConfig` jest modyfikowany i zapisywany w OCP.[29, 43] Na przykład, jeśli deweloper doda nową zmienną środowiskową do `spec.strategy.env` w `BuildConfig` i zapisze zmianę, `ConfigChangeTrigger` natychmiast uruchomi nowy build, aby odzwierciedlić tę zmianę w wynikowym obrazie.[29]

## Lekcja 2.4: Strategie Budowania: S2I (Source-to-Image) vs `Docker` vs `Pipeline`

Platforma OCP oferuje kilka strategii budowania, z których każda jest zoptymalizowana pod kątem różnych scenariuszy i wymagań.[37, 40, 47] Trzy podstawowe strategie to Source-to-Image (S2I), Docker oraz Pipeline.

### 4.1. Source-to-Image (S2I): Dogłębna Analiza

**Koncepcja Podstawowa:** S2I to framework i strategia budowania, która produkuje gotowe do uruchomienia obrazy aplikacji poprzez połączenie kodu źródłowego aplikacji z dedykowanym "obrazem budującym" (builder image). Najważniejszą cechą S2I jest to, że deweloper *nie musi pisać ani utrzymywać pliku `Dockerfile`*.[40, 48, 49, 50]

**Kluczowe Elementy S2I** [47, 49, 50]:

1.  **Kod Źródłowy Aplikacji:** Repozytorium Git dewelopera.
2.  **Obraz Budujący (Builder Image):** Specjalny obraz kontenera (np. `ubi8/python-39`, `ubi8/java-11`) dostarczany przez Red Hat lub tworzony na zamówienie. Zawiera on wszystkie niezbędne narzędzia budowania (np. `pip`, `maven`, `npm`) oraz kluczowe skrypty S2I.
3.  **Skrypty S2I:** Są to skrypty powłoki znajdujące się wewnątrz obrazu budującego, które definiują logikę budowania i uruchamiania:
      * `assemble`: (Wymagany) Główny skrypt. Jego zadaniem jest pobranie kodu źródłowego (wstrzykniętego przez OCP do Poda budującego), skompilowanie go, zainstalowanie zależności (np. `pip install -r requirements.txt`) i umieszczenie gotowej aplikacji we właściwym miejscu.[47, 50]
      * `run`: (Wymagany) Definiuje polecenie uruchamiające gotową aplikację (np. `gunicorn myapp.wsgi` lub `java -jar...`).[47, 50]
      * `save-artifacts`: (Opcjonalny) Umożliwia buforowanie (caching) zależności między buildami (np. katalog `.m2`, `node_modules` lub `venv`). Przyspiesza to znacznie kolejne buildy, ponieważ zależności nie muszą być pobierane od zera.[47, 50]

**Przebieg Procesu Budowania S2I** [50]:

1.  OCP uruchamia Poda, używając Obrazu Budującego.
2.  Wstrzykuje kod źródłowy aplikacji (z repozytorium Git) do Poda budującego.
3.  Jeśli istnieją artefakty z poprzedniego builda, skrypt `save-artifacts` je przywraca.
4.  OCP uruchamia skrypt `assemble`, który buduje kod.
5.  OCP uruchamia skrypt `save-artifacts`, aby zapisać nowe/zaktualizowane zależności.
6.  OCP zatwierdza (commits) wynikowy stan Poda jako nowy obraz aplikacji i wypycha go do `ImageStream` zdefiniowanego w `BuildConfig.output`.

**Główne Zalety S2I** [48, 49, 51]:

1.  **Prostota dla Deweloperów:** Deweloperzy mogą skupić się na pisaniu kodu, nie martwiąc się o tworzenie i optymalizację `Dockerfile`.[48, 49, 50]
2.  **Bezpieczeństwo:** To kluczowa, choć często niedoceniana zaleta. Tradycyjny `docker build` wymaga dostępu do uprzywilejowanego demona Dockera, co jest poważnym ryzykiem bezpieczeństwa w środowisku wielodostępnym (multi-tenant). S2I wykonuje cały proces budowania w standardowym, nieuprzywilejowanym Podzie OCP, który podlega wszystkim politykom bezpieczeństwa klastra (np. Security Context Constraints).[51]
3.  **Szybkość:** Dzięki mechanizmowi `save-artifacts`, buildy przyrostowe (incremental builds) są bardzo szybkie.[51]
4.  **Standaryzacja:** Zapewnia, że wszystkie aplikacje (np. wszystkie aplikacje Java) w organizacji są budowane i uruchamiane w ten sam, spójny, zatwierdzony przez administratorów sposób.

### 4.2. Docker: Strategia Oparta na `Dockerfile`

**Koncepcja Podstawowa:** Strategia `Docker` instruuje OCP, aby odnalazł plik `Dockerfile` w repozytorium kodu źródłowego i wykonał proces budowania na jego podstawie.[37, 40, 50, 52]

Ważnym szczegółem architektonicznym jest to, że OCP *nie* używa demona `docker` do wykonania tego procesu. Byłoby to wspomniane wcześniej ryzyko bezpieczeństwa. Zamiast tego, OCP wykorzystuje narzędzie `Buildah` [47, 53], które jest zdolne do budowania obrazów OCI/Docker w sposób bezdemonowy (daemon-less) i potencjalnie bez uprawnień root (root-less), wszystko to wewnątrz kontrolowanego Poda budującego.

**Kiedy Używać Strategii Docker?** [34, 54]:

1.  **Migracja (Legacy):** Jest to idealne rozwiązanie, gdy przenosimy do OCP istniejącą aplikację, która *już* posiada dobrze utrzymywany, działający `Dockerfile`.[54]
2.  **Pełna Kontrola (Fine-Grained Control):** Gdy S2I jest zbyt restrykcyjne lub "magiczne". `Dockerfile` daje deweloperowi pełną, drobnoziarnistą kontrolę nad każdą warstwą obrazu, każdą instalowaną biblioteką i każdym poleceniem `RUN`.[34]
3.  **Niestandardowe Wymagania:** Gdy dla danej technologii (np. rzadkiego języka programowania) nie ma dostępnego, zatwierdzonego obrazu budującego S2I.

### 4.3. Pipeline: Wprowadzenie do Złożonych Przepływów CI/CD

**Koncepcja Podstawowa:** Strategia `Pipeline` różni się fundamentalnie od S2I i Docker. Tamte dwie strategie *tworzą* obraz. Strategia `Pipeline` *orkiestruje* złożony, wieloetapowy proces, który *może* obejmować budowanie obrazu jako jeden z wielu kroków.[34, 37, 40, 47]

`BuildConfig` dla tej strategii wskazuje na definicję potoku, zazwyczaj w formie pliku `Jenkinsfile` (dla integracji z Jenkins) [40] lub, w nowocześniejszym podejściu OCP, na definicje zadań `Tekton` (które są częścią OpenShift Pipelines).[47]

**Scenariusz Użycia** [34, 37, 47]:
Strategia ta jest używana, gdy prosty przepływ `build -> push` jest niewystarczający. Typowy potok może obejmować:

1.  Pobranie kodu.
2.  Uruchomienie analizy statycznej kodu (Linting) i testów jednostkowych.
3.  Zbudowanie obrazu (np. poprzez wywołanie innego `BuildConfig` typu S2I).
4.  Przeskanowanie obrazu pod kątem luk bezpieczeństwa.
5.  Wdrożenie obrazu na środowisku `staging`.
6.  Uruchomienie testów integracyjnych na środowisku `staging`.
7.  Oczekiwanie na ręczną akceptację (np. od QA).
8.  Promocja obrazu (przez `oc tag`) na środowisko `production`.

### 4.4. Rekomendacje: Wybór Odpowiedniej Strategii

Poniższa tabela syntetyzuje kluczowe różnice i pomaga w wyborze odpowiedniej strategii dla danego scenariusza.

**Tabela 1: Analiza Porównawcza Strategii Budowania OCP**

| Cecha | **Source-to-Image (S2I)** | **Docker** | **Pipeline (Jenkins/Tekton)** |
| :--- | :--- | :--- | :--- |
| **Główny Cel** | Budowanie obrazu aplikacji z kodu źródłowego | Budowanie obrazu aplikacji z `Dockerfile` | Orkierstracja złożonego potoku CI/CD |
| **Wymagany Artefakt** | Kod źródłowy (np. `app.py`, `pom.xml`) | `Dockerfile` (w repozytorium) | `Jenkinsfile` lub `Tekton TaskRun` (w repozytorium) |
| **Jednostka Wykonawcza** | Obraz Budujący (Builder Image) + Skrypty (`assemble`) [49] | `Buildah` (wykonujący instrukcje `Dockerfile`) [47, 53] | Agent Jenkins lub Pod Tekton (wykonujący etapy) [40] |
| **Poziom Kontroli** | Niski (Ograniczony do logiki `assemble`) | Wysoki (Pełna kontrola nad każdą warstwą i poleceniem) [34] | Bardzo Wysoki (Pełna kontrola nad logiką i przepływem) |
| **Zalety** | Prostota, bezpieczeństwo (brak uprawnień root), standaryzacja, brak `Dockerfile` [48, 50, 51] | Pełna kontrola, przenośność (standard Docker), łatwa migracja istniejących aplikacji [34, 54] | Elastyczność, obsługa złożonych przepływów, testowanie, promocja [34, 47] |
| **Typowy Scenariusz** | "Mam kod w Python/Java/Node, chcę go uruchomić. Szybko." | "Mam aplikację z istniejącym `Dockerfile` i chcę ją przenieść do OCP." | "Chcę uruchomić testy, zbudować, przeskanować i wdrożyć z ręczną akceptacją." |

## Lekcja 2.5: Warsztat End-to-End \#1 (Od `git push` do działającej aplikacji S2I)

### 5.1. Inicjalizacja Aplikacji: Analiza Polecenia `oc new-app` i Tworzone Obiekty

Polecenie `oc new-app` jest potężnym narzędziem "magazynowym" (scaffolding), które automatyzuje tworzenie wszystkich niezbędnych zasobów OCP do zbudowania i wdrożenia aplikacji z jednego polecenia.[55, 56, 57]

Użycie `oc new-app` z repozytorium Git (np. `oc new-app https://github.com/sclorg/nodejs-ex --name=my-app` [58]) uruchamia inteligentny proces introspekcji [59]:

1.  **Analiza Argumentu:** `oc new-app` sprawdza, czy podany argument to repozytorium Git, obraz Docker czy szablon.[59]
2.  **Wykrywanie Strategii:** W przypadku repozytorium Git [58], `oc new-app` klonuje je tymczasowo i analizuje jego zawartość.[59]
      * Jeśli znajdzie `Dockerfile`, automatycznie wybierze strategię budowania `Docker`.[59]
      * Jeśli nie znajdzie `Dockerfile`, będzie szukać znanych plików, takich jak `package.json`, `pom.xml` czy `requirements.txt`. Na podstawie tych plików, automatycznie wykryje język (np. Node.js) i wybierze odpowiedni obraz budujący S2I.[58, 59]

Po pomyślnej analizie, `oc new-app` tworzy zestaw powiązanych ze sobą zasobów [57, 59, 60]:

1.  **`ImageStream` (np. `is/my-app`):** Pusty `ImageStream` gotowy do przyjmowania obrazów aplikacji, które zostaną zbudowane.[59]
2.  **`BuildConfig` (np. `bc/my-app`):** Skonfigurowany ze strategią (S2I lub Docker), wskazujący na repozytorium Git (`source`) i `ImageStream` (`output`).[57, 59] Co ważne, ten `BuildConfig` jest automatycznie tworzony z włączonymi triggerami `ConfigChange` [29] oraz webhookami `GitHub`/`Generic`.[42, 43]
3.  **`DeploymentConfig` (np. `dc/my-app`) lub `Deployment`:** Historycznie, `oc new-app` tworzyło `DeploymentConfig` (DC) [57, 60], zasób specyficzny dla OCP. Nowsze wersje `oc` domyślnie tworzą standardowy, K8s-natywny `Deployment`.[61] Jest to istotna różnica, ponieważ `DeploymentConfig` natywnie obsługuje `ImageChangeTrigger`, podczas gdy standardowy `Deployment` (w OCP 4.x) również może być do tego skonfigurowany, choć mechanizm jest inny (poprzez adnotacje `image.openshift.io/triggers` [31, 33]). Można wymusić stare zachowanie (stworzenie DC) za pomocą flagi `--as-deployment-config`.[61]
4.  **`Service` (np. `svc/my-app`):** Jeśli obraz budujący S2I lub `Dockerfile` eksponuje port (np. 8080), `oc new-app` automatycznie utworzy `Service` typu `ClusterIP`, aby umożliwić wewnętrzną komunikację sieciową z podami aplikacji.[57, 59, 60, 62]

Po utworzeniu tych zasobów, `oc new-app` automatycznie uruchamia także pierwszy `Build` [59], prawdopodobnie aktywowany przez `ConfigChangeTrigger`.

### 5.2. Monitorowanie Procesu Budowania: Efektywne Użycie `oc logs -f bc/my-app`

Gdy build jest w toku, deweloper musi śledzić jego postępy. Podejście naiwne polegałoby na znalezieniu Poda budującego (np. `oc get pods | grep build`) i śledzeniu jego logów.[63]

OpenShift oferuje znacznie wygodniejszą abstrakcję: `oc logs -f bc/<buildconfig_name>`.[64, 65, 66, 67]
Polecenie `oc logs -f bc/my-app` jest "inteligentne". Nie czyta ono logów z obiektu `BuildConfig` (który jest tylko definicją YAML). Zamiast tego, klient `oc`:

1.  Odnajduje `BuildConfig` o nazwie `my-app`.
2.  Sprawdza jego status, aby znaleźć *ostatni* uruchomiony obiekt `Build` (np. `build/my-app-1`).[65]
3.  Pobiera nazwę Poda powiązanego z tym obiektem `Build` (np. `my-app-1-build`).
4.  Wykonuje `oc logs -f` (follow) na tym konkretnym Podzie.

Dzięki temu deweloper nie musi znać nazwy Poda budującego, która zmienia się przy każdym buildzie. Możliwe jest również pobranie logów z konkretnej, historycznej wersji builda za pomocą flagi `--version`, np. `oc logs --version=1 bc/my-app`.[66, 67]

### 5.3. Wystawianie Aplikacji: Kreacja `Route` za Pomocą `oc expose svc/my-app`

Po pomyślnym zbudowaniu i wdrożeniu, aplikacja działa w Podzie, a `Service` (`svc/my-app`) udostępnia ją w ramach wewnętrznej sieci klastra.[60, 62] Aby udostępnić aplikację użytkownikom zewnętrznym (przez przeglądarkę), należy ją "wystawić" (expose).

Służy do tego polecenie `oc expose svc/my-app`.[68, 69, 70, 71]

Polecenie to tworzy nowy zasób OCP o nazwie `Route`.[15, 62, 68, 69, 72] `Route` (poprzednik `Ingress` w Kubernetes) jest instrukcją dla wbudowanego routera Ingress OCP (zazwyczaj HAProxy). Instruuje on router, aby:

1.  Zarezerwował publicznie dostępny adres URL (Hostname), np. `my-app-my-project.apps.mycluster.com`.[62, 72]
2.  Nasłuchiwał na portach 80 (HTTP) i 443 (HTTPS).
3.  Przekierowywał cały ruch przychodzący na ten Hostname do *wewnętrznej* usługi `svc/my-app`.[72]

Polecenie `oc expose` można dostosować, np. podając niestandardową nazwę hosta (`--hostname=www.example.com` [71, 72, 73]) lub definiując typ terminacji TLS (np. `--termination=edge` [15, 62]).

### 5.4. Weryfikacja End-to-End: Od `git push` do Działającej Usługi

Łącząc wszystkie omówione komponenty, możemy prześledzić kompletny, zautomatyzowany przepływ CI/CD w OCP, często nazywany "złotą ścieżką" (golden path):

1.  **Commit:** Deweloper wykonuje `git push` do repozytorium GitHub.
2.  **Trigger (Webhook):** GitHub wysyła powiadomienie do endpointu Webhook skonfigurowanego w `BuildConfig` `bc/my-app`.[42, 44]
3.  **Build:** `BuildConfig` uruchamia nowy `Build` (np. `build/my-app-2`).
4.  **Monitor:** Deweloper obserwuje proces budowania w czasie rzeczywistym: `oc logs -f bc/my-app`.[64]
5.  **Push (Internal):** Proces budowania (S2I) kończy się sukcesem, tworzy nowy obraz i wypycha go do `ImageStreamTag` `is/my-app:latest`.[50]
6.  **Trigger (ImageChange):** `ImageChangeTrigger` skonfigurowany w `DeploymentConfig` `dc/my-app` wykrywa, że `ImageStreamTag`, który obserwuje, został zaktualizowany.[18, 31]
7.  **Deployment:** `DeploymentConfig` automatycznie rozpoczyna nowy "rollout", tworząc Poda aplikacji w nowej wersji.[29]
8.  **Route (Service):** `Service` `svc/my-app` płynnie przełącza ruch na nowy Pod, gdy ten stanie się gotowy.
9.  **Access:** `Route` `route/my-app` (utworzony wcześniej przez `oc expose`) przez cały czas kieruje ruch zewnętrzny do `Service`.

Weryfikacja polega na pobraniu adresu `Route` (za pomocą `oc get route my-app` [62, 68]) i odświeżeniu strony w przeglądarce. Zmiany wprowadzone w `git push` są widoczne w działającej aplikacji. Ten zamknięty, w pełni zautomatyzowany cykl od kodu do wdrożenia jest rdzenną propozycją wartości, jaką OpenShift oferuje zespołom deweloperskim.\`
#### **Cytowane prace**

1. Expose OpenShift Internal Registry To External Users | by ..., otwierano: listopada 14, 2025, [https://computingpost.medium.com/expose-openshift-internal-registry-to-external-users-479b320003e7](https://computingpost.medium.com/expose-openshift-internal-registry-to-external-users-479b320003e7)  
2. Registry | OpenShift Container Platform | 4.8 \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html-single/registry/index](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html-single/registry/index)  
3. Chapter 4\. Accessing the registry | Registry | OpenShift Container Platform | 4.11, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.11/html/registry/accessing-the-registry](https://docs.redhat.com/en/documentation/openshift_container_platform/4.11/html/registry/accessing-the-registry)  
4. Chapter 2\. Image Registry Operator in OpenShift Container Platform, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.1/html/registry/image-registry-operator-in-openshift-container-platform](https://docs.redhat.com/en/documentation/openshift_container_platform/4.1/html/registry/image-registry-operator-in-openshift-container-platform)  
5. Chapter 5\. Exposing the registry | Registry | OpenShift Container Platform | 4.1, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.1/html/registry/securing-exposing-registry](https://docs.redhat.com/en/documentation/openshift_container_platform/4.1/html/registry/securing-exposing-registry)  
6. Enabling the Red Hat OpenShift internal image registry \- IBM, otwierano: listopada 14, 2025, [https://www.ibm.com/docs/en/masv-and-l/cd?topic=installing-enabling-red-hat-openshift-internal-image-registry](https://www.ibm.com/docs/en/masv-and-l/cd?topic=installing-enabling-red-hat-openshift-internal-image-registry)  
7. Chapter 4\. Accessing the registry | Registry | OpenShift Container Platform | 4.1, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.1/html/registry/accessing-the-registry](https://docs.redhat.com/en/documentation/openshift_container_platform/4.1/html/registry/accessing-the-registry)  
8. Chapter 9\. Image configuration resources | Images | OpenShift Container Platform | 4.9, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.9/html/images/image-configuration](https://docs.redhat.com/en/documentation/openshift_container_platform/4.9/html/images/image-configuration)  
9. Using OpenShift's Internal Registry | by Michael Greenberg \- Medium, otwierano: listopada 14, 2025, [https://medium.com/@mgreenbe\_84803/using-openshifts-internal-registry-e4a81d09da59](https://medium.com/@mgreenbe_84803/using-openshifts-internal-registry-e4a81d09da59)  
10. How to \`docker login\` to OpenShift Docker registry \- Stack Overflow, otwierano: listopada 14, 2025, [https://stackoverflow.com/questions/64480609/how-to-docker-login-to-openshift-docker-registry](https://stackoverflow.com/questions/64480609/how-to-docker-login-to-openshift-docker-registry)  
11. Chapter 4\. Accessing the registry \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/registry/accessing-the-registry](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/registry/accessing-the-registry)  
12. Chapter 4\. Accessing the registry | Registry | OpenShift Container Platform | 4.18, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.18/html/registry/accessing-the-registry](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/registry/accessing-the-registry)  
13. Setting up an image registry \- IBM Cloud Docs, otwierano: listopada 14, 2025, [https://cloud.ibm.com/docs/openshift?topic=openshift-registry](https://cloud.ibm.com/docs/openshift?topic=openshift-registry)  
14. How to register account to "image-registry.openshift-image-registry" \- Stack Overflow, otwierano: listopada 14, 2025, [https://stackoverflow.com/questions/63844369/how-to-register-account-to-image-registry-openshift-image-registry](https://stackoverflow.com/questions/63844369/how-to-register-account-to-image-registry-openshift-image-registry)  
15. How to deploy a web service on OpenShift \- Red Hat, otwierano: listopada 14, 2025, [https://www.redhat.com/en/blog/deploy-web-service-openshift](https://www.redhat.com/en/blog/deploy-web-service-openshift)  
16. Chapter 4\. Accessing the registry | Registry | OpenShift Container Platform | 4.12, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.12/html/registry/accessing-the-registry](https://docs.redhat.com/en/documentation/openshift_container_platform/4.12/html/registry/accessing-the-registry)  
17. podman-login, otwierano: listopada 14, 2025, [https://docs.podman.io/en/v5.1.0/markdown/podman-login.1.html](https://docs.podman.io/en/v5.1.0/markdown/podman-login.1.html)  
18. Why managing container images on OpenShift is better than on ..., otwierano: listopada 14, 2025, [https://blog.cloudowski.com/articles/why-managing-container-images-on-openshift-is-better-than-on-kubernetes/](https://blog.cloudowski.com/articles/why-managing-container-images-on-openshift-is-better-than-on-kubernetes/)  
19. Chapter 6\. Managing image streams | Images | OpenShift Container ..., otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/images/managing-image-streams](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/images/managing-image-streams)  
20. Chapter 2\. Understanding containers, images, and imagestreams | Images | OpenShift Container Platform | 4.1 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.1/html/images/understanding-images](https://docs.redhat.com/en/documentation/openshift_container_platform/4.1/html/images/understanding-images)  
21. Builds and Image Streams \- Core Concepts | Architecture | OpenShift Container Platform Branch Build \- Fedora People, otwierano: listopada 14, 2025, [https://miminar.fedorapeople.org/\_preview/openshift-enterprise/registry-redeploy/architecture/core\_concepts/builds\_and\_image\_streams.html](https://miminar.fedorapeople.org/_preview/openshift-enterprise/registry-redeploy/architecture/core_concepts/builds_and_image_streams.html)  
22. Why managing container images on OpenShift is better than on Kubernetes \- Cloudowski, otwierano: listopada 14, 2025, [https://cloudowski.com/articles/why-managing-container-images-on-openshift-is-better-than-on-kubernetes/](https://cloudowski.com/articles/why-managing-container-images-on-openshift-is-better-than-on-kubernetes/)  
23. Chapter 5\. Managing imagestreams | Images | OpenShift Container Platform | 4.1, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.1/html/images/managing-image-streams](https://docs.redhat.com/en/documentation/openshift_container_platform/4.1/html/images/managing-image-streams)  
24. Chapter 6\. Managing image streams | Images | OpenShift Container Platform | 4.10, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.10/html/images/managing-image-streams](https://docs.redhat.com/en/documentation/openshift_container_platform/4.10/html/images/managing-image-streams)  
25. Chapter 6\. Managing image streams | Images | OpenShift Container Platform | 4.9, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.9/html/images/managing-image-streams](https://docs.redhat.com/en/documentation/openshift_container_platform/4.9/html/images/managing-image-streams)  
26. Remotely Push and Pull Container Images to OpenShift \- Red Hat, otwierano: listopada 14, 2025, [https://www.redhat.com/en/blog/remotely-push-pull-container-images-openshift](https://www.redhat.com/en/blog/remotely-push-pull-container-images-openshift)  
27. Image Streams in OpenShift: What You Need to Know \- Tutorial Works, otwierano: listopada 14, 2025, [https://www.tutorialworks.com/openshift-imagestreams/](https://www.tutorialworks.com/openshift-imagestreams/)  
28. openshift how imagestream track the image changes? \- Stack Overflow, otwierano: listopada 14, 2025, [https://stackoverflow.com/questions/52402971/openshift-how-imagestream-track-the-image-changes](https://stackoverflow.com/questions/52402971/openshift-how-imagestream-track-the-image-changes)  
29. Openshift Build Triggers Webhook Image Change Configuration ..., otwierano: listopada 14, 2025, [https://notes.kodekloud.com/docs/OpenShift-4/Concepts-Builds-and-Deployments/Openshift-Build-Triggers-Webhook-Image-Change-Configuration-Change](https://notes.kodekloud.com/docs/OpenShift-4/Concepts-Builds-and-Deployments/Openshift-Build-Triggers-Webhook-Image-Change-Configuration-Change)  
30. Images | OpenShift Container Platform | 4.14 \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.14/html-single/images/index](https://docs.redhat.com/en/documentation/openshift_container_platform/4.14/html-single/images/index)  
31. Chapter 8\. Triggering updates on image stream changes | Images | OpenShift Container Platform | 4.8 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/images/triggering-updates-on-imagestream-changes](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/images/triggering-updates-on-imagestream-changes)  
32. Openshift ImageChange trigger gets deleted in Deploymentconfig when applying templage, otwierano: listopada 14, 2025, [https://stackoverflow.com/questions/54293217/openshift-imagechange-trigger-gets-deleted-in-deploymentconfig-when-applying-tem](https://stackoverflow.com/questions/54293217/openshift-imagechange-trigger-gets-deleted-in-deploymentconfig-when-applying-tem)  
33. Triggering updates on image stream changes \- OKD Documentation, otwierano: listopada 14, 2025, [https://docs.okd.io/4.18/openshift\_images/triggering-updates-on-imagestream-changes.html](https://docs.okd.io/4.18/openshift_images/triggering-updates-on-imagestream-changes.html)  
34. OpenShift Build Strategies. In today's rapidly evolving software… | by Berkay HELVACIOGLU | Medium, otwierano: listopada 14, 2025, [https://medium.com/@berkayhelvacioglu/openshift-build-strategies-0f385338a759](https://medium.com/@berkayhelvacioglu/openshift-build-strategies-0f385338a759)  
35. Chapter 1\. Understanding image builds | Builds using BuildConfig | OpenShift Container Platform | 4.15 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.15/html/builds\_using\_buildconfig/understanding-image-builds](https://docs.redhat.com/en/documentation/openshift_container_platform/4.15/html/builds_using_buildconfig/understanding-image-builds)  
36. Chapter 2\. Understanding build configurations | Builds using BuildConfig | OpenShift Container Platform | 4.17 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.17/html/builds\_using\_buildconfig/understanding-buildconfigs](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/builds_using_buildconfig/understanding-buildconfigs)  
37. Chapter 1\. Understanding image builds | Builds | OpenShift Container Platform | 4.2, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.2/html/builds/understanding-image-builds](https://docs.redhat.com/en/documentation/openshift_container_platform/4.2/html/builds/understanding-image-builds)  
38. OpenShift BuildConfig Tutorial \- DevOpsSchool.com, otwierano: listopada 14, 2025, [https://www.devopsschool.com/blog/openshift-buildconfig-tutorial/](https://www.devopsschool.com/blog/openshift-buildconfig-tutorial/)  
39. OpenShift Build & BuildConfig | K21Academy \- YouTube, otwierano: listopada 14, 2025, [https://www.youtube.com/watch?v=2PAKw5PHyb4](https://www.youtube.com/watch?v=2PAKw5PHyb4)  
40. Openshift Build Strategies \- KodeKloud Notes, otwierano: listopada 14, 2025, [https://notes.kodekloud.com/docs/OpenShift-4/Concepts-Builds-and-Deployments/Openshift-Build-Strategies](https://notes.kodekloud.com/docs/OpenShift-4/Concepts-Builds-and-Deployments/Openshift-Build-Strategies)  
41. BuildConfig \[build.openshift.io/v1\] \- Workloads APIs | API reference | OKD 4.19, otwierano: listopada 14, 2025, [https://docs.okd.io/4.19/rest\_api/workloads\_apis/buildconfig-build-openshift-io-v1.html](https://docs.okd.io/4.19/rest_api/workloads_apis/buildconfig-build-openshift-io-v1.html)  
42. Chapter 8\. Triggering and modifying builds | Builds | OpenShift Container Platform | 4.1, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.1/html/builds/triggering-builds-build-hooks](https://docs.redhat.com/en/documentation/openshift_container_platform/4.1/html/builds/triggering-builds-build-hooks)  
43. Chapter 8\. Triggering and modifying builds | Builds using ..., otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.14/html/builds\_using\_buildconfig/triggering-builds-build-hooks](https://docs.redhat.com/en/documentation/openshift_container_platform/4.14/html/builds_using_buildconfig/triggering-builds-build-hooks)  
44. Enable continuous deployment using Red Hat OpenShift S2I and GitHub webhooks, otwierano: listopada 14, 2025, [https://developer.ibm.com/tutorials/continuous-deployment-s2i-and-webhooks/](https://developer.ibm.com/tutorials/continuous-deployment-s2i-and-webhooks/)  
45. Setting up GitHub webhooks for an OpenShift build \- Stack Overflow, otwierano: listopada 14, 2025, [https://stackoverflow.com/questions/58041226/setting-up-github-webhooks-for-an-openshift-build](https://stackoverflow.com/questions/58041226/setting-up-github-webhooks-for-an-openshift-build)  
46. How I automated BuildConfigs and ImageStreams in OpenShift \- Level Up Coding, otwierano: listopada 14, 2025, [https://levelup.gitconnected.com/how-i-automated-buildconfigs-and-imagestreams-in-openshift-dd9745c4ea8f](https://levelup.gitconnected.com/how-i-automated-buildconfigs-and-imagestreams-in-openshift-dd9745c4ea8f)  
47. Chapter 2\. Builds | CI/CD | OpenShift Container Platform | 4.8 | Red ..., otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/cicd/builds](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/cicd/builds)  
48. Chapter 4\. S2I Requirements | Creating Images | OpenShift Container Platform | 3.11, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.11/html/creating\_images/creating-images-s2i](https://docs.redhat.com/en/documentation/openshift_container_platform/3.11/html/creating_images/creating-images-s2i)  
49. Chapter 2\. Using Source-to-Image (S2I) \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/red\_hat\_software\_collections/2/html/using\_red\_hat\_software\_collections\_container\_images/sti](https://docs.redhat.com/en/documentation/red_hat_software_collections/2/html/using_red_hat_software_collections_container_images/sti)  
50. Understanding the Red Hat OpenShift Build Process: S2I vs Docker ..., otwierano: listopada 14, 2025, [https://medium.com/@morepravin1989/understanding-the-red-hat-openshift-build-process-s2i-vs-docker-builds-3ac1a55fc1b0](https://medium.com/@morepravin1989/understanding-the-red-hat-openshift-build-process-s2i-vs-docker-builds-3ac1a55fc1b0)  
51. OpenShift Concepts, otwierano: listopada 14, 2025, [https://www.rosaworkshop.io/ostoy/2-concepts/](https://www.rosaworkshop.io/ostoy/2-concepts/)  
52. Chapter 5\. Using build strategies | Builds | OpenShift Container Platform | 4.1 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.1/html/builds/build-strategies](https://docs.redhat.com/en/documentation/openshift_container_platform/4.1/html/builds/build-strategies)  
53. Chapter 1\. Understanding image builds | Builds | OpenShift Container Platform | 4.6, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.6/html/builds/understanding-image-builds](https://docs.redhat.com/en/documentation/openshift_container_platform/4.6/html/builds/understanding-image-builds)  
54. 4 Ways to do a Dockerfile Build in OpenShift \- Tutorial Works, otwierano: listopada 14, 2025, [https://www.tutorialworks.com/openshift-dockerfile/](https://www.tutorialworks.com/openshift-dockerfile/)  
55. Creating A Sample Application \- New England Research Cloud(NERC), otwierano: listopada 14, 2025, [https://nerc-project.github.io/nerc-docs/openshift/applications/creating-a-sample-application/](https://nerc-project.github.io/nerc-docs/openshift/applications/creating-a-sample-application/)  
56. Chapter 3\. Creating applications | Building applications | OpenShift Container Platform | 4.12, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.12/html/building\_applications/creating-applications](https://docs.redhat.com/en/documentation/openshift_container_platform/4.12/html/building_applications/creating-applications)  
57. Chapter 5\. Creating New Applications | Developer Guide | OpenShift Container Platform | 3.0 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/pt-br/documentation/openshift\_container\_platform/3.0/html/developer\_guide/dev-guide-new-app](https://docs.redhat.com/pt-br/documentation/openshift_container_platform/3.0/html/developer_guide/dev-guide-new-app)  
58. Chapter 3\. Creating Applications | Building Applications | OpenShift Container Platform | 4.8, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/building\_applications/creating-applications](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/building_applications/creating-applications)  
59. Deep Dive into OpenShift's 'oc new-app' Command | by Jimin ..., otwierano: listopada 14, 2025, [https://jiminbyun.medium.com/deep-dive-into-openshifts-oc-new-app-command-cc16281e322](https://jiminbyun.medium.com/deep-dive-into-openshifts-oc-new-app-command-cc16281e322)  
60. Learn OpenShift \- The oc new-app command \- O'Reilly, otwierano: listopada 14, 2025, [https://www.oreilly.com/library/view/learn-openshift/9781788992329/6de14a27-78b5-4d1c-aeab-165f600134cc.xhtml](https://www.oreilly.com/library/view/learn-openshift/9781788992329/6de14a27-78b5-4d1c-aeab-165f600134cc.xhtml)  
61. Can oc new-app create a Deployment instead of a DeploymentConfig? \- Stack Overflow, otwierano: listopada 14, 2025, [https://stackoverflow.com/questions/65148976/can-oc-new-app-create-a-deployment-instead-of-a-deploymentconfig](https://stackoverflow.com/questions/65148976/can-oc-new-app-create-a-deployment-instead-of-a-deploymentconfig)  
62. Expose OpenShift Apps over HTTPS \- Pradipta Banerjee \- Medium, otwierano: listopada 14, 2025, [https://pradiptabanerjee.medium.com/expose-openshift-apps-over-https-22e301d5a6f2](https://pradiptabanerjee.medium.com/expose-openshift-apps-over-https-22e301d5a6f2)  
63. Lab 7 \- Developing and Managing Your Application \- Red Hat | Public Sector, otwierano: listopada 14, 2025, [http://redhatgov.io/workshops/openshift\_4\_101\_dynatrace/lab7-devmanage/](http://redhatgov.io/workshops/openshift_4_101_dynatrace/lab7-devmanage/)  
64. Logging, Monitoring, and Debugging \- Deploying to OpenShift \[Book\] \- O'Reilly, otwierano: listopada 14, 2025, [https://www.oreilly.com/library/view/deploying-to-openshift/9781491957158/ch18.html](https://www.oreilly.com/library/view/deploying-to-openshift/9781491957158/ch18.html)  
65. Debugging in OpenShift: A Beginner's Guide | by Jimin \- Medium, otwierano: listopada 14, 2025, [https://jiminbyun.medium.com/debugging-in-openshift-a-beginners-guide-8599622e16f7](https://jiminbyun.medium.com/debugging-in-openshift-a-beginners-guide-8599622e16f7)  
66. Chapter 8\. Builds | Developer Guide | OpenShift Container Platform | 3.11 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.11/html/developer\_guide/builds](https://docs.redhat.com/en/documentation/openshift_container_platform/3.11/html/developer_guide/builds)  
67. Chapter 7\. Performing basic builds | Builds | OpenShift Container Platform | 4.1 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.1/html/builds/basic-build-operations](https://docs.redhat.com/en/documentation/openshift_container_platform/4.1/html/builds/basic-build-operations)  
68. Deploy an application from source to Azure Red Hat OpenShift \- Microsoft Learn, otwierano: listopada 14, 2025, [https://learn.microsoft.com/en-us/azure/openshift/howto-deploy-with-s2i](https://learn.microsoft.com/en-us/azure/openshift/howto-deploy-with-s2i)  
69. Chapter 17\. Configuring Routes | Networking | OpenShift Container ..., otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/networking/configuring-routes](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/networking/configuring-routes)  
70. How to build and deploy an app from local directory? \- Stack Overflow, otwierano: listopada 14, 2025, [https://stackoverflow.com/questions/47260933/how-to-build-and-deploy-an-app-from-local-directory](https://stackoverflow.com/questions/47260933/how-to-build-and-deploy-an-app-from-local-directory)  
71. OpenShift CLI developer command reference \- OKD Documentation, otwierano: listopada 14, 2025, [https://docs.okd.io/4.20/cli\_reference/openshift\_cli/developer-cli-commands.html](https://docs.okd.io/4.20/cli_reference/openshift_cli/developer-cli-commands.html)  
72. OpenShift Route: Tutorial & Examples \- Densify, otwierano: listopada 14, 2025, [https://www.densify.com/openshift-tutorial/openshift-route/](https://www.densify.com/openshift-tutorial/openshift-route/)  
73. Exposing apps with routes in Red Hat OpenShift 4 \- IBM Cloud Docs, otwierano: listopada 14, 2025, [https://cloud.ibm.com/docs/openshift?topic=openshift-openshift\_routes](https://cloud.ibm.com/docs/openshift?topic=openshift-openshift_routes)
