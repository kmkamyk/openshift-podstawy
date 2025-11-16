# Moduł 0: Przygotowanie Laboratorium

---

## Lekcja 0.1: Wprowadzenie do OpenShift Local (dawniej CodeReady Containers)

### 0.1.1. Czym jest OpenShift Local (OCP Local)?

Red Hat OpenShift Local, znany wcześniej jako CodeReady Containers (CRC), to samowystarczalna aplikacja zaprojektowana do uruchamiania minimalistycznego, wstępnie skonfigurowanego klastra OpenShift na lokalnej stacji roboczej.[1, 2] Jego głównym celem jest zapewnienie deweloperom i testerom środowiska, które emuluje produkcyjne środowisko chmurowe OpenShift, pozwalając na szybkie rozpoczęcie pracy z budowaniem i testowaniem klastrów OpenShift.[1, 2]

Należy na wstępie wyjaśnić kluczową kwestię terminologiczną. Oficjalna nazwa produktu to **Red Hat OpenShift Local**.[1] Jego poprzednia nazwa, CodeReady Containers (CRC), jest nadal powszechnie spotykana w dokumentacji i na forach.[2, 3, 4] Co najważniejsze, narzędzie wiersza poleceń używane do instalacji i zarządzania tym lokalnym klastrem nazywa się **`crc`**, co jest bezpośrednim dziedzictwem poprzedniej nazwy. W tym module do konfiguracji i zarządzania cyklem życia klastra używane będzie wyłącznie polecenie `crc`. Narzędzie `oc` (standardowy klient CLI OpenShift) [5] będzie natomiast używane do interakcji z *wewnętrznym* API już uruchomionego klastra.

Architektonicznie, OpenShift Local działa jako **klaster jednowęzłowy (single-node cluster)**.[6] Jest to fundamentalna różnica w stosunku do środowisk produkcyjnych, które dla zapewnienia wysokiej dostępności (HA) wymagają wielu węzłów płaszczyzny sterowania (control plane) i wielu węzłów roboczych (worker nodes).[7, 8] OpenShift Local osiąga tę jednowęzłową architekturę poprzez uruchomienie maszyny wirtualnej (VM) na lokalnej stacji roboczej. Wewnątrz tej maszyny wirtualnej, zarówno komponenty płaszczyzny sterowania, jak i funkcje węzła roboczego są uruchomione na tej samej instancji.[1, 9]

OpenShift Local dostarczany jest z lokalną wersją platformy OpenShift Container Platform (OCP).[6] Aby jednak oszczędzać zasoby systemowe na maszynie deweloperskiej, uruchamia się domyślnie z wyłączonymi niektórymi funkcjami. Najbardziej znaczącą z nich jest **monitorowanie klastra**, które jest domyślnie wyłączone, ale może zostać aktywowane przez użytkownika w razie potrzeby.[1]

Istnieją również kluczowe ograniczenia operacyjne. Klaster OpenShift Local jest **efemeryczny** i **nie wspiera automatycznych aktualizacji** ani uaktualnień w miejscu (in-place upgrades).[9] Aby zaktualizować klaster do nowszej wersji, użytkownik musi zniszczyć (usunąć) istniejącą instancję i utworzyć ją na nowo.[10] Ponadto, klaster ma **stałą, niezmienną nazwę** (`crc.local`).[10] Domyślnie, sieć klastra jest również ograniczona tylko do hosta (host-only), co oznacza, że klaster **nie komunikuje się z niczym poza maszyną**, na której jest uruchomiony, chociaż istnieją obejścia tego ograniczenia.[10]

### 0.1.2. Dla kogo jest przeznaczone? (Deweloperzy, nauka)

Docelową grupą odbiorców OpenShift Local są przede wszystkim **deweloperzy i testerzy**.[1, 6] Narzędzie to zapewnia "minimalistyczne środowisko" [1] które jest idealnie dopasowane do ich cyklu pracy. Umożliwia deweloperom lokalne pisanie, budowanie i testowanie aplikacji w sposób, który wiernie naśladuje ich działanie na produkcyjnym klastrze OpenShift.[6] Dzięki temu mogą oni "tworzyć mikrousługi, przekształcać je w obrazy i uruchamiać w kontenerach hostowanych przez Kubernetes" bezpośrednio na swoich laptopach lub komputerach stacjonarnych.[6, 11, 12]

Drugą kluczową grupą odbiorców są osoby **uczące się (nauka)** i uczestniczące w szkoleniach. Ze względu na drastyczne uproszczenie procesu konfiguracji i eliminację potrzeby posiadania kosztownej infrastruktury serwerowej, OpenShift Local jest idealnym narzędziem do nauki i eksploracji platformy OpenShift.[6] Pozwala nowym użytkownikom na bezpieczne eksperymentowanie zarówno z przepływami pracy dewelopera, jak i administratora.

Należy kategorycznie podkreślić, że OpenShift Local **nie jest przeznaczony do użytku produkcyjnego**.[1] Jego jednowęzłowa architektura, efemeryczny charakter oraz domyślne wyłączenie kluczowych usług (jak monitorowanie) sprawiają, że jest on całkowicie nieodpowiedni do obsługi jakichkolwiek rzeczywistych obciążeń roboczych.[9, 10]

W kontekście nauki i rozwoju, nowi użytkownicy często stają przed wyborem: OpenShift Local czy Red Hat Developer Sandbox. Ważne jest, aby zrozumieć różnice:

  * **OpenShift Local (`crc`)**: Uruchamiany jest na *lokalnym* komputerze użytkownika, zużywając jego zasoby (CPU, RAM).[4] Jest używany "tylko przez Ciebie" i ma "nieograniczony" czas użytkowania.[4] Jest to idealne rozwiązanie do pracy w trybie offline oraz do testów wymagających większych zasobów (w granicach możliwości sprzętowych maszyny).
  * **Developer Sandbox**: Jest to *współdzielona, hostowana w chmurze* instancja OpenShift zarządzana przez Red Hat.[4, 13] Nie zużywa *żadnych* lokalnych zasobów, ale ma bardzo *minimalne* przydziały zasobów i jest ograniczona czasowo (np. "30 dni").[4, 13]

Obecny moduł szkoleniowy koncentruje się na OpenShift Local, ponieważ zapewnia on pełną kontrolę nad środowiskiem, nie jest ograniczony czasowo i pozwala na instalację niestandardowych operatorów, co jest kluczowe dla zaawansowanych scenariuszy laboratoryjnych.

### 0.1.3. Jakie są wymagania systemowe? (Kluczowe: RAM, CPU, miejsce na dysku)

Przed instalacją kluczowe jest zweryfikowanie, czy lokalna maszyna spełnia minimalne wymagania systemowe.

