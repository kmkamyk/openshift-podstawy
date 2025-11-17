# Moduł 01 (infra-01): "Pod Maską" – RHCOS i Architektura

## Lekcja 1.1: Czym jest RHCOS (Red Hat Enterprise Linux CoreOS)?

### 1.1.1. Definicja i Rola RHCOS w OpenShift 4.x

Red Hat Enterprise Linux CoreOS (RHCOS) to fundament, na którym zbudowany jest OpenShift 4.[3] Jest to system operacyjny zaprojektowany specjalnie i wyłącznie do uruchamiania kontenerów w ramach klastra OCP. Zgodnie z oficjalną dokumentacją, RHCOS jest *jedynym* wspieranym systemem operacyjnym dla węzłów Płaszczyzny Sterowania (Control Plane / Master).[4, 8] Jest również *domyślnym* i strategicznie zalecanym systemem operacyjnym dla wszystkich węzłów roboczych (Worker / Compute).[4]

W przeciwieństwie do tradycyjnego RHEL, RHCOS nie jest systemem ogólnego przeznaczenia. Jest to system *w pełni zarządzany* przez sam klaster OpenShift.[3] Oznacza to, że aktualizacje systemu operacyjnego, jego konfiguracja oraz zarządzanie stanem są integralną częścią procesów zarządzania klastrem, kontrolowanych przez dedykowane Operatory Infrastrukturalne.[3, 9] RHCOS łączy filozofię atomowych aktualizacji i niezmienności, wywodzącą się z projektu CoreOS (przejętego przez Red Hat), z bezpieczeństwem i fundamentem pakietów RPM pochodzących z RHEL.[2, 8, 10]

### 1.1.2. Uzasadnienie Wyboru: Dlaczego OCP 4.x działa na RHCOS, a nie na standardowym RHEL?

Decyzja o oparciu OCP 4 na RHCOS zamiast na standardowym RHEL była bezpośrednią odpowiedzią na wyzwania operacyjne OCP 3.x.[1] W modelu OCP 3 administratorzy musieli oddzielnie zarządzać cyklem życia systemu RHEL (hardening, aktualizacje pakietów, konfiguracja) oraz cyklem życia platformy OCP. Ten podwójny tor zarządzania był głównym źródłem problemów.

Głównym problemem był "dryf konfiguracyjny". Ręczna zmiana konfiguracji na jednym z węzłów RHEL (np. instalacja dodatkowego pakietu `yum`, zmiana ustawień `sysctl` czy modyfikacja plików konfiguracyjnych) prowadziła do niespójności między węzłami. Taka niespójność mogła powodować nieprzewidywalne błędy, problemy ze stabilnością lub, co najgorsze, niepowodzenie aktualizacji całego klastra.

Zintegrowanie OCP 4 z RHCOS [2, 3] eliminuje ten problem u jego źródła. Klaster, poprzez Machine Config Operator (MCO), staje się *jedynym źródłem prawdy* (single source of truth) co do stanu i konfiguracji systemu operacyjnego. Gwarantuje to, że każdy węzeł danego typu (np. 'worker') jest absolutnie identyczny pod względem oprogramowania i konfiguracji, co jest kluczowe dla niezawodności i przewidywalności operacji na dużą skalę.[8, 9]

### 1.1.3. Koncepcja "Niezmiennego Systemu Operacyjnego" (Immutable OS)

RHCOS implementuje model "niezmiennego" (immutable) systemu plików. W praktyce oznacza to, że kluczowe katalogi systemowe, przede wszystkim `/usr` (gdzie przechowywane są wszystkie binaria systemu operacyjnego, biblioteki i zależności), są montowane w trybie *tylko do odczytu* (read-only).[9, 11] Administratorzy nie mogą bezpośrednio modyfikować tych plików.

Katalogi przeznaczone na dane specyficzne dla maszyny, takie jak `/etc`, `/boot` i `/var`, pozostają zapisywalne.[9, 11] Jednakże bezpośrednia modyfikacja plików w `/etc` przez administratora (np. przez `ssh` i `vi`) jest stanowczo odradzana. Wszystkie zmiany konfiguracyjne powinny być wprowadzane deklaratywnie poprzez zasoby `MachineConfig`, a klaster (poprzez MCO) sam zadba o ich wdrożenie.[9]

Nazwa "immutable" bywa myląca. Nie chodzi o to, że system *nigdy* się nie zmienia. Bardziej precyzyj Fidorący opis, preferowany przez entuzjastów projektu [12], to "system warstwowy" (Layered OS) lub "system zarządzany atomowo". Chodzi o to, że system nie zmienia się "po kawałku" (pakiet po pakiecie), ale przechodzi z jednego spójnego, znanego stanu (np. wersji 4.10.15) do drugiego (np. 4.10.16) w sposób *atomowy*, czyli jako całość.[9, 13]

### 1.1.4. Zarządzanie Oprogramowaniem bez `yum` i `dnf`

Kluczową cechą projektową RHCOS, która jest bezpośrednią konsekwencją filozofii niezmienności, jest celowy brak tradycyjnych menedżerów pakietów, takich jak `yum` czy `dnf`.[9, 14] Ich obecność byłaby fundamentalnie sprzeczna z gwarancjami spójności klastra.

Uruchomienie polecenia `yum install <pakiet>` na pojedynczym węźle natychmiast zniszczyłoby spójność i wprowadziło "dryf konfiguracyjny".[8] Węzeł ten posiadałby oprogramowanie, o którym klaster (a konkretnie MCO) "nie wie". To z kolei cofnęłoby platformę do problemów znanych z OCP 3.x.[15]

Dlatego brak `yum` i `dnf` nie jest błędem ani brakiem, lecz *kluczową cechą projektową* (design feature). Wymusza to na administratorach fundamentalną zmianę podejścia: zamiast logować się na maszynę i "naprawiać" ją w sposób imperatywny, muszą oni opisać *pożądany stan* (np. "chcę, aby na węzłach był ten pakiet") w sposób deklaratywny i pozwolić klastrowi zaimplementować tę zmianę w kontrolowany, spójny sposób na wszystkich węzłach.

### 1.1.5. Rola `rpm-ostree`: Atomowe Aktualizacje i Wycofanie Zmian

Technologią, która umożliwia atomowe zarządzanie stanem RHCOS, jest `rpm-ostree`.[9, 13] Jest to hybrydowy system zarządzania obrazem/pakietami, który łączy niezawodność pakietów RPM z podejściem atomowym, podobnym do `git`.

Zamiast zarządzać tysiącami pojedynczych plików lub pakietów, `rpm-ostree` zarządza całymi, rozruchowymi "drzewami" (bootable filesystem trees) systemu plików.[13] Aktualizacja systemu operacyjnego w RHCOS (zawsze zarządzana przez MCO w kontekście aktualizacji całego klastra) nie polega na uruchomieniu `yum update` na setkach pakietów. Proces ten wygląda następująco:

1.  MCO instruuje `rpm-ostree`, aby pobrało nowy, atomowy obraz systemu (np. w formie obrazu kontenera).[9]
2.  Nowy obraz (nowe "drzewo" systemowe) jest "inscenizowany" (staged) na dysku, obok aktualnie działającego systemu.[9, 11]
3.  Modyfikowany jest wskaźnik bootloadera, aby przy następnym uruchomieniu system wystartował z *nowego* drzewa.
4.  Węzeł jest restartowany (reboot).[9]

Główną zaletą tego podejścia jest niezawodność. Jeśli aktualizacja `yum` nie powiedzie się w połowie, system może pozostać w niestabilnym, "pół-zaktualizowanym" stanie. W `rpm-ostree` taka sytuacja jest niemożliwa. Co więcej, jeśli z jakiegokolwiek powodu nowy obraz systemu okaże się problematyczny (np. aplikacja przestanie działać), proces wycofania zmian (rollback) jest trywialny: polega na zmianie wskaźnika bootloadera z powrotem na *stare*, wciąż nienaruszone drzewo systemu i ponownym restarcie.[9, 11]

