# Moduł 12. Obserwowalność w OpenShift Container Platform

## Lekcja 12.1: Monitoring (Prometheus & Grafana)

### Architektura Wbudowanego Stosu Monitoringu OCP

Architektura monitoringu w OpenShift Container Platform (OCP) jest w pełni zintegrowanym, zarządzanym operatorem stosem, zaprojektowanym w celu zapewnienia natychmiastowej obserwowalności samej platformy oraz, opcjonalnie, aplikacji użytkownika.

Centralnym komponentem zarządzającym jest **Cluster Monitoring Operator (CMO)**.[1, 2] CMO jest wdrażany przez nadrzędny Cluster Version Operator (CVO), co gwarantuje, że sam system monitoringu jest wersjonowany i zarządzany z taką samą niezawodnością, jak rdzeń klastra.[2] Głównym zadaniem CMO jest wdrażanie, konfigurowanie i automatyczne aktualizowanie wszystkich pozostałych komponentów stosu monitoringu, w tym Prometheus, Grafana i Alertmanager.[1, 2]

Stos ten jest architektonicznie rozwidlony (z ang. *bifurcated*) na dwie odrębne, izolowane od siebie instancje:

1.  **Stos Platformy (Platform Stack):** Wdrażany domyślnie w przestrzeni nazw `openshift-monitoring`. Jest on przeznaczony *wyłącznie* do monitorowania kluczowych komponentów samego klastra OCP.[2, 3] Jest to kluczowa decyzja projektowa mająca na celu izolację i ochronę. Zapobiega to sytuacji, w której nieprawidłowo skonfigurowane zapytanie lub metryka o wysokiej kardynalności z aplikacji użytkownika mogłaby przeciążyć i unieruchomić system monitorowania odpowiedzialny za stabilność platformy.
2.  **Stos Użytkownika (User Workload Stack):** Jest to funkcja *opcjonalna*, którą administrator klastra musi jawnie włączyć.[4] Po aktywacji, CMO wdraża *drugi, równoległy* zestaw komponentów w dedykowanej przestrzeni nazw `openshift-user-workload-monitoring`, przeznaczony do monitorowania projektów i aplikacji użytkownika.[2]

Kluczowe komponenty domyślnego stosu platformy obejmują:

*   **Prometheus Operator:** Wdrożony przez CMO, zarządza cyklem życia instancji Prometheus i Alertmanager dla platformy.[2]
*   **Prometheus:** Dwie domyślne instancje (dla wysokiej dostępności) bazy danych szeregów czasowych, które skrobią metryki komponentów klastra, oceniają reguły i wysyłają alerty.[2]
*   **Alertmanager:** Odbiera alerty z Prometheus, zarządza ich deduplikacją, grupowaniem i routingiem do skonfigurowanych odbiorców.[2, 4]
*   **Grafana:** Platforma do wizualizacji i analizy metryk. Ważne jest, że domyślna instancja Grafany dostarczana ze stosem platformy jest skonfigurowana w trybie *tylko do odczytu (read-only)*.[4]
*   **Thanos Querier:** Komponent zapewniający globalny, zagregowany widok zapytań (PromQL) dla wielu instancji Prometheus, w tym (jeśli jest włączony) stosu użytkownika. Jest to kluczowy punkt dostępu dla zapytań obejmujących cały klaster.[2, 5]
*   **Telemeter Client:** Odpowiedzialny za wysyłanie podzbioru zanonimizowanych metryk kondycji klastra do Red Hat w celu zdalnego monitorowania (Remote Health Monitoring).[2, 4]

Poniższa tabela systematyzuje kluczowe komponenty i ich role w architekturze bifurkacyjnej.

**Tabela 1: Kluczowe Komponenty Stosu Monitoringu OCP (Platforma vs. Użytkownik)**

| Komponent | Przestrzeń Nazw | Kluczowa Rola | Zarządzany przez |
| :--- | :--- | :--- | :--- |
| **Cluster Monitoring Operator (CMO)** | `openshift-monitoring` | Nadrzędny operator; wdraża i zarządza *obydwoma* stosami. | CVO |
| **Prometheus Operator (Platform)** | `openshift-monitoring` | Zarządza instancjami Prometheus i Alertmanager *platformy*. | CMO |
| **Prometheus (Platform)** | `openshift-monitoring` | Baza danych szeregów czasowych; zbiera metryki *rdzenia klastra*. | Prometheus Operator (Platform) |
| **Alertmanager** | `openshift-monitoring` | Zarządza alertami *platformy*. | Prometheus Operator (Platform) |
| **Thanos Querier** | `openshift-monitoring` | Globalny punkt zapytań dla *wszystkich* instancji Prometheus. | CMO |
| **Grafana (Platform)** | `openshift-monitoring` | Wizualizacja metryk *platformy* (tryb Read-Only). | CMO |
| **Prometheus Operator (User)** | `openshift-user-workload-monitoring` | Zarządza instancjami Prometheus i Thanos Ruler *użytkownika*. | CMO (po aktywacji) |
| **Prometheus (User-Workload)** | `openshift-user-workload-monitoring` | Baza danych szeregów czasowych; zbiera metryki *aplikacji użytkownika*. | Prometheus Operator (User) |
| **Thanos Ruler (User-Workload)** | `openshift-user-workload-monitoring` | Ocenia reguły i alerty dla metryk *użytkownika*. | Prometheus Operator (User) |

### Automonitorowanie Platformy: Jak OCP Obserwuje Samego Siebie

Domyślna instancja monitoringu OCP jest skonfigurowana "out-of-the-box" do skrupulatnego obserwowania własnej kondycji. Zakres tego domyślnego monitorowania precyzyjnie definiuje, co Red Hat uważa za "granicę wsparcia" (support boundary) platformy.

Stos platformy automatycznie wykrywa i zbiera metryki z kluczowych komponentów płaszczyzny sterowania (control plane) i krytycznej ścieżki danych (data path).[3] Lista ta obejmuje:

*   `etcd` (rozproszona baza klucz-wartość)
*   `Kubernetes API server`
*   `Kubelets` (agenci na każdym węźle)
*   `Kubernetes controller manager` i `Kubernetes scheduler`
*   `OpenShift API server` i `OpenShift Controller Manager`
*   `CoreDNS`
*   `HAProxy` (dla tras OCP Ingress)
*   `Image registry`
*   `Operator Lifecycle Manager (OLM)`

Co istotne, stos obserwowalności jest "samoświadomy" dzięki monitorowaniu krzyżowemu (cross-pillar monitoring). Stos monitoringu (Prometheus) aktywnie monitoruje również komponenty stosu logowania (Filar 2), takie jak `Fluentd` i `Elasticsearch` (jeśli są zainstalowane).[3] Jest to krytyczna cecha projektowa, która zapobiega "cichej awarii" stosu logowania; jeśli kolektor logów na węźle ulegnie awarii, Prometheus wykryje to i wygeneruje alert.

Domyślnie platforma zawiera również bogaty zestaw predefiniowanych reguł alertowych (Prometheus Rules) specyficznie dla tych komponentów, informując administratorów o potencjalnych problemach, takich jak zapełnianie się wolumenów trwałych (Persistent Volumes) czy problemy z wydajnością `etcd`.[6] Wizualizacje dla tych kluczowych metryk platformy są natychmiast dostępne w konsoli webowej OCP.[7]

### Włączanie Monitoringu dla Własnych Projektów

Domyślnie monitoring aplikacji użytkownika jest wyłączony w celu oszczędzania zasobów i zachowania ścisłej izolacji.[4] Aby umożliwić deweloperom monitorowanie ich własnych usług, administrator klastra (posiadający rolę `cluster-admin`) musi aktywować tę funkcję.[8]

Procedura aktywacji jest operacją deklaratywną, realizowaną poprzez modyfikację `ConfigMap` zarządzającego konfiguracją CMO:

1.  Administrator edytuje obiekt `ConfigMap` o nazwie `cluster-monitoring-config` w przestrzeni nazw `openshift-monitoring`.[8, 9]
2.  W sekcji `data/config.yaml` tego obiektu, dodawany jest klucz `enableUserWorkload: true`.[8, 9, 10]
3.  Zapisanie tej zmiany jest wykrywane przez Cluster Monitoring Operator (CMO).

Reakcją CMO na tę zmianę nie jest modyfikacja istniejącego stosu platformy. Zamiast tego, uruchamia on drugą, niezależną pętlę reconcyliacji, która wdraża *całkowicie nowy, równoległy stos monitoringu* dedykowany dla użytkowników.[2]