**Wymagania Systemu Operacyjnego:**

  * **Windows**: Windows 10 (wersja Fall Creators Update, 1709 lub nowsza).[1]
  * **macOS**: macOS 11 Big Sur lub nowszy. Maszyny z procesorami Apple Silicon (M1/M2/M3) są wspierane.[1]
  * **Linux**: Oficjalnie wspierane są Red Hat Enterprise Linux (RHEL), Fedora oraz CentOS 8 lub nowsze.[1] Inne dystrybucje, takie jak Ubuntu czy Debian, mogą działać, ale mogą wymagać "drobnych zastrzeżeń".[1]
  * Instalacja na Linuksie wymaga dodatkowo zainstalowanych i skonfigurowanych pakietów: `libvirt`, `NetworkManager` oraz `qemu-kvm`.[9]

**Minimalne Wymagania Sprzętowe:**

  * **CPU**: 4 fizyczne rdzenie procesora.[1, 9, 10, 14]
  * **RAM**: 9 GB wolnej pamięci operacyjnej.[1, 9, 10, 15, 14]
  * **Miejsce na Dysku**: 35 GB wolnego miejsca na dysku twardym.[1, 10, 15, 14]

**Konfiguracja Zasobów i Zalecenia Praktyczne:**
Powyższe wartości (9 GB RAM, 4 CPU) to **domyślna konfiguracja** maszyny wirtualnej.[9] Należy jednak podkreślić, że 9 GB RAM to absolutne minimum wymagane do *uruchomienia* klastra w stanie bezczynności. W praktyce, jest to wartość niewystarczająca do komfortowej pracy i nauki.[1]

W momencie, gdy student lub deweloper spróbuje wdrożyć jakąkolwiek aplikację (np. bazę danych, aplikację Java, proces budowania obrazu), limit 9 GB zostanie natychmiast przekroczony. Doprowadzi to do "eksmitowania" podów (Pod evictions) przez klaster, błędów braku pamięci (OOMKilled) i ogólnej niestabilności środowiska, co uniemożliwi realizację ćwiczeń.

Dlatego, chociaż minimum techniczne to 9 GB, **praktycznym minimum** do efektywnej pracy laboratoryjnej jest **16 GB RAM**. Silnie zalecane jest posiadanie maszyny z **32 GB RAM**.[1]

OpenShift Local pozwala na dostosowanie alokacji zasobów za pomocą polecenia `crc config`. Jeśli maszyna dysponuje większą ilością zasobów, można je przydzielić do VM klastra, na przykład [9]:

  * `crc config set memory 16384` (ustawia 16 GB RAM)
  * `crc config set cpus 8` (ustawia 8 rdzeni CPU)

Poniższa tabela podsumowuje wymagania, rozróżniając między absolutnym minimum a zaleceniami dla celów szkoleniowych.

**Tabela 1: Wymagania Systemowe OpenShift Local (OpenShift Local System Requirements)**

| Komponent (Component) | Wymagane Minimum (Minimum Requirement) | Rekomendowane (Recommended for Lab Work) | Źródła (Sources) |
| :--- | :--- | :--- | :--- |
| **CPU** | 4 rdzenie fizyczne (physical cores) | 8+ vCPUs | [1, 9] |
| **RAM** | 9 GB wolnej pamięci (free memory) | 16 GB - 32 GB wolnej pamięci | [1, 9] |
| **Dysk (Disk)** | 35 GB wolnego miejsca (free space) | 50+ GB wolnego miejsca | [1, 10] |
| **System (OS)** | Windows 10 (1709+), macOS 11+, RHEL/Fedora/CentOS 8+ | Najnowsza stabilna wersja OS | [1] |

### 0.1.4. Różnica między OCP (Enterprise) a OKD (Community)

Aby w pełni zrozumieć pozycjonowanie OpenShift Local, konieczne jest rozróżnienie dwóch głównych dystrybucji OpenShift.

**Podstawowe Rozróżnienie:**

  * **Red Hat OpenShift Container Platform (OCP)**: Jest to oficjalny, komercyjny produkt klasy enterprise. Jest oferowany w modelu subskrypcyjnym, w pełni wspierany przez Red Hat i zaprojektowany, aby sprostać rygorystycznym wymaganiom oprogramowania dla przedsiębiorstw.[16, 17, 18, 19]
  * **OKD (Origin Kubernetes Distribution)**: Jest to darmowy, otwarty (open-source) projekt społecznościowy.[3, 16, 18] OKD jest projektem "upstream" dla OCP, co oznacza, że to w nim rozwijane i testowane są nowe funkcje.[16]

**Kluczowe Różnice:**

1.  **Wsparcie (Support):** OCP zawiera pełne wsparcie techniczne 24/7 od Red Hat, 9-letni cykl życia produktu oraz dedykowane zespoły ds. bezpieczeństwa.[16] OKD jest wspierane wyłącznie przez społeczność poprzez kanały na Slacku, GitHubie i listach mailingowych.[16, 20]
2.  **System Operacyjny (OS):** OCP działa *wyłącznie* na systemach **Red Hat Enterprise Linux (RHEL)** oraz **RHEL CoreOS (RHCOS)**.[16, 21] OKD działa na **Fedora CoreOS** lub **CentOS Stream CoreOS**.[16, 21]
3.  **Cykliczność Wydań (Feature Cadence):** Ponieważ OKD jest projektem upstream, nowe funkcje często pojawiają się tam *w pierwszej kolejności* w celu przetestowania, zanim zostaną ustabilizowane i włączone do OCP.[16] Oznacza to, że OKD może być "kilka wydań do przodu pod względem funkcji".[16]
4.  **Koszt (Cost):** OCP wymaga płatnej subskrypcji.[16, 18, 19] OKD jest "całkowicie darmowe do użytku i modyfikacji".[20]

**Miejsce OpenShift Local w Ekosystemie:**
Jak OpenShift Local wpisuje się w ten podział? Narzędzie `crc` (OpenShift Local) jest technicznie "pakowaczem", który może dostarczyć klaster oparty *zarówno* na OCP, jak *i* na OKD, w zależności od pobranego pakietu (bundle).[3]

Jednakże, standardowa, oficjalna dystrybucja OpenShift Local pobierana z portalu Red Hat Developer dostarcza lokalną instancję **OCP (Enterprise)**.[6] Kluczowym dowodem na to jest wymóg posiadania `pull-secret`, który zostanie omówiony w następnej lekcji. `Pull-secret` to klucz uwierzytelniający (entitlement key) powiązany z kontem Red Hat, który autoryzuje pobieranie obrazów z *płatnych, korporacyjnych* rejestrów OCP. Przepływy pracy deweloperskiej w obu wersjach są niemal identyczne, ale dla celów tego laboratorium, uczestnicy będą pracować na lokalnej, jednowęzłowej wersji OCP.

**Tabela 2: Porównanie: OCP (Enterprise) vs. OKD (Community)**

