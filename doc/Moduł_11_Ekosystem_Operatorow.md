# Moduł 11: Ekosystem Operatorów (OLM)

## Lekcja 11.1: Koncepcja Operatora (Operator Pattern) i CRD

### 11.1.1. Wprowadzenie: Ewolucja od Zarządzania Manualnego do Automatyzacji Stanowej

Wczesna automatyzacja w Kubernetes, napędzana przez wbudowane kontrolery, takie jak $Deployment$ czy $ReplicaSet$, koncentrowała się przede wszystkim na zarządzaniu aplikacjami bezstanowymi. Te mechanizmy doskonale radzą sobie z zapewnieniem, że określona liczba replik bezstanowej aplikacji jest uruchomiona i dostępna. Jednakże, ekosystemy IT są w dużej mierze zależne od aplikacji stanowych – takich jak bazy danych, systemy kolejkowania wiadomości czy klastry $etcd$ – które posiadają skomplikowaną, wewnętrzną logikę operacyjną.

Problem polega na tym, że generyczne kontrolery Kubernetes nie posiadają wiedzy dziedzinowej (domain-specific knowledge) wymaganej do poprawnego zarządzania cyklem życia tych złożonych systemów.[1] Wdrożenie, a następnie zarządzanie, skalowanie, tworzenie kopii zapasowych, przywracanie po awarii (failover) czy aktualizacja klastra bazy danych to zadania wykraczające poza prostą kontrolę liczby podów.[1, 2]

Wzorzec Operatora (Operator Pattern) został wprowadzony właśnie po to, aby rozwiązać ten problem. Motywacją było zautomatyzowanie i zakodowanie wiedzy oraz powtarzalnych zadań, które normalnie wykonuje wykwalifikowany "operator ludzki" (Human Operator).[2, 3] Operator przechwytuje tę głęboką wiedzę na temat działania systemu i przekłada ją na kod.[3] Pozwala to na rozszerzenie możliwości klastra Kubernetes i automatyzację zadań wykraczających poza standardowe funkcje, bez konieczności modyfikowania samego, bazowego kodu Kubernetes.[3, 4]

### 11.1.2. Filar 1: Custom Resource Definition (CRD) – Rozszerzanie API Kubernetes

Pierwszym fundamentalnym filarem wzorca Operatora jest $Custom Resource Definition$ (CRD). CRD to natywny mechanizm Kubernetes służący do rozszerzania jego API.[1, 5] W praktyce, CRD pozwala na zdefiniowanie zupełnie nowego *rodzaju* (Kind) zasobu, który serwer API Kubernetes będzie przechowywał, udostępniał i zarządzał nim tak samo, jak wbudowanymi zasobami, takimi jak $Pods$, $Services$ czy $Deployments$.[5, 6]

Należy rozróżnić dwa pojęcia:

1.  **Custom Resource Definition (CRD):** Jest to *schemat* lub *definicja* nowego typu. Definiuje ona nazwę (np. $SampleDB$), grupę API (np. $db.example.com$) oraz strukturę danych (specyfikację).[1]
2.  **Custom Resource (CR):** Jest to *instancja* (obiekt) utworzona na podstawie danego CRD. Kiedy użytkownik tworzy obiekt $kind: SampleDB$, tworzy właśnie Custom Resource.[1, 6]

Po zainstalowaniu CRD w klastrze, użytkownicy mogą natychmiast rozpocząć tworzenie i zarządzanie obiektami CR za pomocą standardowych narzędzi, takich jak $kubectl$ (np. $kubectl get sampledb$).[5, 7] Co kluczowe, te nowe zasoby integrują się z ekosystemem Kubernetes, w tym z kontrolą dostępu opartą na rolach (RBAC), co pozwala na precyzyjne zarządzanie uprawnieniami do nich.[1, 5]

Z perspektywy użytkownika, CRD staje się nowym, wysokopoziomowym interfejsem API. Zamiast ręcznie tworzyć skomplikowany zestaw zasobów (np. $StatefulSet$, $Service$, $ConfigMap$, $Secret$), użytkownik dostarcza "deklarację intencji" (record of intent) [2] w postaci prostego obiektu CR. Opisuje on *pożądany stan* na wysokim poziomie (np. "Chcę 3-węzłowy klaster Postgres z codziennymi backupami"), a nie *jak* ten stan ma zostać osiągnięty.[1, 7]

Warto zauważyć, że CRD to nie jedyny sposób rozszerzania API, ale jest najprostszy. Bardziej zaawansowaną alternatywą jest $API Aggregation$, która pozwala na budowę własnego, dedykowanego serwera API, dając pełną kontrolę nad walidacją, sposobem przechowywania danych i konwersją między wersjami API. Jest to jednak znacznie bardziej skomplikowane.[5] Nowoczesne CRD oferują jednak bogate funkcje, takie jak walidacja schematu (OpenAPI v3), obsługa wielu wersji API (kluczowa dla ewolucji i unikania łamania kompatybilności) oraz mechanizmy $finalizers$ do bezpiecznego zarządzania procesem usuwania zasobów.[8, 9]

### 11.1.3. Filar 2: Kontroler (Controller) – Mózg Operacji

Samo zdefiniowanie CRD i tworzenie obiektów CR nie wnosi żadnej funkcjonalności – są to jedynie rekordy danych przechowywane w $etcd$.[7] Aby te dane "ożyły" i przełożyły się na realne działania w klastrze, potrzebny jest drugi filar: **Kontroler**.

Kontroler jest aktywnym procesem (demonem), zazwyczaj uruchomionym jako $Deployment$ w klastrze [3], który implementuje "pętlę sterowania" (control loop) lub, bardziej precyzyjnie, "pętlę uzgadniania" (reconciliation loop).[1, 3, 10] Kontroler jest klientem API Kubernetes, który nieustannie wykonuje cykl trzech kroków [3, 11, 12]:

1.  **Obserwuj (Watch):** Kontroler monitoruje serwer API Kubernetes pod kątem zmian (tworzenie, aktualizacja, usuwanie) w określonych zasobach. Przede wszystkim obserwuje on obiekty CR zdefiniowane przez powiązane z nim CRD (np. wszystkie obiekty $kind: SampleDB$).[3, 11]
2.  **Porównaj (Diff / Reconcile):** Gdy kontroler wykryje zmianę, pobiera obiekt CR i porównuje *stan pożądany* (zapisany w polu $spec$ obiektu) z *rzeczywistym stanem* klastra (np. jakie Pody, Serwisy czy Secrety faktycznie istnieją i są powiązane z tym CR).
3.  **Działaj (Act):** Jeśli stany się różnią, kontroler podejmuje działania, aby doprowadzić stan rzeczywisty do stanu pożądanego.[1, 11] Może to oznaczać tworzenie nowych Podów, modyfikowanie $ConfigMap$, wywoływanie zewnętrznego API w celu utworzenia backupu lub cokolwiek innego, co zostało zakodowane w jego logice.[13]

Ta nieskończona pętla uzgadniania jest fundamentalną zasadą działania Kubernetes. Kontroler nie reaguje tylko na zdarzenia; stale dąży do tego, by rzeczywistość odpowiadała deklaracji, co zapewnia samonaprawianie się systemu.[10, 12]

### 11.1.4. Synteza: Operator jako Kompletny Wzorzec

Wzorzec Operatora to synergia obu tych filarów: $Operator = Custom Resource Definition (CRD) + Controller$.[6, 14]

  * CRD to *dane* i "interfejs API" – to jak zdefiniowanie nowej tabeli w bazie danych.[2, 14]
  * Kontroler to *logika* i "mózg" – to aplikacja, która odczytuje i zapisuje do tej tabeli, nadając jej znaczenie.[2, 14]

Weźmy za przykład hipotetyczny Operator $SampleDB$.[3] Składałby się on z:

1.  **CRD** o nazwie $SampleDB$, definiującego pola takie jak $version$, $replicas$ czy $backupPolicy$.
2.  **Kontrolera**, uruchomionego jako $Deployment$, który obserwuje zasoby $SampleDB$.

