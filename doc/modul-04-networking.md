# Moduł 4: Architektura Sieci w OpenShift: Od Usług Wewnętrznych do Globalnej Ekspozycji

## Wprowadzenie

Sieci stanowią fundamentalny i zarazem jeden z najbardziej złożonych aspektów platform kontenerowych. W przypadku OpenShift (OCP), sieci ewoluowały poza standardowy model Kubernetes, oferując zintegrowane, gotowe do użytku korporacyjnego rozwiązania, które zapewniają zarówno ekspozycję aplikacji, jak i rygorystyczną izolację. Zrozumienie tego ekosystemu jest krytyczne dla administratorów platformy, architektów i zespołów DevOps.

Niniejszy raport techniczny stanowi wyczerpującą analizę Modułu 4, obejmującego cztery filary sieci w OpenShift. Dokument ten przekształca punkty sylabusa w dogłębną analizę architektoniczną:

1.  **Abstrakcja Wewnętrzna L4 (`Service`):** Analiza fundamentalnych obiektów `Service` Kubernetes (ClusterIP, NodePort, LoadBalancer), ze szczególnym uwzględnieniem ograniczeń w środowiskach lokalnych (OCP Local) i implikacji dla architektury platformy.
2.  **Brama Zewnętrzna L7 (`Route`):** Dogłębna dekonstrukcja obiektu `Route`, natywnego dla OpenShift, jego architektury opartej na HAProxy (OpenShift Router) oraz jego przewag i różnic w stosunku do standardowego obiektu `Ingress`.
3.  **Zarządzanie Szyfrowaniem na Krawędzi (Terminacja TLS):** Zorientowana na bezpieczeństwo analiza trzech strategii terminacji TLS (`Edge`, `Passthrough`, `Re-encrypt`), kluczowych dla zabezpieczenia ruchu przychodzącego.
4.  **Segmentacja i Izolacja L3/L4 (`NetworkPolicy`):** Praktyczny przewodnik po modelu izolacji OpenShift, od domyślnej izolacji międzyprojektowej (`multitenant`) po granulowaną kontrolę wewnątrz projektu przy użyciu standardowych obiektów `NetworkPolicy`.

Sukces wdrożenia, skalowania i zabezpieczenia aplikacji w OpenShift jest nierozerwalnie związany z dogłębnym zrozumieniem i poprawną konfiguracją tych czterech komponentów sieciowych. Raport ten dostarcza niezbędnej wiedzy technicznej do ich mistrzowskiego opanowania.

-----

## Lekcja 4.1: Powtórka z Service – Wewnętrzny Kręgosłup Aplikacji

### 1.1 Problem Efemeryczności Podów i Rola `Service`

Podstawową jednostką obliczeniową w Kubernetes i OpenShift jest Pod. Architektura platformy zakłada, że Pody są efemeryczne (nietrwałe).[1] Oznacza to, że mogą być tworzone, usuwane, restartowane lub przeskalowywane w dowolnym momencie. Każdy nowy Pod otrzymuje nowy, unikalny adres IP w ramach sieci klastra.[2] Poleganie na tych dynamicznie zmieniających się adresach IP Podów do komunikacji między komponentami aplikacji (np. między frontendem a backendem) jest niemożliwe i sprzeczne z zasadami projektowania aplikacji chmurowych.[3]

Rozwiązaniem tego problemu jest obiekt `Service`.[3] Działa on jako trwała abstrakcja warstwy 4 (L4) modelu OSI. `Service` zapewnia stabilny, wirtualny adres IP (VIP) oraz port, który działa jako stały punkt końcowy (endpoint) dla logicznej grupy Podów.[4, 5]

Mechanizm działania opiera się na selektorach (labels). `Service` używa selektora etykiet do dynamicznego monitorowania, które Pody w klastrze pasują do jego definicji i są w stanie "zdrowym". Jednocześnie komponent `kube-proxy` (lub jego odpowiednik w nowszych implementacjach OVN-Kubernetes) na każdym węźle w klastrze programuje lokalne reguły sieciowe (np. `iptables` lub `IPVS`). Reguły te przechwytują ruch skierowany na wirtualny IP (`ClusterIP`) usługi i rozkładają go (load balancing) pomiędzy aktualnie dostępne Pody pasujące do selektora.[1, 5]

### 1.2 Analiza `ClusterIP` (Domyślny Typ)

`ClusterIP` jest domyślnym i najczęściej używanym typem `Service`.[4, 6] Jak sama nazwa wskazuje, platforma przydziela mu wewnętrzny, klastrowy adres IP, który jest osiągalny *wyłącznie* z wnętrza klastra.[7, 8] Żaden klient spoza klastra OpenShift nie może bezpośrednio odwołać się do tego adresu.

**Główny Przypadek Użycia:**
`ClusterIP` jest kręgosłupem komunikacji "wschód-zachód" (intra-cluster).[9] Jest to standardowy sposób, w jaki mikrousługi wdrożone na platformie komunikują się ze sobą.[10] Typowe scenariusze obejmują:

  * Pody `frontend` komunikujące się z usługą `backend` wystawioną jako `Service` typu `ClusterIP`.
  * Pody `backend` komunikujące się z bazą danych (np. PostgreSQL, Redis) również wystawioną jako `Service` typu `ClusterIP`.

Poniżej znajduje się koncepcyjny przykład definicji YAML dla usługi `ClusterIP`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-internal-backend
spec:
  # 'type: ClusterIP' jest domyślny, więc ta linia jest opcjonalna
  type: ClusterIP 
  selector:
    app: my-backend # Mapuje ten Service na Pody z etykietą 'app: my-backend'
  ports:
  - protocol: TCP
    port: 8080       # Port, na którym Service nasłuchuje (VIP:8080)
    targetPort: 8080 # Port, na którym nasłuchują docelowe Pody
```

### 1.3 Analiza `NodePort` (Wystawianie na Węźle)

`Service` typu `NodePort` jest logicznym rozszerzeniem typu `ClusterIP`.[3, 6] Po jego utworzeniu, platforma automatycznie wykonuje dwie czynności:

1.  Tworzy `Service` typu `ClusterIP`, aby zapewnić dostępność usługi wewnątrz klastra.
2.  Dodatkowo, otwiera statyczny port (z domyślnego zakresu 30000-32767) na adresie IP *każdego* węzła (Node) w klastrze.[3, 11, 12]

**Przepływ Ruchu:**
Klient zewnętrzny może teraz uzyskać dostęp do usługi, wysyłając ruch na adres `$http://<IP_dowolnego_węzła>:<NodePort>$.` Ruch ten jest następnie przechwytywany przez `kube-proxy` na tym węźle i przekierowywany do wewnętrznego `ClusterIP` usługi, a następnie do jednego z docelowych Podów.[10]