### 1.1.6. Rozszerzanie RHCOS: Metoda "CoreOS Image Layering"

W odpowiedzi na uzasadnione potrzeby administratorów, którzy *muszą* instalować dodatkowe oprogramowanie RPM (np. specyficzne sterowniki sprzętowe, agenty monitoringu firm trzecich czy narzędzia bezpieczeństwa), Red Hat wprowadził funkcję "CoreOS Image Layering" (ogólnie dostępną, GA, od OCP 4.13).[14]

Jest to "oficjalny wyjątek od reguły", który pozwala na rozszerzenie bazowego obrazu RHCOS, ale czyni to w sposób w pełni zgodny z deklaratywną filozofią OCP 4. Proces ten polega na:

1.  **Stworzeniu `Containerfile`** (analogicznie do `Dockerfile`).[14]
2.  Użyciu jako obrazu bazowego (`FROM`) oficjalnego obrazu RHCOS pobranego z rejestru (np. `quay.io/.../rhel-coreos`).[14]
3.  Użyciu w `Containerfile` polecenia `RUN rpm-ostree install <nazwa-pakietu>`, aby dodać wymaganego RPM-a do tej nowej warstwy.[14]
4.  Zatwierdzeniu zmian w nowym obrazie poleceniem `ostree container commit`.[14]
5.  Zbudowaniu i wypchnięciu tego niestandardowego obrazu RHCOS do wewnętrznego rejestru.
6.  Na koniec, administrator tworzy nowy zasób `MachineConfig`, który instruuje MCO, aby węzły w danej puli (`MachineConfigPool`) używały tego *nowego, niestandardowego obrazu* jako swojego systemu bazowego (poprzez ustawienie pola `spec.osImageURL`).[14]

W ten sposób, nawet instalacja dodatkowego oprogramowania jest procesem deklaratywnym, wersjonowanym i wdrażanym w kontrolowany sposób przez klaster, zamiast być ręczną, imperatywną operacją na pojedynczym węźle.

-----

## Lekcja 1.2: Architektura Węzłów: Control Plane vs. Workers

### 1.2.1. Definicja i Rola Węzłów Control Plane (Masterów)

Węzły Płaszczyzny Sterowania (Control Plane), historycznie nazywane również Masterami, stanowią "mózg" i centrum nerwowe klastra Kubernetes i OpenShift.[16, 17] W architekturze OpenShift 4.x, w celu zapewnienia wysokiej dostępności (HA) komponentów zarządzających, wdrożenie produkcyjne *musi* posiadać dokładnie trzy węzły Control Plane.[18]

Węzły te, zgodnie z wymaganiami architektury OCP 4, *muszą* działać wyłącznie na systemie operacyjnym RHCOS.[4, 19] Ich główną rolą jest hostowanie kluczowych usług, które przechowują stan klastra (`etcd`), udostępniają API (`kube-apiserver`) oraz podejmują decyzje o harmonogramowaniu obciążeń (`kube-scheduler`).[16, 20]

### 1.2.2. Komponenty Płaszczyzny Sterowania: `etcd`

`etcd` to rozproszona baza danych klucz-wartość, zaprojektowana z myślą o spójności i wysokiej dostępności.[20] W kontekście Kubernetesa i OpenShift, `etcd` jest absolutnie kluczowym komponentem – służy jako *jedyne* autorytatywne źródło prawdy (single source of truth) przechowujące *cały* stan klastra.[18, 20]

Wszystkie obiekty i zasoby definiowane w klastrze – takie jak Pody, Deploymenty, Serwisy, ConfigMapy, Secrety, a także wszystkie zasoby niestandardowe (CRD) – są zapisywane i odczytywane właśnie z `etcd`. Pozostałe komponenty płaszczyzny sterowania (jak `kube-apiserver`) obserwują `etcd` w poszukiwaniu zmian, aby dostosować aktualny stan klastra do stanu pożądanego.[18] Utrata kworum `etcd` (czyli awaria 2 z 3 węzłów master) jest równoznaczna z utratą stanu klastra i wymaga odtworzenia go z kopii zapasowej.

### 1.2.3. Komponenty Płaszczyzny Sterowania: `kube-apiserver`

Serwer API Kubernetesa (`kube-apiserver`) działa jako "brama" lub "frontend" dla całej płaszczyzny sterowania.[16, 20] Jest to centralny punkt, przez który odbywa się *cała* komunikacja z klastrem.

Każde polecenie (np. `oc` lub `kubectl`), każdy komponent systemowy (np. `kubelet` na węźle roboczym, `kube-scheduler`) i każdy Operator komunikuje się *wyłącznie* z `kube-apiserver`.[18, 20] `kube-apiserver` jest odpowiedzialny za:

  * Walidację i przetwarzanie wszystkich żądań API (REST).
  * Uwierzytelnianie i autoryzację.
  * Zapisywanie pożądanego stanu w `etcd` i odczytywanie z niego aktualnego stanu.[18]

Co istotne, `kube-apiserver` jest *jedynym* komponentem w całej architekturze, który ma prawo bezpośredniego zapisu do bazy `etcd`. W specyfice OpenShift, obok `kube-apiserver` (obsługującego zasoby Kubernetes, np. `Pod`, `Deployment`), działa również `openshift-apiserver`, który obsługuje zasoby specyficzne dla OCP (np. `Route`, `Project`, `BuildConfig`).[18]

### 1.2.4. Komponenty Płaszczyzny Sterowania: `kube-scheduler`

`kube-scheduler` to kluczowy komponent decyzyjny, odpowiedzialny za proces "harmonogramowania" (scheduling), czyli decydowania, na którym węźle roboczym (Worker) zostanie uruchomiony dany Pod.[20]

Scheduler działa w pętli:

1.  Nieustannie obserwuje `kube-apiserver` w poszukiwaniu nowo utworzonych Podów, które nie mają jeszcze przypisanego węzła (pole `.spec.nodeName` jest puste).[18, 20]
2.  Dla każdego takiego Poda, scheduler analizuje jego wymagania (żądania CPU i RAM, selektory węzłów, taints i tolerations, zasady affinity/anti-affinity).
3.  Filtruje listę dostępnych węzłów roboczych, aby znaleźć te, które spełniają wymagania Poda.
4.  Wybiera "najlepszy" węzeł spośród kandydatów i informuje `kube-apiserver` o swojej decyzji (poprzez aktualizację obiektu Pod i ustawienie pola `spec.nodeName`).[18]
5.  Od tego momentu `kubelet` na wybranym węźle przejmuje odpowiedzialność za uruchomienie Poda.

Poniższa tabela podsumowuje role kluczowych komponentów Płaszczyzny Sterowania Kubernetesa, które działają na węzłach Master w OpenShift.

**Tabela 1.2-A: Kluczowe komponenty Control Plane (Kubernetes)**

| Komponent | Rola (Metafora) | Główna Funkcja |
| :--- | :--- | :--- |
| **etcd** | "Baza Danych" / "Księga Stanu" | Przechowuje *pożądany* i *aktualny* stan wszystkich zasobów klastra.[18, 20] |
| **kube-apiserver** | "Brama" / "API Frontend" | Waliduje i przetwarza żądania REST; jedyny komponent zapisujący do `etcd`.[18, 20] |
| **kube-scheduler** | "Dyspozytor" | Obserwuje nowe Pody i decyduje, na którym węźle (Worker) je umieścić.[18, 20] |
| **kube-controller-manager** | "Kontrolerzy Pętli" | Uruchamia pętle sterowania (np. `ReplicaSet` controller, `Node` controller), które dążą do zgodności stanu aktualnego z pożądanym.[18, 20] |

### 1.2.5. Rola Węzłów Workers (Roboczych)