Gdy użytkownik tworzy prosty obiekt CR $kind: SampleDB$, kontroler (mózg) wykrywa go. Odczytuje specyfikację i rozpoczyna pętlę uzgadniania, tłumacząc tę wysokopoziomową intencję na konkretne, niskopoziomowe zasoby Kubernetes, takie jak $StatefulSet$ do uruchomienia Podów bazy danych, $Service$ do zapewnienia dostępu sieciowego oraz $Secret$ do bezpiecznego przechowania haseł administratora.[7]

Kluczowa zmiana paradygmatu polega na przejściu z zarządzania imperatywnego ("zrób to") na deklaratywne zarządzanie stanem ("zapewnij, że tak jest").[5, 13] Użytkownik nie wydaje serii poleceń, aby coś utworzyć. Zamiast tego, tworzy w API Kubernetes pojedynczy "rekord intencji" (CR).[2] Nieskończona pętla kontrolera dba o realizację tej intencji, zapewniając automatyczną korektę i samonaprawianie. Jeśli administrator ręcznie usunie $Service$ należący do bazy danych, kontroler (działając jak zautomatyzowany ludzki operator) zauważy tę rozbieżność i natychmiast go odtworzy, aby dopasować stan rzeczywisty do pożądanego.

Co więcej, CRD staje się formalnym, wersjonowanym kontraktem API dla danej aplikacji.[1] Oddziela to logikę biznesową (co użytkownik chce skonfigurować, zdefiniowane w schemacie CRD) od logiki implementacji (jak kontroler to osiągnie). Ten stabilny kontrakt API, który można wersjonować niezależnie od klastra [8] i który jest introspektywny (np. przez $kubectl explain$ [9]), pozwala na budowanie stabilnych i przewidywalnych ekosystemów automatyzacji wokół złożonego oprogramowania.

## Lekcja 11.2: Operator Lifecycle Manager (OLM)

### 11.2.1. Definicja OLM: "System Operacyjny" lub "App Store" dla Operatorów

Wprowadzenie wzorca Operatora rozwiązało problem zarządzania skomplikowanymi aplikacjami *wewnątrz* Kubernetes. Szybko jednak pojawił się nowy problem: same Operatory są potężnym oprogramowaniem, które również wymaga zarządzania.[15] Kto będzie instalować Operatory, zarządzać ich zależnościami (Operator A może wymagać Operatora B), aktualizować je do nowych wersji i konfigurować dla nich skomplikowane uprawnienia RBAC? Kto zarządza menedżerami?

Odpowiedzią na te wyzwania jest **Operator Lifecycle Manager (OLM)**. OLM to projekt, który rozszerza Kubernetes, aby zapewnić deklaratywny sposób instalacji, zarządzania cyklem życia i aktualizacji Operatorów oraz ich zależności na klastrze.[16, 17, 18]

OLM można postrzegać na dwa sposoby:

1.  **Analogia do "App Store"** [19]: OLM zapewnia mechanizmy odkrywania (Discovery) Operatorów, automatycznych aktualizacji "over-the-air" oraz model zależności (Dependency model).[16] Działa jak scentralizowany punkt do zarządzania "aplikacjami" (Operatorami) na klastrze.
2.  **Analogia do Menedżera Pakietów** [15, 20]: OLM działa bardzo podobnie do systemowych menedżerów pakietów, takich jak $yum$ (RPM) czy $apt$ (DPKG). Rozwiązuje zależności i dba o to, aby na klastrze zainstalowany był spójny i kompatybilny zestaw oprogramowania (Operatorów).[16, 21]

### 11.2.2. Architektura OLM: Operator dla Operatorów

Fundamentalną koncepcją OLM jest to, że sam w sobie jest on implementacją wzorca Operatora – jest to "Meta-Operator", czyli Operator stworzony do zarządzania innymi Operatorami. Wykorzystuje ten sam model (CRD + Kontrolery) do automatyzacji cyklu życia Operatorów.

Architektura OLM opiera się na dwóch głównych kontrolerach (Operatorach), które zazwyczaj działają w przestrzeni nazw $openshift-operator-lifecycle-manager$ [22, 23]:

1.  **$OLM Operator$ (Operator Cyklu Życia):** Jest to "wykonawca". Jego zadaniem jest monitorowanie zatwierdzonych planów instalacji (CRD $InstallPlan$) oraz manifestów (CRD $ClusterServiceVersion$). Kiedy $OLM Operator$ widzi gotowy do wykonania plan, jest odpowiedzialny za faktyczne utworzenie *wszystkich* zasobów zdefiniowanych w manifeście Operatora – jego $Deployment$, $ServiceAccount$, powiązań RBAC ($Roles$, $ClusterRoles$) oraz CRD, które ten Operator udostępnia.[22, 24, 25]
2.  **$Catalog Operator$ (Operator Katalogu):** Jest to "resolver" lub "planista". Jego zadaniem jest monitorowanie źródeł oprogramowania (CRD $CatalogSource$) oraz intencji instalacji użytkownika (CRD $Subscription$). Kiedy użytkownik tworzy nową $Subscription$, $Catalog Operator$ przeszukuje dostępne katalogi, znajduje odpowiedni manifest (CSV) dla żądanego Operatora, rozwiązuje wszystkie jego zależności (znajduje CSV dla innych wymaganych Operatorów) i na tej podstawie generuje szczegółowy "plan wykonawczy" (CRD $InstallPlan$).[22, 24, 25]

Ten wielowarstwowy, rekursywny system jest niezwykle potężny. Użytkownik po prostu deklaruje intencję (poprzez CR $Subscription$), a dwa kontrolery OLM współpracują, aby tę intencję rozwiązać, zaplanować i bezpiecznie wykonać.

### 11.2.3. Kluczowe Zasoby (CRD) Architektury OLM

"Magia" OLM jest w pełni oparta na zestawie dedykowanych definicji $Custom Resource Definitions$ (CRD), które OLM sam instaluje i którymi zarządza. Zrozumienie tych zasobów jest kluczowe dla zrozumienia OLM.[18, 24, 26]

  * **$CatalogSource$ ($catsrc$):** Definiuje repozytorium lub "katalog" z oprogramowaniem.[24] Jest to zazwyczaj wskaźnik do obrazu kontenera w rejestrze (tzw. "index image"), który zawiera bazę danych wszystkich dostępnych Operatorów, ich manifestów (CSV) i powiązanych CRD.[26, 27]
  * **$Subscription$ ($sub$):** Jest to "deklaracja intencji instalacji" tworzona przez użytkownika (lub automatycznie przez kliknięcie "Install" w OperatorHub).[23, 28] Mówi OLM: "Chcę zainstalować Operatora X, z katalogu Y, w kanale aktualizacji Z (np. $stable$)".[26] OLM będzie również monitorować ten kanał i automatycznie proponować (lub instalować) aktualizacje, gdy się pojawią.[28]
  * **$ClusterServiceVersion$ ($CSV$):** To jest serce pakietu Operatora. CSV to pojedynczy manifest YAML zawierający *wszystkie* metadane potrzebne do uruchomienia i zarządzania Operatorem [22]:
      * **Metadane aplikacji:** Nazwa, opis, wersja (zgodna z semver), ikony, linki.[22]
      * **Strategia instalacji:** Pełna specyfikacja $Deployment$ Operatora (jaki obraz, jakie zmienne środowiskowe itp.).[22]
      * **Wymagania RBAC:** Dokładna lista uprawnień ($Roles$, $ClusterRoles$), których Operator potrzebuje do działania.[22]
      * **Definicje API:** Lista CRD, które ten Operator *posiada* (owned) i będzie udostępniał użytkownikom, oraz lista API (CRD lub $APIServices$), których *wymaga* (required) od innych Operatorów (zależności).[21, 22]
  * **$InstallPlan$ ($ip$):** Obliczony "plan wykonawczy" generowany przez $Catalog Operator$.[29] Zawiera on dokładną, krok po kroku listę *wszystkich* zasobów (zarówno nowych, jak i aktualizowanych), które muszą zostać utworzone, aby bezpiecznie zainstalować lub zaktualizować Operatora do żądanej wersji CSV.[24, 26] Plany te mogą wymagać ręcznej akceptacji przez administratora lub być zatwierdzane automatycznie, w zależności od konfiguracji $Subscription$.[25]
  * **$OperatorGroup$ ($og$):** Zasób kluczowy dla Lekcji 11.4. Definiuje on zasięg (scope) i uprawnienia dla Operatorów instalowanych w danej przestrzeni nazw.[23, 24, 26]