**Główny Przypadek Użycia:**
`NodePort` jest rzadko używany w środowiskach produkcyjnych. Jego głównym zastosowaniem jest **debugowanie i szybkie testowanie**.[9, 13] Pozwala deweloperom lub administratorom na natychmiastowe sprawdzenie, czy aplikacja działa, bez konieczności konfigurowania skomplikowanego routingu L7 (Ingress/Route).

**Ograniczenia Produkcyjne:**

  * **Bezpieczeństwo:** Otwieranie losowych, wysokich portów na wszystkich węzłach jest poważnym wyzwaniem dla zespołów bezpieczeństwa i zarządzania zaporami sieciowymi.
  * **Brak HA (High Availability) po stronie klienta:** Klient musi "wiedzieć", na który adres IP węzła ma trafić. Jeśli ten konkretny węzeł ulegnie awarii, połączenie zostanie zerwane (chyba że klient ma własny, zewnętrzny mechanizm load balancingu).
  * **Zarządzanie Portami:** Ręczne zarządzanie pulą portów 30000-32767 w celu uniknięcia kolizji jest niepraktyczne na dużą skalę.[3]

### 1.4 Analiza `LoadBalancer` i Kontekst "OCP Local"

Typ `LoadBalancer` stanowi najwyższy poziom hierarchii `Service`, będąc rozszerzeniem typu `NodePort`.[3, 6] Po jego utworzeniu, platforma automatycznie tworzy `NodePort` oraz `ClusterIP`, ale dodatkowo wykonuje *trzecią*, kluczową czynność: komunikuje się z API zewnętrznego dostawcy chmury (Cloud Provider) w celu dynamicznego utworzenia i skonfigurowania *zewnętrznego* load balancera L4 (np. AWS Elastic Load Balancer, Azure Load Balancer, GCP Network Load Balancer).[5, 13]

Ten zewnętrzny load balancer otrzymuje publiczny, stabilny adres IP i jest automatycznie konfigurowany tak, aby kierować ruch do portów `NodePort` otwartych na węzłach klastra.

**Problem w "OCP Local" (zgodny z zapytaniem):**
Mechanizm `type: LoadBalancer` działa w oparciu o fundamentalne założenie, że klaster działa w chmurze publicznej, która posiada API do rezerwowania zasobów sieciowych.[13, 14]

W środowiskach lokalnych (on-premise), takich jak OCP Local, vSphere, czy instalacje bare-metal, **nie ma takiego "dostawcy chmury"**. Utworzenie `Service` typu `LoadBalancer` w takim środowisku spowoduje, że obiekt ten utknie w stanie `Pending`. Będzie on w nieskończoność oczekiwał na zewnętrzny adres IP, który nigdy nie zostanie mu przypisany, ponieważ brakuje komponentu, który mógłby na to żądanie odpowiedzieć.[15]

**Rozwiązanie dla On-Premise (MetalLB):**
Aby zasymulować funkcjonalność chmurową w środowiskach on-premise, administratorzy muszą zainstalować dodatkowy kontroler, taki jak **MetalLB**. MetalLB (zazwyczaj instalowany jako Operator w OCP) monitoruje API Kubernetes.[15, 16, 17] Gdy wykryje żądanie utworzenia `Service` typu `LoadBalancer`, przejmuje rolę "dostawcy chmury", rezerwuje adres IP ze wstępnie skonfigurowanej puli adresów (którą zarządza) i przypisuje go do usługi, kończąc proces.[16]

### 1.5 Wnioski i Analiza (Sekcja 1)

Typy `Service` Kubernetes nie są trzema odrębnymi bytami, lecz stanowią **hierarchiczną piramidę ekspozycji**.[3, 6] Zrozumienie tej zależności jest kluczowe do debugowania sieci:

  * `LoadBalancer` (poziom chmury) *zawiera w sobie* `NodePort`.
  * `NodePort` (poziom węzła) *zawiera w sobie* `ClusterIP`.
  * `ClusterIP` (poziom klastra) jest fundamentem.

Problem z `type: LoadBalancer` w środowiskach on-premise [15] jest fundamentalnym powodem, dla którego platforma OpenShift od samego początku tak mocno inwestowała w **abstrakcję L7 (Warstwy 7)**, czyli obiekt `Route`. `Route` (omawiany w następnej sekcji) pozwala na elegancką, opartą na DNS ekspozycję aplikacji HTTP/S, całkowicie omijając problematykę provisioningu load balancerów L4, co jest idealnym rozwiązaniem dla wdrożeń lokalnych i hybrydowych.

**Tabela 1: Porównanie Typów `Service` Kubernetes**

| Typ Usługi | Dostępność | Automatyzacja Zewnętrznego IP | Domyślny? | Główny Przypadek Użycia |
| :--- | :--- | :--- | :--- | :--- |
| **`ClusterIP`** | Tylko wewnątrz klastra | Brak | **Tak** | Komunikacja Wschód-Zachód (np. frontend do backend) [9, 10] |
| **`NodePort`** | Wewnętrzna ORAZ Zewnętrzna (przez `NodeIP:Port`) | Brak | Nie | Debugowanie, szybkie testy [9, 13] |
| **`LoadBalancer`** | Wewnętrzna ORAZ Zewnętrzna (przez stabilny VIP) | Wymaga dostawcy chmury lub MetalLB [13, 15] | Nie | Produkcyjna ekspozycja usług L4 w chmurze [9] |

-----

## Lekcja 4.2: Route – Brama OCP do Świata

Podczas gdy `Service` zapewnia fundamentalną łączność L4, nie jest rozwiązaniem wystarczającym do wystawiania aplikacji webowych (L7) na świat. Standardową odpowiedzią Kubernetes na ten problem jest obiekt `Ingress`.[1] OpenShift dostarcza jednak własne, bardziej zintegrowane rozwiązanie: `Route`.

### 2.1 `Route` kontra `Ingress`: Kontekst Architektoniczny

Standardowy obiekt `Ingress` w Kubernetes jest jedynie *specyfikacją API*. Definiuje on, *jak* ruch HTTP/S ma być kierowany (np. routing oparty na hoście lub ścieżce), ale sam w sobie nie *realizuje* tego routingu. Aby `Ingress` zadziałał, administrator musi ręcznie wybrać, zainstalować i skonfigurować oddzielną *implementację* – tak zwany Ingress Controller (np. Nginx Ingress Controller, Traefik).