Ten nowy stos jest tworzony w przestrzeni nazw `openshift-user-workload-monitoring` i obejmuje kluczowe komponenty [8, 10]:

*   Drugi, dedykowany `prometheus-operator`
*   Instancję `prometheus-user-workload` (do skrobania metryk aplikacji)
*   Instancję `thanos-ruler-user-workload` (do oceny reguł alertowych użytkownika)

Fizyczna segregacja instancji Prometheus gwarantuje, że metryki aplikacji (które mogą być niestabilne lub mieć wysoką kardynalność) są całkowicie odizolowane od metryk platformy, zapewniając najwyższy poziom stabilności.

**Krytyczne Ostrzeżenie:** Włączenie wbudowanego monitoringu użytkownika (`enableUserWorkload: true`) jest fundamentalnie *niekompatybilne* z ręcznym instalowaniem "generycznego" Operatora Prometheus (np. z OperatorHub/OLM).[8, 10] Takie działanie prowadzi do konfliktu, w którym dwa różne operatory próbują zarządzać tymi samymi zasobami CRD (jak `ServiceMonitor`), co prowadzi do nadpisywania konfiguracji i awarii monitoringu.[11] Administrator musi wybrać jedną, wspieraną ścieżkę: albo w pełni zintegrowany stos OCP, albo w pełni niestandardowy ("DIY"), ale nie oba jednocześnie.

### Użycie `ServiceMonitor` CRD, aby Prometheus automatycznie skrobał metryki

Po włączeniu monitoringu użytkownika, platforma OCP oferuje elegancki, deklaratywny mechanizm automatycznego wykrywania (service discovery) aplikacji, znany jako `ServiceMonitor`.

`ServiceMonitor` to definicja zasobu niestandardowego (Custom Resource Definition, CRD), która pozwala deweloperom deklaratywnie opisać, *jak* Prometheus ma skrobać metryki z ich usług.[12, 13, 14]

Mechanizm ten jest kluczową warstwą abstrakcji, która oddziela deweloperów aplikacji od administratorów platformy monitoringu. Zamiast prosić administratora o ręczną edycję pliku konfiguracyjnego Prometheus (co jest operacyjnym wąskim gardłem), deweloper po prostu dołącza plik YAML `ServiceMonitor` do swojego projektu, obok zasobów `Deployment` i `Service`.[13, 15]

Przepływ działania jest następujący:

1.  Deweloper tworzy aplikację, która eksportuje metryki w formacie Prometheus na określonym punkcie końcowym (np. `http://<pod_ip>:8080/metrics`).[16]
2.  Deweloper tworzy standardowy zasób `Service` (np. o nazwie `my-app-service`), który wskazuje na pody aplikacji i definiuje port metryk (np. `port: 8080`, `name: web`).[12]
3.  Deweloper tworzy zasób `ServiceMonitor` w tej samej przestrzeni nazw.[13, 17]
4.  W `spec.selector.matchLabels` zasobu `ServiceMonitor` deweloper umieszcza etykiety pasujące do zasobu `Service` (np. `app: my-app-service`).[17, 18, 19]
5.  W `spec.endpoints` zasobu `ServiceMonitor` deweloper określa, który *port* serwisu ma być skrobany (np. `port: web`) oraz *ścieżkę* (np. `path: /metrics`).[18, 19]
6.  Operator Prometheus (działający w `openshift-user-workload-monitoring`) stale obserwuje wszystkie przestrzenie nazw pod kątem nowych zasobów `ServiceMonitor`.[18]
7.  Gdy operator znajduje `ServiceMonitor` i pasujący do niego `Service`, automatycznie generuje odpowiednią konfigurację skrobania (`scrape_config`) i wstrzykuje ją do konfiguracji instancji `prometheus-user-workload`, która następnie rozpoczyna zbieranie metryk.[14, 19]

**Pułapka implementacyjna:** Jednym z najczęstszych problemów przy implementacji `ServiceMonitor` jest konfiguracja portu. Pole `spec.endpoints.port` w `ServiceMonitor` musi pasować do *nazwy* (`name:`) portu zdefiniowanej w zasobie `Service`, a nie tylko do jego numeru. Jeśli port w definicji `Service` jest nienazwany (np. `- port: 8080` zamiast `- name: web port: 8080`), `ServiceMonitor` często nie jest w stanie go znaleźć, co prowadzi do cichej awarii skrobania.[20]

Alternatywą dla `ServiceMonitor` jest `PodMonitor`, który działa na podobnej zasadzie, ale pomija warstwę `Service` i wykrywa pody bezpośrednio na podstawie ich etykiet.[12, 16, 18]

### Dostęp do wbudowanych dashboardów Grafana

Dostęp do wbudowanej instancji Grafana jest możliwy z poziomu konsoli OCP, w sekcji `Observe > Dashboards`.[21] Ta domyślna instancja zawiera predefiniowane dashboardy dla monitorowanych komponentów platformy (np. `etcd`, `Kubelet`).[3]

Jednakże, jak wspomniano, ta domyślna instancja jest skonfigurowana w trybie *tylko do odczytu (read-only)*.[4] Jest to celowe zabezpieczenie stabilności platformy. Uniemożliwia ono użytkownikom (nawet administratorom) tworzenie niestandardowych dashboardów lub importowanie ich z plików JSON.[4] Gdyby użytkownicy mogli tworzyć "ciężkie" zapytania PromQL w *tej samej* instancji Grafana, mogliby nieumyślnie przeciążyć *platformową* instancję Prometheus, ryzykując stabilność całego klastra.[22]

Wspieraną i rekomendowaną metodą na tworzenie niestandardowych wizualizacji jest wdrożenie *drugiej, w pełni zarządzalnej* instancji Grafana:

1.  Administrator instaluje **Operatora Grafana** (Grafana Operator) z OperatorHub.[23]
2.  Za pomocą tego operatora tworzy nową, niestandardową instancję `Grafana` (CRD) w wybranej przestrzeni nazw (np. `openshift-user-workload-monitoring`).[23] Ta instancja *nie będzie* działać w trybie read-only.[22]
3.  Następnie ta nowa instancja musi być skonfigurowana ze źródłem danych (Data Source).
4.  Kluczowym punktem jest to, że źródłem danych *nie powinny* być poszczególne instancje Prometheus. Prawidłowym źródłem danych jest trasa (route) do komponentu **`thanos-querier`** (znajdująca się w `openshift-monitoring`).[5, 24]
5.  `Thanos Querier` działa jako pojedynczy, globalny punkt dostępu (endpoint), który agreguje i deduplikuje metryki *zarówno* ze stosu platformy, jak i stosu użytkownika. Podłączenie do niego niestandardowej Grafany daje dostęp do *wszystkich* metryk w klastrze w bezpieczny sposób.
6.  Uwierzytelnienie nowej Grafany do `Thanos Querier` wymaga stworzenia dedykowanego `ServiceAccount` i przyznania mu odpowiednich uprawnień RBAC do odpytywania API Prometheus.[25]

## Lekcja 12.2: Logowanie (EFK / Loki)

### Architektura stosu logowania (Fluentd na każdym węźle, Loki lub Elasticsearch jako backend, Kibana/Grafana jako UI)

Architektura logowania w OCP, podobnie jak monitoringu, jest wysoce modułowa i zarządzana przez dedykowany operator. **Operator Cluster Logging (CLO)** obserwuje zasób niestandardowy (CRD) o nazwie `ClusterLogging`. Ten pojedynczy zasób CRD działa jak centralna "tablica rozdzielcza", w której administrator deklaruje pożądany stan całego potoku logowania (pipeline).[26]

Potok ten składa się z trzech głównych komponentów:

1.  **Kolektor (Collector):** Jest to komponent wdrożony jako `DaemonSet`, co oznacza, że jego pod działa na każdym węźle roboczym (Worker Node) i węźle płaszczyzny sterowania (Control Plane Node) klastra.[27] Jego zadaniem jest zbieranie logów ze źródeł na węźle (głównie logi kontenerów z `stdout`/`stderr` z `/var/log/containers` oraz logi systemowe węzła z `journald` [28]). Kolektor również wzbogaca te logi o kluczowe metadane Kubernetes, takie jak przestrzeń nazw, nazwa poda i etykiety.[29] OCP historycznie używało **Fluentd** [30], ale nowsze wersje wspierają również **Vector** jako nowocześniejszy, bardziej wydajny kolektor.[27]
2.  **Magazyn (Log Store):** Jest to backend, do którego kolektory przesyłają zebrane i przetworzone logi. Administrator definiuje ten backend w CRD `ClusterLogging`. OCP wspiera dwa główne typy magazynów:
    *   **Elasticsearch (EFK):** Tradycyjny, potężny silnik wyszukiwania pełnotekstowego.[31, 32]
    *   **Loki:** Nowocześniejszy, lekki system agregacji logów wdrażany jako `LokiStack`.[31, 33, 34]