### 11.2.4. Zarządzanie Zależnościami i Aktualizacjami

Jedną z najważniejszych funkcji OLM jest zaawansowane zarządzanie zależnościami. Działa to w oparciu o $ClusterServiceVersion$. Kiedy $Catalog Operator$ analizuje CSV dla Operatora A, sprawdza pole $spec.customresourcedefinitions.required$ (lub $spec.apiservicedefinitions.required$).[21]

Jeśli Operator A deklaruje, że do działania wymaga CRD $kind: Bar, group: foo.com, version: v1$ [20], OLM nie pozwoli na jego instalację, dopóki nie znajdzie innego Operatora (np. Operatora B), który w swoim CSV deklaruje, że *posiada* (owns) dokładnie ten CRD. Jeśli OLM znajdzie Operatora B w dostępnych $CatalogSource$, automatycznie dołączy go do $InstallPlan$ jako zależność i zainstaluje go w pierwszej kolejności.[21] Jeśli żaden Operator nie dostarcza wymaganego API, instalacja Operatora A nie powiedzie się, chroniąc klaster przed stanem niekompletnej lub niefunkcjonalnej instalacji.[21]

OLM podchodzi do tego zadania z naciskiem na stabilność klastra, podobnie jak menedżery pakietów $yum$ czy $apt$.[20] Gwarantuje, że nigdy:

1.  Nie zainstaluje zestawu Operatorów, które wymagają API, które nie mogą być dostarczone.
2.  Nie zaktualizuje Operatora A w sposób, który zepsuje Operatora B, który od niego zależy.[16, 20, 21]

Aktualizacje są zarządzane poprzez "kanały" (channels) zdefiniowane w $Subscription$.[28, 30] Kanały (np. $stable$, $beta$, $fast$) pozwalają autorom Operatorów na bezpieczne kontrolowanie ścieżki aktualizacji. Kiedy w śledzonym kanale pojawi się nowa wersja CSV, $Catalog Operator$ wykrywa ją i automatycznie generuje nowy $InstallPlan$ w celu przeprowadzenia aktualizacji.[25]

Prawdziwą siłą OLM jest $ClusterServiceVersion$ (CSV). Działa on jak hermetyczny kontener na wszystko, co definiuje Operatora, włączając w to jego kompletny "ślad bezpieczeństwa".[22] Operator nie instaluje sobie uprawnień sam; on *deklaruje* swoje potrzeby RBAC w manifeście CSV. To $OLM Operator$ odczytuje tę deklarację i jest odpowiedzialny za *wygenerowanie* (lub weryfikację) tych $Roles$ i $RoleBindings$ podczas instalacji. Daje to administratorowi klastra pełną przejrzystość – $InstallPlan$ [29] pokaże mu dokładnie, jakie uprawnienia (np. $ClusterRole$ dający dostęp do wszystkich $Secrets$ w klastrze) zamierza przyznać, *zanim* Operator zostanie zainstalowany. CSV jest więc nie tylko manifestem technicznym, ale fundamentalnym "kontraktem bezpieczeństwa" między autorem Operatora a administratorem klastra.

### Tabela 1: Kluczowe Komponenty (CRD) Operator Lifecycle Manager (OLM)

Poniższa tabela syntetyzuje kluczowe zasoby (CRD) wprowadzone przez OLM, które tworzą jego architekturę. Zrozumienie tych "słów kluczowych" jest niezbędne do pracy z ekosystemem Operatorów na platformach takich jak OpenShift.

| Zasób (Kind) | Skrót | Opis [18, 24, 26] |
| :--- | :--- | :--- |
| $CatalogSource$ | $catsrc$ | Repozytorium (katalog) definicji Operatorów (CSV, CRD, pakiety). Definiuje *skąd* można instalować Operatory. |
| $Subscription$ | $sub$ | Deklaracja intencji instalacji Operatora; śledzi "kanał" (channel) w celu zarządzania aktualizacjami. |
| $ClusterServiceVersion$ | $csv$ | Manifest Operatora; zawiera metadane (opis, ikona), wymagania RBAC, posiadane CRD i strategię instalacji ($Deployment$). |
| $InstallPlan$ | $ip$ | Obliczona lista zasobów do utworzenia/aktualizacji w celu zainstalowania lub uaktualnienia danego CSV. Generowany przez $Catalog Operator$. |
| $OperatorGroup$ | $og$ | Konfiguruje zasięg (np. które przestrzenie nazw) Operatorów zainstalowanych w tej samej przestrzeni nazw. Kluczowy dla RBAC. |

## Lekcja 11.3: OperatorHub – Instalacja i Zarządzanie Oprogramowaniem

### 11.3.1. OperatorHub: Interfejs Użytkownika dla OLM

OperatorHub to graficzny interfejs użytkownika (GUI) zintegrowany z konsolą webową OpenShift Container Platform (OCP). Służy on jako "witryna sklepowa" lub "centrum odkrywania" dla wszystkich Operatorów, którymi zarządza OLM.[31, 32, 33, 34]

Podczas gdy OLM jest potężnym silnikiem "pod maską", OperatorHub dostarcza przyjazną dla użytkownika warstwę abstrakcji, która pozwala administratorom i deweloperom na łatwe przeglądanie, wybieranie i instalowanie Operatorów. Architektonicznie, interfejs OperatorHub jest napędzany przez dedykowany $Marketplace Operator$, który zazwyczaj działa w przestrzeni nazw $openshift-marketplace$.[31, 32]

OperatorHub agreguje wszystkie Operatory (CSV) udostępniane przez różne $CatalogSource$ skonfigurowane w klastrze.[33, 35] Następnie kategoryzuje je, aby ułatwić administratorom wybór odpowiedniego oprogramowania [32, 36]:

  * **$Certified Operators$:** Oprogramowanie od zweryfikowanych partnerów Red Hat (ISV). Te Operatory są przetestowane, zoptymalizowane pod kątem OpenShift i objęte komercyjnym wsparciem.
  * **$Community Operators$:** Projekty open-source dostarczane przez społeczność. Nie są one objęte formalnym wsparciem Red Hat.
  * **$Custom Operators$:** Operatory dodane przez administratorów klastra, często pochodzące z wewnętrznych, firmowych repozytoriów, niedostępne publicznie.

Głównym celem OperatorHub jest umożliwienie administratorom "jednym kliknięciem" zainstalowania i zasubskrybowania Operatora. To z kolei udostępnia nowe możliwości (np. bazy danych, systemy monitoringu) zespołom deweloperskim w modelu "self-service".[22, 31, 32]

### 11.3.2. Studium Przypadku 1: Instalacja Operatora PostgreSQL

Proces instalacji Operatora za pomocą OperatorHub jest ustandaryzowany i intuicyjny:

1.  **Odkrywanie:** Administrator klastra loguje się do konsoli OCP, przechodzi do sekcji $Operators$ i wybiera $OperatorHub$.[37, 38]
2.  **Wyszukiwanie:** Używając paska wyszukiwania, filtruje listę, wpisując "PostgreSQL".[37] Pojawia się kilka opcji, na przykład $Crunchy PostgreSQL for OpenShift$ lub $PostgreSQL Operator by Dev4Ddevs.com$.[37, 38]
3.  **Instalacja (Subskrypcja):** Administrator wybiera Operatora i klika przycisk "Install".[38, 39]
4.  **Konfiguracja Subskrypcji:** Ten krok jest kluczowy. Administrator musi skonfigurować, *jak* OLM ma zainstalować Operatora. UI prosi o [37, 38, 40]:
      * **$Installation Mode$:** Zasięg działania Operatora (np. $AllNamespaces$ lub $SingleNamespace$) – temat ten zostanie szczegółowo omówiony w Lekcji 11.4.
      * **$Namespace$:** Przestrzeń nazw, w której fizycznie zostanie uruchomiony $Deployment$ Operatora (oraz, w zależności od trybu, którą będzie obserwował).
      * **$Update Channel$:** Wybór kanału aktualizacji (np. $stable$, $beta$), który OLM ma śledzić.[40]
      * **$Approval Strategy$:** Wybór, czy aktualizacje (nowe $InstallPlan$) mają być zatwierdzane $Automatic$ (automatycznie) czy $Manual$ (ręcznie przez admina).