Obiekt `Route` w OpenShift (z API `route.openshift.io/v1`) jest historycznie starszy niż `Ingress`. Jak zaznaczono w zapytaniu, jest on "głębiej zintegrowany" z platformą.[18]

Kluczowa różnica polega na tym, że OpenShift dostarcza nie tylko API (`Route`), ale także w pełni zintegrowaną, zarządzaną przez platformę, działającą "out-of-the-box" implementację tego API (OpenShift Router).[18] Co ważne, nowoczesne wersje OpenShift wspierają *oba* obiekty (`Route` i `Ingress`), a domyślny OpenShift Router jest w stanie realizować reguły zdefiniowane w obu tych obiektach.[18]

### 2.2 Anatomia Architektury: OpenShift Router i Ingress Operator

Architektura routingu w OCP składa się z dwóch kluczowych komponentów, które realizują logikę obiektu `Route`:

1.  **Ingress Operator:** Jest to jeden z podstawowych Operatorów platformy OCP. Jego zadaniem jest wdrażanie, zarządzanie cyklem życia (aktualizacje, skalowanie) i konfiguracja Kontrolerów Ingress w klastrze.[18]
2.  **Ingress Controller (OpenShift Router):** Jest to faktyczne wdrożenie (Deployment) Podów, które realizują routing L7. Domyślną i wysoce zoptymalizowaną implementacją używaną przez OpenShift jest **HAProxy**.[18, 19, 20, 21]

Przepływ pracy jest w pełni zautomatyzowany:

1.  Deweloper lub proces CI/CD tworzy obiekt `Route` w API OpenShift.
2.  Pody `Ingress Controller` (HAProxy) stale monitorują (ang. *watch*) API OCP w poszukiwaniu nowych lub zmienionych obiektów `Route` oraz powiązanych z nimi obiektów `Endpoints`.[19]
3.  Gdy kontroler wykryje nowy `Route`, dynamicznie i bezprzerwowo (gracefully) regeneruje swoją wewnętrzną konfigurację (`haproxy.cfg`).
4.  Ruch zewnętrzny, trafiający na Pody routera HAProxy, jest natychmiast kierowany do docelowej aplikacji zgodnie z nowo zdefiniowaną regułą.

### 2.3 Mechanika Połączenia: Jak `Route` łączy się z `Service` (L7 -\> L4)

Zrozumienie przepływu ruchu jest kluczowe: `Route` *nie* wysyła ruchu bezpośrednio do Podów. Łączy on świat zewnętrzny (L7) ze światem wewnętrznym (L4).

1.  **`Route` (L7):** Mapuje zewnętrzny, publiczny `hostname` (np. `aplikacja.example.com`) na wewnętrzny `Service` (L4) w obrębie projektu.[19, 22]
2.  **`Service` (L4):** Mapuje swój stabilny `ClusterIP` na dynamiczną listę obiektów `Endpoints`, które reprezentują aktualne adresy IP Podów.[23]

Pełny przepływ pakietu dla żądania HTTP wygląda następująco:

1.  Klient (przeglądarka) wysyła żądanie `GET http://aplikacja.example.com`.
2.  Zewnętrzny DNS rozwiązuje nazwę `aplikacja.example.com` na publiczny adres IP OpenShift Routera (Poda HAProxy).
3.  Router (HAProxy) otrzymuje żądanie. Analizuje nagłówek `Host` (Warstwa 7).
4.  W swojej konfiguracji znajduje pasujący `Route`, który mówi: "ruch dla `aplikacja.example.com` ma być skierowany do usługi o nazwie `my-app-service`".[22, 24, 25]
5.  Router (HAProxy), będąc inteligentnym kontrolerem, pobiera listę `Endpoints` (adresów IP Podów) powiązanych z `my-app-service` i wykonuje load balancing, wysyłając żądanie *bezpośrednio* do jednego z docelowych Podów.

Ta kluczowa optymalizacja (krok 5) – gdzie router omija wirtualny IP usługi (`ClusterIP`) i `kube-proxy`, kierując ruch bezpośrednio do Podów – redukuje opóźnienia sieciowe i pozwala na implementację zaawansowanych funkcji L7, takich jak sesje lepkie (sticky sessions).[26]

### 2.4 Automatyczne Generowanie: `oc expose`

OpenShift zdaje sobie sprawę, że ręczne tworzenie plików YAML dla każdej usługi jest czasochłonne. Dlatego platforma oferuje polecenie `oc expose`, które automatyzuje tworzenie `Route` na podstawie istniejącego `Service`.[27, 28, 29, 30]

**Proste Użycie:**
`$ oc expose svc/my-app-service`

To polecenie wykonuje kilka czynności [29, 30]:

1.  Tworzy nowy obiekt `Route` w projekcie.
2.  Konfiguruje `Route` tak, aby wskazywał na `Service` o nazwie `my-app-service`.[22]
3.  Ponieważ nie podano `hostname`, OCP automatycznie wygeneruje unikalny FQDN dla tej trasy, używając domyślnej domeny aplikacji klastra (np. `my-app-service-nazwa-projektu.apps.ocp.example.com`).[31]

Polecenie to może być również użyte do tworzenia zabezpieczonych tras, na przykład przy użyciu `oc create route`, co zostanie omówione w następnej sekcji.[31, 32]

```yaml
# Przykładowy YAML wygenerowany przez 'oc expose'
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: my-app-service
spec:
  # Hostname wygenerowany automatycznie przez OCP
  host: my-app-service-default.apps.ocp.example.com 
  to:
    kind: Service
    name: my-app-service # Wskazuje na nasz Service
  port:
    targetPort: 8080 # Port docelowy pobrany z Service
```

### 2.5 Wnioski i Analiza (Sekcja 2)

Architektura `Route` w OCP demonstruje klarowną **separację ról**. Deweloperzy aplikacji są odpowiedzialni za definiowanie, *co* chcą wystawić (`Service`) i *jak* ma być ono dostępne z zewnątrz (`Route`). Administratorzy Platformy są odpowiedzialni za *infrastrukturę*, która to umożliwia – zarządzają `Ingress Operator`, konfigurują domyślne domeny (`*.apps`) i skalują Pody routera.

Głęboka integracja, o której mowa w zapytaniu, oznacza, że OpenShift Router (HAProxy) jest komponentem *zarządzanym przez platformę*.[18, 19] Jest on automatycznie monitorowany, aktualizowany i zabezpieczany w ramach cyklu życia OCP. To radykalnie odróżnia OCP od standardowego Kubernetes, gdzie Ingress Controller jest często traktowany jak "obcy" dodatek, za którego pełne utrzymanie odpowiada administrator.

-----