3.  **Wizualizator (UI):** Interfejs użytkownika używany do przeszukiwania, filtrowania i wizualizacji logów. Wybór wizualizatora jest ściśle powiązany z wyborem magazynu:
    *   **Kibana:** Używana *wyłącznie* w połączeniu z Elasticsearch.[33, 35]
    *   **Konsola OCP / Grafana:** Używane w połączeniu z Loki. Logi są dostępne bezpośrednio w konsoli OCP (`Observe > Logs`) lub mogą być analizowane w Grafanie (tej samej, która służy do metryk).[33, 36]

### Różnica między EFK (Elasticsearch) a Loki (lżejsze, bazujące na etykietach)

Wybór między Elasticsearch a Loki jest jedną z najważniejszych decyzji architektonicznych dotyczących obserwowalności w OCP. Reprezentują one dwa fundamentalnie różne podejścia do indeksowania i przechowywania logów, co pociąga za sobą bezpośredni kompromis między *mocą zapytań* a *kosztem operacyjnym*.

**Stos EFK (Elasticsearch, Fluentd, Kibana):**

*   **Zasada Działania:** Elasticsearch stosuje metodę **indeksowania pełnotekstowego (full-text index)**. Oznacza to, że każda linia logu jest analizowana, a niemal każde słowo w niej zawarte jest indeksowane.[32, 37, 38]
*   **Zalety:** Zapewnia to niezwykle potężne i szybkie możliwości wyszukiwania pełnotekstowego, analityki i agregacji, podobne do wyszukiwarki internetowej.[37]
*   **Wady:** Koszt tej mocy jest ogromny. Indeksowanie pełnotekstowe jest procesem **wysoce zasobożernym** (CPU, pamięć RAM).[37, 39] Wymaga również znacznej ilości szybkiej przestrzeni dyskowej (Persistent Volumes), co jest drogie.[32] Przyjmowanie logów (ingestion) może stać się wąskim gardłem przy dużym wolumenie [31, 40], a skalowanie klastra Elasticsearch jest złożone i kosztowne.[39] W OCP, domyślna instancja ES jest optymalizowana tylko do krótkotrwałego przechowywania (np. 7 dni).[31, 32]

**Stos Loki (LokiStack):**

*   **Zasada Działania:** Loki jest inspirowany Prometheusem i działa na zasadzie **indeksowania tylko etykiet (labels-only index)**.[41] *Nie indeksuje* on pełnej treści tekstowej logów.[32, 37, 40]
*   Indeksowany jest tylko mały, stały zestaw metadanych (etykiet), takich jak `namespace`, `pod`, `app`, `level`.[38] Sama treść logu jest kompresowana w "bloki" (chunks) i przechowywana w tanim magazynie obiektowym (np. Amazon S3, GCS, Azure Blob Storage lub MinIO).[37]
*   **Zalety:** Podejście to jest **wyjątkowo lekkie i tanie**. Zużycie zasobów (CPU/RAM) jest minimalne w porównaniu do EFK.[37] Przyjmowanie logów jest błyskawiczne, ponieważ nie ma kosztownego indeksowania.[32, 40] Skalowanie horyzontalne jest proste, a koszt przechowywania (w magazynie obiektowym) jest drastycznie niższy.[38, 41]
*   **Wady:** Możliwości zapytań są inne. Zapytanie (w języku LogQL) musi najpierw szybko filtrować logi na podstawie *etykiet*, a następnie może "grepować" (przeszukiwać tekst) wewnątrz dopasowanych bloków.[37, 42] Jest to mniej wydajne dla zapytań analitycznych obejmujących całą treść logów.

**Strategia Red Hat i Migracja:**

Filozofia Loki jest znacznie bliższa architekturze cloud-native i stosowi Prometheus. Używa tego samego modelu danych opartego na etykietach [38] i języka zapytań (LogQL), który jest zaprojektowany tak, aby przypominał PromQL.[38] Ze względu na notorycznie wysokie koszty operacyjne (TCO) stosu EFK [40, 43], Red Hat podjął strategiczną decyzję o zmianie.

Stos EFK (Elasticsearch i Kibana) jest **oficjalnie przestarzały (deprecated)** w OCP Logging w wersji 5.x i nowszych.[33, 43, 44] Red Hat **rekomenduje migrację na `LokiStack`** jako domyślny magazyn logów.[33, 44] Pozwala to na skorzystanie z niższych kosztów, lepszej skalowalności [41] oraz głębszej integracji z konsolą OCP, eliminując potrzebę utrzymywania oddzielnej instancji Kibana.[33, 43]

Poniższa tabela podsumowuje kluczowe różnice techniczne.

**Tabela 2: Porównanie Techniczne Backendów Logowania: Elasticsearch (EFK) vs. Loki**

| Cecha | Stos EFK (Elasticsearch) | Stos Loki (LokiStack) |
| :--- | :--- | :--- |
| **Metoda Indeksowania** | **Indeksowanie pełnotekstowe** (Full-text) [32, 37] | **Indeksowanie tylko etykiet** (Labels-only) [32, 41] |
| **Model Danych** | Dokumenty JSON [37] | Strumienie logów z etykietami (jak Prometheus) [38] |
| **Język Zapytań** | Elasticsearch DSL / KQL [38] | LogQL [38] |
| **Zasobożerność (CPU/RAM)** | **Bardzo wysoka** [37, 40] | **Bardzo niska** [37, 40] |
| **Wymagania Dyskowe** | Wysokie (wymagane szybkie dyski/PV) [32] | Niskie (używa magazynu obiektowego, np. S3) [37] |
| **Skalowalność** | Złożona i kosztowna [39] | Prosta i tania (skalowanie horyzontalne) [38, 41] |
| **Główne Przeznaczenie** | Zaawansowana analityka logów, wyszukiwanie pełnotekstowe [38] | Efektywne kosztowo debugowanie i przeglądanie logów [38] |
| **Status w OCP** | **Przestarzały (Deprecated)** [33] | **Rekomendowany** [33, 44] |

### Przeglądanie logów (infrastruktury i aplikacji) w konsoli OCP

W konsoli webowej OpenShift istnieją dwa fundamentalnie różne sposoby interakcji z logami, a ich zrozumienie jest kluczowe dla efektywnego debugowania.

1.  **Logi Strumieniowe (z Poda):**
    Jest to widok dostępny w sekcji `Workloads > Pods`, po wybraniu konkretnego poda i przejściu do zakładki `Logs`.[45, 46, 47] Ten interfejs jest graficznym odpowiednikiem komendy `oc logs <nazwa_poda>`.[45, 48]
    *   **Co pokazuje:** *Bieżący* strumień (live stream) `stdout` i `stderr` z kontenera.[46]
    *   **Ograniczenia:** Ten widok *nie odpytuje* centralnego magazynu logów (ani EFK, ani Loki). Jest to tylko bufor ostatnich logów przechowywanych przez Kubelet na węźle. Jeśli pod uległ awarii i został zrestartowany, lub jeśli został usunięty, te logi są *tracone*. Jest to przydatne tylko do obserwacji działającej aplikacji w czasie rzeczywistym.

2.  **Logi Zagregowane (z Magazynu):**
    Jest to centralny, historyczny widok logów dostępny w głównej sekcji `Observe > Logs`.[36, 49, 50]
    *   **Wymagania:** Ta zakładka jest funkcjonalna *tylko* wtedy, gdy administrator zainstalował i skonfigurował Operatora Cluster Logging (CLO) i co najmniej jeden backend logów (EFK lub Loki).[47, 51]
    *   **Zachowanie zależne od backendu:**
        *   W przypadku starego stosu **EFK**, ten widok (`Observe > Logs`) był często wyłączony. Użytkownik musiał opuścić konsolę OCP i przejść do oddzielnego adresu URL, aby otworzyć interfejs **Kibana**.[36, 45, 51]
        *   W przypadku nowoczesnego stosu **LokiStack**, ta zakładka jest *włączona* i w pełni zintegrowana z konsolą OCP (poprzez `logging-view-plugin` [49, 50, 52]). Zapewnia ona natywny interfejs do uruchamiania zapytań LogQL i przeglądania logów historycznych (aplikacji i infrastruktury) bez opuszczania konsoli OCP.[33]