5.  **Akceptacja:** Administrator klika "Install" (lub "Subscribe").
6.  **Weryfikacja:** Po chwili administrator może przejść do sekcji $Operators \rightarrow Installed Operators$, gdzie zobaczy nowy Operator ze statusem $Succeeded$.[38]

W tle, to kliknięcie w UI spowodowało jedynie utworzenie obiektu CR $kind: Subscription$. Całą resztę (rozwiązanie zależności, wygenerowanie $InstallPlan$, instalację $CSV$ i utworzenie zasobów) wykonały automatycznie kontrolery OLM ($Catalog Operator$ i $OLM Operator$).[23, 25]

### 11.3.3. Magia Abstrakcji: Tworzenie Bazy Danych za Pomocą Obiektu K8s

Instalacja Operatora to dopiero początek. Prawdziwa wartość ujawnia się teraz, gdy deweloperzy chcą skorzystać z oprogramowania, którym Operator zarządza.

**Problem "Przed Operatorem":** Jak pokazuje analiza ręcznych wdrożeń, deweloper próbujący uruchomić Postgres w Kubernetes musiałby ręcznie zarządzać wieloma prymitywami: $ConfigMap$ i $Secret$ na dane konfiguracyjne i hasła, $Service$ do komunikacji sieciowej, $PersistentVolume$ (PV) i $PersistentVolumeClaim$ (PVC) do trwałego przechowywania danych, a być może także $HorizontalPodAutoscaler$ (HPA) do skalowania.[41] Jest to proces skomplikowany, podatny na błędy i wymagający od dewelopera głębokiej wiedzy na temat wewnętrznych mechanizmów Kubernetes.[41, 42]

**Rozwiązanie "Po Operatorze":** Dzięki Operatorowi, deweloper nie musi już rozumieć tych wszystkich niskopoziomowych koncepcji.[7] Zamiast tego, po prostu tworzy jeden, wysokopoziomowy zasób (CR) zdefiniowany przez Operatora.

Na przykład, aby utworzyć w pełni funkcjonalny, replikowany klaster PostgreSQL zarządzany przez Operatora CrunchyData, deweloper tworzy następujący plik YAML [43]:

```yaml
apiVersion: postgres-operator.crunchydata.com/v1beta1
kind: PostgresCluster
metadata:
  name: hippo
  namespace: my-app-project
spec:
  postgresVersion: 17
  instances:
  - name: instance1
    replicas: 2
    dataVolumeClaimSpec:
      accessModes:
      resources:
        requests:
          storage: 1Gi
  backups:
    pgbackrest:
      repos:
      - name: repo1
        volume:
          volumeClaimSpec:
            accessModes:
            resources:
              requests:
                storage: 1Gi
```

Gdy deweloper wykona polecenie $oc apply -f hippo.yaml$, dzieje się "magia":

1.  Kontroler Operatora PostgreSQL (zainstalowany w kroku 11.3.2) natychmiast wykrywa nowy obiekt $PostgresCluster$.
2.  Odczytuje jego $spec$ i rozpoczyna pętlę uzgadniania (Lekcja 11.1).
3.  Na podstawie tej prostej deklaracji, kontroler *automatycznie* tworzy i konfiguruje *wszystkie* potrzebne zasoby podrzędne: $StatefulSet$ dla replik bazy danych, $Service$ dla discovery, $Secret$ dla haseł użytkowników, $ConfigMap$ dla konfiguracji $postgresql.conf$, $PersistentVolumeClaims$ dla danych, a nawet konfiguruje $pgbackrest$ do backupów i $PodDisruptionBudget$ do bezpiecznych aktualizacji.[44, 45, 46]

Operator *tłumaczy* wysokopoziomową dyrektywę na niskopoziomowe działania.[1] To jest właśnie inwersja modelu zarządzania: użytkownik przestaje zarządzać infrastrukturą (Podami, PVC), a zaczyna zarządzać *usługą* (bazą danych) poprzez jej dedykowane, wysokopoziomowe API (CRD).[7]

### 11.3.4. Studium Przypadku 2: Instalacja i Użycie Operatora Redis

Ten sam wzorzec dotyczy każdego oprogramowania zarządzanego przez Operatora.

**1. Instalacja:** Proces jest identyczny jak dla PostgreSQL. Administrator przechodzi do $OperatorHub$, wyszukuje "Redis", wybiera (np. $Redis Enterprise Operator$ firmy Redis), i instaluje, wybierając namespace, kanał (np. $6.2$) i strategię zatwierdzania.[40, 47]

**2. Tworzenie instancji:** Deweloper, zamiast ręcznie tworzyć $StatefulSet$ dla Redis [48], tworzy prosty plik CRD, np. $my-rec.yaml$ [49]:

```yaml
apiVersion: "app.redislabs.com/v1"
kind: "RedisEnterpriseCluster"
metadata:
  name: my-rec
  namespace: my-app-project
spec:
  nodes: 3
```

**3. Działanie "pod maską":** Kontroler Operatora $RedisEnterpriseCluster$ reaguje na ten CR i tworzy wszystkie wymagane zasoby: $StatefulSet$ dla węzłów Redis Enterprise, $Secret$ dla poświadczeń i licencji, wiele obiektów $Service$ (dla UI, REST API, Sentinela) oraz $Pod Disruption Budget$.[49, 50]

Co więcej, Operatory mogą oferować różne "smaki" usług poprzez udostępnianie wielu CRD. Na przykład, jeden Operator Redis może udostępniać $kind: RedisCluster$ (dla klastra), $kind: RedisReplication$ (dla replikacji master-slave) oraz $kind: Redis$ (dla instancji standalone), dając użytkownikowi elastyczność wyboru odpowiedniej topologii.[51]

Ten model jest niezwykle potężny, ponieważ umożliwia prawdziwy "self-service" dla deweloperów.[18, 22] Administratorzy dbają o dostępność Operatorów (usług) w $OperatorHub$, a deweloperzy mogą samodzielnie i bezpiecznie provisionować potrzebne im zasoby (jak bazy danych), po prostu tworząc obiekty w API Kubernetes, bez potrzeby głębokiej wiedzy o implementacji tych usług.[7]

## Lekcja 11.4: Zarządzanie Aplikacjami w Wielu Namespace'ach (RBAC i Operatory)

### 11.4.1. Definicja Zasięgu: OperatorGroups

Jednym z najważniejszych i najbardziej złożonych aspektów zarządzania Operatorami jest określenie ich *zasięgu* (scope). Pojawia się fundamentalne pytanie: Gdzie Operator (jego kontroler) powinien szukać zasobów CR, którymi ma zarządzać? Czy powinien widzieć tylko CR-y w swojej własnej przestrzeni nazw? W kilku wybranych? Czy we wszystkich przestrzeniach nazw w całym klastrze?

Odpowiedź na to pytanie ma ogromne implikacje dla bezpieczeństwa (RBAC), izolacji (multi-tenancy) i zużycia zasobów.

Rozwiązaniem, które OLM wprowadza do zarządzania tym problemem, jest $OperatorGroup$ (OG).[52] $OperatorGroup$ to zasób OLM, który definiuje konfigurację i zasięg dla *wszystkich* Operatorów (CSV), które są zainstalowane w *tej samej* przestrzeni nazw co $OperatorGroup$.[23, 53]

Kluczową i rygorystyczną zasadą OLM jest: **Może istnieć tylko jedna $OperatorGroup$ na przestrzeń nazw**.[54, 55] Jeśli administrator spróbuje utworzyć drugą $OperatorGroup$ w namespace, który już ją posiada, OLM zgłosi błąd $TooManyOperatorGroups$ i nie zainstaluje żadnych nowych CSV w tej przestrzeni nazw.[55]