## Lekcja 4.3: Terminacja TLS – Zarządzanie Bezpieczeństwem na Krawędzi Klastra

Wystawienie aplikacji na świat za pomocą `Route` to tylko połowa sukcesu. W środowiskach produkcyjnych ruch musi być szyfrowany. Obiekt `Route` w OpenShift posiada wbudowane, pierwszorzędne wsparcie dla zarządzania szyfrowaniem (TLS), oferując trzy różne strategie terminacji.[33, 34, 35] "Terminacja TLS" odnosi się do *miejsca* w łańcuchu sieciowym, w którym szyfrowana sesja HTTPS jest "rozpakowywana" (deszyfrowana) i przetwarzana.

### 3.2 Terminacja `Edge` (Najczęstsza)

Terminacja typu `Edge` (krawędziowa) jest najczęstszym i najbardziej zrównoważonym podejściem.[22, 36]

**Przepływ Ruchu [37, 38]:**
`(Klient)` --(HTTPS, Szyfrowane)--\> `(OpenShift Router [HAProxy])` --(HTTP, Nieszyfrowane)--\> `(Service -> Pod)`

**Jak to działa:**

1.  Klient (przeglądarka) ustanawia w pełni szyfrowaną sesję HTTPS (TLS) z OpenShift Routerem.
2.  Router używa certyfikatu i klucza prywatnego zdefiniowanego w obiekcie `Route`, aby zakończyć (zterminować) sesję TLS i zdeszyfrować żądanie.[39]
3.  Router, mając teraz dostęp do nieszyfrowanego żądania L7, może podejmować inteligentne decyzje (np. routing oparty na ścieżce, wstrzykiwanie nagłówków).
4.  Na koniec, router przekazuje żądanie jako *zwykły, nieszyfrowany HTTP* do docelowego Poda (poprzez `Service`).

**Przypadek Użycia:** Standard dla większości aplikacji webowych. Zapewnia pełne bezpieczeństwo w publicznym internecie, jednocześnie odciążając Pody aplikacji od kosztownego obliczeniowo procesu deszyfrowania TLS. Model ten zakłada, że wewnętrzna sieć klastra (SDN) jest zaufana.

**YAML (`oc create route edge...`) [39]:**

```yaml
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: edge-secured-route
spec:
  host: app.example.com
  to:
    kind: Service
    name: my-app-service
  tls:
    termination: edge # Kluczowy wpis
    key: |-
      -----BEGIN PRIVATE KEY-----
      [...]
      -----END PRIVATE KEY-----
    certificate: |-
      -----BEGIN CERTIFICATE-----
      [...]
      -----END CERTIFICATE-----
```

### 3.3 Terminacja `Passthrough` (Przelotowa)

Terminacja `Passthrough` reprezentuje zupełnie inne podejście.[22, 36]

**Przepływ Ruchu [37, 40]:**
`(Klient)` --(HTTPS, Szyfrowane)--\> `(Router)` --(HTTPS, Wciąż Szyfrowane)--\> `(Service -> Pod)`

**Jak to działa:**

1.  OpenShift Router *nie dotyka* ruchu TLS.[39, 40] Działa na warstwie L4 (jak prosty forwarder TCP), przekazując zaszyfrowane pakiety bezpośrednio do Poda.
2.  Cała sesja TLS jest negocjowana bezpośrednio między klientem a docelowym Podem.
3.  Oznacza to, że to *Pod* musi posiadać odpowiedni certyfikat i klucz prywatny oraz być skonfigurowany do obsługi HTTPS.[39]

**Przypadki Użycia:**

1.  **mTLS (Mutual TLS):** Główny powód użycia. Wymagane, gdy aplikacja (Pod) musi zweryfikować certyfikat *klienta* (uwierzytelnianie dwukierunkowe).[37, 39] W trybie `Edge`, Router zakończyłby sesję TLS, zanim Pod miałby szansę zobaczyć certyfikat klienta.
2.  Niestandardowe protokoły oparte na TLS lub aplikacje z własną, sztywno zakodowaną logiką certyfikatów.

**Ograniczenia:** Ponieważ router jest "ślepy" na ruch (nie widzi L7), większość zaawansowanych funkcji routingu, takich jak routing oparty na ścieżce (`/foo`), sticky sessions czy wstrzykiwanie nagłówków, nie działa.

**YAML (`oc create route passthrough...`) [39]:**

```yaml
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: passthrough-route
spec:
  host: app-with-mtls.example.com
  to:
    kind: Service
    name: my-mtls-service
  tls:
    termination: passthrough # Kluczowy wpis
    # Brak certyfikatów - router ich nie potrzebuje
```

### 3.4 Terminacja `Re-encrypt` (Ponowne Szyfrowanie)

Terminacja `Re-encrypt` zapewnia najbardziej kompleksowe bezpieczeństwo, często wymagane przez standardy zgodności (compliance).[22, 36]

**Przepływ Ruchu [37, 40]:**
`(Klient)` --(HTTPS [Certyfikat 1], Szyfrowane)--\> `(Router)`
`(Router)` --(HTTPS [Certyfikat 2], Szyfrowane)--\> `(Service -> Pod)`

**Jak to działa:** Jest to hybryda łącząca zalety obu poprzednich metod:

1.  Router termin\_uje\_ sesję TLS od klienta (używając publicznego certyfikatu `Cert 1`), tak jak w trybie `Edge`. Pozwala mu to na inspekcję ruchu L7.[40]
2.  Następnie Router *ponownie szyfruje* ruch, inicjując nową sesję TLS (używając innego, zazwyczaj wewnętrznego certyfikatu `Cert 2`), zanim wyśle go do Poda.[39]

**Przypadek Użycia:** Środowiska o najwyższych wymaganiach bezpieczeństwa i zgodności (np. PCI, HIPAA), które *zabraniają* przesyłania jakiegokolwiek nieszyfrowanego ruchu, nawet w "zaufanej" sieci wewnętrznej.[37] Rozwiązuje to problem "ostatniej mili" (last mile security), który występuje w trybie `Edge`, jednocześnie zachowując inteligencję L7 routera.

**Wymagania:** Jest to najbardziej złożony operacyjnie tryb. Wymaga zarządzania dwoma zestawami certyfikatów: jednym dla routera (widocznym dla klienta) i drugim dla Poda (używanym do komunikacji router-Pod).

**YAML (`oc create route reencrypt...`) [39]:**