Węzły Workers (Robocze), nazywane również węzłami Compute, stanowią "siłę roboczą" klastra. Ich jedyną i podstawową rolą jest uruchamianie aplikacji użytkownika, hermetyzowanych w Podach.[16]

Podczas gdy węzły Control Plane zarządzają klastrem, węzły Workers wykonują właściwą pracę. Na każdym węźle Worker działa kilka kluczowych usług:

  * **Kubelet:** Lokalny agent na każdym węźle, który komunikuje się z `kube-apiserver`. Otrzymuje polecenia (np. "uruchom ten Pod") i zarządza cyklem życia kontenerów na *tym* konkretnym węźle.[21, 22]
  * **CRI-O:** Środowisko uruchomieniowe kontenerów (zgodne z Container Runtime Interface), które faktycznie uruchamia kontenery i zarządza nimi na niskim poziomie.[9, 21] W RHCOS, CRI-O jest domyślnym i jedynym wspieranym środowiskiem uruchomieniowym.
  * **Kube-proxy:** Komponent sieciowy, który zarządza regułami sieciowymi na węźle (np. `iptables` lub `OVN`), aby umożliwić wykrywanie i komunikację z Serwisami (Services) Kubernetesa.[16, 22]

Domyślnym systemem operacyjnym dla węzłów Worker jest RHCOS, co pozwala na pełną automatyzację zarządzania nimi przez MCO.[4] Jednak OCP *wspiera* również użycie standardowego RHEL dla węzłów Worker.[4, 19, 23] Jest to opcja wykorzystywana w scenariuszach, gdy firma musi uruchomić na węzłach specyficzne oprogramowanie firm trzecich (niedostępne przez Image Layering) lub gdy ma istniejące, rygorystyczne procedury zarządzania RHEL, których musi przestrzegać.

### 1.2.6. Koncepcja Węzłów "Infra"

Węzły "Infra" (infrastrukturalne) *nie są* oddzielnym, magicznym typem węzła w sensie technicznym. W rzeczywistości są to standardowe węzły *Worker* (lub Compute) [24], którym nadano specjalną rolę poprzez dedykowaną etykietę: `node-role.kubernetes.io/infra`.[25, 26]

Celem stworzenia tej oddzielnej puli węzłów jest wydzielenie na nie komponentów *wspierających* działanie klastra, aby odizolować je od właściwych aplikacji biznesowych uruchamianych na standardowych węzłach Worker.[22, 26]

### 1.2.7. Przeznaczenie Węzłów "Infra": Router, Rejestr, Monitoring

Głównym celem węzłów Infra jest **izolacja obciążeń**. Komponenty systemowe, takie jak:

  * **OpenShift Router (Ingress Controller)** [24, 27, 28]
  * **Wewnętrzny Rejestr Obrazów (Image Registry)** [24, 27, 28]
  * **Stos Monitoringu (Prometheus, Alertmanager)** [24, 26, 27, 28]
  * **Stos Logowania (Elasticsearch/Loki, Kibana/Grafana)** [24, 26, 28]

...mogą generować znaczące i często nieprzewidywalne obciążenie (duży ruch sieciowy, wysokie I/O dyskowe, skoki CPU/RAM). Uruchamianie ich obok krytycznych aplikacji biznesowych może prowadzić do wzajemnego zakłócania się (tzw. problem "noisy neighbor").

Administratorzy konfigurują klaster tak, aby te usługi działały wyłącznie na węzłach Infra. Osiąga się to poprzez [24]:

1.  Stworzenie dedykowanej puli maszyn (np. `MachineSet`) dla węzłów Infra (z etykietą `.../infra`).
2.  Dodanie do tych węzłów "Taint" (np. `infra=true:NoSchedule`), aby scheduler domyślnie nie umieszczał na nich zwykłych Podów aplikacyjnych.
3.  Skonfigurowanie komponentów infrastrukturalnych (np. poprzez edycję CRD `IngressController` czy `Config` dla rejestru), aby używały `nodeSelector` wskazującego na etykietę `.../infra` oraz posiadały "Toleration" dla Taintu.[24, 27]

Istnieje jednak druga, kluczowa motywacja biznesowa dla używania węzłów Infra: **optymalizacja kosztów licencyjnych**.[24, 25, 27, 29] Red Hat i dostawcy chmurowi (np. Azure) [27] jasno określają, że węzły, które są poprawnie oznaczone etykietą `.../infra` i uruchamiają *wyłącznie* kwalifikowane obciążenia infrastrukturalne (Router, Rejestr, Monitoring, Logowanie), **nie zużywają (nie liczą się do) płatnych subskrypcji OpenShift Container Platform**.[24, 25, 27] Organizacja płaci wówczas jedynie za koszt bazowej maszyny wirtualnej (np. w AWS czy Azure), ale nie za licencję OCP na tym węźle.[27] Jest to krytyczna optymalizacja TCO (Total Cost of Ownership) dla środowisk produkcyjnych.

-----

## Lekcja 1.3: Rola Operatorów Infrastrukturalnych

### 1.3.1. Wprowadzenie do Operatorów definiujących OCP 4

Platforma OpenShift 4 jest "zbudowana z Operatorów" i na Operatorach.[5, 6] Jest to fundamentalna zasada tej architektury. Wzorzec Operatora, czyli oprogramowania (kontrolera Kubernetesa), które automatyzuje zarządzanie cyklem życia komponentu (kodując w sobie wiedzę operacyjną "jak instalować, aktualizować, naprawiać"), jest w OCP 4 wykorzystywany nie tylko do aplikacji użytkownika (przez Operator Lifecycle Manager, OLM), ale przede wszystkim do zarządzania *samą platformą*.

W przeciwieństwie do OCP 3, gdzie wiele komponentów systemowych było statycznymi Podami lub usługami `systemd`, w OCP 4 *każdy* kluczowy komponent klastra – w tym `kube-apiserver`, `etcd`, `kube-scheduler`, a nawet same mechanizmy aktualizacji – jest zarządzany przez dedykowany Operator Klastra (Cluster Operator).[30, 31] Platforma używa tego samego wzorca, który oferuje swoim użytkownikom, do zarządzania *samą sobą*.

### 1.3.2. CVO (Cluster Version Operator): "Mózg" Klastra

Cluster Version Operator (CVO) jest nadrzędnym, najważniejszym operatorem w klastrze.[32] Można go określić mianem "mózgu" operacji Dnia 2, którego zadaniem jest utrzymanie całego klastra w pożądanej, spójnej wersji oraz orkiestracja procesu aktualizacji.

CVO nie posiada tej wiedzy "w sobie". Jego absolutnym źródłem prawdy jest **"release payload image"** (obraz ładunku wydania).[33] Jest to obraz kontenera publikowany dla *każdej* pojedynczej wersji OCP (np. `4.10.15`), który zawiera w sobie manifesty YAML *wszystkich* zasobów niezbędnych do działania tej konkretnej wersji – definicje wszystkich Operatorów Klastra, ich CRD, DaemonSety, Role RBAC itp.

Głównym punktem konfiguracyjnym dla administratora jest zasób niestandardowy (CR) `ClusterVersion` (domyślnie o nazwie `version`). CVO nieustannie monitoruje ten zasób, w szczególności pole `spec.desiredUpdate`.[33]

### 1.3.3. Proces Aktualizacji Klastra zarządzany przez CVO

Proces aktualizacji całego klastra OCP 4 jest w pełni zautomatyzowany i sterowany przez CVO. Przebiega on następująco:

1.  **Inicjacja:** Administrator (lub automatyzacja) inicjuje aktualizację, ustawiając pole `spec.desiredUpdate` w zasobie `ClusterVersion` na nową, docelową wersję (np. pobraną z OpenShift Update Service - OSUS).[33, 34]
2.  **Pobranie i Weryfikacja:** CVO wykrywa tę zmianę, pobiera `release payload image` dla nowej wersji i weryfikuje go.[33]
3.  **Reconcyliacja (Runlevels):** CVO rozpoczyna proces rekoncyliacji klastra do nowego stanu. Wdraża nowe manifesty z obrazu ładunku w ściśle określonej kolejności, zwanej "Runlevels".[34]
4.  **Aktualizacja Operatorów:** W pierwszej kolejności CVO aktualizuje definicje pozostałych Operatorów Klastra (np. `kube-apiserver-operator`, `etcd-operator`, `machine-config-operator`).[30, 34]
5.  **Reakcja Łańcuchowa:** Zaktualizowane Operatory (będące teraz w nowszej wersji) natychmiast wykrywają, że ich komponenty (tzw. operandy) są w starej wersji i same rozpoczynają proces ich aktualizacji, aby doprowadzić je do stanu zgodnego ze swoją nową logiką.[33, 34]
6.  **Kolejność:** CVO dba o krytyczną kolejność – najpierw aktualizowana jest Płaszczyzna Sterowania.[34]
7.  **Przekazanie Pałeczki:** *Po* pomyślnej aktualizacji wszystkich komponentów na Płaszczyźnie Sterowania, CVO "przekazuje pałeczkę" do Machine Config Operatora (MCO), dając mu sygnał do rozpoczęcia aktualizacji systemu operacyjnego RHCOS na węzłach.[34, 35]

### 1.3.4. MCO (Machine Config Operator): "Ręce" Klastra

Jeśli CVO jest "mózgiem" aktualizacji, to Machine Config Operator (MCO) jest ich "rękami".[36] Jest to kolejny kluczowy Operator na poziomie klastra [31, 37], którego wyłączną odpowiedzialnością jest zarządzanie *konfiguracją i aktualizacjami systemu operacyjnego (RHCOS)* na każdym węźle klastra.[36]

Zakres odpowiedzialności MCO obejmuje wszystko "pomiędzy jądrem a kubeletem" [36]: zarządzanie usługami `systemd`, konfiguracją `crio-o` i `kubelet`, aktualizacjami jądra i sterowników (poprzez `rpm-ostree`), plikami konfiguracyjnymi w `/etc` (np. `/etc/resolv.conf`, `/etc/ntp.conf`) oraz kluczami SSH.[31, 36, 37] Źródłem prawdy dla MCO są zasoby `MachineConfig`.[36]

### 1.3.5. Architektura MCO: Kontroler, Serwer i Daemony

MCO samo w sobie jest złożonym operatorem, składającym się z kilku kluczowych komponentów [38]:

  * **`machine-config-operator`:** Główny kontroler, który wdraża i zarządza pozostałymi komponentami MCO. Jego status w `oc get clusteroperator` odzwierciedla ogólną kondycję zarządzania konfiguracją węzłów.
  * **`machine-config-controller`:** "Mózg" MCO. Działa na płaszczyźnie sterowania. Obserwuje zasoby `MachineConfig` oraz `MachineConfigPool`. Jego kluczową rolą jest **renderowanie**.[37, 38] Łączy on wiele *fragmentów* `MachineConfig` (np. `01-worker-sshkeys`, `05-worker-ntp`, `99-worker-kubelet-maxpods`) w jeden, duży, "wyrenderowany" zasób `MachineConfig` (np. `rendered-worker-a1b2c3d4`), który reprezentuje *kompletny, pożądany stan* dla danej puli węzłów.[37]
  * **`machine-config-server`:** Endpoint (serwer), który udostępnia wyrenderowane konfiguracje Ignition dla *nowych* węzłów podczas ich pierwszego uruchomienia (bootstrap).[38]
  * **`machine-config-daemon`:** "Ręce" MCO. Działa jako `DaemonSet` na *każdym* węźle RHCOS w klastrze (zarówno Master, jak i Worker).[38, 39] Demon ten obserwuje `MachineConfigPool`, do którego należy jego węzeł. Jego zadaniem jest porównywanie *aktualnej* konfiguracji węzła z *pożądaną* konfiguracją (wskazaną przez `rendered-worker-...`) i podejmowanie działań, aby je uzgodnić.

### 1.3.6. Mechanizm Stosowania Zmian przez `MachineConfigPools`

`MachineConfigPool` (MCP) to zasób CRD, który grupuje węzły o identycznej roli i pożądanej konfiguracji.[31, 36] Domyślnie w klastrze istnieją dwie pule: `master` i `worker`.[37]

MCP jest kluczowym "łącznikiem". Używa selektorów (label selectors) do zrobienia dwóch rzeczy [37]:

1.  **Wybrania węzłów**, którymi ma zarządzać (np. `node-role.kubernetes.io/worker: ""`).
2.  **Wybrania zasobów `MachineConfig`**, które mają być do nich zastosowane (np. `machineconfiguration.openshift.io/role: worker`).

Umożliwia to administratorom tworzenie niestandardowych pul (np. `worker-gpu`) i stosowanie do nich specyficznych konfiguracji (np. innych argumentów jądra lub sterowników), które nie będą miały wpływu na domyślną pulę `worker`.[39, 40]

### 1.3.7. Proces Aktualizacji Węzła: Od `MachineConfig` do Rebootu

Zrozumienie pełnego cyklu życia zmiany konfiguracyjnej jest kluczowe dla zrozumienia operacji Dnia 2 w OCP 4. Proces ten, łączący wszystkie komponenty MCO, przebiega następująco:

1.  **Krok 1: Inicjacja Zmiany.** Administrator chce zmienić parametr `kubelet` (np. `maxPods`) dla wszystkich węzłów roboczych. *Nie* loguje się na węzły. Zamiast tego tworzy nowy zasób `KubeletConfig` i stosuje go w klastrze (`oc apply -f...`).[41, 42]
2.  **Krok 2: Wykrycie przez Kontroler.** `machine-config-controller` (działający na masterze) wykrywa ten nowy CR `KubeletConfig`.[38]
3.  **Krok 3: Renderowanie.** Kontroler rozpoznaje, że ta zmiana dotyczy puli `worker`. Pobiera *wszystkie* pasujące fragmenty `MachineConfig` dla tej puli (stary `kubelet`, nową zmianę `maxPods`, konfigurację NTP, klucze SSH itp.) i "renderuje" je (łączy) w jeden, nowy, monolityczny obiekt `MachineConfig` o nowej nazwie, np. `rendered-worker-b2c3d4e5`.[37]
4.  **Krok 4: Aktualizacja Puli.** Kontroler aktualizuje zasób `MachineConfigPool` (MCP) o nazwie `worker`, ustawiając jego `.spec.configuration.name` na `rendered-worker-b2c3d4e5`. Węzły w puli przechodzą w stan `Updating`.[36]
5.  **Krok 5: Wykrycie przez Daemona.** Na każdym węźle roboczym, `machine-config-daemon` (MCD) [38, 39] monitoruje swój MCP. Wykrywa, że pożądana konfiguracja (`...b2c3d4e5`) jest *inna* niż aktualnie zastosowana (`...a1b2c3d4`).
6.  **Krok 6: Rolling Update (Cordon/Drain/Reboot).** MCO rozpoczyna *kolejną* (rolling) aktualizację węzłów w puli, jeden po drugim, aby zachować dostępność aplikacji.[38] Dla *każdego* węzła:
    a.  **Cordon:** Węzeł jest oznaczany jako nieszarżowalny (`Unschedulable`), aby nie przyjmował nowych Podów.[39]
    b.  **Drain:** MCO wykonuje drenaż (ewikucję) wszystkich Podów z tego węzła. Pody te są przenoszone przez scheduler na inne, zdrowe węzły.[39, 43]
    c.  **Apply:** MCD pobiera nową konfigurację i ją stosuje. Jeśli zmiana dotyczy systemu bazowego (np. aktualizacja RHCOS podczas upgrade'u klastra), wywołuje `rpm-ostree`.[36] Jeśli dotyczy plików (np. `/etc/kubelet.conf`), zapisuje nowe pliki.[39]
    d.  **Reboot:** W *większości* przypadków (poza drobnymi wyjątkami jak zmiana kluczy SSH czy globalnego pull secreta [39]), MCO *restartuje* (reboot) węzeł. Jest to konieczne, aby atomowo zastosować zmiany (szczególnie te z `rpm-ostree`) i zapewnić, że wszystkie usługi (jak `kubelet`) zostaną uruchomione z nową konfiguracją.[39, 43]
    e.  **Uncordon:** Po restarcie, `kubelet` zgłasza się, MCD potwierdza, że węzeł ma nową konfigurację, a MCO oznacza węzeł jako gotowy i szarżowalny (`Schedulable`).[39]

Proces ten jest następnie powtarzany dla następnego węzła w puli, aż cała pula `worker` zostanie zaktualizowana do nowej, spójnej konfiguracji.

-----

## Lekcja 1.4: Czym jest Machine API?

### 1.4.1. Zarządzanie Węzłami jako Zasobami Kubernetes (CRD)

Machine API to kluczowy komponent OpenShift 4, który realizuje ideę "Infrastructure-as-Code" bezpośrednio w API Kubernetesa.[44] Jest to implementacja Red Hat, która wyewoluowała z wczesnych wersji upstreamowego projektu Cluster API (choć obecnie nie jest z nim w pełni kompatybilna API).[7, 44, 45]

W praktyce Machine API przenosi zarządzanie cyklem życia infrastruktury (maszyn wirtualnych w chmurze, serwerów Bare Metal) *do* klastra OpenShift. Osiąga to poprzez wprowadzenie zestawu niestandardowych definicji zasobów (CRD).[7, 46, 47] Zamiast ręcznie tworzyć VM-ki w konsoli AWS czy vSphere, a następnie dołączać je do klastra, administratorzy mogą teraz zarządzać węzłami roboczymi w ten sam deklaratywny sposób (używając `oc` i plików YAML), w jaki zarządzają Podami i Deploymentami.[44] Machine API jest podstawą działania automatycznego provisioningu w instalacjach typu IPI (Installer Provisioned Infrastructure).[44]

### 1.4.2. Zasób `Machine`: Reprezentacja Węzła

Zasób `Machine` jest podstawową, atomową jednostką Machine API.[7, 47] Jest to obiekt CRD, który reprezentuje *jeden* fizyczny lub wirtualny host.[46, 47] Definicja zasobu `Machine` zawiera kluczowe pole `providerSpec`.

`providerSpec` jest specyficzny dla każdego dostawcy infrastruktury (np. AWS, Azure, vSphere) i zawiera wszystkie niezbędne informacje do stworzenia maszyny u tego dostawcy.[46] Na przykład, w `providerSpec` dla AWS znajdą się takie informacje jak:

  * Typ instancji (np. `m5.xlarge`)
  * ID obrazu AMI (zazwyczaj wskazujące na konkretną wersję RHCOS)
  * Strefa dostępności (np. `us-east-1a`)
  * Grupy bezpieczeństwa i podsieć

Istnieje bezpośrednia relacja 1:1 między obiektem `Machine` w przestrzeni nazw `openshift-machine-api` a rzeczywistą instancją VM u dostawcy chmury oraz (docelowo) obiektem `Node` w API Kubernetesa.

### 1.4.3. Zasób `MachineSet`: Odpowiednik `ReplicaSet` dla Węzłów

Zasób `MachineSet` to kontroler wyższego poziomu, który zarządza grupą identycznych zasobów `Machine`.[7, 46, 47] Społeczność i dokumentacja słusznie używają analogii:

**`MachineSet` jest dla `Machine` tym, czym `ReplicaSet` jest dla `Pod`**.[7, 47]

`MachineSet` definiuje dwa kluczowe elementy:

1.  **`template`:** Szablon, który opisuje, jak mają wyglądać nowe obiekty `Machine` (zawiera m.in. `providerSpec`).
2.  **`replicas`:** Pożądana liczba maszyn, które mają pasować do tego szablonu.

Kontroler `MachineSet` działa w pętli rekoncyliacji, nieustannie monitorując stan klastra. Jego zadaniem jest zapewnienie, że *aktualna* liczba maszyn (`status.replicas`) jest *zawsze* równa *pożądanej* liczbie maszyn (`spec.replicas`).[7, 47]

### 1.4.4. Skalowanie Klastra (Dodawanie/Usuwanie Workerów) przez Edycję YAML

Dzięki Machine API, horyzontalne skalowanie puli węzłów roboczych staje się operacją trywialną, szybką i w pełni deklaratywną. Proces ten jest jednym z najbardziej efektownych przykładów potęgi OCP 4.

**Proces skalowania w górę (np. z 3 do 5 węzłów):**

1.  **Identyfikacja:** Administrator listuje dostępne `MachineSet` (zazwyczaj jeden na strefę dostępności):
    ```bash
    oc get machinesets -n openshift-machine-api
    ```
    [48]
2.  **Edycja:** Administrator edytuje wybrany `MachineSet` poleceniem `oc edit`:
    ```bash
    oc edit machineset <nazwa_machineset> -n openshift-machine-api
    ```
    [48, 49, 50]
3.  **Zmiana:** W edytorze YAML, administrator zmienia *tylko jedną wartość*: `spec.replicas`.
    ```yaml
    apiVersion: machine.openshift.io/v1beta1
    kind: MachineSet
    metadata:
      name: my-cluster-worker-us-east-1a
      namespace: openshift-machine-api
    spec:
      replicas: 5 # <--- ORYGINALNIE BYŁO 3
      template:
        #... (długa specyfikacja szablonu maszyny)...
    ```
    [48]
4.  **Efekt:** W momencie zapisania zmiany, kontroler `MachineSet` natychmiast wykrywa różnicę (pożądane: 5, aktualne: 3). Tworzy dwa nowe zasoby `Machine` na podstawie szablonu `template`.
5.  Kontroler `machine-api-operator` (specyficzny dla chmury) wykrywa te nowe obiekty `Machine` i wysyła żądania do API chmury (np. AWS EC2 API) o stworzenie dwóch nowych instancji VM.
6.  Nowe VM-ki startują, pobierają konfigurację Ignition z `machine-config-server` (patrz Lekcja 1.3.5) i automatycznie dołączają do klastra jako nowe węzły Worker.

**Proces skalowania w dół (np. z 5 do 3):**

Proces jest odwrotny. Zmiana `spec.replicas` z 5 na 3 powoduje, że kontroler `MachineSet` losowo (lub wg `deletePolicy` [48]) wybiera dwie maszyny do usunięcia. Usuwa ich zasoby `Machine`. Kontroler `machine-api-operator` wykrywa usunięcie i wysyła do API chmury żądanie *zakończenia* (terminate) odpowiednich instancji VM.

### 1.4.5. Zasób `MachineHealthCheck`: Automatyczna Naprawa Węzłów

`MachineHealthCheck` (MHC) to zasób CRD, który domyka pętlę automatyzacji, wprowadzając mechanizm samonaprawiania się węzłów.[7, 51]

Administrator tworzy zasób MHC i kieruje go (poprzez `selector`) na grupę maszyn, zazwyczaj tych zarządzanych przez jeden `MachineSet`.[52] W definicji MHC określa warunki, które świadczą o "złym stanie zdrowia" węzła, na przykład [53]:

  * Stan `Node.Status.Ready` ma wartość `False` przez ponad 10 minut.
  * Stan `Node.Status.Ready` ma wartość `Unknown` przez ponad 15 minut.

**Proces automatycznej naprawy (remediacji) jest genialny w swojej prostocie i doskonale ilustruje, jak komponenty OCP 4 współpracują ze sobą:**

1.  **Awaria:** Węzeł roboczy ulega awarii (np. awaria sprzętu, kernel panic, awaria zasilania). `Kubelet` na tym węźle przestaje raportować do `kube-apiserver`.
2.  **Wykrycie:** Kontroler węzłów na płaszczyźnie sterowania zauważa brak raportów i po pewnym czasie zmienia stan obiektu `Node` na `NotReady`.[53]
3.  **Diagnoza MHC:** Kontroler `MachineHealthCheck` monitoruje ten węzeł. Widzi, że stan `NotReady` utrzymuje się dłużej niż skonfigurowany próg (np. 10 minut). Uznaje węzeł za "uszkodzony" (unhealthy).
4.  **Remediacja (Usunięcie):** `MachineHealthCheck` wykonuje *jedyną* akcję, do której jest uprawniony: **usuwa powiązany z tym węzłem zasób `Machine`**.[53, 54]
5.  **Reakcja `MachineSet`:** Kontroler `MachineSet` (który monitoruje ten sam zestaw maszyn) natychmiast zauważa, że brakuje mu jednej repliki. Jego `spec.replicas` to 3, ale `status.replicas` właśnie spadło do 2.
6.  **Samonaprawienie:** Aby spełnić swoje kontraktowe zobowiązanie (`spec.replicas: 3`), `MachineSet` **automatycznie tworzy nowy zasób `Machine`** [47], aby zastąpić ten usunięty przez MHC.
7.  **Powrót do Normy:** Od tego momentu uruchamiany jest standardowy proces provisioningu (opisany w 1.4.4). Nowa maszyna VM jest tworzona w chmurze, bootuje RHCOS, jest konfigurowana przez MCO i dołącza do klastra, zastępując uszkodzony węzeł.

Awaria węzła, która w tradycyjnych systemach wymagałaby nocnej interwencji administratora, w OCP 4 staje się rutynowym, automatycznie obsłużonym zdarzeniem.

Należy pamiętać o ograniczeniach: MHC domyślnie nie działa na węzłach Control Plane (choć wsparcie dla tego jest wprowadzane w nowszych wersjach OCP) [53, 54, 55] oraz posiada zabezpieczenie `maxUnhealthy`, które blokuje remediację, jeśli uszkodzonych jest zbyt wiele węzłów jednocześnie (np. podczas awarii sieci), aby zapobiec kaskadowej awarii klastra.[54]

-----

#### **Cytowane prace**

1. Change from RHEL 7.7 to RHCOS \- openshift \- Stack Overflow, otwierano: listopada 17, 2025, [https://stackoverflow.com/questions/68135717/change-from-rhel-7-7-to-rhcos](https://stackoverflow.com/questions/68135717/change-from-rhel-7-7-to-rhcos)  
2. What Sets OpenShift Apart? \- Reddit, otwierano: listopada 17, 2025, [https://www.reddit.com/r/openshift/comments/1ctfotd/what\_sets\_openshift\_apart/](https://www.reddit.com/r/openshift/comments/1ctfotd/what_sets_openshift_apart/)  
3. RHEL Versions Utilized by RHEL CoreOS and OCP \- Red Hat Customer Portal, otwierano: listopada 17, 2025, [https://access.redhat.com/articles/6907891](https://access.redhat.com/articles/6907891)  
4. otwierano: listopada 17, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/architecture/architecture-rhcos\#:\~:text=RHCOS%20is%20the%20only%20supported,RHEL%20as%20their%20operating%20system.](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/architecture/architecture-rhcos#:~:text=RHCOS%20is%20the%20only%20supported,RHEL%20as%20their%20operating%20system.)  
5. Chapter 1\. OpenShift Container Platform 4.10 Documentation | About, otwierano: listopada 17, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.10/html/about/welcome-index](https://docs.redhat.com/en/documentation/openshift_container_platform/4.10/html/about/welcome-index)  
6. Chapter 1\. OpenShift Container Platform 4.12 Documentation | About, otwierano: listopada 17, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.12/html/about/welcome-index](https://docs.redhat.com/en/documentation/openshift_container_platform/4.12/html/about/welcome-index)  
7. Chapter 1\. Overview of machine management | Machine ..., otwierano: listopada 17, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.13/html/machine\_management/overview-of-machine-management](https://docs.redhat.com/en/documentation/openshift_container_platform/4.13/html/machine_management/overview-of-machine-management)  
8. Chapter 7\. Red Hat Enterprise Linux CoreOS (RHCOS) | Architecture | OpenShift Container Platform | 4.11, otwierano: listopada 17, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.11/html/architecture/architecture-rhcos](https://docs.redhat.com/en/documentation/openshift_container_platform/4.11/html/architecture/architecture-rhcos)  
9. Chapter 6\. Red Hat Enterprise Linux CoreOS (RHCOS ..., otwierano: listopada 17, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/architecture/architecture-rhcos](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/architecture/architecture-rhcos)  
10. RHCOS \- OpenShift Infrastructure Provider Onboarding Guide, otwierano: listopada 17, 2025, [https://docs.providers.openshift.org/rhcos/](https://docs.providers.openshift.org/rhcos/)  
11. Chapter 5\. Red Hat Enterprise Linux CoreOS (RHCOS) | Architecture | OpenShift Container Platform | 4.1, otwierano: listopada 17, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.1/html/architecture/architecture-rhcos](https://docs.redhat.com/en/documentation/openshift_container_platform/4.1/html/architecture/architecture-rhcos)  
12. Explaining the concept of immutable operating systems : r/linux \- Reddit, otwierano: listopada 17, 2025, [https://www.reddit.com/r/linux/comments/x0anok/explaining\_the\_concept\_of\_immutable\_operating/](https://www.reddit.com/r/linux/comments/x0anok/explaining_the_concept_of_immutable_operating/)  
13. Immutable Images for Oracle Linux with OSTree, otwierano: listopada 17, 2025, [https://blogs.oracle.com/linux/immutable-images-for-oracle-linux-with-ostree](https://blogs.oracle.com/linux/immutable-images-for-oracle-linux-with-ostree)  
14. Updating RHCOS Images with Custom Configurations |, otwierano: listopada 17, 2025, [https://xphyr.net/post/updating\_coreos\_with\_additional\_packages/](https://xphyr.net/post/updating_coreos_with_additional_packages/)  
15. Help regarding dnf/yum install on Rhel. : r/redhat \- Reddit, otwierano: listopada 17, 2025, [https://www.reddit.com/r/redhat/comments/19eefsr/help\_regarding\_dnfyum\_install\_on\_rhel/](https://www.reddit.com/r/redhat/comments/19eefsr/help_regarding_dnfyum_install_on_rhel/)  
16. Cluster Architecture | Kubernetes, otwierano: listopada 17, 2025, [https://kubernetes.io/docs/concepts/architecture/](https://kubernetes.io/docs/concepts/architecture/)  
17. Kubernetes Architecture: Control Plane, Data Plane, and 11 Core Components Explained, otwierano: listopada 17, 2025, [https://spot.io/resources/kubernetes-architecture/11-core-components-explained/](https://spot.io/resources/kubernetes-architecture/11-core-components-explained/)  
18. Chapter 4\. Control plane architecture | Architecture | OpenShift ..., otwierano: listopada 17, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/architecture/control-plane](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/architecture/control-plane)  
19. Chapter 2\. OpenShift Container Platform architecture \- Red Hat Documentation, otwierano: listopada 17, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.10/html/architecture/architecture](https://docs.redhat.com/en/documentation/openshift_container_platform/4.10/html/architecture/architecture)  
20. Kubernetes Components, otwierano: listopada 17, 2025, [https://kubernetes.io/docs/concepts/overview/components/](https://kubernetes.io/docs/concepts/overview/components/)  
21. Chapter 4\. Control plane architecture | Architecture | Red Hat OpenShift Service on AWS, otwierano: listopada 17, 2025, [https://docs.redhat.com/en/documentation/red\_hat\_openshift\_service\_on\_aws/4/html/architecture/control-plane](https://docs.redhat.com/en/documentation/red_hat_openshift_service_on_aws/4/html/architecture/control-plane)  
22. An overview of Openshift Infra node \- eG Innovations, otwierano: listopada 17, 2025, [https://www.eginnovations.com/documentation/Openshift-Infra/What-is-Openshift-Infra.htm](https://www.eginnovations.com/documentation/Openshift-Infra/What-is-Openshift-Infra.htm)  
23. Architecture | OpenShift Container Platform | 4.2 \- Red Hat Documentation, otwierano: listopada 17, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.2/html-single/architecture/index](https://docs.redhat.com/en/documentation/openshift_container_platform/4.2/html-single/architecture/index)  
24. Chapter 7\. Creating infrastructure machine sets | Machine ..., otwierano: listopada 17, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.10/html/machine\_management/creating-infrastructure-machinesets](https://docs.redhat.com/en/documentation/openshift_container_platform/4.10/html/machine_management/creating-infrastructure-machinesets)  
25. Chapter 6\. How to use dedicated worker nodes for Red Hat OpenShift Container Storage, otwierano: listopada 17, 2025, [https://docs.redhat.com/en/documentation/red\_hat\_openshift\_container\_storage/4.7/html/managing\_and\_allocating\_storage\_resources/how-to-use-dedicated-worker-nodes-for-openshift-container-storage\_rhocs](https://docs.redhat.com/en/documentation/red_hat_openshift_container_storage/4.7/html/managing_and_allocating_storage_resources/how-to-use-dedicated-worker-nodes-for-openshift-container-storage_rhocs)  
26. Workload placement | Red Hat OpenShift Container Platform on HPE SimpliVity, otwierano: listopada 17, 2025, [https://hewlettpackard.github.io/OpenShift-on-SimpliVity/post-deploy/placement.html](https://hewlettpackard.github.io/OpenShift-on-SimpliVity/post-deploy/placement.html)  
27. Deploy infrastructure nodes in an Azure Red Hat OpenShift cluster ..., otwierano: listopada 17, 2025, [https://learn.microsoft.com/en-us/azure/openshift/howto-infrastructure-nodes](https://learn.microsoft.com/en-us/azure/openshift/howto-infrastructure-nodes)  
28. Chapter 6\. Creating infrastructure machine sets | Machine management | OpenShift Container Platform | 4.4 | Red Hat Documentation, otwierano: listopada 17, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.4/html/machine\_management/creating-infrastructure-machinesets](https://docs.redhat.com/en/documentation/openshift_container_platform/4.4/html/machine_management/creating-infrastructure-machinesets)  
29. Understanding Node Roles : r/openshift \- Reddit, otwierano: listopada 17, 2025, [https://www.reddit.com/r/openshift/comments/sny8pg/understanding\_node\_roles/](https://www.reddit.com/r/openshift/comments/sny8pg/understanding_node_roles/)  
30. Chapter 6\. Cluster Operators reference | Operators | OpenShift Container Platform | 4.9 | Red Hat Documentation, otwierano: listopada 17, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.9/html/operators/cluster-operators-ref](https://docs.redhat.com/en/documentation/openshift_container_platform/4.9/html/operators/cluster-operators-ref)  
31. Machine Config Pool — OpenShift Container Platform 4.x | by Kamlesh Prajapati | Medium, otwierano: listopada 17, 2025, [https://kamsjec.medium.com/machine-config-pool-openshift-container-platform-4-x-c515e7a093fb](https://kamsjec.medium.com/machine-config-pool-openshift-container-platform-4-x-c515e7a093fb)  
32. Chapter 2\. Understanding cluster version condition types | Updating clusters | OpenShift Container Platform | 4.10 | Red Hat Documentation, otwierano: listopada 17, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.10/html/updating\_clusters/understanding-clusterversion-conditiontypes\_updating-clusters-overview](https://docs.redhat.com/en/documentation/openshift_container_platform/4.10/html/updating_clusters/understanding-clusterversion-conditiontypes_updating-clusters-overview)  
33. openshift/cluster-version-operator \- GitHub, otwierano: listopada 17, 2025, [https://github.com/openshift/cluster-version-operator](https://github.com/openshift/cluster-version-operator)  
34. Chapter 2\. Understanding OpenShift updates | Updating clusters | OpenShift Container Platform | 4.13 | Red Hat Documentation, otwierano: listopada 17, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.13/html/updating\_clusters/understanding-openshift-updates-1](https://docs.redhat.com/en/documentation/openshift_container_platform/4.13/html/updating_clusters/understanding-openshift-updates-1)  
35. Introduction to OpenShift updates \- OKD Documentation, otwierano: listopada 17, 2025, [https://docs.okd.io/4.17/updating/understanding\_updates/intro-to-updates.html](https://docs.okd.io/4.17/updating/understanding_updates/intro-to-updates.html)  
36. openshift/machine-config-operator \- GitHub, otwierano: listopada 17, 2025, [https://github.com/openshift/machine-config-operator](https://github.com/openshift/machine-config-operator)  
37. OpenShift Container Platform 4: How does Machine Config Pool work?, otwierano: listopada 17, 2025, [https://www.redhat.com/en/blog/openshift-container-platform-4-how-does-machine-config-pool-work](https://www.redhat.com/en/blog/openshift-container-platform-4-how-does-machine-config-pool-work)  
38. Getting Along with the OpenShift Machine Config Operator | Purplecarrot, otwierano: listopada 17, 2025, [https://purplecarrot.co.uk/post/2021-12-19-machineconfigoperator/](https://purplecarrot.co.uk/post/2021-12-19-machineconfigoperator/)  
39. Chapter 1\. Machine configuration overview | Machine configuration ..., otwierano: listopada 17, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.17/html/machine\_configuration/machine-config-index](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/machine_configuration/machine-config-index)  
40. Understanding OpenShift MachineConfigs and MachineConfigPools |, otwierano: listopada 17, 2025, [https://xphyr.net/post/machine\_configs\_and\_mcp/](https://xphyr.net/post/machine_configs_and_mcp/)  
41. Postinstallation machine configuration tasks \- OKD Documentation, otwierano: listopada 17, 2025, [https://docs.okd.io/4.13/post\_installation\_configuration/machine-configuration-tasks.html](https://docs.okd.io/4.13/post_installation_configuration/machine-configuration-tasks.html)  
42. Chapter 4\. Configuring MCO-related custom resources | Machine configuration | OpenShift Container Platform | 4.16 | Red Hat Documentation, otwierano: listopada 17, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.16/html/machine\_configuration/machine-configs-custom](https://docs.redhat.com/en/documentation/openshift_container_platform/4.16/html/machine_configuration/machine-configs-custom)  
43. Performing a canary rollout update \- OKD Documentation, otwierano: listopada 17, 2025, [https://docs.okd.io/latest/updating/updating\_a\_cluster/update-using-custom-machine-config-pools.html](https://docs.okd.io/latest/updating/updating_a_cluster/update-using-custom-machine-config-pools.html)  
44. Machine API Controllers \- OpenShift Infrastructure Provider Onboarding Guide, otwierano: listopada 17, 2025, [https://docs.providers.openshift.org/machine-api-controllers/](https://docs.providers.openshift.org/machine-api-controllers/)  
45. About the Cluster API \- Managing machines with the Cluster API \- OKD Documentation, otwierano: listopada 17, 2025, [https://docs.okd.io/latest/machine\_management/cluster\_api\_machine\_management/cluster-api-about.html](https://docs.okd.io/latest/machine_management/cluster_api_machine_management/cluster-api-about.html)  
46. Chapter 1\. Overview of machine management \- Red Hat Documentation, otwierano: listopada 17, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.9/html/machine\_management/overview-of-machine-management](https://docs.redhat.com/en/documentation/openshift_container_platform/4.9/html/machine_management/overview-of-machine-management)  
47. Chapter 1\. Overview of machine management | Machine management | OpenShift Container Platform | 4.11 | Red Hat Documentation, otwierano: listopada 17, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.11/html/machine\_management/overview-of-machine-management](https://docs.redhat.com/en/documentation/openshift_container_platform/4.11/html/machine_management/overview-of-machine-management)  
48. Chapter 3\. Manually scaling a machine set | Machine management ..., otwierano: listopada 17, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.9/html/machine\_management/manually-scaling-machineset](https://docs.redhat.com/en/documentation/openshift_container_platform/4.9/html/machine_management/manually-scaling-machineset)  
49. Chapter 3\. Recommended cluster scaling practices | Scalability and performance | OpenShift Container Platform | 4.6 | Red Hat Documentation, otwierano: listopada 17, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.6/html/scalability\_and\_performance/recommended-cluster-scaling-practices](https://docs.redhat.com/en/documentation/openshift_container_platform/4.6/html/scalability_and_performance/recommended-cluster-scaling-practices)  
50. Red Hat OpenShift on VMware vSphere \- How to Scale and Edit your cluster deployments, otwierano: listopada 17, 2025, [https://veducate.co.uk/openshift-vsphere-scale-clusters/](https://veducate.co.uk/openshift-vsphere-scale-clusters/)  
51. MachineHealthCheck \[machine.openshift.io/v1beta1\] \- Machine APIs | API reference | OKD 4.16 \- OKD Documentation, otwierano: listopada 17, 2025, [https://docs.okd.io/4.16/rest\_api/machine\_apis/machinehealthcheck-machine-openshift-io-v1beta1.html](https://docs.okd.io/4.16/rest_api/machine_apis/machinehealthcheck-machine-openshift-io-v1beta1.html)  
52. Chapter 11\. Deploying machine health checks | Machine management | OpenShift Container Platform | 4.6 | Red Hat Documentation, otwierano: listopada 17, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.6/html/machine\_management/deploying-machine-health-checks](https://docs.redhat.com/en/documentation/openshift_container_platform/4.6/html/machine_management/deploying-machine-health-checks)  
53. Chapter 11\. Deploying machine health checks | Machine ..., otwierano: listopada 17, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/machine\_management/deploying-machine-health-checks](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/machine_management/deploying-machine-health-checks)  
54. Chapter 8\. Deploying machine health checks | Machine management | OpenShift Container Platform | 4.4 | Red Hat Documentation, otwierano: listopada 17, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.4/html/machine\_management/deploying-machine-health-checks](https://docs.redhat.com/en/documentation/openshift_container_platform/4.4/html/machine_management/deploying-machine-health-checks)  
55. Ask an OpenShift Admin (E97) | Control Plane Machine Sets; Infra node management, otwierano: listopada 17, 2025, [https://www.youtube.com/watch?v=fR2v-\_C4mhw](https://www.youtube.com/watch?v=fR2v-_C4mhw)  
56. What is Red Hat Enterprise Linux CoreOS (RHEL CoreOS or RHCOS)? OpenShift | Benefits | Use Cases \- YouTube, otwierano: listopada 17, 2025, [https://www.youtube.com/watch?v=M7dYTWtuYqM](https://www.youtube.com/watch?v=M7dYTWtuYqM)  
57. What are the differences between Red Hat Enterprise Linux (RHEL) and RHEL CoreOS?, otwierano: listopada 17, 2025, [https://www.youtube.com/watch?v=w8hY21Y9uJ0](https://www.youtube.com/watch?v=w8hY21Y9uJ0)  
58. Solved: http:// yum repos. Can dnf search and dnf list but... \- Red Hat Learning Community, otwierano: listopada 17, 2025, [https://learn.redhat.com/t5/Platform-Linux/http-yum-repos-Can-dnf-search-and-dnf-list-but-cannot-install/td-p/16791](https://learn.redhat.com/t5/Platform-Linux/http-yum-repos-Can-dnf-search-and-dnf-list-but-cannot-install/td-p/16791)  
59. latest yum/dnf packages not showing on RHEL 8 \- Unix & Linux Stack Exchange, otwierano: listopada 17, 2025, [https://unix.stackexchange.com/questions/762500/latest-yum-dnf-packages-not-showing-on-rhel-8](https://unix.stackexchange.com/questions/762500/latest-yum-dnf-packages-not-showing-on-rhel-8)  
60. Creating infrastructure nodes \- Working with nodes \- OKD Documentation, otwierano: listopada 17, 2025, [https://docs.okd.io/latest/nodes/nodes/nodes-nodes-creating-infrastructure-nodes.html](https://docs.okd.io/latest/nodes/nodes/nodes-nodes-creating-infrastructure-nodes.html)  
61. Chapter 3\. Post-installation machine configuration tasks \- Red Hat Documentation, otwierano: listopada 17, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/post-installation\_configuration/post-install-machine-configuration-tasks](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/post-installation_configuration/post-install-machine-configuration-tasks)  
62. Configuring each kubelet in your cluster using kubeadm \- Kubernetes, otwierano: listopada 17, 2025, [https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/kubelet-integration/](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/kubelet-integration/)  
63. Chapter 1\. Overview of machine management \- Red Hat Documentation, otwierano: listopada 17, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/machine\_management/overview-of-machine-management](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/machine_management/overview-of-machine-management)  
64. MachineSet \[machine.openshift.io/v1beta1\] \- Machine APIs | API reference | OKD 4, otwierano: listopada 17, 2025, [https://docs.okd.io/latest/rest\_api/machine\_apis/machineset-machine-openshift-io-v1beta1.html](https://docs.okd.io/latest/rest_api/machine_apis/machineset-machine-openshift-io-v1beta1.html)  
65. Machinesets and Auto-scaling OpenShift Cluster | by Winton Huang | Medium, otwierano: listopada 17, 2025, [https://medium.com/@wintonjkt/machinesets-and-auto-scaling-openshift-cluster-a24c458a200a](https://medium.com/@wintonjkt/machinesets-and-auto-scaling-openshift-cluster-a24c458a200a)  
66. how can we scale out Azure redhat Openshift with same master node and different worker node with different subnet and different domain \- Microsoft Learn, otwierano: listopada 17, 2025, [https://learn.microsoft.com/en-us/answers/questions/426328/how-can-we-scale-out-azure-redhat-openshift-with-s](https://learn.microsoft.com/en-us/answers/questions/426328/how-can-we-scale-out-azure-redhat-openshift-with-s)  
67. OpenShift Container Platform | 4.20 \- Red Hat Documentation, otwierano: listopada 17, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/](https://docs.redhat.com/en/documentation/openshift_container_platform/)  
68. Chapter 1\. Architecture overview | Architecture | OpenShift Container Platform | 4.10 | Red Hat Documentation, otwierano: listopada 17, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.10/html/architecture/architecture-overview](https://docs.redhat.com/en/documentation/openshift_container_platform/4.10/html/architecture/architecture-overview)  
69. OpenShift Container Platform 4.18 Architecture \- Red Hat Documentation, otwierano: listopada 17, 2025, [https://docs.redhat.com/de/documentation/openshift\_container\_platform/4.18/pdf/architecture/index](https://docs.redhat.com/de/documentation/openshift_container_platform/4.18/pdf/architecture/index)  
70. OpenShift Learning Resources, otwierano: listopada 17, 2025, [https://etoews.github.io/blog/2018/12/03/openshift-learning-resources/](https://etoews.github.io/blog/2018/12/03/openshift-learning-resources/)  
71. Where can I find the best documentation to get started with OpenShift? \- Reddit, otwierano: listopada 17, 2025, [https://www.reddit.com/r/openshift/comments/g3nv0r/where\_can\_i\_find\_the\_best\_documentation\_to\_get/](https://www.reddit.com/r/openshift/comments/g3nv0r/where_can_i_find_the_best_documentation_to_get/)