Mechanizm działania $OperatorGroup$ polega na zdefiniowaniu zestawu docelowych przestrzeni nazw, które Operatory "członkowskie" będą obserwować. Odbywa się to poprzez pole $spec.targetNamespaces$ lub, w nowszych wersjach, poprzez adnotację $olm.targetNamespaces$ w obiekcie $OperatorGroup$.[52, 53, 56]

Aby instalacja się powiodła, konfiguracja $OperatorGroup$ musi być kompatybilna z trybami instalacji ($InstallMode$) wspieranymi przez Operatora (zadeklarowanymi w jego $CSV$).[55, 57, 58] CSV Operatora deklaruje, jakie tryby *wspiera* (np. $AllNamespaces: true$, $SingleNamespace: true$, $OwnNamespace: true$), a $OperatorGroup$ *wybiera* jeden z tych wspieranych trybów dla danej przestrzeni nazw.[53, 59]

### 11.4.2. Analiza Trybów Instalacji: SingleNamespace vs. AllNamespaces

Wybór trybu instalacji jest fundamentalną decyzją architektoniczną.

**Tryb $SingleNamespace$ (lub $OwnNamespace$)** [53, 59, 60]

  * **Opis:** Operator jest instalowany w przestrzeni nazw $my-project$ i ma uprawnienia do obserwowania zasobów (CR) *tylko i wyłącznie* w tej samej przestrzeni nazw $my-project$ ($OwnNamespace$) lub w innej, specyficznej przestrzeni nazw ($SingleNamespace$).
  * **Konfiguracja:** Administrator tworzy (lub OCP tworzy automatycznie) $OperatorGroup$ w $my-project$, której zasięg jest ustawiony tylko na $my-project$. Następnie tworzy $Subscription$ w $my-project$.[54, 58, 60]
  * **Zalety:**
      * **Bezpieczeństwo:** Jest to zgodne z zasadą najmniejszych uprawnień (Principle of Least Privilege - PoLP).[61]
      * **Izolacja:** Błąd lub kompromitacja Operatora ma wpływ tylko na jedną przestrzeń nazw.[62]
      * **Delegowanie:** Umożliwia administratorom poszczególnych projektów (którzy nie są adminami klastra) na samodzielne instalowanie Operatorów o zasięgu ograniczonym do ich projektu.[63]
  * **Wady:**
      * **Zużycie zasobów:** Jeśli 20 zespołów potrzebuje Operatora PostgreSQL, skutkuje to uruchomieniem 20 oddzielnych instancji (Podów) kontrolera Operatora, z których każda zużywa CPU i pamięć.

**Tryb $AllNamespaces$** [53, 59, 60]

  * **Opis:** Operator jest instalowany *tylko raz* w centralnej, dedykowanej przestrzeni nazw (domyślnie w OpenShift jest to $openshift-operators$).[54, 60, 64] Ta jedna instancja Operatora ma uprawnienia do obserwowania i zarządzania zasobami CR we *wszystkich* przestrzeniach nazw w całym klastrze.[53]
  * **Konfiguracja:** W $openshift-operators$ domyślnie istnieje $OperatorGroup$ skonfigurowana do obserwowania wszystkich przestrzeni nazw (zasięg globalny).[57, 65] Administrator po prostu tworzy $Subscription$ w przestrzeni $openshift-operators$.
  * **Zalety:**
      * **Efektywność zasobów:** Tylko jedna instancja Operatora (jeden $Deployment$) zarządza całym klastrem. Jest to idealne dla usług współdzielonych, takich jak monitoring (np. Operator Prometheus) czy Service Mesh (np. Operator Istio).[62]
  * **Wady:**
      * **Bezpieczeństwo:** Operator ten musi otrzymać bardzo szerokie, globalne uprawnienia (zazwyczaj $ClusterRole$), co stwarza poważne ryzyko.[61, 62] Błąd w tym Operatorze (lub jego kompromitacja) może zdestabilizować lub naruszyć bezpieczeństwo *całego* klastra.
      * **Wydajność na dużą skalę:** Na bardzo dużych klastrach (tysiące przestrzeni nazw) OLM domyślnie tworzy kopie CSV w każdym namespace, co może prowadzić do problemów z wydajnością $etcd$ i zużyciem pamięci przez OLM, chociaż można to zachowanie wyłączyć.[66]

### 11.4.3. Konfiguracja RBAC: Jak OLM Zarządza Uprawnieniami

OLM nie tylko instaluje Operatora; aktywnie zarządza również jego uprawnieniami RBAC.[29, 52, 53] Jak wspomniano, uprawnienia są *deklarowane* przez autora Operatora w manifeście $CSV$.[22] OLM odczytuje tę deklarację i *generuje* odpowiednie zasoby RBAC w oparciu o $InstallMode$ i zasięg $OperatorGroup$.

**RBAC w trybie $SingleNamespace$ / $OwnNamespace$:**

1.  OLM odczytuje deklaracje uprawnień z $CSV$.
2.  Tworzy $ServiceAccount$ dla Operatora w jego przestrzeni nazw (np. $my-project$).
3.  Zamiast tworzyć potężny $ClusterRole$, OLM tworzy $Role$ (które z definicji jest ograniczone do przestrzeni nazw) oraz $RoleBinding$ w $my-project$.[62, 67]
4.  Uprawnienia Operatora są ściśle ograniczone *tylko* do zasobów wewnątrz $my-project$. Nie widzi on niczego poza swoim "pudełkiem".

**RBAC w trybie $AllNamespaces$:**

1.  OLM odczytuje deklaracje uprawnień z $CSV$.
2.  Tworzy $ServiceAccount$ dla Operatora w $openshift-operators$.
3.  Ponieważ Operator musi mieć uprawnienia do odczytu/zapisu zasobów (np. tworzenia $Pods$ lub $Secrets$) we *wszystkich* przestrzeniach nazw, OLM *musi* utworzyć $ClusterRole$.[62, 66, 68, 69]
4.  Następnie OLM tworzy $ClusterRoleBinding$, wiążąc ten globalny $ClusterRole$ z $ServiceAccount$ Operatora.
5.  Daje to Operatorowi potężne, globalne uprawnienia, co jest zarówno konieczne do jego funkcjonowania, jak i stanowi potencjalne ryzyko bezpieczeństwa.[62, 66]

Zasób $OperatorGroup$ jest zatem kluczowym mechanizmem kontrolnym, który pozwala administratorowi klastra wymusić politykę bezpieczeństwa i multi-tenancy.[53] Działa on jak *filtr* lub *maska* na uprawnienia. Operator może *prosić* o $ClusterRole$ w swoim $CSV$ [22], ale jeśli administrator zdecyduje się zainstalować go w trybie $SingleNamespace$ (poprzez odpowiednio skonfigurowaną $OperatorGroup$), OLM zignoruje prośbę o $ClusterRole$ i wygeneruje *jedynie* lokalny $Role$.[62, 67] W ten sposób $OperatorGroup$ wymusza politykę bezpieczeństwa "z góry", ograniczając zasięg Operatora do wyznaczonego mu lokum.

Rygorystyczna zasada "tylko jedna $OperatorGroup$ na namespace" [54, 55] ma głębokie konsekwencje architektoniczne. Skutecznie "typuje" ona każdą przestrzeń nazw, zmuszając administratorów do świadomego decydowania o jej przeznaczeniu. Nie można mieszać i dopasowywać zasięgów w ramach jednej przestrzeni nazw (np. instalować tam Operatora A w trybie $AllNamespaces$ i Operatora B w trybie $OwnNamespace$). Wymusza to czystą architekturę:

1.  Centralne przestrzenie nazw (jak $openshift-operators$) są przeznaczone *tylko* dla Operatorów $AllNamespaces$ i mają jedną, globalną $OperatorGroup$.[60]
2.  Przestrzenie nazw aplikacji (jak $my-app-prod$) są przeznaczone *tylko* dla Operatorów $OwnNamespace$/$SingleNamespace$ i każda z nich ma swoją własną, lokalną $OperatorGroup$.[54]
    Ta sztywna zasada upraszcza model uprawnień OLM i czyni architekturę multi-tenancy przewidywalną.[29]