## Lekcja 12.3: Wprowadzenie do Tracingu (Jaeger) i OpenTelemetry

### Trzeci filar obserwowalności (Metryki, Logi, Tracing)

Podczas gdy monitoring (metryki) i logowanie (logi) są podstawą, nie zapewniają one pełnego obrazu w złożonych, rozproszonych architekturach. Obserwowalność opiera się na trzech filarach, z których każdy odpowiada na inne kluczowe pytanie podczas analizy problemu.[53, 54, 55]

1.  **Metryki (Metrics):** Odpowiadają na pytanie **"Co?"**.[56] Są to zagregowane, numeryczne dane szeregów czasowych, które informują o ogólnej kondycji systemu (np. "Zużycie CPU wynosi 90%", "P99 opóźnienia wynosi 2.5 sekundy", "Liczba błędów 5xx wzrosła").[53, 57, 58]
2.  **Logi (Logs):** Odpowiadają na pytanie **"Dlaczego?"**.[56] Są to szczegółowe, chronologiczne, niezmienne zapisy dyskretnych zdarzeń (np. "ERROR: Payment failed for user_id: 123. Database connection pool exhausted").[53, 58]
3.  **Ślady (Traces):** Odpowiadają na pytanie **"Gdzie?"**.[56] Reprezentują całościową, kontekstową ścieżkę *pojedynczego żądania* (transakcji) podczas jego przepływu przez wiele różnych mikrousług.[53, 54, 55]

Te filary nie są redundantne – są komplementarne i używane razem w typowym przepływie pracy SRE (Site Reliability Engineering):

1.  **Alert (Metryka):** PagerDuty uruchamia alert: "P99 opóźnienia dla usługi `checkout-api` przekroczyło 3 sekundy." (Wiemy *Co* jest źle).
2.  **Izolacja (Ślad):** Inżynier otwiera dashboard śledzenia (np. Jaeger) i filtruje ślady dla `checkout-api` trwające > 3s. Otwiera jeden z nich i widzi wizualizację (wykres Gantta), że żądanie spędziło 2.9 sekundy oczekiwując na odpowiedź z `inventory-service`. (Wiemy *Gdzie* jest wąskie gardło).
3.  **Analiza (Log):** Inżynier pobiera `Trace ID` z tego wolnego śladu, przechodzi do interfejsu logowania (np. Loki w konsoli OCP) i wyszukuje logi dla `inventory-service` z tym konkretnym `Trace ID`. Znajduje log błędu: `ERROR: Downstream service 'legacy-db' timeout`. (Wiemy *Dlaczego* wystąpił problem).

Poniższa tabela podsumowuje role poszczególnych filarów.

**Tabela 3: Trzy Filary Obserwowalności i Pytania, na które Odpowiadają**

| Filar | Kluczowe Pytanie | Forma Danych | Przykład |
| :--- | :--- | :--- | :--- |
| **Metryki** | **Co?** (Jaka jest kondycja?) | Numeryczne, agregowalne szeregi czasowe [53] | `http_requests_total{status="500"}` [57] |
| **Logi** | **Dlaczego?** (Co się stało w danym momencie?) | Chronologiczny, tekstowy zapis zdarzeń [53] | `ERROR: Connection refused for user 'x'` [58] |
| **Ślady** | **Gdzie?** (Gdzie jest wąskie gardło?) | Skontekstualizowana ścieżka żądania (Span/Trace) [53] | `Żądanie X: 20ms (API-GW) -> 2.5s (Usługa B)` [55] |

### Czym jest Tracing Dystrybuowany (śledzenie żądania przez wiele mikrousług)

W tradycyjnej aplikacji monolitycznej debugowanie jest stosunkowo proste.[56] W architekturze mikrousługowej pojedyncze żądanie użytkownika (np. złożenie zamówienia) jest "rozbijane na dziesiątki kawałków" [56], które komunikują się ze sobą przez API (HTTP, gRPC).[59, 60] Jeśli żądanie jest wolne lub kończy się błędem, znalezienie winnej usługi jest jak szukanie igły w stogu siana.[61]

**Śledzenie rozproszone (Distributed Tracing)** to technika, która rozwiązuje ten problem poprzez obserwację *całej ścieżki* (przepływu) pojedynczego żądania przez wszystkie komponenty, z którymi wchodzi ono w interakcję.[59, 62]

Podstawową jednostką jest **Span** (fragment). Span reprezentuje pojedynczą, logiczną jednostkę pracy w ramach jednej usługi (np. odebranie żądania HTTP, zapytanie do bazy danych, wywołanie innej usługi).[56, 59, 63] Każdy Span posiada:

*   Unikalny `Span ID`.
*   `Parent ID` (wskazujący na `Span ID` operacji, która go wywołała).
*   Nazwę operacji, czas rozpoczęcia i czas trwania.
*   Tagi (metadane) i logi (zdarzenia w ramach spana).[56, 64]

**Trace** (ślad) to zbiór wszystkich spanów (z różnych usług), które pochodzą od jednego żądania inicjującego. Wszystkie spany w ramach jednego śladu współdzielą ten sam, unikalny identyfikator: **`Trace ID`**.[56, 59]

Kluczowym mechanizmem, który pozwala "zszywać" (stitch) poszczególne spany w jeden spójny ślad, jest **Propagacja Kontekstu (Context Propagation)**.[56, 65, 66]

1.  Gdy żądanie po raz pierwszy wchodzi do systemu (np. do bramki API), generowany jest nowy `Trace ID` i `Span ID` (dla root spana).[64]
2.  Gdy ta pierwsza usługa wywołuje kolejną mikrousługę (np. przez HTTP), *wstrzykuje* ona ten kontekst (`Trace ID` i `Parent ID` - czyli swój `Span ID`) do **nagłówków HTTP**.[65]
3.  Kolejna usługa (usługa potomna) odbiera żądanie, *odczytuje* te nagłówki i rozumie, że jest częścią istniejącego śladu. Tworzy własny, *potomny* Span (z tym samym `Trace ID` i `Parent ID` wskazującym na span usługi nadrzędnej).[64]
4.  Proces ten jest powtarzany w całym łańcuchu wywołań.

Jeśli *jakakolwiek* usługa w łańcuchu nie przekaże tych nagłówków, ślad zostaje w tym miejscu *zerwany*. Dlatego tak kluczowe są standardy, takie jak **W3C Trace Context** (używający nagłówka `traceparent`) lub **B3** (używający nagłówków `X-B3-TraceId`), które zapewniają interoperacyjność.[65]

### Instalacja Operatora Jaeger

Samo generowanie śladów to tylko połowa sukcesu. Ślady te muszą być wysyłane do centralnego *backendu*, który potrafi je zbierać, przechowywać i wizualizować. **Jaeger** to otwarty (open-source), kompletny system do śledzenia rozproszonego, pierwotnie stworzony w firmie Uber, a obecnie projekt CNCF.[63, 66, 67]

Jaeger *nie jest* narzędziem do metryk ani logów.[67, 68] Jest to wysoce wyspecjalizowany backend *wyłącznie dla śladów*, który dostarcza:

*   Kolektory (agenty) do odbierania spanów.
*   Trwały magazyn (Storage Backend) do ich przechowywania.
*   Interfejs API do ich odpytywania.
*   Potężny interfejs graficzny (UI) do wizualizacji śladów, analizy zależności między usługami i optymalizacji opóźnień.[63, 66, 69]

W OpenShift, rekomendowaną metodą instalacji Jaegera jest użycie **Operatora Jaeger** (Jaeger Operator) dostępnego w OperatorHub.[70, 71, 72]

**Procedura instalacji:**