```yaml
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: reencrypt-route
spec:
  host: highly-secure-app.example.com
  to:
    kind: Service
    name: my-secure-service
  tls:
    termination: reencrypt # Kluczowy wpis
    # Certyfikat dla klienta (jak w Edge)
    key:...
    certificate:...
    # Dodatkowo, certyfikat CA do weryfikacji Poda
    destinationCACertificate: |-
      -----BEGIN CERTIFICATE-----
      [...] (Certyfikat CA, który podpisał certyfikat Poda)
      -----END CERTIFICATE-----
```

### 3.5 Wnioski i Analiza (Sekcja 3)

Wybór strategii terminacji TLS to spektrum kompromisów pomiędzy bezpieczeństwem, wydajnością a złożonością operacyjną. Sama obecność opcji `Re-encrypt` jako wbudowanej, pierwszorzędnej funkcji pokazuje, że OpenShift został zaprojektowany z myślą o rygorystycznych wymaganiach korporacyjnych i rządowych, dla których prostota trybu `Edge` jest niewystarczająca.

**Tabela 2: Porównanie Strategii Terminacji TLS w OpenShift Route**

| Strategia | Terminacja Klienta | Ruch Wewnętrzny (Router -\> Pod) | Wymagania Certyfikatów | Główny Przypadek Użycia |
| :--- | :--- | :--- | :--- | :--- |
| **`Edge`** | Na Routerze | **HTTP** (Nieszyfrowany) [37] | Tylko na Routerze | Standardowe aplikacje webowe |
| **`Passthrough`** | Na Podzie | **HTTPS** (Szyfrowany) [37] | Tylko na Podzie | mTLS, niestandardowe protokoły [37, 39] |
| **`Re-encrypt`** | Na Routerze | **HTTPS** (Ponownie szyfrowany) [37] | Router (Cert 1) + Pod (Cert 2) | Wysoka zgodność (PCI, HIPAA), Zero Trust [37] |

-----

## Lekcja 4.4: Podstawy NetworkPolicy w Praktyce – Izolacja Podów

Po zabezpieczeniu ruchu "północ-południe" (z zewnątrz do klastra) za pomocą `Route` i TLS, ostatnim filarem jest zabezpieczenie ruchu "wschód-zachód" (wewnątrz klastra) za pomocą `NetworkPolicy`.

### 4.1 Domyślna Polityka Sieciowa OCP: Tryb `multitenant`

Standardowy Kubernetes domyślnie posiada "płaską" sieć. Oznacza to, że każdy Pod w dowolnej przestrzeni nazw (Namespace) może komunikować się z każdym innym Podem w klastrze. Jest to model "allow-all" (zezwalaj na wszystko).

OpenShift od samego początku przyjął filozofię "bezpieczny domyślnie" (secure-by-default), odwracając ten model. Zapytanie odnosi się do domyślnego trybu `multitenant`, który historycznie był domyślnym trybem OpenShift SDN (Software Defined Network).[41, 42]

Logika trybu `multitenant` jest prosta, ale potężna [41]:

1.  **Ruch *wewnątrz* projektu (Namespace):** `allow-all`. Pody w tym samym projekcie mogą swobodnie komunikować się ze sobą.
2.  **Ruch *pomiędzy* projektami:** `deny-all`. Pod z Projektu A *nie może* domyślnie komunikować się z Podem z Projektu B.[42, 43, 44]

To domyślne zachowanie `deny-all` między projektami jest fundamentalną cechą bezpieczeństwa OCP. Zapewnia natychmiastową izolację dzierżawców (tenantów) – zespołów lub aplikacji – bez konieczności stosowania jakiejkolwiek dodatkowej konfiguracji.

### 4.2 Ewolucja: Tryb `multitenant` vs. Tryb `networkpolicy`

Tryb `multitenant` był specyficzną, wbudowaną w OCP implementacją (w ramach OpenShift SDN). W miarę dojrzewania ekosystemu Kubernetes, wprowadzono standardowy, natywny obiekt `NetworkPolicy` API (`networking.k8s.io/v1`).[45]

Nowoczesne wersje OCP (np. 4.6+) oraz domyślna wtyczka sieciowa OVN-Kubernetes, domyślnie używają trybu `networkpolicy`.[42, 46, 47, 48]

Obserwujemy tu konwergencję standardów. OCP przeszło z własnego, "sztywnego" modelu izolacji międzyprojektowej (`multitenant`) na standardowy, *elastyczny* model K8s (`networkpolicy`). Sam tryb `networkpolicy` nie blokuje niczego domyślnie (jest to `allow-all`), *dopóki* nie zastosuje się pierwszego obiektu `NetworkPolicy`.

Niezależnie od domyślnego trybu, do *segmentacji wewnątrz projektu* (np. izolowania `frontend` od `backend` w tym samym projekcie), administratorzy *zawsze* używają standardowych obiektów `NetworkPolicy` K8s.

### 4.3 Anatomia Obiektu `NetworkPolicy` K8s

Obiekty `NetworkPolicy` działają na zasadzie "Zero Trust" i białej listy (allow-list).[49] Ich logikę definiuje jedna, złota zasada:

**Złota Zasada `NetworkPolicy`:** W momencie, gdy jakikolwiek obiekt `NetworkPolicy` *wybierze* Poda (za pomocą `podSelector`), ten Pod natychmiast staje się `deny-all` dla *wszystkiego* (ruchu przychodzącego i/lub wychodzącego), z wyjątkiem tego ruchu, który jest *jawnie* dozwolony w regułach tego obiektu.[48, 50]

Kluczowe pola w specyfikacji `NetworkPolicy`:

  * `podSelector`: Wybiera Pody, których dotyczy polityka. Pusty selektor (`{}`) wybiera wszystkie Pody w danym projekcie.[51]
  * `policyTypes`: Określa, czy polityka dotyczy ruchu przychodzącego (`Ingress`), wychodzącego (`Egress`), czy obu.
  * `ingress`: Definiuje reguły dla ruchu przychodzącego (Kto może łączyć się *DO* tego Poda?).
  * `egress`: Definiuje reguły dla ruchu wychodzącego (Gdzie ten Pod może łączyć się *NA ZEWNĄTRZ*?).

### 4.4 Praktyczny Przykład: Izolacja `frontend` -\> `backend`

Rozważmy scenariusz z zapytania: w ramach jednego projektu mamy Pody `frontend` (z etykietą `app: frontend`) oraz Pody `backend` (z etykietą `app: backend`). Chcemy zezwolić na ruch z `frontend` do `backend`, ale zablokować wszelki inny ruch (np. bezpośredni dostęp z `frontend` do `database` lub dostęp z zewnątrz do `backend`).

Zakładamy, że działamy w trybie `networkpolicy` i domyślnie panuje `allow-all`.