### Tabela 2: Porównanie Trybów Instalacji Operatora (Install Modes)

Poniższa tabela syntetyzuje kluczowe różnice, zalety i wady głównych trybów instalacji Operatora, stanowiąc narzędzie decyzyjne dla administratorów platformy.

| Cecha | Tryb $AllNamespaces$ | Tryb $SingleNamespace$ | Tryb $OwnNamespace$ |
| :--- | :--- | :--- | :--- |
| **Opis [59]** | Operator obserwuje *wszystkie* przestrzenie nazw. | Operator obserwuje *jedną, inną* przestrzeń nazw. | Operator obserwuje *tę samą* przestrzeń nazw, w której jest zainstalowany. |
| **Domyślna Przestrzeń Instalacji [60]** | $openshift-operators$ | $[nazwa_projektu_docelowego]$ | $[nazwa_projektu_aplikacji]$ |
| **Zasięg Obserwacji CR** | Cały klaster | Tylko przestrzeń docelowa | Tylko przestrzeń własna |
| **Wygenerowany RBAC [67, 69]** | $ClusterRole$ + $ClusterRoleBinding$ | $Role$ + $RoleBinding$ (w przestrzeni docelowej) | $Role$ + $RoleBinding$ (w przestrzeni własnej) |
| **Model Użycia** | Usługi współdzielone, monitoring, service mesh (np. Prometheus) [62] | Aplikacje dedykowane dla projektu, bazy danych [63] | Najczęstszy tryb "per-projekt" (jak $SingleNamespace$) |
| **Zaleta** | Efektywność zasobów (1 instancja Operatora) | Silna izolacja, bezpieczeństwo (PoLP) [61] | Silna izolacja, bezpieczeństwo (PoLP) [61] |
| **Wada** | Szerokie, globalne uprawnienia (ryzyko bezpieczeństwa) [62] | Wiele instancji Operatora (zużycie zasobów) | Wiele instancji Operatora (zużycie zasobów) |

## Wnioski: Synteza Ekosystemu Operatorów

Moduł 11 przedstawia kompletną ewolucję w zarządzaniu aplikacjami na platformie Kubernetes, przechodząc od podstawowych koncepcji do zaawansowanych architektur bezpieczeństwa.

**Lekcja 11.1** ustanowiła fundamentalny paradygmat: Wzorzec Operatora ($CRD$ + $Kontroler$) jako metodę kodowania wiedzy ludzkiego operatora w oprogramowaniu. To przejście od zarządzania imperatywnego do deklaratywnego, gdzie $CRD$ staje się wysokopoziomowym API dla złożonej usługi, a $Kontroler$ działa jako nieustanna pętla uzgadniania, zapewniająca samonaprawianie.

**Lekcja 11.2** odpowiedziała na pytanie "kto zarządza menedżerami", wprowadzając Operator Lifecycle Manager (OLM). OLM jest Meta-Operatorem, który używa własnych CRD (takich jak $Subscription$, $CSV$, $InstallPlan$), aby zautomatyzować cykl życia samych Operatorów. Jego kluczowe funkcje – zarządzanie zależnościami i bezpieczne aktualizacje poprzez kanały – czynią go odpowiednikiem systemowego menedżera pakietów dla Kubernetes.

**Lekcja 11.3** przeniosła teorię do praktyki, demonstrując $OperatorHub$ jako przyjazny dla użytkownika "App Store" dla OLM. Kluczową demonstracją była radykalna zmiana w provisioningu oprogramowania: zamiast skomplikowanej, ręcznej konfiguracji wielu zasobów (Poda, Service, PVC), deweloper po prostu tworzy jeden, wysokopoziomowy obiekt (np. $kind: PostgresCluster$). Operator (zainstalowany przez OLM z $OperatorHub$) zajmuje się resztą, tłumacząc tę prostą intencję na złożoną architekturę niskopoziomową.

**Lekcja 11.4** poruszyła krytyczne aspekty bezpieczeństwa i multi-tenancy. Wybór między trybami $AllNamespaces$ i $SingleNamespace$ jest fundamentalną decyzją architektoniczną, balansującą między efektywnością zasobów a izolacją i bezpieczeństwem. Zasób $OperatorGroup$ został zidentyfikowany jako kluczowy mechanizm kontrolny OLM, który nie tylko definiuje zasięg, ale także aktywnie *generuje* i *ogranicza* uprawnienia RBAC Operatora, wymuszając politykę bezpieczeństwa administratora klastra.

Podsumowując, ekosystem Operatorów (OLM) to dojrzałe i kompleksowe rozwiązanie, które przekształca Kubernetes z platformy do uruchamiania kontenerów w prawdziwą platformę do zarządzania złożonymi usługami w modelu "as-a-service".
#### **Cytowane prace**