| Cecha (Feature) | OCP (OpenShift Container Platform) | OKD (Origin Kubernetes Distribution) | Źródła (Sources) |
| :--- | :--- | :--- | :--- |
| **Model (Model)** | Produkt komercyjny (Commercial Product) | Projekt Community (Community Project) | [17, 18] |
| **Wsparcie (Support)** | Pełne wsparcie Red Hat 24/7 (Full Red Hat Support) | Wsparcie społeczności (Community Support) | [16, 20] |
| **Koszt (Cost)** | Płatna subskrypcja (Paid Subscription) | Darmowy (Free) | [16, 20, 18] |
| **Bazowy OS (Base OS)** | RHEL CoreOS (RHCOS) | Fedora CoreOS / CentOS Stream CoreOS | [16, 21] |
| **Nowe Funkcje (Features)** | Stabilne, sprawdzone (Stable, Hardened) | "Upstream", nowe funkcje pojawiają się pierwsze | [16] |
| **Certyfikacja (Certification)** | Certyfikowani operatorzy, bazy danych, middleware | Brak formalnej certyfikacji | [16] |

---

## Lekcja 0.2: Instalacja i Konfiguracja OpenShift Local na Twojej Lokalnej Maszynie

### 0.2.1. Pobieranie `crc` z Red Hat Developer Portal

Jak ustalono w Lekcji 0.1, narzędziem wymaganym do instalacji klastra jest plik binarny **`crc`**. Ten plik binarny jest samowystarczalnym programem wykonywalnym, który zarządza całym cyklem życia klastra OpenShift Local.[9] Narzędzie `crc` można pobrać bezpośrednio z portalu Red Hat Developer Portal.

**Procedura pobierania krok po kroku:**