**Krok 1: Wdrożenie Dobrej Praktyki - Domyślna Blokada (Default Deny) w Projekcie**
Zanim zaczniemy cokolwiek zezwalać, najlepszą praktyką jest zablokowanie wszystkiego. Stosujemy politykę, która wybiera wszystkie Pody i nie definiuje żadnych reguł `ingress`/`egress`, skutecznie izolując wszystko.[51, 52]

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {} # Wybierz wszystkie Pody w projekcie
  policyTypes:
  - Ingress
  - Egress
  ingress: # Nie zezwalaj na żaden ruch przychodzący
  egress:  # Nie zezwalaj na żaden ruch wychodzący
```

*Po zastosowaniu tej polityki, Pody `frontend` i `backend` nie mogą się ze sobą komunikować.*

**Krok 2: Polityka Ingress dla `backend` [53]**
Teraz musimy jawnie otworzyć ruch. Tworzymy politykę, która "mówi": "Pody `backend` mogą przyjmować ruch *tylko* z Podów `frontend`".

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
spec:
  podSelector:
    matchLabels:
      app: backend # Stosuj tę politykę do Podów 'backend'
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend # Zezwól na ruch Z Podów 'frontend'
    ports: # Opcjonalnie: zezwól tylko na konkretny port
    - protocol: TCP
      port: 8080
```

**Krok 3: Polityka Egress dla `frontend` [53]**
Polityka z Kroku 2 nie wystarczy. Domyślna blokada (Krok 1) wciąż blokuje ruch *wychodzący* (Egress) z `frontend`. Musimy stworzyć drugą politykę: "Pody `frontend` mogą wysyłać ruch *tylko* do Podów `backend`".

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-policy
spec:
  podSelector:
    matchLabels:
      app: frontend # Stosuj tę politykę do Podów 'frontend'
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: backend # Zezwól na ruch DO Podów 'backend'
    ports:
    - protocol: TCP
      port: 8080