1. What is a Kubernetes operator? \- Red Hat, otwierano: listopada 15, 2025, [https://www.redhat.com/en/topics/containers/what-is-a-kubernetes-operator](https://www.redhat.com/en/topics/containers/what-is-a-kubernetes-operator)  
2. Exploring Kubernetes Operator Pattern, otwierano: listopada 15, 2025, [https://iximiuz.com/en/posts/kubernetes-operator-pattern/](https://iximiuz.com/en/posts/kubernetes-operator-pattern/)  
3. Operator pattern \- Kubernetes, otwierano: listopada 15, 2025, [https://kubernetes.io/docs/concepts/extend-kubernetes/operator/](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/)  
4. Kubernetes Operators: what are they? Some examples | CNCF, otwierano: listopada 15, 2025, [https://www.cncf.io/blog/2022/06/15/kubernetes-operators-what-are-they-some-examples/](https://www.cncf.io/blog/2022/06/15/kubernetes-operators-what-are-they-some-examples/)  
5. Custom Resources \- Kubernetes, otwierano: listopada 15, 2025, [https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)  
6. WHAT IS THE KUBERNETES OPERATOR PATTERN? \- BMC Blogs, otwierano: listopada 15, 2025, [https://blogs.bmc.com/kubernetes-operator/?print-posts=pdf](https://blogs.bmc.com/kubernetes-operator/?print-posts=pdf)  
7. Extending Kubernetes with Custom Resource Definitions (CRDs) \- vCluster, otwierano: listopada 15, 2025, [https://www.vcluster.com/blog/extending-kubernetes-with-custom-resource-definitions-crds](https://www.vcluster.com/blog/extending-kubernetes-with-custom-resource-definitions-crds)  
8. Versions in CustomResourceDefinitions \- Kubernetes, otwierano: listopada 15, 2025, [https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definition-versioning/](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definition-versioning/)  
9. Extend the Kubernetes API with CustomResourceDefinitions, otwierano: listopada 15, 2025, [https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/)  
10. Good Practices \- The Kubebuilder Book, otwierano: listopada 15, 2025, [https://book.kubebuilder.io/reference/good-practices](https://book.kubebuilder.io/reference/good-practices)  
11. Kubernetes Controllers 101 — Watch, Reconcile, Repeat | by Dhruv Behl | Medium, otwierano: listopada 15, 2025, [https://medium.com/@dhruvbhl/kubernetes-controllers-101-watch-reconcile-repeat-8d93398e19bd](https://medium.com/@dhruvbhl/kubernetes-controllers-101-watch-reconcile-repeat-8d93398e19bd)  
12. Kubernetes Reconciliation loop \- Medium, otwierano: listopada 15, 2025, [https://medium.com/@inchararlingappa/kubernetes-reconciliation-loop-74d3f38e382f](https://medium.com/@inchararlingappa/kubernetes-reconciliation-loop-74d3f38e382f)  
13. Controllers \- Kubernetes, otwierano: listopada 15, 2025, [https://kubernetes.io/docs/concepts/architecture/controller/](https://kubernetes.io/docs/concepts/architecture/controller/)  
14. Controllers VS Operators : r/kubernetes \- Reddit, otwierano: listopada 15, 2025, [https://www.reddit.com/r/kubernetes/comments/1fotaun/controllers\_vs\_operators/](https://www.reddit.com/r/kubernetes/comments/1fotaun/controllers_vs_operators/)  
15. Introduction to the Operator Lifecycle Manager Module \- Oracle Help Center, otwierano: listopada 15, 2025, [https://docs.oracle.com/en/operating-systems/olcne/1.8/olm/intro.html](https://docs.oracle.com/en/operating-systems/olcne/1.8/olm/intro.html)  
16. Operator Lifecycle Manager (OLM) \- Operator framework, otwierano: listopada 15, 2025, [https://olm.operatorframework.io/](https://olm.operatorframework.io/)  
17. otwierano: listopada 15, 2025, [https://docs.oracle.com/en/operating-systems/olcne/1.8/olm/intro.html\#:\~:text=The%20Operator%20Lifecycle%20Manager%20module%20installs%20an%20instance%20of%20Operator,that%20interacts%20with%20operator%20registries.](https://docs.oracle.com/en/operating-systems/olcne/1.8/olm/intro.html#:~:text=The%20Operator%20Lifecycle%20Manager%20module%20installs%20an%20instance%20of%20Operator,that%20interacts%20with%20operator%20registries.)  
18. Operator Lifecycle Manager concepts and resources \- OKD Documentation, otwierano: listopada 15, 2025, [https://docs.okd.io/4.13/operators/understanding/olm/olm-understanding-olm.html](https://docs.okd.io/4.13/operators/understanding/olm/olm-understanding-olm.html)  
19. OpenShift Commons Briefing: Operator Lifecycle Management with Evan Cordell (Red Hat), otwierano: listopada 15, 2025, [https://www.youtube.com/watch?v=rlXJDrNJVpQ](https://www.youtube.com/watch?v=rlXJDrNJVpQ)  
20. Operator Lifecycle Manager dependency resolution \- OKD Documentation, otwierano: listopada 15, 2025, [https://docs.okd.io/latest/operators/understanding/olm/olm-understanding-dependency-resolution.html](https://docs.okd.io/latest/operators/understanding/olm/olm-understanding-dependency-resolution.html)  
21. Operator Dependency and Requirement Resolution | olm-book \- GitHub Pages, otwierano: listopada 15, 2025, [https://operator-framework.github.io/olm-book/docs/operator-dependencies-and-requirements.html](https://operator-framework.github.io/olm-book/docs/operator-dependencies-and-requirements.html)  
22. Chapter 2\. Understanding the Operator Lifecycle Manager (OLM) \- Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.2/html/operators/understanding-the-operator-lifecycle-manager-olm](https://docs.redhat.com/en/documentation/openshift_container_platform/4.2/html/operators/understanding-the-operator-lifecycle-manager-olm)  
23. Understanding OpenShift's Operator Lifecycle Manager (OLM) \- IBM TechXchange Community, otwierano: listopada 15, 2025, [https://community.ibm.com/community/user/blogs/manogya-sharma/2025/07/04/understanding-openshifts-operator-lifecycle-manage](https://community.ibm.com/community/user/blogs/manogya-sharma/2025/07/04/understanding-openshifts-operator-lifecycle-manage)  
24. OLM Architecture \- Operator Lifecycle Manager, otwierano: listopada 15, 2025, [https://olm.operatorframework.io/docs/concepts/olm-architecture/](https://olm.operatorframework.io/docs/concepts/olm-architecture/)  
25. How does Operator Life Cycle Manager work in Kubernetes? \- Reddit, otwierano: listopada 15, 2025, [https://www.reddit.com/r/kubernetes/comments/173ykr1/how\_does\_operator\_life\_cycle\_manager\_work\_in/](https://www.reddit.com/r/kubernetes/comments/173ykr1/how_does_operator_life_cycle_manager_work_in/)  
26. Operator Lifecycle Manager concepts and resources \- OKD Documentation, otwierano: listopada 15, 2025, [https://docs.okd.io/4.18/operators/understanding/olm/olm-understanding-olm.html](https://docs.okd.io/4.18/operators/understanding/olm/olm-understanding-olm.html)  
27. Chapter 2\. Understanding Operators | Operators | OpenShift Container Platform | 4.18 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.18/html/operators/understanding-operators](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/operators/understanding-operators)  
28. Subscription | Operator Lifecycle Manager, otwierano: listopada 15, 2025, [https://olm.operatorframework.io/docs/troubleshooting/subscription/](https://olm.operatorframework.io/docs/troubleshooting/subscription/)  
29. Chapter 2\. Understanding Operators | Operators | OpenShift Container Platform | 4.8 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/operators/understanding-operators](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/operators/understanding-operators)  
30. Dependency Resolution | Operator Lifecycle Manager, otwierano: listopada 15, 2025, [https://olm.operatorframework.io/docs/concepts/olm-architecture/dependency-resolution/](https://olm.operatorframework.io/docs/concepts/olm-architecture/dependency-resolution/)  
31. OperatorHub \- Understanding Operators \- OKD Documentation, otwierano: listopada 15, 2025, [https://docs.okd.io/4.13/operators/understanding/olm-understanding-operatorhub.html](https://docs.okd.io/4.13/operators/understanding/olm-understanding-operatorhub.html)  
32. Chapter 3\. Understanding the OperatorHub | Operators | OpenShift Container Platform | 4.4, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.4/html/operators/olm-understanding-operatorhub](https://docs.redhat.com/en/documentation/openshift_container_platform/4.4/html/operators/olm-understanding-operatorhub)  
33. OpenShift Operators: Tutorial & Instructions \- Densify, otwierano: listopada 15, 2025, [https://www.densify.com/openshift-tutorial/openshift-operators/](https://www.densify.com/openshift-tutorial/openshift-operators/)  
34. Chapter 1\. Operators overview | Operators | OpenShift Container Platform | 4.10 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.10/html/operators/operators-overview](https://docs.redhat.com/en/documentation/openshift_container_platform/4.10/html/operators/operators-overview)  
35. OperatorHub \- Understanding Operators | Operators | OKD 4.18 \- OKD Documentation, otwierano: listopada 15, 2025, [https://docs.okd.io/4.18/operators/understanding/olm-understanding-operatorhub.html](https://docs.okd.io/4.18/operators/understanding/olm-understanding-operatorhub.html)  
36. Chapter 3\. Understanding the OperatorHub | Operators | OpenShift Container Platform | 4.2, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.2/html/operators/olm-understanding-operatorhub](https://docs.redhat.com/en/documentation/openshift_container_platform/4.2/html/operators/olm-understanding-operatorhub)  
37. Chapter 4\. Deploying Service Registry storage in a PostgreSQL database \- Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/red\_hat\_integration/2022.q1/html/installing\_and\_deploying\_service\_registry\_on\_openshift/installing-registry-db-storage](https://docs.redhat.com/en/documentation/red_hat_integration/2022.q1/html/installing_and_deploying_service_registry_on_openshift/installing-registry-db-storage)  
38. Fun with OperatorHub \- IBM Developer, otwierano: listopada 15, 2025, [https://developer.ibm.com/tutorials/operator-hub-openshift-4-operators-ibm-cloud/](https://developer.ibm.com/tutorials/operator-hub-openshift-4-operators-ibm-cloud/)  
39. Installation via OperatorHub :: StackGres Documentation, otwierano: listopada 15, 2025, [https://stackgres.io/doc/1.4/install/operatorhub/](https://stackgres.io/doc/1.4/install/operatorhub/)  
40. Deploy Redis Enterprise with OpenShift OperatorHub | Docs, otwierano: listopada 15, 2025, [https://redis.io/docs/latest/operate/kubernetes/deployment/openshift/openshift-operatorhub/](https://redis.io/docs/latest/operate/kubernetes/deployment/openshift/openshift-operatorhub/)  
41. Implementing postgres on a kubernetes cluster for production. Any guides, articles, checklist, etc? \- Reddit, otwierano: listopada 15, 2025, [https://www.reddit.com/r/kubernetes/comments/1201ve3/implementing\_postgres\_on\_a\_kubernetes\_cluster\_for/](https://www.reddit.com/r/kubernetes/comments/1201ve3/implementing_postgres_on_a_kubernetes_cluster_for/)  
42. Postgres in Kubernetes: How to Deploy, Scale, and Manage \- Groundcover, otwierano: listopada 15, 2025, [https://www.groundcover.com/blog/postgres-in-kubernetes-how-to-deploy-scale-and-manage](https://www.groundcover.com/blog/postgres-in-kubernetes-how-to-deploy-scale-and-manage)  
43. Customize a Postgres Cluster \- Crunchy Data Customer Portal, otwierano: listopada 15, 2025, [https://access.crunchydata.com/documentation/postgres-operator/latest/tutorials/day-two/customize-cluster](https://access.crunchydata.com/documentation/postgres-operator/latest/tutorials/day-two/customize-cluster)  
44. Custom Resource options \- Percona Operator for PostgreSQL, otwierano: listopada 15, 2025, [https://docs.percona.com/percona-operator-for-postgresql/2.0/operator.html](https://docs.percona.com/percona-operator-for-postgresql/2.0/operator.html)  
45. Administrator \- Postgres Operator \- Read the Docs, otwierano: listopada 15, 2025, [https://postgres-operator.readthedocs.io/en/latest/administrator/](https://postgres-operator.readthedocs.io/en/latest/administrator/)  
46. Creating a PostgreSQL Cluster with Kubernetes CRDs | Crunchy Data Blog, otwierano: listopada 15, 2025, [https://www.crunchydata.com/blog/creating-a-postgresql-cluster-with-kubernetes-crds](https://www.crunchydata.com/blog/creating-a-postgresql-cluster-with-kubernetes-crds)  
47. Automation Suite \- Deploying Redis through OperatorHub \- UiPath Documentation, otwierano: listopada 15, 2025, [https://docs.uipath.com/automation-suite/automation-suite/2024.10/installation-guide-openshift/deploying-redis-through-operatorhub](https://docs.uipath.com/automation-suite/automation-suite/2024.10/installation-guide-openshift/deploying-redis-through-operatorhub)  
48. Deploying Redis Cluster with StatefulSets \- Kubernetes Tutorial with CKA/CKAD Prep, otwierano: listopada 15, 2025, [https://kubernetes-tutorial.schoolofdevops.com/13\_redis\_statefulset/](https://kubernetes-tutorial.schoolofdevops.com/13_redis_statefulset/)  
49. Deploy Redis Enterprise Software for Kubernetes | Docs, otwierano: listopada 15, 2025, [https://redis.io/docs/latest/operate/kubernetes/deployment/quick-start/](https://redis.io/docs/latest/operate/kubernetes/deployment/quick-start/)  
50. Redis Enterprise for Kubernetes operator-based architecture | Docs, otwierano: listopada 15, 2025, [https://redis.io/docs/latest/operate/kubernetes/7.4.6/architecture/operator/](https://redis.io/docs/latest/operate/kubernetes/7.4.6/architecture/operator/)  
51. Redis Operator \- OperatorHub.io, otwierano: listopada 15, 2025, [https://operatorhub.io/operator/redis-operator](https://operatorhub.io/operator/redis-operator)  
52. Chapter 4\. Administrator tasks | Operators | OpenShift Container Platform | 4.8 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/operators/administrator-tasks](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/operators/administrator-tasks)  
53. Operator scoping with OperatorGroups, otwierano: listopada 15, 2025, [https://olm.operatorframework.io/docs/advanced-tasks/operator-scoping-with-operatorgroups/](https://olm.operatorframework.io/docs/advanced-tasks/operator-scoping-with-operatorgroups/)  
54. Installing Operators in your namespace \- User tasks \- OKD Documentation, otwierano: listopada 15, 2025, [https://docs.okd.io/4.13/operators/user/olm-installing-operators-in-namespace.html](https://docs.okd.io/4.13/operators/user/olm-installing-operators-in-namespace.html)  
55. OperatorGroup | Operator Lifecycle Manager, otwierano: listopada 15, 2025, [https://olm.operatorframework.io/docs/concepts/crds/operatorgroup/](https://olm.operatorframework.io/docs/concepts/crds/operatorgroup/)  
56. Chapter 2\. Understanding Operators | Operators | OpenShift Container Platform | 4.9 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.9/html/operators/understanding-operators](https://docs.redhat.com/en/documentation/openshift_container_platform/4.9/html/operators/understanding-operators)  
57. Chapter 4\. Adding Operators to a cluster | Operators | OpenShift Container Platform | 4.2 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.2/html/operators/olm-adding-operators-to-a-cluster](https://docs.redhat.com/en/documentation/openshift_container_platform/4.2/html/operators/olm-adding-operators-to-a-cluster)  
58. Chapter 4\. Adding Operators to a cluster | Operators | OpenShift Container Platform | 4.3, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.3/html/operators/olm-adding-operators-to-a-cluster](https://docs.redhat.com/en/documentation/openshift_container_platform/4.3/html/operators/olm-adding-operators-to-a-cluster)  
59. Operator groups \- Understanding Operators | Operators | OKD 4 \- OKD Documentation, otwierano: listopada 15, 2025, [https://docs.okd.io/latest/operators/understanding/olm/olm-understanding-operatorgroups.html](https://docs.okd.io/latest/operators/understanding/olm/olm-understanding-operatorgroups.html)  
60. Chapter 3\. User tasks | Operators | OpenShift Container Platform \- Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.11/html/operators/user-tasks](https://docs.redhat.com/en/documentation/openshift_container_platform/4.11/html/operators/user-tasks)  
61. Kubernetes Operators: good security practices \- Red Hat, otwierano: listopada 15, 2025, [https://www.redhat.com/en/blog/kubernetes-operators-good-security-practices](https://www.redhat.com/en/blog/kubernetes-operators-good-security-practices)  
62. With Kubernetes Operators comes great responsibility \- Red Hat, otwierano: listopada 15, 2025, [https://www.redhat.com/en/blog/kubernetes-operators-comes-great-responsibility](https://www.redhat.com/en/blog/kubernetes-operators-comes-great-responsibility)  
63. A non cluster admin role that can deploy operators? : r/openshift \- Reddit, otwierano: listopada 15, 2025, [https://www.reddit.com/r/openshift/comments/me1q81/a\_non\_cluster\_admin\_role\_that\_can\_deploy\_operators/](https://www.reddit.com/r/openshift/comments/me1q81/a_non_cluster_admin_role_that_can_deploy_operators/)  
64. Operators | OpenShift Container Platform | 4.6 \- Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.6/html-single/operators/index](https://docs.redhat.com/en/documentation/openshift_container_platform/4.6/html-single/operators/index)  
65. Installing the IBM MQ Operator using the Red Hat OpenShift CLI, otwierano: listopada 15, 2025, [https://www.ibm.com/docs/en/ibm-mq/9.3.x?topic=imo-installing-mq-operator-using-red-hat-openshift-cli](https://www.ibm.com/docs/en/ibm-mq/9.3.x?topic=imo-installing-mq-operator-using-red-hat-openshift-cli)  
66. Chapter 4\. Administrator tasks | Operators | OpenShift Container Platform | 4.10, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.10/html/operators/administrator-tasks](https://docs.redhat.com/en/documentation/openshift_container_platform/4.10/html/operators/administrator-tasks)  
67. Concepts \- Access and identity in Azure Kubernetes Services (AKS) \- Microsoft Learn, otwierano: listopada 15, 2025, [https://learn.microsoft.com/en-us/azure/aks/concepts-identity](https://learn.microsoft.com/en-us/azure/aks/concepts-identity)  
68. Kubernetes RBAC Authorization: The Ultimate Guide \- Plural, otwierano: listopada 15, 2025, [https://www.plural.sh/blog/kubernetes-rbac-guide/](https://www.plural.sh/blog/kubernetes-rbac-guide/)  
69. Operators Scope, otwierano: listopada 15, 2025, [https://sdk.operatorframework.io/docs/building-operators/golang/operator-scope/](https://sdk.operatorframework.io/docs/building-operators/golang/operator-scope/)