1.  Administrator klastra (`cluster-admin`) musi najpierw (dla wdrożeń produkcyjnych) zainstalować **Operatora Elasticsearch**.[70, 71]
2.  Powodem tej zależności jest fakt, że Jaeger (w trybie produkcyjnym) używa zewnętrznej bazy danych do trwałego przechowywania śladów. Domyślnie jest to Elasticsearch lub Cassandra.[67, 72] Oznacza to, że *ten sam* klaster Elasticsearch, który jest używany przez stos logowania EFK, może być *współużytkowany* jako magazyn dla śladów Jaegera.
3.  Następnie administrator instaluje Operatora Jaeger z OperatorHub.[70]
4.  Po zainstalowaniu operatora, administrator tworzy zasób niestandardowy (CRD) `Jaeger`, określając pożądaną strategię wdrożenia:
    *   **`all-in-one`:** Proste wdrożenie do celów deweloperskich i testowych. Wszystkie komponenty Jaegera działają w jednym podzie, a ślady przechowywane są w pamięci (`in-memory`) i tracone po restarcie.[70, 72]
    *   **`production`:** Skalowalne wdrożenie produkcyjne, które rozdziela komponenty (kolektor, agent, UI) i konfiguruje trwały magazyn (np. wcześniej wdrożony Elasticsearch).[72]

### Rola `OpenTelemetry` (OTel) jako nowego standardu instrumentacji kodu

Historycznie, świat śledzenia był sfragmentowany. Dwa wiodące otwarte projekty, **OpenTracing** (framework API) i **OpenCensus** (zbiór bibliotek od Google), konkurowały ze sobą, tworząc zamieszanie i utrudniając standaryzację.[73, 74]

Aby rozwiązać ten problem, oba projekty połączyły się, tworząc **OpenTelemetry (OTel)**, który jest teraz pojedynczym, ujednoliconym projektem CNCF.[74]

OpenTelemetry to **neutralny od dostawców (vendor-neutral) framework do obserwowalności**.[75, 76] Jego celem *nie jest* bycie backendem (jak Jaeger czy Prometheus).[73] Zamiast tego, OTel *standaryzuje* sposób, w jaki aplikacje **instrumentują** kod oraz **generują, kolekcjonują i eksportują** dane telemetryczne.[77]

Kluczową korzyścią OTel jest **niezależność od dostawcy (vendor independence)** [76]:

*   **Problem "Przed OTel":** Jeśli firma instrumentowała swoje aplikacje za pomocą agentów i bibliotek (SDK) komercyjnego dostawcy (np. Datadog), a następnie chciała przejść na innego dostawcę (np. New Relic), musiała *przepisać całą instrumentację* w swoim kodzie źródłowym.[73]
*   **Rozwiązanie "z OTel":** Deweloperzy instrumentują swój kod *tylko raz*, używając standardowych **API i SDK OpenTelemetry** (dostępnych dla większości języków, np. Java, Go, Python,.NET).[77, 78, 79] Następnie aplikacja może być *skonfigurowana* (bez zmiany kodu) do eksportowania telemetrii do *dowolnego* backendu – czy to otwartego (Jaeger, Prometheus) czy komercyjnego (Datadog, Azure Monitor).[75, 78]

Co najważniejsze, OpenTelemetry jest *siłą unifikującą* dla wszystkich trzech filarów obserwowalności. Podczas gdy Jaeger skupia się tylko na śladach [67], a Prometheus tylko na metrykach, OTel jest *pierwszym* standardem, który dostarcza **API i SDK do generowania metryk, logów ORAZ śladów**.[75, 76, 80, 81] Umożliwia to korelację tych sygnałów u samego źródła, na przykład poprzez automatyczne wstrzykiwanie `Trace ID` do wszystkich logów generowanych w trakcie danej transakcji.[80]

Poniższa tabela ilustruje ewolucję, która doprowadziła do powstania OTel.

**Tabela 4: Ewolucja Instrumentacji: Od Fragmentacji do OpenTelemetry**

| Projekt | Główny Cel | Obsługiwane Sygnały | Status |
| :--- | :--- | :--- | :--- |
| **OpenTracing** | Standaryzacja API dla śledzenia (tylko API). | Tylko Ślady (Traces) | Przestarzały (Deprecated); wchłonięty przez OTel [74] |
| **OpenCensus** | Zestaw bibliotek do śledzenia i metryk (od Google). | Ślady (Traces) i Metryki (Metrics) | Przestarzały (Deprecated); wchłonięty przez OTel [74] |
| **OpenTelemetry (OTel)** | Jeden, neutralny standard instrumentacji i eksportu. | **Ślady (Traces), Metryki (Metrics) i Logi (Logs)** [75] | **Aktualny Standard Branżowy** [76, 77] |

### Wprowadzenie do Tracingu (Jaeger) i OpenTelemetry

OpenTelemetry (warstwa instrumentacji) i Jaeger (warstwa backendu) nie są konkurentami – są idealnie komplementarne.[68, 82]

Nowoczesna, standardowa architektura obserwowalności opiera się na komponencie **OTel Collector** (Kolektor OpenTelemetry). Jest to "szwajcarski scyzoryk" telemetrii: elastyczny, neutralny od dostawców agent, którego jedynym zadaniem jest **odbieranie, przetwarzanie i eksportowanie** danych.[77, 81]

Standardowy przepływ pracy wygląda następująco:

1.  Aplikacja w podzie jest instrumentowana za pomocą **OTel SDK** (np. OTel Java Agent).[79]
2.  Aplikacja generuje wszystkie trzy sygnały (metryki, logi, ślady).
3.  Aplikacja eksportuje *wszystkie* te dane w standardowym formacie **OTLP** (OpenTelemetry Protocol) do *jednego* miejsca: instancji **OTel Collector**.[81, 83]
4.  OTel Collector jest skonfigurowany za pomocą potoku (pipeline) `receivers -> processors -> exporters`.[84]
5.  Kolektor odbiera dane OTLP, a następnie *rozdziela* je (fan-out) do odpowiednich backendów:
    *   Używa `jaeger_exporter` do wysłania **śladów** do backendu Jaeger.[82, 83]
    *   Używa `prometheus_exporter` do wysłania **metryk** do Prometheus.
    *   Używa `loki_exporter` do wysłania **logów** do Loki.

Ta architektura jest niezwykle potężna, ponieważ aplikacja jest całkowicie odizolowana od wiedzy o backendach.[75] W przyszłości, jeśli firma zechce wysyłać ślady *równocześnie* do Jaegera i do komercyjnego narzędzia X, wystarczy dodać drugi eksporter w konfiguracji Kolektora – bez *żadnych* zmian w aplikacji.

Co więcej, sam projekt Jaeger ewoluuje w tym kierunku. Najnowsze wersje komponentów backendu Jaegera są *budowane na bazie* OTel Collector.[85] Oznacza to, że w przyszłości "binarka Jaegera" będzie po prostu OTel Collectorem ze wstępnie skonfigurowanymi odbiornikami OTLP i eksporterem do magazynu Jaegera, co ostatecznie cementuje OTel jako uniwersalny standard dla całej branży.[85] Red Hat również dostarcza własną, wspieraną dystrybucję OpenTelemetry.[86]

## Wnioski Modułu 12: Strategia Zunifikowanej Obserwowalności w OCP

Analiza trzech filarów obserwowalności w OpenShift ujawnia dwa nadrzędne, strategiczne trendy, które kierują ewolucją platformy: unifikację interfejsu użytkownika i wydajności oraz unifikację warstwy instrumentacji.

**Trend 1: Unifikacja UI i Wydajności (Metryki + Logi)**
Platforma OCP wyraźnie odchodzi od historycznego, ciężkiego i zasobożernego stosu EFK (Elasticsearch/Kibana).[33, 43] Jest on zastępowany przez lekki, natywny dla chmury stos Loki.[44] Ta migracja jest motywowana nie tylko drastyczną redukcją kosztów operacyjnych (TCO) [40], ale przede wszystkim dążeniem do unifikacji. Loki, jako "Prometheus dla logów", używa tego samego modelu danych opartego na etykietach co Prometheus [38] i integruje się z tymi samymi narzędziami (Grafana oraz natywna konsola OCP `Observe > Logs`).[33, 36] Eliminuje to potrzebę utrzymywania oddzielnej instancji Kibana i pozwala inżynierom SRE na korelowanie metryk (z Prometheus) i logów (z Loki) w jednym, spójnym interfejsie.

**Trend 2: Unifikacja Instrumentacji (Metryki + Logi + Ślady)**
Równolegle, ewolucja od fragmentarycznych standardów (OpenTracing, OpenCensus) do OpenTelemetry [74] rozwiązuje problem standaryzacji na poziomie aplikacji. Adopcja OTel przez Red Hat [86] i samego Jaegera [85] sygnalizuje ruch w kierunku *pojedynczej* warstwy instrumentacji dla *wszystkich trzech filarów*.[75, 76]