1.  Przejdź do portalu **Red Hat Developer Portal** pod adresem: [https://developers.redhat.com/](https://developers.redhat.com/).[22]
2.  Do pobrania oprogramowania oraz uzyskania klucza `pull-secret` (omówionego poniżej) wymagane jest darmowe konto Red Hat Developer. Zaloguj się lub zarejestruj nowe konto.[23, 22]
3.  Z głównego menu nawigacyjnego wybierz **Products -\> Red Hat OpenShift**.
4.  Na stronie OpenShift znajdź i wybierz opcję **OpenShift Local**.[6, 22]
5.  Na stronie przeglądu produktu OpenShift Local [6] kliknij na główny przycisk akcji, np. **"Install OpenShift on your laptop"** lub **"Download"**.[6, 23]
6.  Zostaniesz przekierowany na stronę pobierania, gdzie należy wybrać plik binarny odpowiedni dla Twojego systemu operacyjnego: **Windows**, **macOS** lub **Linux**.
7.  Pobierz archiwum (`.zip` dla Windows/macOS, `.tar.gz` dla Linux).
8.  Rozpakuj pobrane archiwum. Wewnątrz znajdziesz plik wykonywalny `crc` (lub `crc.exe` na Windows).
9.  Przenieś ten plik binarny `crc` do katalogu, który znajduje się w systemowej zmiennej `PATH` (np. `/usr/local/bin` na Linux/macOS, lub dedykowany folder dodany do `PATH` na Windows). Umożliwi to uruchamianie komendy `crc` z dowolnego miejsca w terminalu.[24, 25]

### 0.2.2. Czym jest `pull-secret` i jak go zdobyć?

Instalacja OpenShift Local (w wersji OCP) wymaga dwóch komponentów: pliku binarnego `crc` oraz klucza `pull-secret`.

**Definicja `pull-secret`:**
`Pull-secret` to token uwierzytelniający.[26] Jest to plik tekstowy w formacie JSON [26, 27, 28] który zawiera zaszyfrowane poświadczenia. Te poświadczenia pozwalają klastrowi OpenShift na uwierzytelnianie się i pobieranie (pull) obrazów kontenerów z zabezpieczonych, prywatnych rejestrów Red Hat.[26, 29, 30, 31]

Rejestry te, takie jak `Quay.io` oraz `registry.redhat.io`, hostują oficjalne, certyfikowane obrazy kontenerów dla komponentów OCP.[26, 27, 29, 30, 31] `Pull-secret` jest w istocie **kluczem licencyjnym (entitlement key)**, który potwierdza uprawnienia Twojego klastra (nawet lokalnego) do dostępu do oprogramowania klasy enterprise, którego potrzebuje do działania.[12]

**Jak zdobyć `pull-secret`:**
`Pull-secret` jest unikalny dla każdego konta Red Hat i można go uzyskać z portalu **Red Hat OpenShift Cluster Manager (OCM)**.[26, 27, 32, 33]

**Procedura krok po kroku:**

1.  Zaloguj się do portalu Red Hat OpenShift Cluster Manager: [https://console.redhat.com/openshift/](https://www.google.com/search?q=https://console.redhat.com/openshift/).[33] Użyj tego samego konta Red Hat, którego użyłeś do pobrania `crc`.
2.  W głównym panelu nawigacyjnym portalu przejdź do strony **"Downloads"**.[33]
3.  Na stronie pobierania zlokalizuj sekcję zatytułowaną **"Tokens"** (Tokeny).[33]
4.  W tej sekcji znajdziesz wpis **"Pull Secret"**.
5.  Masz dwie opcje [26, 32, 33]:
      * **Click "Download pull secret"**: Spowoduje to pobranie pliku `pull-secret.txt` na Twój komputer.
      * **Click "Copy pull secret"**: Spowoduje to skopiowanie całej zawartości JSON klucza do schowka systemowego.

Zaleca się skopiowanie klucza do schowka, ponieważ będzie on potrzebny podczas procesu `crc start`.

### 0.2.3. Inicjalizacja środowiska: `crc setup`

Zanim będzie można uruchomić klaster, należy przygotować maszynę hosta. Służy do tego polecenie `crc setup`.

**Cel polecenia `crc setup`:**
Polecenie `crc setup` [23] nie uruchamia klastra. Jego zadaniem jest skonfigurowanie lokalnej maszyny (hosta) tak, aby była gotowa do uruchomienia maszyny wirtualnej OpenShift Local.[23]

**Co `crc setup` robi "pod maską":**

  * Weryfikuje, czy system spełnia minimalne wymagania (CPU, RAM, dysk).
  * Tworzy katalog `~/.crc` (lub `C:\Users\<user>\.crc` na Windows), jeśli jeszcze nie istnieje. Będzie on używany do przechowywania plików konfiguracyjacych, pobranego obrazu VM i innych zasobów.[23]
  * Na **Linux**: Konfiguruje `libvirt` i `NetworkManager` pod kątem sieci wirtualnej klastra. Ten krok może wymagać podania hasła `sudo`.[9, 23]
  * Na **Windows/macOS**: Konfiguruje domyślny hiperwizor systemowy (Hyper-V na Windows Pro, lub HyperKit/Virtualization Framework na macOS). Ten krok może wymagać uprawnień administratora.[23]
  * **Pobiera obraz maszyny wirtualnej**: Jest to najdłuższy etap. `crc` pobierze ważący wiele gigabajtów obraz dysku VM zawierający RHEL CoreOS i wstępnie załadowane obrazy OpenShift. Czas trwania "może być długi, w zależności od szybkości sieci i dysku".[9]
  * Rozpakowuje plik binarny `oc` (OpenShift CLI) i umieszcza go w wewnętrznej pamięci podręcznej (`~/.crc/bin`), skąd zostanie później dodany do ścieżki `PATH`.[23]

**Wykonanie:**

1.  Otwórz nowy terminal.
2.  Uruchom polecenie: `crc setup`
3.  Zostaniesz poproszony o podanie hasła administratora/`sudo` w celu skonfigurowania sieci lub hiperwizora.[9, 23]
4.  Poczekaj na zakończenie procesu, który może potrwać kilkanaście minut, w zależności od szybkości pobierania.

### 0.2.4. Uruchomienie klastra: `crc start`

Po pomyślnym przygotowaniu środowiska przez `crc setup`, można uruchomić klaster za pomocą polecenia `crc start`.

**Cel polecenia `crc start`:**
To polecenie [23] faktycznie tworzy, konfiguruje i uruchamia (bootuje) jednowęzłową maszynę wirtualną klastra OpenShift.

**Wykonanie:**

1.  W terminalu uruchom polecenie: `crc start`.[23]
2.  **Kluczowy krok**: Podczas *pierwszego* uruchomienia, `crc` zatrzyma proces i **wyświetli monit o podanie klucza `pull-secret`**.[23]
3.  Wklej w terminalu całą zawartość JSON klucza `pull-secret` (skopiowaną wcześniej z portalu OCM).
4.  Naciśnij Enter.
5.  `crc` rozpocznie teraz proces uruchamiania:
      * Utworzy instancję maszyny wirtualnej (np. w Hyper-V lub libvirt).
      * Wstrzyknie (inject) dostarczony `pull-secret` do konfiguracji maszyny wirtualnej.
      * Uruchomi maszynę wirtualną i poczeka na start systemu RHEL CoreOS.
      * Rozpocznie proces uruchamiania usług OpenShift (płaszczyzny sterowania, API, kubelet itd.).
      * Proces ten trwa "minimum cztery minuty" [23], ale w praktyce pierwsze uruchomienie zajmuje zazwyczaj od 10 do 15 minut.

**Pomyślne Uruchomienie:**
Po zakończeniu procesu, w terminalu wyświetlony zostanie komunikat podobny do poniższego, zawierający wszystkie kluczowe informacje [1, 23]:

```bash
INFO  Starting OpenShift cluster...
INFO  OpenShift cluster is running.

To access the cluster, remove the 'KUBECONFIG' environment variable
or run 'export KUBECONFIG=~/.crc/machines/crc/kubeconfig'
To login as root, run 'oc login -u kubeadmin -p <kubeadmin-password>'
To login as developer, run 'oc login -u developer -p <developer-password>'

Run 'crc console' to access the OpenShift web console.
```

*(Uwaga: Dokładne hasła dla `kubeadmin` i `developer` zostaną wygenerowane i wyświetlone w tym miejscu).*

### 0.2.5. Gdzie są przechowywane kluczowe informacje (kubeconfig, hasła)

Po uruchomieniu klastra, kluczowe dane dostępowe są przechowywane w określonych lokalizacjach lub dostępne za pomocą poleceń `crc`.

**Plik `kubeconfig`:**
Plik `kubeconfig`, który zawiera poświadczenia administratora i informacje o punkcie końcowym API klastra, *nie jest* automatycznie dodawany do domyślnej lokalizacji `~/.kube/config`. Jest on przechowywany w katalogu zasobów `crc`, w ścieżce podobnej do:
`~/.crc/machines/crc/kubeconfig`.[23]

Dokładna ścieżka jest zawsze drukowana w danych wyjściowych polecenia `crc start`.

**Hasła (`kubeadmin` i `developer`):**
Hasła dla dwóch domyślnych użytkowników (`kubeadmin` i `developer`) są generowane losowo podczas procesu `crc start` i są **drukowane w terminalu** po pomyślnym uruchomieniu.[23]

**Metoda Ekspercka (Preferowany sposób dostępu do informacji):**
Nie ma potrzeby ręcznego wyszukiwania pliku `kubeconfig` ani kopiowania haseł z wyjścia terminala za każdym razem. Narzędzie `crc` udostępnia polecenia pomocnicze do zarządzania dostępem:

  * **Aby wyświetlić URL konsoli i oba hasła:**
    `crc console --credentials` [23]
    To polecenie jest najpewniejszym sposobem na odzyskanie haseł, jeśli terminal został wyczyszczony.

  * **Aby skonfigurować bieżącą powłokę (shell) do pracy z klastrem:**
    `crc oc-env` [23]
    To polecenie *drukuje* komendę, którą należy wykonać w powłoce (np. `eval $(crc oc-env)` dla bash/zsh), aby tymczasowo ustawić zmienną `KUBECONFIG` i dodać `oc` do `PATH`.

  * **Aby zobaczyć aktualną konfigurację `oc`:**
    `oc config view` [34, 35, 36]
    Po uruchomieniu `eval $(crc oc-env)`, to polecenie pokaże, że `oc` jest teraz skonfigurowane do wskazywania klastra `crc`.

---

## Lekcja 0.3: Pierwsze logowanie – `oc login` vs Konsola Webowa. Weryfikacja stanu klastra.

### 0.3.1. Jak znaleźć adres URL konsoli i hasło `kubeadmin`

Po pomyślnym uruchomieniu klastra za pomocą `crc start`, istnieją trzy proste metody uzyskania dostępu do danych logowania.

  * **Metoda 1: Dane wyjściowe `crc start` (Pierwsze uruchomienie)**
    Jak pokazano w Lekcji 0.2, adres URL konsoli oraz hasła dla `kubeadmin` i `developer` są drukowane bezpośrednio w terminalu natychmiast po zakończeniu uruchamiania klastra.[23]

  * **Metoda 2: Polecenie `crc console` (Najprostsza metoda)**
    Aby automatycznie otworzyć konsolę webową w domyślnej przeglądarce, wystarczy uruchomić polecenie:
    `crc console` [23]
    To polecenie samo pobierze właściwy adres URL i zainicjuje otwarcie go w przeglądarce.

  * **Metoda 3: Polecenie `crc console --credentials` (Metoda informacyjna)**
    Aby **wyświetlić** adres URL konsoli, adres API serwera oraz hasła dla `kubeadmin` i `developer` *bez* automatycznego otwierania przeglądarki, należy uruchomić polecenie:
    `crc console --credentials` [23]
    Jest to najbardziej niezawodna metoda pobierania poświadczeń w dowolnym momencie.

### 0.3.2. Logowanie przez `oc login -u kubeadmin...`

Zanim będzie można użyć klienta wiersza poleceń `oc` do zalogowania się, terminal musi "wiedzieć", gdzie znajduje się plik binarny `oc` i jakiego klastra ma używać.

**Warunek wstępny: Konfiguracja powłoki (Shell)**

1.  W terminalu uruchom polecenie `crc oc-env`.[23] Spowoduje to wydrukowanie komendy specyficznej dla Twojej powłoki (np. `eval $(crc oc-env)` dla bash/zsh, lub `crc oc-env | Invoke-Expression` dla PowerShell).
2.  Uruchom komendę, którą wydrukowało `crc oc-env`. To polecenie tymczasowo ustawi zmienną środowiskową `KUBECONFIG` tak, aby wskazywała na plik konfiguracyjny klastra `crc` oraz doda katalog `~/.crc/bin` (zawierający `oc`) do Twojej systemowej zmiennej `PATH`.

**Logowanie CLI (jako Administrator):**
Teoretycznie, proces logowania jako `kubeadmin` wyglądałby następująco:

1.  Zdobądź hasło `kubeadmin` poleceniem `crc console --credentials`.[23]
2.  Zdobądź adres URL serwera API z tego samego polecenia (np. `https://api.crc.testing:6443`).[23]
3.  Uruchom pełne polecenie `oc login`:
    `oc login -u kubeadmin -p <twoje-haslo-kubeadmin> https://api.crc.testing:6443`.[23, 37]

**Prostszy Sposób (Praktyka w OpenShift Local):**
W praktyce, krok `oc login` dla użytkownika `kubeadmin` **nie jest konieczny**.

Plik `kubeconfig` dostarczany przez `crc` (i aktywowany przez `crc oc-env`) jest już wstępnie skonfigurowany z tokenem uwierzytelniającym dla `kubeadmin`.[23] Oznacza to, że natychmiast po uruchomieniu `eval $(crc oc-env)`, Twoja sesja terminala jest **automatycznie zalogowana jako `kubeadmin`**.

Można to natychmiast zweryfikować, uruchamiając:
`oc whoami`
Wynik powinien brzmieć: `kubeadmin`.[23]

### 0.3.3. Logowanie jako domyślny użytkownik `developer`

OpenShift Local udostępnia dwóch użytkowników, aby odzwierciedlić fundamentalną zasadę bezpieczeństwa OpenShift: separację ról.

  * `kubeadmin`: Super-użytkownik (administrator klastra), który może zarządzać wszystkim.
  * `developer`: Użytkownik o ograniczonych uprawnieniach, który może tworzyć projekty i zarządzać aplikacjami *wewnątrz* tych projektów, ale nie może modyfikować globalnych ustawień klastra.[23]

Do pracy laboratoryjnej i codziennego rozwoju, zalecane jest używanie konta `developer`.

**Logowanie przez Konsolę Webową (jako Developer):**

1.  Uruchom `crc console`, aby otworzyć przeglądarkę.
2.  Na ekranie logowania wybierz opcję logowania za pomocą `developer` (lub wpisz `developer` jako nazwę użytkownika).
3.  Pobierz hasło dla użytkownika `developer` za pomocą `crc console --credentials`.[23]
4.  Wklej hasło i zaloguj się. Zostaniesz automatycznie przekierowany do **Perspektywy Dewelopera**.

**Logowanie przez CLI (jako Developer):**

1.  Upewnij się, że Twoja powłoka jest skonfigurowana (uruchomiłeś `eval $(crc oc-env)`).
2.  Pobierz hasło `developer` za pomocą `crc console --credentials`.[23]
3.  Uruchom polecenie `oc login`:
    `oc login -u developer -p <twoje-haslo-developer> https://api.crc.testing:6443`.[23]
4.  Po pomyślnym logowaniu, zweryfikuj sesję, uruchamiając `oc whoami`.
5.  Terminal zwróci teraz: `developer`. Od tego momentu wszystkie operacje `oc` będą wykonywane z uprawnieniami dewelopera.

### 0.3.4. Pierwsze spojrzenie na konsolę: Perspektywa Administratora vs Dewelopera

Konsola webowa OpenShift jest centralnym punktem zarządzania i interakcji z klastrem. Jej najbardziej charakterystyczną cechą jest przełącznik perspektyw (Perspective Switcher), zwykle znajdujący się w lewym górnym rogu interfejsu, który pozwala przełączać się między widokami "Administrator" i "Developer".[38, 39, 40, 41]

**Perspektywa Administratora (Administrator Perspective):**
Jest to domyślny widok podczas logowania jako `kubeadmin`.[38, 39] Koncentruje się ona na **globalnej infrastrukturze i operacjach na poziomie całego klastra**.

  * **Kluczowe zadania:** Zarządzanie węzłami (w OCP Local jest tylko jeden), globalnymi ustawieniami klastra, pamięcią masową (storage) i siecią.[42, 43, 44]
  * **Zarządzanie użytkownikami:** Konfiguracja dostawców tożsamości (Identity Providers) i zarządzanie dostępem użytkowników poprzez Role-Based Access Control (RBAC).[42, 43]
  * **Zarządzanie operatorami:** Dostęp do OperatorHub, instalowanie i zarządzanie cyklem życia Operatorów na poziomie klastra.[43]
  * **Monitorowanie klastra:** Przeglądanie stanu operatorów klastra (`oc get co`), metryk, alertów i globalnych przydziałów zasobów (quotas).[42, 43]

**Perspektywa Dewelopera (Developer Perspective):**
Jest to domyślny widok dla użytkownika `developer`.[39] Koncentruje się ona na **przepływach pracy zorientowanych na aplikacje w kontekście wybranego projektu (przestrzeni nazw)**.

  * **Kluczowe zadania:** Tworzenie, wdrażanie i monitorowanie aplikacji.[45, 38, 39]
  * **Widok "+Add":** Uproszczony interfejs do wdrażania aplikacji z różnych źródeł: repozytorium Git, obrazu kontenera, pliku Dockerfile lub z katalogu dewelopera (Developer Catalog).[46, 47]
  * **Widok Topologii (Topology View):** Kluczowa funkcja tej perspektywy. Jest to wizualny graf reprezentujący aplikacje, ich komponenty (Deployment, Pods) oraz relacje między nimi (np. połączenia sieciowe).[39, 46]
  * **CI/CD:** Dostęp do interfejsu OpenShift Pipelines (jeśli jest zainstalowany), umożliwiający wizualizację i zarządzanie potokami ciągłej integracji i dostarczania.[46]

**Ewolucja interfejsu: "Zunifikowana Konsola"**
Chociaż podział na perspektywę administratora i dewelopera jest logiczny i stanowi podstawę filozofii OpenShift, warto zauważyć, że w nowszych wersjach platformy (OCP 4.19+) ten paradygmat ulega ewolucji.[41]

Badania użytkowników przeprowadzone przez Red Hat wykazały, że model dwóch perspektyw, choć miał na celu uproszczenie interfejsu, w rzeczywistości powodował "tarcie" (friction) w pracy. Stwierdzono, że **ponad 53% użytkowników** często przełączało się między perspektywami, czasami "nawet 15 razy w jednej sesji".[41] To "ciągłe przełączanie zakłócało przepływy pracy, powodowało zamieszanie i stwarzało niepotrzebną nieefektywność".[41]

W odpowiedzi na te obserwacje, Red Hat wprowadza **"zunifikowane doświadczenie konsoli" (unified console experience)**. Ta nowa perspektywa łączy najważniejsze funkcje z obu widoków, wspierając lepiej hybrydowe role, takie jak "inżynier platformy" (platform engineer). Chociaż w ramach tego laboratorium studenci będą uczyć się klasycznego podziału, ważne jest, aby wiedzieć o tej ewolucji i przyczynach, które do niej doprowadziły.

### 0.3.5. Podstawowe komendy weryfikacyjne: `oc whoami`, `oc status`, `oc get clusteroperators`

Po zalogowaniu się przez CLI, istnieje zestaw podstawowych poleceń służących do weryfikacji tożsamości i stanu środowiska.

**`oc whoami`**

  * **Cel:** Jest to najprostsze polecenie weryfikujące. Wyświetla nazwę użytkownika, jako który jesteś aktualnie uwierzytelniony w aktywnej sesji CLI.[35, 48]
  * **Użycie:** `oc whoami` (Zwróci `kubeadmin` lub `developer`).
  * **Flaga zaawansowana (`-t`):** Użycie `oc whoami -t` spowoduje wydrukowanie surowego tokena okaziciela (bearer token) OIDC dla bieżącej sesji.[48] Jest to niezwykle przydatne do debugowania lub bezpośredniej interakcji z API OpenShift za pomocą narzędzi takich jak `curl`.

**`oc status`**

  * **Cel:** Zapewnia ogólny, czytelny dla człowieka przegląd zasobów i ich stanu w **bieżącym projekcie**.[49, 50]
  * **Zakres:** **Zakres projektowy (Project-Scoped)**. Jest to polecenie przeznaczone głównie dla deweloperów, aby mogli szybko ocenić stan swoich aplikacji.
  * **Analiza wyjścia [36]:**
    ```
    In project default on server [https://api.crc.testing:6443](https://api.crc.testing:6443)
    svc/app001 - 10.17.52.114:27017
    deployment/app001 deploys...
        deployment #5 running for 6 months - 1 pod
    ```
    Jak widać, polecenie informuje o aktywnym projekcie, wykrywa usługi (services), wdrożenia (deployments) i ich aktualny stan (np. "running") w ramach *tego* projektu.

**`oc get clusteroperators` (lub skrót `oc get co`)**

  * **Cel:** Jest to **najważniejsze polecenie administratora** służące do sprawdzania ogólnego stanu "zdrowia" **całego klastra**. Pokazuje status podstawowych komponentów (Operatorów), które zarządzają samym OpenShift (np. uwierzytelnianie, serwer API, sieć, konsola).[51, 52, 53, 54, 55]
  * **Zakres:** **Zakres klastrowy (Cluster-Scoped)**.
  * **Kluczowe Kolumny [53]:**
      * `NAME`: Nazwa kluczowego komponentu klastra (np. `authentication`, `console`, `network`).
      * `AVAILABLE`: `True` oznacza, że operator działa i jest dostępny.
      * `PROGRESSING`: `True` oznacza, że operator jest w trakcie aktualizacji lub wprowadzania zmian (np. podczas uaktualniania klastra).
      * `DEGRADED`: `True` oznacza, że operator napotkał błąd i **nie działa poprawnie**. **Jest to krytyczna kolumna do monitorowania.** Prawidłowo działający klaster powinien mieć `False` we wszystkich wierszach tej kolumny.

Podsumowanie tych trzech poleceń doskonale ilustruje różnice w zakresach odpowiedzialności w OpenShift.

**Tabela 3: Podstawowe Komendy Weryfikacyjne (Basic Verification Commands)**

| Komenda (Command) | Zasięg (Scope) | Główny Użytkownik (Primary User) | Cel (Purpose) | Źródła (Sources) |
| :--- | :--- | :--- | :--- | :--- |
| **`oc whoami`** | Sesja Użytkownika (User Session) | Wszyscy (All) | Weryfikuje, jako kto jesteś zalogowany. (Verifies who you are logged in as.) | [48] |
| **`oc status`** | Projekt (Project-Scoped) | Deweloper (Developer) | Pokazuje status aplikacji i serwisów *wewnątrz* projektu. (Shows status of apps/services *inside* a project.) | [50, 36] |
| **`oc get co`** | Klaster (Cluster-Scoped) | Administrator (Admin) | Pokazuje stan "zdrowia" podstawowych komponentów *całego* klastra. (Shows health of the *entire* cluster's core components.) | [53] |

---

## Cytowane prace

1. Red Hat OpenShift Local, otwierano: listopada 14, 2025, [https://openshift.guide/getting-started/openshift-local.html](https://openshift.guide/getting-started/openshift-local.html)  
2. OpenShift Local Development \- Comparing Your Options \- Infralovers, otwierano: listopada 14, 2025, [https://www.infralovers.com/blog/2025-10-14-openshift-local-development-environments/](https://www.infralovers.com/blog/2025-10-14-openshift-local-development-environments/)  
3. Red Hat OpenShift Local, otwierano: listopada 14, 2025, [https://developers.redhat.com/products/openshift-local/overview](https://developers.redhat.com/products/openshift-local/overview)  
4. Compare OKD vs CodeReady Containers vs OpenShift Local \- DevOpsSchool.com, otwierano: listopada 14, 2025, [https://www.devopsschool.com/blog/openshift-compare-okd-vs-codeready-containers-vs-openshift-local/](https://www.devopsschool.com/blog/openshift-compare-okd-vs-codeready-containers-vs-openshift-local/)  
5. What's new in OpenShift Local 2.0 \- Red Hat Developer, otwierano: listopada 14, 2025, [https://developers.redhat.com/articles/2022/05/10/whats-new-openshift-local-20](https://developers.redhat.com/articles/2022/05/10/whats-new-openshift-local-20)  
6. Download and install the Red Hat OpenShift CLI, otwierano: listopada 14, 2025, [https://developers.redhat.com/learn/openshift/download-and-install-red-hat-openshift-cli](https://developers.redhat.com/learn/openshift/download-and-install-red-hat-openshift-cli)  
7. Developer sandbox Vs Openshift local : r/redhat \- Reddit, otwierano: listopada 14, 2025, [https://www.reddit.com/r/redhat/comments/16g56f4/developer\_sandbox\_vs\_openshift\_local/](https://www.reddit.com/r/redhat/comments/16g56f4/developer_sandbox_vs_openshift_local/)  
8. System requirements \- IBM, otwierano: listopada 14, 2025, [https://www.ibm.com/docs/en/spectrum-discover/2.0.5?topic=planning-system-requirements](https://www.ibm.com/docs/en/spectrum-discover/2.0.5?topic=planning-system-requirements)  
9. OpenShift Requirements \- Documentation, otwierano: listopada 14, 2025, [https://docs.rackn.io/v4.14.30/arch/provisioning/application/openshift/requirements/](https://docs.rackn.io/v4.14.30/arch/provisioning/application/openshift/requirements/)  
10. How to install Red Hat OpenShift Local on your laptop, otwierano: listopada 14, 2025, [https://www.redhat.com/en/blog/install-openshift-local](https://www.redhat.com/en/blog/install-openshift-local)  
11. OpenShift Local or Single Node OpenShift – Open Sourcerers, otwierano: listopada 14, 2025, [https://www.opensourcerers.org/2022/09/13/openshift-local-or-single-node-openshift/](https://www.opensourcerers.org/2022/09/13/openshift-local-or-single-node-openshift/)  
12. Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/](https://docs.redhat.com/)  
13. Chapter 2\. OpenShift Container Platform overview | Getting started \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.12/html/getting\_started/openshift-overview](https://docs.redhat.com/en/documentation/openshift_container_platform/4.12/html/getting_started/openshift-overview)  
14. Download Red Hat Openshift, otwierano: listopada 14, 2025, [https://developers.redhat.com/products/openshift/download](https://developers.redhat.com/products/openshift/download)  
15. Getting Started with OpenShift Local | by Sanjit Chakraborty | Medium, otwierano: listopada 14, 2025, [https://sanjitcibm.medium.com/getting-started-with-openshift-local-f59c07cbfd4c](https://sanjitcibm.medium.com/getting-started-with-openshift-local-f59c07cbfd4c)  
16. Running Red Hat OpenShift on a Tiny Form Factor: My Hardware Picks and Setup Guide, otwierano: listopada 14, 2025, [https://nleiva.medium.com/running-red-hat-openshift-on-a-tiny-form-factor-my-hardware-picks-and-setup-guide-e540323da810](https://nleiva.medium.com/running-red-hat-openshift-on-a-tiny-form-factor-my-hardware-picks-and-setup-guide-e540323da810)  
17. Red Hat OpenShift vs. OKD, otwierano: listopada 14, 2025, [https://www.redhat.com/en/topics/containers/red-hat-openshift-okd](https://www.redhat.com/en/topics/containers/red-hat-openshift-okd)  
18. OKD vs OCP \- Red Hat Learning Community, otwierano: listopada 14, 2025, [https://learn.redhat.com/t5/Kube-by-Example-KBE/OKD-vs-OCP/td-p/23997](https://learn.redhat.com/t5/Kube-by-Example-KBE/OKD-vs-OCP/td-p/23997)  
19. OKD vs OpenShift \- Reddit, otwierano: listopada 14, 2025, [https://www.reddit.com/r/openshift/comments/dyrnlj/okd\_vs\_openshift/](https://www.reddit.com/r/openshift/comments/dyrnlj/okd_vs_openshift/)  
20. Compliance in the Cloud: Compliant Kubernetes vs OpenShift \- elastisys, otwierano: listopada 14, 2025, [https://elastisys.com/compliant-kubernetes-vs-openshift/](https://elastisys.com/compliant-kubernetes-vs-openshift/)  
21. Differences between Red Hat Openshift Container Platform (OCP) and OKD \- Reddit, otwierano: listopada 14, 2025, [https://www.reddit.com/r/openshift/comments/qbw0ai/differences\_between\_red\_hat\_openshift\_container/](https://www.reddit.com/r/openshift/comments/qbw0ai/differences_between_red_hat_openshift_container/)  
22. Self-managed Red Hat OpenShift subscription guide, otwierano: listopada 14, 2025, [https://www.redhat.com/en/resources/self-managed-openshift-subscription-guide](https://www.redhat.com/en/resources/self-managed-openshift-subscription-guide)  
23. Getting started with Red Hat OpenShift Local | Red Hat Developer, otwierano: listopada 14, 2025, [https://developers.redhat.com/products/openshift-local/getting-started](https://developers.redhat.com/products/openshift-local/getting-started)  
24. Red Hat Developer, otwierano: listopada 14, 2025, [https://developers.redhat.com/](https://developers.redhat.com/)  
25. Chapter 1\. OpenShift Container Platform installation overview \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.10/html/installing/ocp-installation-overview](https://docs.redhat.com/en/documentation/openshift_container_platform/4.10/html/installing/ocp-installation-overview)  
26. Getting started with the OpenShift CLI \- OKD Documentation, otwierano: listopada 14, 2025, [https://docs.okd.io/4.18/cli\_reference/openshift\_cli/getting-started-cli.html](https://docs.okd.io/4.18/cli_reference/openshift_cli/getting-started-cli.html)  
27. Chapter 1\. OpenShift CLI (oc) | CLI tools \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.2/html/cli\_tools/openshift-cli-oc](https://docs.redhat.com/en/documentation/openshift_container_platform/4.2/html/cli_tools/openshift-cli-oc)  
28. Add or update your Red Hat pull secret on an Azure Red Hat OpenShift 4 cluster, otwierano: listopada 14, 2025, [https://learn.microsoft.com/en-us/azure/openshift/howto-add-update-pull-secret](https://learn.microsoft.com/en-us/azure/openshift/howto-add-update-pull-secret)  
29. Chapter 5\. Managing images | Images | OpenShift Container Platform | 4.8 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/images/managing-images](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/images/managing-images)  
30. otwierano: listopada 14, 2025, [https://docs.okd.io/4.18/openshift\_images/managing\_images/using-image-pull-secrets.html\#:\~:text=You%20can%20obtain%20the%20image,container%20images%20for%20OKD%20components.](https://docs.okd.io/4.18/openshift_images/managing_images/using-image-pull-secrets.html#:~:text=You%20can%20obtain%20the%20image,container%20images%20for%20OKD%20components.)  
31. Chapter 5\. Managing images | Images | OpenShift Container ..., otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.13/html/images/managing-images](https://docs.redhat.com/en/documentation/openshift_container_platform/4.13/html/images/managing-images)  
32. Using image pull secrets \- Managing images | Images | OKD 4.18 \- OKD Documentation, otwierano: listopada 14, 2025, [https://docs.okd.io/4.18/openshift\_images/managing\_images/using-image-pull-secrets.html](https://docs.okd.io/4.18/openshift_images/managing_images/using-image-pull-secrets.html)  
33. Optional: Obtain a Red Hat pull secret \- IBM, otwierano: listopada 14, 2025, [https://www.ibm.com/docs/en/guardium-insights/3.2.x?topic=aro-optional-obtain-red-hat-pull-secret](https://www.ibm.com/docs/en/guardium-insights/3.2.x?topic=aro-optional-obtain-red-hat-pull-secret)  
34. Chapter 4\. Managing your clusters | Managing clusters | OpenShift ..., otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_cluster\_manager/1-latest/html/managing\_clusters/assembly-managing-clusters](https://docs.redhat.com/en/documentation/openshift_cluster_manager/1-latest/html/managing_clusters/assembly-managing-clusters)  
35. Chapter 2\. Accessing the web console | Web console | OpenShift ..., otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.13/html/web\_console/web-console](https://docs.redhat.com/en/documentation/openshift_container_platform/4.13/html/web_console/web-console)  
36. Chapter 2\. OpenShift CLI (oc) \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.9/html/cli\_tools/openshift-cli-oc](https://docs.redhat.com/en/documentation/openshift_container_platform/4.9/html/cli_tools/openshift-cli-oc)  
37. OpenShift CLI developer command reference \- OpenShift CLI (oc ..., otwierano: listopada 14, 2025, [https://docs.okd.io/latest/cli\_reference/openshift\_cli/developer-cli-commands.html](https://docs.okd.io/latest/cli_reference/openshift_cli/developer-cli-commands.html)  
38. CLI Reference | OpenShift Container Platform | 3.5 \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.5/html-single/cli\_reference/index](https://docs.redhat.com/en/documentation/openshift_container_platform/3.5/html-single/cli_reference/index)  
39. Accessing Red Hat OpenShift clusters \- IBM Cloud Docs, otwierano: listopada 14, 2025, [https://cloud.ibm.com/docs/openshift?topic=openshift-access\_cluster](https://cloud.ibm.com/docs/openshift?topic=openshift-access_cluster)  
40. What is the difference between application console vs cluster console? \- Stack Overflow, otwierano: listopada 14, 2025, [https://stackoverflow.com/questions/65487799/what-is-the-difference-between-application-console-vs-cluster-console](https://stackoverflow.com/questions/65487799/what-is-the-difference-between-application-console-vs-cluster-console)  
41. Chapter 5\. About the Developer perspective in the web console ..., otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.4/html/web\_console/odc-about-developer-perspective](https://docs.redhat.com/en/documentation/openshift_container_platform/4.4/html/web_console/odc-about-developer-perspective)  
42. Chapter 5\. About the Developer perspective in the web console | Web console | OpenShift Container Platform | 4.2 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.2/html/web\_console/odc-about-developer-perspective](https://docs.redhat.com/en/documentation/openshift_container_platform/4.2/html/web_console/odc-about-developer-perspective)  
43. Chapter 3\. Creating and building an application using the web console | Getting started | OpenShift Container Platform \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.11/html/getting\_started/openshift-web-console](https://docs.redhat.com/en/documentation/openshift_container_platform/4.11/html/getting_started/openshift-web-console)  
44. OpenShift 101 \- IBM Developer, otwierano: listopada 14, 2025, [https://developer.ibm.com/articles/openshift-101/](https://developer.ibm.com/articles/openshift-101/)  
45. Chapter 1\. Web Console Overview | Web console | Red Hat ..., otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/red\_hat\_openshift\_service\_on\_aws\_classic\_architecture/4/html/web\_console/web-console-overview](https://docs.redhat.com/en/documentation/red_hat_openshift_service_on_aws_classic_architecture/4/html/web_console/web-console-overview)  
46. Chapter 1\. Web Console Overview | Web console | OpenShift Container Platform | 4.8, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/web\_console/web-console-overview](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/web_console/web-console-overview)  
47. Tour of the Developer Perspective in the Red Hat OpenShift 4.2 web console, otwierano: listopada 14, 2025, [https://developers.redhat.com/blog/2019/10/16/openshift-developer-perspective](https://developers.redhat.com/blog/2019/10/16/openshift-developer-perspective)  
48. Creating applications using the Developer perspective \- OKD Documentation, otwierano: listopada 14, 2025, [https://docs.okd.io/latest/applications/creating\_applications/odc-creating-applications-using-developer-perspective.html](https://docs.okd.io/latest/applications/creating_applications/odc-creating-applications-using-developer-perspective.html)  
49. OpenShift 4.19 brings a unified console for developers and admins ..., otwierano: listopada 14, 2025, [https://developers.redhat.com/articles/2025/06/26/openshift-419-brings-unified-console-developers-and-admins](https://developers.redhat.com/articles/2025/06/26/openshift-419-brings-unified-console-developers-and-admins)  
50. The oc Command for Newbies \- Red Hat, otwierano: listopada 14, 2025, [https://www.redhat.com/en/blog/oc-command-newbies](https://www.redhat.com/en/blog/oc-command-newbies)  
51. Chapter 1\. OpenShift CLI (oc) | CLI tools | OpenShift Container ..., otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.5/html/cli\_tools/openshift-cli-oc](https://docs.redhat.com/en/documentation/openshift_container_platform/4.5/html/cli_tools/openshift-cli-oc)  
52. OpenShift \- Deployment status using the oc status ... \- Bootstrap, otwierano: listopada 14, 2025, [https://www.freekb.net/Article?id=2694](https://www.freekb.net/Article?id=2694)  
53. ClusterOperator \[config.openshift.io/v1\] \- Config APIs | API reference | OKD 4.17, otwierano: listopada 14, 2025, [https://docs.okd.io/4.17/rest\_api/config\_apis/clusteroperator-config-openshift-io-v1.html](https://docs.okd.io/4.17/rest_api/config_apis/clusteroperator-config-openshift-io-v1.html)  
54. OpenShift ClusterOperatorDegraded \- Doctor Droid, otwierano: listopada 14, 2025, [https://drdroid.io/stack-diagnosis/openshift-clusteroperatordegraded](https://drdroid.io/stack-diagnosis/openshift-clusteroperatordegraded)  
55. Check OpenShift / OKD Cluster Version and Operators Status ..., otwierano: listopada 14, 2025, [https://computingforgeeks.com/check-openshift-okd-cluster-version-and-operators-status/](https://computingforgeeks.com/check-openshift-okd-cluster-version-and-operators-status/)