```

**Wynik:** Po zastosowaniu tych trzech polityk, osiągnęliśmy granulowaną kontrolę:

  * `frontend` -\> `backend` (Dozwolone)
  * `frontend` -\> `database` (Zablokowane przez `frontend-policy` Egress)
  * `inny-pod` -\> `backend` (Zablokowane przez `backend-policy` Ingress)

### 4.5 Wnioski i Analiza (Sekcja 4)

Domyślny tryb `multitenant` w OCP [42, 43] był wczesnym, specyficznym dla platformy rozwiązaniem problemu "płaskiej sieci" K8s i kluczowym argumentem sprzedażowym dla przedsiębiorstw wymagających wielodostępności. Przejście OCP na standardowy tryb `networkpolicy` [42, 48] jest sygnałem dojrzałości ekosystemu Kubernetes, który obecnie dostarcza elastycznych narzędzi do realizacji tych samych (i bardziej złożonych) celów bezpieczeństwa.

Wiele zespołów koncentruje się wyłącznie na politykach `ingress` (ochrona serwera). Powyższy przykład pokazuje, że polityki `egress` (kontrola ruchu wychodzącego) są równie krytyczne. Ograniczając, dokąd Pod `frontend` może wysyłać ruch, drastycznie zmniejszamy potencjalny "promień rażenia" (blast radius) w przypadku, gdyby Pod `frontend` został skompromitowany.[52]

## Wnioski Końcowe

Architektura sieciowa OpenShift stanowi kompletny, wielowarstwowy system obronny (defense-in-depth), który wykracza daleko poza standardowe komponenty Kubernetes. Cztery filary przeanalizowane w tym raporcie – `Service`, `Route`, Terminacja TLS i `NetworkPolicy` – łączą się, tworząc spójny model zarządzania ruchem:

1.  **`Service`** (`ClusterIP`, `NodePort`) tworzy stabilny, wewnętrzny szkielet L4 dla komunikacji między mikrousługami. Ograniczenia `LoadBalancer` w środowiskach on-premise [15] naturalnie prowadzą do konieczności zastosowania bardziej zaawansowanego rozwiązania L7.
2.  **`Route`** (`route.openshift.io/v1`) wypełnia tę lukę, dostarczając zintegrowane z platformą, oparte na HAProxy rozwiązanie L7, które jest w pełni zarządzane przez `Ingress Operator` [18] i gotowe do użytku "out-of-the-box".
3.  **Strategie Terminacji TLS** (`Edge`, `Passthrough`, `Re-encrypt`) zapewniają elastyczność niezbędną do sprostania różnorodnym wymaganiom bezpieczeństwa – od prostych aplikacji webowych po systemy o rygorystycznej zgodności (compliance), wymagające szyfrowania end-to-end.[37]
4.  **`NetworkPolicy`** (wraz z domyślną izolacją międzyprojektową OCP) przenosi filozofię Zero Trust do wnętrza klastra, umożliwiając administratorom rygorystyczną kontrolę ruchu "wschód-zachód" i segmentację aplikacji, co jest kluczowe dla ograniczenia ryzyka w przypadku naruszenia bezpieczeństwa.[52]

Razem, te cztery komponenty pozwalają platformie OpenShift dostarczyć na obietnicę bycia nie tylko "dystrybucją Kubernetes", ale zintegrowaną, bezpieczną domyślnie platformą aplikacyjną klasy korporacyjnej.
#### **Cytowane prace**

1. Services, Load Balancing, and Networking \- Kubernetes, otwierano: listopada 14, 2025, [https://kubernetes.io/docs/concepts/services-networking/](https://kubernetes.io/docs/concepts/services-networking/)  
2. Connecting Applications with Services \- Kubernetes, otwierano: listopada 14, 2025, [https://kubernetes.io/docs/tutorials/services/connect-applications-service/](https://kubernetes.io/docs/tutorials/services/connect-applications-service/)  
3. Understand Kubernetes Services | GKE networking \- Google Cloud Documentation, otwierano: listopada 14, 2025, [https://docs.cloud.google.com/kubernetes-engine/docs/concepts/service](https://docs.cloud.google.com/kubernetes-engine/docs/concepts/service)  
4. Kubernetes Services: ClusterIP, Nodeport and LoadBalancer | Sysdig, otwierano: listopada 14, 2025, [https://www.sysdig.com/blog/kubernetes-services-clusterip-nodeport-loadbalancer](https://www.sysdig.com/blog/kubernetes-services-clusterip-nodeport-loadbalancer)  
5. Service | Kubernetes, otwierano: listopada 14, 2025, [https://kubernetes.io/docs/concepts/services-networking/service/](https://kubernetes.io/docs/concepts/services-networking/service/)  
6. Difference between ClusterIP, NodePort and LoadBalancer service types in Kubernetes?, otwierano: listopada 14, 2025, [https://stackoverflow.com/questions/41509439/difference-between-clusterip-nodeport-and-loadbalancer-service-types-in-kuberne](https://stackoverflow.com/questions/41509439/difference-between-clusterip-nodeport-and-loadbalancer-service-types-in-kuberne)  
7. Using a Service to Expose Your App | Kubernetes, otwierano: listopada 14, 2025, [https://kubernetes.io/docs/tutorials/kubernetes-basics/expose/expose-intro/](https://kubernetes.io/docs/tutorials/kubernetes-basics/expose/expose-intro/)  
8. Service ClusterIP allocation | Kubernetes, otwierano: listopada 14, 2025, [https://kubernetes.io/docs/concepts/services-networking/cluster-ip-allocation/](https://kubernetes.io/docs/concepts/services-networking/cluster-ip-allocation/)  
9. ClusterIP vs NodePort vs LoadBalancer: Key Differences & When to ..., otwierano: listopada 14, 2025, [https://kodekloud.com/blog/clusterip-nodeport-loadbalancer/](https://kodekloud.com/blog/clusterip-nodeport-loadbalancer/)  
10. Services NodePort \- KodeKloud Notes, otwierano: listopada 14, 2025, [https://notes.kodekloud.com/docs/kubernetes-for-the-absolute-beginners-hands-on-tutorial/Services/Services-NodePort](https://notes.kodekloud.com/docs/kubernetes-for-the-absolute-beginners-hands-on-tutorial/Services/Services-NodePort)  
11. Kubernetes Service Types: ClusterIP vs. NodePort vs. LoadBalancer vs. Headless, otwierano: listopada 14, 2025, [https://edgedelta.com/company/blog/kubernetes-services-types](https://edgedelta.com/company/blog/kubernetes-services-types)  
12. Kubernetes \- NodePort Service \- GeeksforGeeks, otwierano: listopada 14, 2025, [https://www.geeksforgeeks.org/devops/kubernetes-nodeport-service/](https://www.geeksforgeeks.org/devops/kubernetes-nodeport-service/)  
13. The Difference Between ClusterIP, NodePort, And LoadBalancer Kubernetes Services | Octopus blog, otwierano: listopada 14, 2025, [https://octopus.com/blog/difference-clusterip-nodeport-loadbalancer-kubernetes](https://octopus.com/blog/difference-clusterip-nodeport-loadbalancer-kubernetes)  
14. Exposing an External IP Address to Access an Application in a Cluster | Kubernetes, otwierano: listopada 14, 2025, [https://kubernetes.io/docs/tutorials/stateless-application/expose-external-ip-address/](https://kubernetes.io/docs/tutorials/stateless-application/expose-external-ip-address/)  
15. MetalLB on Red Hat OpenShift Local \- Reddit, otwierano: listopada 14, 2025, [https://www.reddit.com/r/openshift/comments/uo1t2o/metallb\_on\_red\_hat\_openshift\_local/](https://www.reddit.com/r/openshift/comments/uo1t2o/metallb_on_red_hat_openshift_local/)  
16. Configuring services to use MetalLB \- Load balancing with MetalLB | Networking | OKD 4.16, otwierano: listopada 14, 2025, [https://docs.okd.io/4.16/networking/metallb/metallb-configure-services.html](https://docs.okd.io/4.16/networking/metallb/metallb-configure-services.html)  
17. Understanding Openshift \`externalTrafficPolicy: local\` and Source IP Preservation, otwierano: listopada 14, 2025, [https://access.redhat.com/solutions/7028639](https://access.redhat.com/solutions/7028639)  
18. Chapter 6\. Ingress Operator in OpenShift Container Platform ..., otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.9/html/networking/configuring-ingress](https://docs.redhat.com/en/documentation/openshift_container_platform/4.9/html/networking/configuring-ingress)  
19. Chapter 5\. Networking | Architecture | OpenShift Container Platform | 3.11 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.openshift.com/container-platform/3.11/architecture/networking/routes.html](https://docs.openshift.com/container-platform/3.11/architecture/networking/routes.html)  
20. Chapter 3\. Setting up a Router | Configuring Clusters | OpenShift Container Platform | 3.11, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.11/html/configuring\_clusters/setting-up-a-router](https://docs.redhat.com/en/documentation/openshift_container_platform/3.11/html/configuring_clusters/setting-up-a-router)  
21. Chapter 4\. Setting up a Router | Installation and Configuration | OpenShift Container Platform | 3.4 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.4/html/installation\_and\_configuration/setting-up-a-router](https://docs.redhat.com/en/documentation/openshift_container_platform/3.4/html/installation_and_configuration/setting-up-a-router)  
22. OpenShift Route: Tutorial & Examples \- Densify, otwierano: listopada 14, 2025, [https://www.densify.com/openshift-tutorial/openshift-route/](https://www.densify.com/openshift-tutorial/openshift-route/)  
23. Chapter 3\. Core Concepts | Architecture | OpenShift Container Platform | 3.11, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.11/html/architecture/core-concepts](https://docs.redhat.com/en/documentation/openshift_container_platform/3.11/html/architecture/core-concepts)  
24. Routes \- F5 Cloud Docs, otwierano: listopada 14, 2025, [https://clouddocs.f5.com/containers/latest/userguide/routes.html](https://clouddocs.f5.com/containers/latest/userguide/routes.html)  
25. How to configure a route for an OpenShift app with nodeJS and express \- Stack Overflow, otwierano: listopada 14, 2025, [https://stackoverflow.com/questions/59920939/how-to-configure-a-route-for-an-openshift-app-with-nodejs-and-express](https://stackoverflow.com/questions/59920939/how-to-configure-a-route-for-an-openshift-app-with-nodejs-and-express)  
26. Openshift Route is not load balancing from Service pods \- Stack Overflow, otwierano: listopada 14, 2025, [https://stackoverflow.com/questions/54553179/openshift-route-is-not-load-balancing-from-service-pods](https://stackoverflow.com/questions/54553179/openshift-route-is-not-load-balancing-from-service-pods)  
27. Chapter 24\. Configuring Routes | Networking | OpenShift Container Platform | 4.11 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.openshift.com/container-platform/4.11/networking/routes/route-configuration.html](https://docs.openshift.com/container-platform/4.11/networking/routes/route-configuration.html)  
28. Chapter 26\. Configuring Routes | Networking | OpenShift Container Platform | 4.14 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.openshift.com/container-platform/4.14/networking/routes/route-configuration.html](https://docs.openshift.com/container-platform/4.14/networking/routes/route-configuration.html)  
29. Chapter 26\. Configuring Routes | Networking | OpenShift Container Platform | 4.14 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.14/html/networking/configuring-routes](https://docs.redhat.com/en/documentation/openshift_container_platform/4.14/html/networking/configuring-routes)  
30. Chapter 17\. Configuring Routes | Networking | OpenShift Container Platform | 4.8 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/networking/configuring-routes](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/networking/configuring-routes)  
31. Expose OpenShift Apps over HTTPS \- Pradipta Banerjee \- Medium, otwierano: listopada 14, 2025, [https://pradiptabanerjee.medium.com/expose-openshift-apps-over-https-22e301d5a6f2](https://pradiptabanerjee.medium.com/expose-openshift-apps-over-https-22e301d5a6f2)  
32. How to deploy a web service on OpenShift \- Red Hat, otwierano: listopada 14, 2025, [https://www.redhat.com/en/blog/deploy-web-service-openshift](https://www.redhat.com/en/blog/deploy-web-service-openshift)  
33. Chapter 25\. Configuring Routes | Networking | OpenShift Container Platform | 4.12 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.openshift.com/container-platform/4.12/networking/routes/route-configuration.html](https://docs.openshift.com/container-platform/4.12/networking/routes/route-configuration.html)  
34. Chapter 20\. Configuring Routes | Networking | OpenShift Container Platform | 4.10, otwierano: listopada 14, 2025, [https://docs.openshift.com/container-platform/4.10/networking/routes/route-configuration.html](https://docs.openshift.com/container-platform/4.10/networking/routes/route-configuration.html)  
35. Chapter 21\. Configuring Routes | Networking | OpenShift Container Platform | 4.16 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.openshift.com/container-platform/4.16/networking/routes/route-configuration.html](https://docs.openshift.com/container-platform/4.16/networking/routes/route-configuration.html)  
36. OpenShift \- Create secured Route using the oc create route command \- FreeKB, otwierano: listopada 14, 2025, [https://www.freekb.net/Article?id=3971](https://www.freekb.net/Article?id=3971)  
37. 3 ways to encrypt communications in protected environments with ..., otwierano: listopada 14, 2025, [https://www.redhat.com/en/blog/encryption-secure-routes-openshift](https://www.redhat.com/en/blog/encryption-secure-routes-openshift)  
38. Exposing apps with routes in Red Hat OpenShift 4 \- IBM Cloud Docs, otwierano: listopada 14, 2025, [https://cloud.ibm.com/docs/openshift?topic=openshift-openshift\_routes](https://cloud.ibm.com/docs/openshift?topic=openshift-openshift_routes)  
39. Secured routes \- Configuring Routes | Networking | OKD 4.16, otwierano: listopada 14, 2025, [https://docs.okd.io/4.16/networking/routes/secured-routes.html](https://docs.okd.io/4.16/networking/routes/secured-routes.html)  
40. OpenShift Origin V3- edge, passthrough and encrypt termination \- Stack Overflow, otwierano: listopada 14, 2025, [https://stackoverflow.com/questions/64812296/openshift-origin-v3-edge-passthrough-and-encrypt-termination](https://stackoverflow.com/questions/64812296/openshift-origin-v3-edge-passthrough-and-encrypt-termination)  
41. Chapter 9\. OpenShift SDN default CNI network provider \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.openshift.com/container-platform/4.3/networking/openshift\_sdn/multitenant-isolation.html](https://docs.openshift.com/container-platform/4.3/networking/openshift_sdn/multitenant-isolation.html)  
42. Chapter 15\. OpenShift SDN default CNI network provider \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.9/html/networking/openshift-sdn-default-cni-network-provider](https://docs.redhat.com/en/documentation/openshift_container_platform/4.9/html/networking/openshift-sdn-default-cni-network-provider)  
43. 12.13. Configuring network isolation using OpenShift SDN \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/zh-cn/documentation/openshift\_container\_platform/4.5/html/networking/configuring-multitenant-isolation](https://docs.redhat.com/zh-cn/documentation/openshift_container_platform/4.5/html/networking/configuring-multitenant-isolation)  
44. Configuring multitenant isolation \- OpenShift SDN network plugin ..., otwierano: listopada 14, 2025, [https://docs.okd.io/4.15/networking/openshift\_sdn/multitenant-isolation.html](https://docs.okd.io/4.15/networking/openshift_sdn/multitenant-isolation.html)  
45. Network Policies \- Kubernetes, otwierano: listopada 14, 2025, [https://kubernetes.io/docs/concepts/services-networking/network-policies/](https://kubernetes.io/docs/concepts/services-networking/network-policies/)  
46. Chapter 10\. Network policy | Networking | OpenShift Container Platform | 4.6 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.openshift.com/container-platform/4.6/networking/network\_policy/about-network-policy.html](https://docs.openshift.com/container-platform/4.6/networking/network_policy/about-network-policy.html)  
47. Chapter 18\. Network policy | Networking | OpenShift Container Platform | 4.12 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.openshift.com/container-platform/4.12/networking/network\_policy/about-network-policy.html](https://docs.openshift.com/container-platform/4.12/networking/network_policy/about-network-policy.html)  
48. Chapter 12\. Network policy | Networking | OpenShift Container Platform | 4.9 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.openshift.com/container-platform/4.9/networking/network\_policy/about-network-policy.html](https://docs.openshift.com/container-platform/4.9/networking/network_policy/about-network-policy.html)  
49. Network Policy \- OpenShift Examples, otwierano: listopada 14, 2025, [https://examples.openshift.pub/networking/network-policy/](https://examples.openshift.pub/networking/network-policy/)  
50. Chapter 9\. Network policy | Networking | OpenShift Container Platform | 4.5 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.openshift.com/container-platform/4.5/networking/network\_policy/about-network-policy.html](https://docs.openshift.com/container-platform/4.5/networking/network_policy/about-network-policy.html)  
51. Chapter 9\. Network policy | Networking | OpenShift Container Platform | 4.5 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.5/html/networking/network-policy](https://docs.redhat.com/en/documentation/openshift_container_platform/4.5/html/networking/network-policy)  
52. Kubernetes Network Policy: Use Cases, Examples & Tips \[2025\] \- Tigera.io, otwierano: listopada 14, 2025, [https://www.tigera.io/learn/guides/kubernetes-security/kubernetes-network-policy/](https://www.tigera.io/learn/guides/kubernetes-security/kubernetes-network-policy/)  
53. Kubernetes Network Policy: A Beginner's Guide | Okteto, otwierano: listopada 14, 2025, [https://www.okteto.com/blog/kubernetes-network-policies/](https://www.okteto.com/blog/kubernetes-network-policies/)