**Architektura Docelowa (End-State):**
Przyszłością obserwowalności w OCP jest w pełni ujednolicony potok, oparty w 100% na otwartych standardach:

1.  **Instrumentacja:** Aplikacje są instrumentowane *jeden raz* za pomocą **OTel SDK**, generując metryki, logi i ślady.[79, 80]
2.  **Kolekcja:** Wszystkie dane są wysyłane (w formacie OTLP) do **OTel Collector**, który działa jako centralny agent routingu.[81]
3.  **Backend (Routing):** OTel Collector rozdziela ruch: **metryki** trafiają do **Prometheus**, **logi** do **Loki**, a **ślady** do **Jaeger**.[84]
4.  **Wizualizacja:** Użytkownik korzysta ze zunifikowanego interfejsu (Grafana lub Konsola OCP) do analizy metryk i logów [36] oraz z UI Jaegera do głębokiej analizy śladów.[67]

Dzięki temu podejściu OpenShift przekształca się ze zbioru oddzielnych narzędzi do obserwacji w spójną, zintegrowaną i efektywną kosztowo platformę obserwowalności.
#### **Cytowane prace**

1. Chapter 1\. Monitoring overview | Monitoring | OpenShift Container Platform | 4.12 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.12/html/monitoring/monitoring-overview](https://docs.redhat.com/en/documentation/openshift_container_platform/4.12/html/monitoring/monitoring-overview)  
2. Chapter 1\. About OpenShift Container Platform monitoring \- Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.18/html/monitoring/about-openshift-container-platform-monitoring](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/monitoring/about-openshift-container-platform-monitoring)  
3. Chapter 1\. Monitoring overview | Monitoring | OpenShift Container Platform | 4.10 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.10/html/monitoring/monitoring-overview](https://docs.redhat.com/en/documentation/openshift_container_platform/4.10/html/monitoring/monitoring-overview)  
4. Chapter 1\. Monitoring overview | Monitoring | OpenShift Container Platform | 4.9 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.9/html/monitoring/monitoring-overview](https://docs.redhat.com/en/documentation/openshift_container_platform/4.9/html/monitoring/monitoring-overview)  
5. Monitor Clusters on OpenShift \- Portworx Documentation, otwierano: listopada 15, 2025, [https://docs.portworx.com/portworx-enterprise/operations/monitoring/set-ocp-prometheus](https://docs.portworx.com/portworx-enterprise/operations/monitoring/set-ocp-prometheus)  
6. Logging and monitoring \- IBM, otwierano: listopada 15, 2025, [https://www.ibm.com/docs/en/rhocp-ibm-z?topic=considerations-logging-monitoring](https://www.ibm.com/docs/en/rhocp-ibm-z?topic=considerations-logging-monitoring)  
7. OpenShift monitoring tools \- Datadog, otwierano: listopada 15, 2025, [https://www.datadoghq.com/blog/openshift-monitoring-tools/](https://www.datadoghq.com/blog/openshift-monitoring-tools/)  
8. Chapter 5\. Enabling monitoring for user-defined projects | Monitoring | OpenShift Container Platform | 4.12 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.12/html/monitoring/enabling-monitoring-for-user-defined-projects](https://docs.redhat.com/en/documentation/openshift_container_platform/4.12/html/monitoring/enabling-monitoring-for-user-defined-projects)  
9. Enabling monitoring in OpenShift Container Platform \- Genesys Documentation, otwierano: listopada 15, 2025, [https://all.docs.genesys.com/PrivateEdition/Current/Operations/EnableMonitoringServicesOCP](https://all.docs.genesys.com/PrivateEdition/Current/Operations/EnableMonitoringServicesOCP)  
10. Chapter 3\. Enabling monitoring for user-defined projects | Monitoring | OpenShift Container Platform | 4.8 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/monitoring/enabling-monitoring-for-user-defined-projects](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/monitoring/enabling-monitoring-for-user-defined-projects)  
11. Openshift default monitoring stack and Service Mesh Operator, otwierano: listopada 15, 2025, [https://stackoverflow.com/questions/72250354/openshift-default-monitoring-stack-and-service-mesh-operator](https://stackoverflow.com/questions/72250354/openshift-default-monitoring-stack-and-service-mesh-operator)  
12. Chapter 2\. Monitoring your own services | Monitoring | OpenShift Container Platform | 4.3 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.3/html/monitoring/monitoring-your-own-services](https://docs.redhat.com/en/documentation/openshift_container_platform/4.3/html/monitoring/monitoring-your-own-services)  
13. Chapter 4\. Managing metrics | Monitoring | OpenShift Container Platform | 4.8, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/monitoring/managing-metrics](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/monitoring/managing-metrics)  
14. Prometheus Operator creates/configures/manages Prometheus clusters atop Kubernetes \- GitHub, otwierano: listopada 15, 2025, [https://github.com/prometheus-operator/prometheus-operator](https://github.com/prometheus-operator/prometheus-operator)  
15. Monitor Your Application Metrics Using Openshift's Monitoring Stack | by Shon Paz | Medium, otwierano: listopada 15, 2025, [https://shonpaz.medium.com/monitor-your-application-metrics-using-the-openshift-monitoring-stack-862cb4111906](https://shonpaz.medium.com/monitor-your-application-metrics-using-the-openshift-monitoring-stack-862cb4111906)  
16. Chapter 7\. Managing metrics | Monitoring | OpenShift Container Platform | 4.12, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.12/html/monitoring/managing-metrics](https://docs.redhat.com/en/documentation/openshift_container_platform/4.12/html/monitoring/managing-metrics)  
17. Creating Prometheus service monitors \- IBM, otwierano: listopada 15, 2025, [https://www.ibm.com/docs/en/erqa?topic=monitoring-creating-prometheus-service-monitors](https://www.ibm.com/docs/en/erqa?topic=monitoring-creating-prometheus-service-monitors)  
18. Getting Started \- Prometheus Operator, otwierano: listopada 15, 2025, [https://prometheus-operator.dev/docs/developer/getting-started/](https://prometheus-operator.dev/docs/developer/getting-started/)  
19. Prometheus Operator \- What is It, Tutorial & Examples \- Spacelift, otwierano: listopada 15, 2025, [https://spacelift.io/blog/prometheus-operator](https://spacelift.io/blog/prometheus-operator)  
20. How to create a ServiceMonitor for prometheus-operator? \[closed\] \- Stack Overflow, otwierano: listopada 15, 2025, [https://stackoverflow.com/questions/52991038/how-to-create-a-servicemonitor-for-prometheus-operator](https://stackoverflow.com/questions/52991038/how-to-create-a-servicemonitor-for-prometheus-operator)  
21. Chapter 15\. Viewing cluster dashboards | Logging | OpenShift Container Platform | 4.10, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.10/html/logging/cluster-logging-dashboards](https://docs.redhat.com/en/documentation/openshift_container_platform/4.10/html/logging/cluster-logging-dashboards)  
22. Custom Grafana dashboards for Red Hat OpenShift Container Platform 4, otwierano: listopada 15, 2025, [https://www.redhat.com/en/blog/custom-grafana-dashboards-red-hat-openshift-container-platform-4](https://www.redhat.com/en/blog/custom-grafana-dashboards-red-hat-openshift-container-platform-4)  
23. Setting up Grafana on Red Hat OpenShift Container Platform (OCP) \- IBM, otwierano: listopada 15, 2025, [https://www.ibm.com/docs/en/cics-tx/11.1.0?topic=ugd-setting-up-grafana-red-hat-openshift-container-platform-ocp](https://www.ibm.com/docs/en/cics-tx/11.1.0?topic=ugd-setting-up-grafana-red-hat-openshift-container-platform-ocp)  
24. Integrating OpenShift Prometheus with Grafana Dashboards | by Peaceworld Abbas, otwierano: listopada 15, 2025, [https://medium.com/@peaceworld.abbas/integrating-openshift-prometheus-with-grafana-dashboards-ba45ddc9239e](https://medium.com/@peaceworld.abbas/integrating-openshift-prometheus-with-grafana-dashboards-ba45ddc9239e)  
25. Hitchhiking on OpenShift's Observability using Custom Grafana Dashboards | ChRIS Project, otwierano: listopada 15, 2025, [https://chrisproject.org/blog/2023/10/22/hitchhiking-openshift-observe](https://chrisproject.org/blog/2023/10/22/hitchhiking-openshift-observe)  
26. Chapter 5\. Understanding the logging subsystem for Red Hat OpenShift, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.10/html/logging/cluster-logging](https://docs.redhat.com/en/documentation/openshift_container_platform/4.10/html/logging/cluster-logging)  
27. Chapter 4\. About Logging | Logging | OpenShift Container Platform | 4.13, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.13/html/logging/cluster-logging](https://docs.redhat.com/en/documentation/openshift_container_platform/4.13/html/logging/cluster-logging)  
28. Way to change fluentd log source location : r/openshift \- Reddit, otwierano: listopada 15, 2025, [https://www.reddit.com/r/openshift/comments/js6dpm/way\_to\_change\_fluentd\_log\_source\_location/](https://www.reddit.com/r/openshift/comments/js6dpm/way_to_change_fluentd_log_source_location/)  
29. Chapter 4\. Configuring your Logging deployment | Logging | OpenShift Container Platform | 4.8 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/logging/configuring-your-logging-deployment](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/logging/configuring-your-logging-deployment)  
30. Chapter 2\. Understanding Red Hat OpenShift Logging, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/logging/cluster-logging](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/logging/cluster-logging)  
31. Chapter 11\. Log storage | Logging | OpenShift Container Platform \- Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.14/html/logging/log-storage-2](https://docs.redhat.com/en/documentation/openshift_container_platform/4.14/html/logging/log-storage-2)  
32. Chapter 10\. Log storage | Logging | OpenShift Container Platform \- Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.12/html/logging/log-storage](https://docs.redhat.com/en/documentation/openshift_container_platform/4.12/html/logging/log-storage)  
33. Migrate your OpenShift logging stack from Elasticsearch to Loki | Red Hat Developer, otwierano: listopada 15, 2025, [https://developers.redhat.com/articles/2025/09/01/migrate-your-openshift-logging-stack-elasticsearch-loki](https://developers.redhat.com/articles/2025/09/01/migrate-your-openshift-logging-stack-elasticsearch-loki)  
34. Chapter 8\. Logging using LokiStack | Logging | OpenShift Container Platform | 4.10, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.10/html/logging/cluster-logging-loki](https://docs.redhat.com/en/documentation/openshift_container_platform/4.10/html/logging/cluster-logging-loki)  
35. Chapter 1\. About cluster logging and OpenShift Container Platform, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.1/html/logging/efk-logging](https://docs.redhat.com/en/documentation/openshift_container_platform/4.1/html/logging/efk-logging)  
36. Chapter 7\. Visualizing logs | Logging | OpenShift Container Platform | 4.12, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.12/html/logging/visualizing-logs](https://docs.redhat.com/en/documentation/openshift_container_platform/4.12/html/logging/visualizing-logs)  
37. Loki vs Elasticsearch \- Which tool to choose for Log Analytics? \- SigNoz, otwierano: listopada 15, 2025, [https://signoz.io/blog/loki-vs-elasticsearch/](https://signoz.io/blog/loki-vs-elasticsearch/)  
38. Loki vs. Elasticsearch: Choosing the Right Logging System for You \- KubeBlogs, otwierano: listopada 15, 2025, [https://www.kubeblogs.com/loki-vs-elasticsearch/](https://www.kubeblogs.com/loki-vs-elasticsearch/)  
39. Grafana Loki vs. ELK Stack for Logging \- OpsVerse, otwierano: listopada 15, 2025, [https://opsverse.io/2024/07/26/grafana-loki-vs-elk-stack-for-logging-a-comprehensive-comparison/](https://opsverse.io/2024/07/26/grafana-loki-vs-elk-stack-for-logging-a-comprehensive-comparison/)  
40. Wtf is Loki and should I replace ELK with it if the project just started? : r/devops \- Reddit, otwierano: listopada 15, 2025, [https://www.reddit.com/r/devops/comments/mv4ztu/wtf\_is\_loki\_and\_should\_i\_replace\_elk\_with\_it\_if/](https://www.reddit.com/r/devops/comments/mv4ztu/wtf_is_loki_and_should_i_replace_elk_with_it_if/)  
41. What's new in Red Hat OpenShift Logging 5.5, otwierano: listopada 15, 2025, [https://www.redhat.com/en/blog/whats-new-in-red-hat-openshift-logging-5.5](https://www.redhat.com/en/blog/whats-new-in-red-hat-openshift-logging-5.5)  
42. What are some opinions and experiences when choosing between Elasticsearch and Loki? : r/devops \- Reddit, otwierano: listopada 15, 2025, [https://www.reddit.com/r/devops/comments/13wjs0p/what\_are\_some\_opinions\_and\_experiences\_when/](https://www.reddit.com/r/devops/comments/13wjs0p/what_are_some_opinions_and_experiences_when/)  
43. EFK to Lokistack ( How Big is the Transition ) : r/openshift \- Reddit, otwierano: listopada 15, 2025, [https://www.reddit.com/r/openshift/comments/1biitpz/efk\_to\_lokistack\_how\_big\_is\_the\_transition/](https://www.reddit.com/r/openshift/comments/1biitpz/efk_to_lokistack_how_big_is_the_transition/)  
44. Logging: Working with the Loki Operator \- Open Source For You, otwierano: listopada 15, 2025, [https://www.opensourceforu.com/2024/08/logging-working-with-the-loki-operator/](https://www.opensourceforu.com/2024/08/logging-working-with-the-loki-operator/)  
45. Viewing cluster logs in Red Hat OpenShift \- IBM, otwierano: listopada 15, 2025, [https://www.ibm.com/docs/en/app-connect/12.0.x?topic=mt-viewing-cluster-logs-in-red-hat-openshift-1](https://www.ibm.com/docs/en/app-connect/12.0.x?topic=mt-viewing-cluster-logs-in-red-hat-openshift-1)  
46. Viewing logs in openshift-web-ui \- Reddit, otwierano: listopada 15, 2025, [https://www.reddit.com/r/openshift/comments/17wo52v/viewing\_logs\_in\_openshiftwebui/](https://www.reddit.com/r/openshift/comments/17wo52v/viewing_logs_in_openshiftwebui/)  
47. Chapter 5\. Viewing logs for a resource | Logging | OpenShift Container Platform | 4.7 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.7/html/logging/vewing-resource-logs](https://docs.redhat.com/en/documentation/openshift_container_platform/4.7/html/logging/vewing-resource-logs)  
48. Accessing console logs with the Red Hat OpenShift command-line interface \- IBM, otwierano: listopada 15, 2025, [https://www.ibm.com/docs/en/ftmfm/4.0.6?topic=ccl-accessing-console-logs-red-hat-openshift-command-line-interface](https://www.ibm.com/docs/en/ftmfm/4.0.6?topic=ccl-accessing-console-logs-red-hat-openshift-command-line-interface)  
49. Log visualization with the web console \- Logging | Observability | OKD 4.16, otwierano: listopada 15, 2025, [https://docs.okd.io/4.16/observability/logging/log\_visualization/log-visualization-ocp-console.html](https://docs.okd.io/4.16/observability/logging/log_visualization/log-visualization-ocp-console.html)  
50. Chapter 7\. Visualizing logs | Logging | OpenShift Container Platform | 4.13 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.13/html/logging/visualizing-logs](https://docs.redhat.com/en/documentation/openshift_container_platform/4.13/html/logging/visualizing-logs)  
51. Chapter 6\. Viewing cluster logs | Logging | OpenShift Container Platform | 4.2, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.2/html/logging/cluster-logging-viewing](https://docs.redhat.com/en/documentation/openshift_container_platform/4.2/html/logging/cluster-logging-viewing)  
52. Log visualization with the web console \- Logging | Observability | OKD 4.13, otwierano: listopada 15, 2025, [https://docs.okd.io/4.13/observability/logging/log\_visualization/log-visualization-ocp-console.html](https://docs.okd.io/4.13/observability/logging/log_visualization/log-visualization-ocp-console.html)  
53. The Three Pillars of Observability: Logs, Metrics, and Traces \- CrowdStrike, otwierano: listopada 15, 2025, [https://www.crowdstrike.com/en-us/cybersecurity-101/observability/three-pillars-of-observability/](https://www.crowdstrike.com/en-us/cybersecurity-101/observability/three-pillars-of-observability/)  
54. What Is Observability? | Datadog, otwierano: listopada 15, 2025, [https://www.datadoghq.com/knowledge-center/observability/](https://www.datadoghq.com/knowledge-center/observability/)  
55. Three Pillars of Observability: Logs vs. Metrics vs. Traces | Edge Delta, otwierano: listopada 15, 2025, [https://edgedelta.com/company/blog/three-pillars-of-observability](https://edgedelta.com/company/blog/three-pillars-of-observability)  
56. Distributed Tracing in Microservices \- GeeksforGeeks, otwierano: listopada 15, 2025, [https://www.geeksforgeeks.org/system-design/distributed-tracing-in-microservices/](https://www.geeksforgeeks.org/system-design/distributed-tracing-in-microservices/)  
57. The 3 pillars of observability: Unified logs, metrics, and traces | Elastic Blog, otwierano: listopada 15, 2025, [https://www.elastic.co/blog/3-pillars-of-observability](https://www.elastic.co/blog/3-pillars-of-observability)  
58. Three Pillars of Observability: Logs, Metrics and Traces \- IBM, otwierano: listopada 15, 2025, [https://www.ibm.com/think/insights/observability-pillars](https://www.ibm.com/think/insights/observability-pillars)  
59. What Is Distributed Tracing? \- Amazon AWS, otwierano: listopada 15, 2025, [https://aws.amazon.com/what-is/distributed-tracing/](https://aws.amazon.com/what-is/distributed-tracing/)  
60. otwierano: listopada 15, 2025, [https://aws.amazon.com/what-is/distributed-tracing/\#:\~:text=Distributed%20tracing%20is%20observing%20data,APIs%20to%20do%20complex%20work.](https://aws.amazon.com/what-is/distributed-tracing/#:~:text=Distributed%20tracing%20is%20observing%20data,APIs%20to%20do%20complex%20work.)  
61. What Is Distributed Tracing? \- Splunk, otwierano: listopada 15, 2025, [https://www.splunk.com/en\_us/blog/learn/distributed-tracing.html](https://www.splunk.com/en_us/blog/learn/distributed-tracing.html)  
62. What is Distributed Tracing? How it Works & Use Cases \- Datadog, otwierano: listopada 15, 2025, [https://www.datadoghq.com/knowledge-center/distributed-tracing/](https://www.datadoghq.com/knowledge-center/distributed-tracing/)  
63. What is Jaeger Tracing? \- Dash0, otwierano: listopada 15, 2025, [https://www.dash0.com/knowledge/what-is-jaeger-tracing](https://www.dash0.com/knowledge/what-is-jaeger-tracing)  
64. What Is Distributed Tracing and How Jaeger Tracing Is Solving Its Challenges | Tiger Data, otwierano: listopada 15, 2025, [https://www.tigerdata.com/blog/what-is-distributed-tracing-and-how-jaeger-tracing-is-solving-its-challenges](https://www.tigerdata.com/blog/what-is-distributed-tracing-and-how-jaeger-tracing-is-solving-its-challenges)  
65. Distributed Tracing Headers Passed Through Spring Boot APIs, otwierano: listopada 15, 2025, [https://medium.com/@AlexanderObregon/distributed-tracing-headers-passed-through-spring-boot-apis-eebb69c5001d](https://medium.com/@AlexanderObregon/distributed-tracing-headers-passed-through-spring-boot-apis-eebb69c5001d)  
66. What is Jaeger? \- Jaeger Tracing Explained \- Amazon AWS, otwierano: listopada 15, 2025, [https://aws.amazon.com/what-is/jaeger/](https://aws.amazon.com/what-is/jaeger/)  
67. A Practical Guide to Distributed Tracing with Jaeger | Better Stack Community, otwierano: listopada 15, 2025, [https://betterstack.com/community/guides/observability/jaeger-guide/](https://betterstack.com/community/guides/observability/jaeger-guide/)  
68. OpenTelemetry and Jaeger | Key Features & Differences \[2025\] \- SigNoz, otwierano: listopada 15, 2025, [https://signoz.io/blog/opentelemetry-vs-jaeger/](https://signoz.io/blog/opentelemetry-vs-jaeger/)  
69. Understanding Jaeger: From Basics to Advanced Distributed Tracing \- Uptrace, otwierano: listopada 15, 2025, [https://uptrace.dev/glossary/what-is-jaeger](https://uptrace.dev/glossary/what-is-jaeger)  
70. Jaeger | OpenShift Container Platform | 4.3 \- Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.3/html-single/jaeger/index](https://docs.redhat.com/en/documentation/openshift_container_platform/4.3/html-single/jaeger/index)  
71. Chapter 3\. Jaeger installation | Jaeger | OpenShift Container Platform | 4.4 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.4/html/jaeger/jaeger-installation](https://docs.redhat.com/en/documentation/openshift_container_platform/4.4/html/jaeger/jaeger-installation)  
72. jaegertracing/jaeger-openshift: Support for deploying Jaeger into OpenShift \- GitHub, otwierano: listopada 15, 2025, [https://github.com/jaegertracing/jaeger-openshift](https://github.com/jaegertracing/jaeger-openshift)  
73. Understanding OpenTelemetry: The Universal Language of Observability | by Dani Vijay | WebClub.io | Oct, 2025, otwierano: listopada 15, 2025, [https://medium.com/the-web-club/understanding-opentelemetry-the-universal-language-of-observability-b4eb41414511](https://medium.com/the-web-club/understanding-opentelemetry-the-universal-language-of-observability-b4eb41414511)  
74. What is OpenTelemetry?, otwierano: listopada 15, 2025, [https://opentelemetry.io/docs/what-is-opentelemetry/](https://opentelemetry.io/docs/what-is-opentelemetry/)  
75. What is OpenTelemetry? How it Works & Use Cases \- Datadog, otwierano: listopada 15, 2025, [https://www.datadoghq.com/knowledge-center/opentelemetry/](https://www.datadoghq.com/knowledge-center/opentelemetry/)  
76. What Is OpenTelemetry? A Complete Guide \- Splunk, otwierano: listopada 15, 2025, [https://www.splunk.com/en\_us/blog/learn/opentelemetry.html](https://www.splunk.com/en_us/blog/learn/opentelemetry.html)  
77. Documentation \- OpenTelemetry, otwierano: listopada 15, 2025, [https://opentelemetry.io/docs/](https://opentelemetry.io/docs/)  
78. .NET Observability with OpenTelemetry \- .NET | Microsoft Learn, otwierano: listopada 15, 2025, [https://learn.microsoft.com/en-us/dotnet/core/diagnostics/observability-with-otel](https://learn.microsoft.com/en-us/dotnet/core/diagnostics/observability-with-otel)  
79. Instrumentation | OpenTelemetry, otwierano: listopada 15, 2025, [https://opentelemetry.io/docs/concepts/instrumentation/](https://opentelemetry.io/docs/concepts/instrumentation/)  
80. OpenTelemetry Logging, otwierano: listopada 15, 2025, [https://opentelemetry.io/docs/specs/otel/logs/](https://opentelemetry.io/docs/specs/otel/logs/)  
81. Quick start \- OpenTelemetry, otwierano: listopada 15, 2025, [https://opentelemetry.io/docs/collector/quick-start/](https://opentelemetry.io/docs/collector/quick-start/)  
82. How to Use Jaeger with OpenTelemetry \- Last9, otwierano: listopada 15, 2025, [https://last9.io/blog/how-to-use-jaeger-with-opentelemetry/](https://last9.io/blog/how-to-use-jaeger-with-opentelemetry/)  
83. Export to Jaeger | OpenTelemetry, otwierano: listopada 15, 2025, [https://opentelemetry.io/docs/languages/dotnet/traces/jaeger/](https://opentelemetry.io/docs/languages/dotnet/traces/jaeger/)  
84. Transforming traces into metrics with OpenTelemetry \- New Relic, otwierano: listopada 15, 2025, [https://newrelic.com/blog/nerdlog/transforming-traces](https://newrelic.com/blog/nerdlog/transforming-traces)  
85. OpenTelemetry \- Jaeger, otwierano: listopada 15, 2025, [https://www.jaegertracing.io/docs/1.21/deployment/opentelemetry/](https://www.jaegertracing.io/docs/1.21/deployment/opentelemetry/)  
86. Chapter 6\. Sending traces, logs, and metrics to the OpenTelemetry Collector \- Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.19/html/red\_hat\_build\_of\_opentelemetry/otel-sending-traces-logs-and-metrics-to-otel-collector](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/red_hat_build_of_opentelemetry/otel-sending-traces-logs-and-metrics-to-otel-collector)
