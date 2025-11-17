# 🚀 Ścieżka Nauki: Poziomu Średniozaawansowanego w OpenShift

Witaj! To repozytorium to mój osobisty, ustrukturyzowany **konspekt tematyczny** (zbiór zagadnień) dotyczący platformy OpenShift.

Nie jest to formalne szkolenie, lecz mapa drogowa i omówienie tematów, które opracowałem podczas własnej nauki. Repozytorium jest zorganizowane w logiczne ścieżki, które odpowiadają różnym rolom w ekosystemie OpenShift.

> **Uwaga:** Poniższe zestawienie tematów i cała agenda zostały pierwotnie wygenerowane przy pomocy AI. Materiały te służą jako wsparcie w nauce i mogą zawierać błędy lub nieścisłości. Nie należy traktować ich jako oficjalnej dokumentacji.

---

## Przegląd Ścieżek (Szybka Nawigacja wg Ról)

### Ścieżka 1: Operator Aplikacji / Deweloper

Ta ścieżka jest zaprojektowana dla każdego, kto chce nauczyć się budować, wdrażać i zarządzać aplikacjami w OpenShift.
* [Przejdź do modułów `op-`...](#moduły-główne-ścieżka-op)

### Ścieżka 2: Administrator Infrastruktury

Ta ścieżka jest przeznaczona dla administratorów VMware, storage, sieci i sprzętu. Skupia się na tym, jak OpenShift jest **instalowany** i **integrowany** z tradycyjnym centrum danych.
* [Przejdź do modułów `infra-`...](#moduły-infrastrukturalne-ścieżka-infra)

### Ścieżka 3: Administrator Floty / Bezpieczeństwa

Ta ścieżka skupia się na operacjach w skali przedsiębiorstwa: zarządzaniu wieloma klastrami, bezpieczeństwem, zgodnością (compliance) i backupem.
* [Przejdź do modułów `mgmt-`...](#moduły-zarządzania-ścieżka-mgmt)

---

## 🧭 Ścieżka Holistyczna (Przeplatana) "Od Zera do Bohatera"

Dla osób, które wolą uczyć się w sposób liniowy, poniższa lista łączy wszystkie moduły w jedną, progresywną ścieżkę nauki. Tematy z różnych ról przeplatają się tu, budując kompletną wiedzę krok po kroku.

### Faza 1: Pierwsze Starcie (Lab i Podstawy)
* **Moduł 01 (op-00):** [Przygotowanie Laboratorium (OpenShift Local)](./sciezka-operatora/op-00-przygotowanie.md)
* **Moduł 02 (op-01):** [Fundamenty – "Dlaczego OpenShift?"](./sciezka-operatora/op-01-fundamenty.md)
* **Moduł 03 (infra-01):** ["Pod Maską" – RHCOS i Architektura](./sciezka-infrastruktury/infra-01-pod-maska-rhcos.md)

### Faza 2: Cykl Życia Aplikacji (Hello World)
* **Moduł 04 (op-02):** [Zarządzanie Obrazami i Budowanie (S2I)](./sciezka-operatora/op-02-zarzadzanie-obrazami.md)
* **Moduł 05 (op-03):** [Wdrażanie Aplikacji (DeploymentConfig)](./sciezka-operatora/op-03-wdrazanie-aplikacji.md)
* **Moduł 06 (op-04):** [Networking Aplikacji (Route)](./sciezka-operatora/op-04-networking.md)
* **Moduł 07 (op-07):** [Konfiguracja (ConfigMap) i Sekrety](./sciezka-operatora/op-07-konfiguracja.md)
* **Moduł 08 (op-08):** [Storage (PVC/PV)](./sciezka-operatora/op-08-storage.md)

### Faza 3: Administracja Aplikacją (Zarządzanie i Bezpieczeństwo)
* **Moduł 09 (op-05):** [Troubleshooting Aplikacji](./sciezka-operatora/op-05-troubleshooting.md)
* **Moduł 10 (op-06):** [Bezpieczeństwo Aplikacji (SCC, RBAC)](./sciezka-operatora/op-06-bezpieczenstwo.md)
* **Moduł 11 (op-09):** [Skalowanie Aplikacji (HPA, Quotas)](./sciezka-operatora/op-09-skalowanie.md)
* **Moduł 12 (op-12):** [Obserwowalność (Monitoring, Logi)](./sciezka-operatora/op-12-obserwowalnosc.md)

### Faza 4: Rozszerzanie Platformy (Automatyzacja i Operatory)
* **Moduł 13 (op-11):** [Ekosystem Operatorów (OLM)](./sciezka-operatora/op-11-ekosystem-operatorow.md)
* **Moduł 14 (op-10):** [CI/CD (Tekton, ArgoCD)](./sciezka-operatora/op-10-cicd.md)

### Faza 5: Budowa Klastra Produkcyjnego (Infrastruktura)
* **Moduł 15 (infra-02):** [Instalacja (IPI vs. UPI) i vSphere](./sciezka-infrastruktury/infra-02-instalacja-ipi-upi.md)
* **Moduł 16 (infra-03):** [Integracja ze Storage (CSI)](./sciezka-infrastruktury/infra-03-storage-csi.md)
* **Moduł 17 (infra-04):** [Integracja Sieciowa (MetalLB)](./sciezka-infrastruktury/infra-04-networking-lb.md)
* **Moduł 18 (mgmt-03):** [Korporacyjne Zarządzanie Tożsamością (SSO)](./sciezka-zarzadzania/mgmt-03-sso-identity.md)

### Faza 6: Zarządzanie w Skali Enterprise (Flota i Bezpieczeństwo)
* **Moduł 19 (mgmt-01):** [Zarządzanie Flotą Klastrów (Red Hat ACM)](./sciezka-zarzadzania/mgmt-01-acm-multicluster.md)
* **Moduł 20 (mgmt-02):** [Zaawansowane Bezpieczeństwo (Red Hat ACS)](./sciezka-zarzadzania/mgmt-02-acs-bezpieczenstwo.md)
* **Moduł 21 (mgmt-04):** [Backup i Disaster Recovery (OADP)](./sciezka-zarzadzania/mgmt-04-oadp-backup-dr.md)
* **Moduł 22 (mgmt-05):** [Zarządzanie Kosztami i Autoskalowanie Klastra](./sciezka-zarzadzania/mgmt-05-cost-management.md)

### Faza 7: Tematy Zaawansowane i Co Dalej
* **Moduł 23 (infra-05):** [OpenShift Virtualization (KubeVirt)](./sciezka-infrastruktury/infra-05-wirtualizacja-kubevirt.md)
* **Moduł 24 (infra-06):** [Wsparcie Wieloarchitekturowe](./sciezka-infrastruktury/infra-06-multi-arch-power-z.md)
* **Moduł 25 (op-13):** [Co Dalej? (Certyfikacja, Service Mesh, Serverless)](./sciezka-operatora/op-13-co-dalej.md)

---

## 📚 Pełny, Szczegółowy Konspekt

Poniżej znajduje się pełne omówienie wszystkich tematów podzielonych na ścieżki i moduły (zgodnie z organizacją katalogów).

---

# Ścieżka 1: Operator Aplikacji / Deweloper

---

### Moduły Główne (Ścieżka `op-`)

* **[Moduł 00:** Przygotowanie Laboratorium](./sciezka-operatora/op-00-przygotowanie.md)**
* **[Moduł 01:** Fundamenty – "Dlaczego OpenShift?"](./sciezka-operatora/op-01-fundamenty.md)**
* **[Moduł 02:** Zarządzanie Obrazami i Budowanie Aplikacji](./sciezka-operatora/op-02-zarzadzanie-obrazami.md)**
* **[Moduł 03:** Wdrażanie Aplikacji (Deployment)](./sciezka-operatora/op-03-wdrazanie-aplikacji.md)**
* **[Moduł 04:** Wystawianie Aplikacji na Świat (Networking)](./sciezka-operatora/op-04-networking.md)**
* **[Moduł 05:** Troubleshooting (Sztuka Debugowania)](./sciezka-operatora/op-05-troubleshooting.md)**
* **[Moduł 06:** Bezpieczeństwo – "Secure by Default"](./sciezka-operatora/op-06-bezpieczenstwo.md)**
* **[Moduł 07:** Zarządzanie Konfiguracją i Sekretami](./sciezka-operatora/op-07-konfiguracja.md)**
* **[Moduł 08:** Storage – Trwałość Danych](./sciezka-operatora/op-08-storage.md)**
* **[Moduł 09:** Skalowanie i Zarządzanie Aplikacjami](./sciezka-operatora/op-09-skalowanie.md)**
* **[Moduł 10:** CI/CD – Kompletne Spojrzenie](./sciezka-operatora/op-10-cicd.md)**
* **[Moduł 11:** Ekosystem Operatorów (OLM)](./sciezka-operatora/op-11-ekosystem-operatorow.md)**
* **[Moduł 12:** Obserwowalność – Monitoring i Logowanie](./sciezka-operatora/op-12-obserwowalnosc.md)**
* **[Moduł 13:** Co Dalej? Ścieżki Rozwoju](./sciezka-operatora/op-13-co-dalej.md)**

## Moduł 00 (op-00): Przygotowanie Laboratorium
* **Lekcja 0.1:** Wprowadzenie do **OpenShift Local** (dawniej CodeReady Containers).
    * Czym jest OpenShift Local (OCP Local)?
    * Dla kogo jest przeznaczone? (Deweloperzy, nauka)
    * Jakie są wymagania systemowe? (Kluczowe: RAM, CPU, miejsce na dysku)
    * Różnica między OCP (Enterprise) a OKD (Community).
* **Lekcja 0.2:** Instalacja i konfiguracja OpenShift Local na Twojej lokalnej maszynie.
    * Pobieranie `oc-local` z Red Hat Developer Portal.
    * Czym jest `pull-secret` i jak go zdobyć?
    * Inicjalizacja środowiska: `oc-local setup`.
    * Uruchomienie klastra: `oc-local start`.
    * Gdzie są przechowywane kluczowe informacje (kubeconfig, hasła).
* **Lekcja 0.3:** Pierwsze logowanie – `oc login` vs Konsola Webowa. Weryfikacja stanu klastra.
    * Jak znaleźć adres URL konsoli i hasło `kubeadmin`.
    * Logowanie przez `oc login -u kubeadmin ...`.
    * Logowanie jako domyślny użytkownik `developer`.
    * Pierwsze spojrzenie na konsolę: Perspektywa Administratora vs Dewelopera.
    * Podstawowe komendy weryfikacyjne: `oc whoami`, `oc status`, `oc get clusteroperators`.

## Moduł 01 (op-01): Fundamenty – "Dlaczego OpenShift to nie jest *tylko* Kubernetes?"
* **Lekcja 1.1: Filozofia: Platforma (OCP) vs. Orkiestrator (K8s)**
    * Metafora: Kubernetes to **silnik**. OpenShift to **samochód** (karoseria, deska rozdzielcza, ABS, poduszki powietrzne).
    * OCP jako "opiniotwórcza" (opinionated) platforma – co to znaczy?
    * Wartość dodana OCP: Bezpieczeństwo, Doświadczenie Deweloperskie (DevEx), Zintegrowane komponenty, Wsparcie Enterprise.
* **Lekcja 1.2: Różnica #1 – Doświadczenie Użytkownika (Konsola Webowa)**
    * K8s: `kubectl` jest królem, opcjonalny Dashboard jest minimalistyczny.
    * OCP: Konsola Webowa to **centrum zarządzania**.
    * Przegląd widoku Dewelopera (Topologia, S2I, Obserwowalność).
    * Przegląd widoku Administratora (Zarządzanie Węzłami, Operatorami, RBAC).
* **Lekcja 1.3: Różnica #2 – Architektura "Operator-First"**
    * K8s: Kluczowe funkcje (np. Ingress Controller, Monitoring) to dodatki instalowane ręcznie (np. Helm).
    * OCP (od 4.x): Klaster jest **zarządzany przez Operatory**.
    * Rola CVO (Cluster Version Operator) – jak OCP samo siebie aktualizuje.
    * Rola OLM (Operator Lifecycle Manager) – "system operacyjny" dla Operatorów.
* **Lekcja 1.4: Różnica #3 – Zarządzanie Zespołami (`Project` vs `Namespace`)**
    * K8s: `Namespace` to tylko logiczna granica (izolacja nazw).
    * OCP: `Project` to `Namespace` **na sterydach**.
    * Co tworzy `oc new-project test`? (Domyślne `RoleBindings`, `NetworkPolicy`, `LimitRanges`, `ServiceAccounts`).
    * Porównanie z `kubectl create namespace test`.
* **Lekcja 1.5: Różnica #4 – Narzędzie Lini Komend (`oc` vs `kubectl`)**
    * `oc` to nadzbiór `kubectl` (każda komenda `kubectl` działa z `oc`).
    * Kluczowe komendy tylko w `oc`:
        * `oc login` (vs skomplikowane zarządzanie `kubeconfig`).
        * `oc new-project` (vs `create namespace` + edycja RBAC).
        * `oc new-app` (buduje aplikację z Git – zajawka S2I).
        * `oc start-build` (do ręcznego triggerowania `BuildConfig`).
        * `oc status` (szybki podgląd projektu).
        * `oc policy add-role-to-user...` (łatwiejsze zarządzanie RBAC).
* **Lekcja 1.6: Zajawka Kluczowych Różnic (Co poznamy dalej?)**
    * Sieć: `Ingress` (K8s) vs `Route` (OCP) -> Moduł 4.
    * Budowanie: `Dockerfile` (K8s) vs `S2I (Source-to-Image)` (OCP) -> Moduł 2.
    * Bezpieczeństwo: `PodSecurity` (K8s) vs `SecurityContextConstraints (SCC)` (OCP) -> Moduł 6.

## Moduł 02 (op-02): Zarządzanie Obrazami i Budowanie Aplikacji
* **Lekcja 2.1:** Zintegrowany Rejestr Obrazów (Internal Registry).
    * Jak działa wewnętrzny rejestr (`image-registry.openshift-image-registry.svc:5000`).
    * Wystawienie rejestru na zewnątrz przez `Route`.
    * Logowanie do rejestru (`podman login`, `docker login`) przy użyciu tokena `oc`.
* **Lekcja 2.2:** `ImageStream` i `ImageStreamTag` – Kluczowy koncept OCP.
    * Dlaczego OCP stworzyło `ImageStream`? (Abstrakcja na obraz).
    * Różnica między `ImageStream` (IS) a `ImageStreamTag` (IST).
    * Jak `ImageStream` może śledzić obrazy w zewnętrznych rejestrach (np. Docker Hub).
    * Rola `ImageChangeTrigger` (zajawka).
* **Lekcja 2.3:** `BuildConfig` – Mózg procesu budowania.
    * Omówienie obiektu `BuildConfig` (BC).
    * Triggery budowania: `GitHub` webhook, `Generic` webhook, `ImageChange`, `ConfigChange`.
* **Lekcja 2.4:** Strategie Budowania: **S2I (Source-to-Image)** vs `Docker` vs `Pipeline`.
    * **S2I**: Jak to działa? (Obraz budujący + kod źródłowy = nowy obraz aplikacji). Zalety (brak `Dockerfile`).
    * **Docker**: Budowanie z `Dockerfile` w repozytorium. Kiedy używać?
    * **Pipeline**: Budowanie przy użyciu Jenkins/Tekton (zajawka Modułu 10).
* **Lekcja 2.5:** Warsztat End-to-End #1 (Od `git push` do działającej aplikacji S2I).
    * Użycie `oc new-app https://github.com/... --name=my-app`.
    * Co zostało stworzone? (`BuildConfig`, `DeploymentConfig`, `Service`, `ImageStream`).
    * Śledzenie logów budowania: `oc logs -f bc/my-app`.
    * Wystawienie aplikacji na świat: `oc expose svc/my-app`.
    * Weryfikacja działającej aplikacji przez `Route`.

## Moduł 03 (op-03): Wdrażanie Aplikacji (Deployment)
* **Lekcja 3.1:** `Deployment` (K8s) vs `DeploymentConfig` (OCP) – Kiedy używać którego?
    * `Deployment` (Deploy): Standard K8s, w pełni deklaratywny, idealny dla GitOps.
    * `DeploymentConfig` (DC): "Klasyczny" sposób OCP, bardziej imperatywny, ma wbudowane triggery.
    * Różnice w zarządzaniu (Rola `ReplicationController` w DC).
    * Rekomendacja: Używaj `Deployment` dla nowych aplikacji, rozumiej `DC` dla istniejących.
* **Lekcja 3.2:** Triggery w `DeploymentConfig` (np. automatyczne wdrożenie po zmianie obrazu).
    * To jest główny powód, dla którego `DC` jest wciąż popularne.
    * Konfiguracja `ImageChangeTrigger` – jak `DC` "słucha" `ImageStream`.
    * Stworzenie pętli CI/CD: `git push` -> `S2I Build` -> `ImageStream update` -> `DC Trigger` -> `Nowe Pody`.
* **Lekcja 3.3:** Strategie Wdrożeniowe (Rolling, Recreate, Blue-Green).
    * `Rolling` (domyślna): Zero downtime, stopniowa wymiana podów.
    * `Recreate`: Downtime, zatrzymaj stare, uruchom nowe (dobre dla PV ReadWriteOnce).
    * `Blue-Green`: Jak OCP to ułatwia (przełączanie ruchu na poziomie `Service`).

## Moduł 04 (op-04): Wystawianie Aplikacji na Świat (Networking)
* **Lekcja 4.1:** Powtórka z `Service` (ClusterIP, NodePort).
    * `ClusterIP` (domyślne): Wewnętrzny adres IP w klastrze.
    * `NodePort`: Otwarcie portu na węźle (głównie do debugowania).
    * `LoadBalancer`: Integracja z chmurą (nie dotyczy OCP Local).
* **Lekcja 4.2:** `Route` – Brama do aplikacji (odpowiednik Ingress).
    * `Route` jako odpowiedź OCP na `Ingress` (starszy, ale głębiej zintegrowany).
    * Jak `Route` łączy się z `Service`.
    * Wbudowany Ingress Controller (OpenShift Router, bazujący na HAProxy).
    * Automatyczne generowanie hostname (`oc expose`).
* **Lekcja 4.3:** Terminacja TLS: `Edge`, `Passthrough`, `Re-encrypt`.
    * `Edge`: Szyfrowanie od klienta do Routera (najczęstsze).
    * `Passthrough`: Router nie dotyka ruchu TLS, terminacja na Podzie.
    * `Re-encrypt`: Szyfrowanie od klienta do Routera *oraz* od Routera do Poda (maksymalne bezpieczeństwo).
* **Lekcja 4.4:** Podstawy `NetworkPolicy` w praktyce (Izolacja Podów).
    * Domyślna polityka w OCP (tryb `multitenant`): `deny-all` między projektami, `allow-all` wewnątrz projektu.
    * Jak używać obiektów `NetworkPolicy` (standard K8s) do izolacji.
    * Przykład: Zezwolenie na ruch z `frontend` (label) do `backend` (label).

## Moduł 05 (op-05): Troubleshooting (Sztuka Debugowania)
* **Lekcja 5.1:** Podstawowy "Triage" – `oc get events`.
    * `oc get events -w` – pierwsze miejsce, gdzie patrzymy.
    * Interpretacja eventów: `FailedScheduling`, `FailedMount`, `ImagePullBackOff`.
* **Lekcja 5.2:** "Zajrzyj do środka" – `oc describe [resource]`.
    * `oc describe pod/...` – drugie najważniejsze polecenie.
    * Analiza sekcji `Status`, `Conditions`, `Events`.
    * Dlaczego Pod jest `Pending`? (Brak zasobów CPU/RAM? Tainty/Tolerations?).
* **Lekcja 5.3:** Co mówi aplikacja? – `oc logs` (oraz flaga `-p`).
    * `oc logs pod/...` – czytanie `stdout`/`stderr` aplikacji.
    * `oc logs -f` (follow) – śledzenie na żywo.
    * `oc logs -p` (previous) – kluczowe dla debugowania `CrashLoopBackOff`.
* **Lekcja 5.4:** Wejście do kontenera – `oc exec`.
    * `oc exec -it pod/... -- /bin/bash` (lub `/bin/sh`).
    * Sprawdzanie środowiska: `env`, `ls -l`, `ping`, `curl` do innych serwisów.
* **Lekcja 5.5:** Analiza problemów z `Build` i `Deployment`.
    * Logi budowania: `oc logs bc/...` lub `oc logs -f build/...`.
    * Debugowanie `DeploymentConfig`: `oc describe dc/...`, `oc describe rc/...`.
* **Lekcja 5.6:** Wprowadzenie do `oc debug` i `oc adm`.
    * `oc debug pod/...` – tworzenie kopii poda z powłoką (nawet jeśli crashuje).
    * `oc adm` – przegląd komend administracyjnych (`oc adm top nodes`, `oc adm drain`).
    * Koncepcja `oc adm must-gather` (do zbierania danych dla wsparcia).
* **Lekcja 5.7:** Praktyczna checklista: "Mój Pod nie wstaje".
    * `ImagePullBackOff`: Zły tag? Błąd w `ImageStream`? Potrzebny `Secret` do rejestru?
    * `CrashLoopBackOff`: Aplikacja umiera. Sprawdź `oc logs -p`. Błąd w kodzie? Błędna konfiguracja?
    * `Pending`: `oc describe`. Brak zasobów? Błąd `PV`?
    * `CreateContainerConfigError`: Brakuje `ConfigMap` lub `Secret`?

## Moduł 06 (op-06): Bezpieczeństwo – "Secure by Default"
* **Lekcja 6.1:** Uwierzytelnianie (OAuth) i AutoryzaCja (RBAC).
    * AuthN (Kim jesteś?): Wbudowany serwer OAuth. Dostawcy tożsamości (`htpasswd`, LDAP, GitHub).
    * AuthZ (Co możesz zrobić?): `RBAC` (Role-Based Access Control).
* **Lekcja 6.2:** Zarządzanie Użytkownikami, Grupami, Rolami (`RoleBinding`).
    * Obiekty: `User`, `Group`, `Role`, `ClusterRole`, `RoleBinding`, `ClusterRoleBinding`.
    * Domyślne role w Projekcie: `admin`, `edit`, `view`.
    * Praktyka: `oc adm policy add-role-to-user admin my-user -n my-project`.
* **Lekcja 6.3:** **`SecurityContextConstraints` (SCC)** – Fundament bezpieczeństwa (dlaczego `root` nie działa).
    * **To jest kluczowa różnica OCP vs K8s.**
    * Dlaczego `docker run... -u 0` (jako root) domyślnie *nie działa* w OpenShift.
    * Domyślna polityka `restricted`.
    * Przegląd innych SCC: `anyuid`, `privileged`.
    * Jak SCC mapuje się na `ServiceAccount` Poda.
* **Lekcja 6.4:** Rola `ServiceAccount`.
    * Czym jest `ServiceAccount` (SA)? (Tożsamość dla maszyn/procesów).
    * Domyślne SA: `default`, `builder`, `deployer`.
    * Jak Pod używa tokena SA do komunikacji z API K8s.
    * Przypisywanie `Secretów` (np. do pobierania obrazów) do SA.
* **Lekcja 6.5:** Skanowanie Obrazów (Wprowadzenie do Quay/Trivy i integracji z rejestrem).
    * Koncepcja "Shift-Left" Security.
    * Rola Red Hat Quay jako zintegrowanego rejestru ze skanowaniem (Clair).
    * Integracja skanerów (np. Trivy) z pipeline'em CI/CD.
* **Lekcja 6.6:** Audytowanie i `PodSecurity` (Wprowadzenie do `PodSecurityAdmission`).
    * `PodSecurityAdmission` (PSA) – nowy standard K8s zastępujący `PodSecurityPolicy` (PSP).
    * Jak OCP mapuje swoje `SCC` na profile PSA (`privileged`, `baseline`, `restricted`).
    * Etykiety `warn`, `enforce`, `audit` na poziomie `Namespace`.

## Moduł 07 (op-07): Zarządzanie Konfiguracją i Sekretami
* **Lekcja 7.1:** `ConfigMap` – Zarządzanie konfiguracją.
    * Przechowywanie danych nie-wrażliwych (np. URL-e API, pliki `settings.xml`).
    * Tworzenie z plików: `oc create configmap... --from-file=...`.
    * Tworzenie z wartości: `oc create configmap... --from-literal=...`.
* **Lekcja 7.2:** `Secret` – Zarządzanie danymi wrażliwymi.
    * Przechowywanie danych wrażliwych (hasła, klucze API, certyfikaty TLS).
    * Base64 to *kodowanie*, a nie *szyfrowanie*.
    * Typy sekretów (np. `docker-registry`, `tls`, `opaque`).
* **Lekcja 7.3:** Podłączanie konfiguracji do Podów (zmienne vs wolumeny).
    * Jako zmienne środowiskowe (`env` lub `envFrom`).
    * Jako wolumeny (pliki montowane w systemie plików kontenera).
    * Automatyczne aktualizacje podów po zmianie `ConfigMap`/`Secret` (wymaga triggera lub restartu).
* **Lekcja 7.4:** `Service Binding` – Nowoczesne łączenie aplikacji z usługami.
    * Problem: Skąd aplikacja ma wiedzieć, jakie jest hasło do bazy danych?
    * Stary sposób: Ręczne tworzenie `Secret` i `ConfigMap`.
    * Nowy sposób (Operator-based): `ServiceBinding` CRD.
    * Jak Operator `ServiceBinding` automatycznie "wstrzykuje" dane (jako pliki/zmienne) z usługi (np. Bazy Danych) do aplikacji (np. `Deployment`).

## Moduł 08 (op-08): Storage – Trwałość Danych
* **Lekcja 8.1:** `PersistentVolume` (PV) i `PersistentVolumeClaim` (PVC).
    * Powtórka koncepcji K8s.
    * `PersistentVolume` (PV): "Dysk", zasób klastra, tworzony przez admina.
    * `PersistentVolumeClaim` (PVC): "Żądanie" dysku, tworzone przez dewelopera.
* **Lekcja 8.2:** `StorageClass` i Dynamic Provisioning.
    * `StorageClass`: "Fabryka" dysków (PV).
    * Jak `StorageClass` pozwala na dynamiczne tworzenie PV na żądanie (PVC).
    * Domyślna `StorageClass` w OpenShift Local (bazująca na `hostPath`).
* **Lekcja 8.3:** Wprowadzenie do OpenShift Data Foundation (Rook/Ceph).
    * "Błogosławione" rozwiązanie storage dla OCP.
    * Czym jest ODF (dawniej OCS)? (Bazuje na Rook/Ceph).
    * Co dostarcza? (Block storage, File storage (RWO/RWX), Object storage (S3)).
* **Lekcja 8.4:** Wprowadzenie do Snapshotów i Backup/Restore (koncepcja).
    * Użycie `VolumeSnapshot` CRD do tworzenia migawek.
    * Różnica między snapshotem a backupem.
    * Koncepcja narzędzi (np. Velero/OADP) do backupu całych projektów.

## Moduł 09 (op-09): Skalowanie i Zarządzanie Aplikacjami
* **Lekcja 9.1:** Sondy (Probes): `liveness`, `readiness`, `startup`.
    * `livenessProbe`: "Czy aplikacja żyje?" (Jeśli nie -> restart kontenera).
    * `readinessProbe`: "Czy aplikacja jest gotowa przyjąć ruch?" (Jeśli nie -> usuń Poda z `Service`).
    * `startupProbe`: Dla wolno startujących aplikacji (opóźnia działanie `livenessProbe`).
    * Typy sond: `httpGet`, `tcpSocket`, `exec`.
* **Lekcja 9.2:** `HorizontalPodAutoscaler` (HPA).
    * Automatyczne skalowanie horyzontalne (więcej podów).
    * `oc autoscale deployment/... --cpu-percent=80 --min=1 --max=5`.
    * Jak HPA pobiera metryki (z serwera metryk, bazującego na Prometheusie).
* **Lekcja 9.3:** Zarządzanie zasobami: `ResourceQuota` i `LimitRange`.
    * Kluczowe dla środowisk współdzielonych (multi-tenant).
    * `ResourceQuota`: Budżet na `Project` (np. max 10 CPU, max 50Gi RAM, max 10 PVC).
    * `LimitRange`: Domyślne wartości dla Podów w `Project` (np. każdy Pod domyślnie dostaje `request` 100m CPU).

## Moduł 10 (op-10): CI/CD – Kompletne Spojrzenie
* **Lekcja 10.1:** **Metoda "Legacy": Jenkins** (Integracja).
    * Instalacja Operatora Jenkins.
    * Użycie `BuildConfig` ze strategią `Pipeline` (`Jenkinsfile`).
    * Jak Jenkins (dzięki wtyczce OpenShift) może komunikować się z `oc` (np. `oc start-build`, `oc tag`).
* **Lekcja 10.2:** **Metoda "Cloud Native": OpenShift Pipelines (Tekton)**.
    * Instalacja Operatora OpenShift Pipelines.
    * Filozofia "bezserwerowego" CI/CD (każdy krok to Pod).
    * Koncepcje: `Task` (krok), `Pipeline` (kolekcija Tasków), `PipelineRun` (uruchomienie), `Workspace` (współdzielony storage).
* **Lekcja 10.3:** **Metoda "GitOps": OpenShift GitOps (ArgoCD)**.
    * Instalacja Operatora OpenShift GitOps.
    * Filozofia GitOps: Git jako *jedyne źródło prawdy*.
    * Model "Pull" (ArgoCD pobiera) vs Model "Push" (Jenkins/Tekton wysyła).
    * Jak ArgoCD wykrywa "dryf" konfiguracji (różnicę między Gitem a klastrem).
* **Lekcja 10.4:** Testowanie Aplikacji w Pipeline (Integration/E2E testy jako `Task` w Tekton).
    * Dodawanie `Task` do `Pipeline` Tekton, który uruchamia `pytest`, `mvn test` itp.
    * Jak pipeline zatrzymuje się, gdy testy nie przejdą.
* **Lekcja 10.5:** Warsztat End-to-End #2 (Rollback i strategia Canary/Blue-Green z ArgoCD).
    * Konfiguracja ArgoCD do śledzenia repozytorium Git.
    * Zmiana w Git (np. tag obrazu) -> ArgoCD automatycznie aktualizuje `Deployment`.
    * Rollback (przez `git revert` i `git push`).
    * Wprowadzenie do `Argo Rollouts` (koncepcja zaawansowanych wdrożeń Canary).

## Moduł 11 (op-11): Ekosystem Operatorów (OLM)
* **Lekcja 11.1:** Koncepcja Operatora (Operator Pattern) i CRD.
    * Powtórka: Operator = `Custom Resource Definition (CRD)` (nasze API) + `Controller` (mózg, automatyzacja).
* **Lekcja 11.2:** Operator Lifecycle Manager (OLM).
    * "System operacyjny" lub "App Store" dla Operatorów.
    * Jak OLM zarządza instalacją, aktualizacjami i zależnościami między Operatorami.
* **Lekcja 11.3:** OperatorHub – Instalacja i zarządzanie oprogramowaniem.
    * Przeglądanie OperatorHub w konsoli OCP.
    * Instalacja Operatora (np. PostgreSQL lub Redis).
    * Tworzenie bazy danych *za pomocą obiektu K8s* (np. `kind: Postgres...`). Operator zajmuje się resztą (tworzy Pody, Serwisy, Secrety).
* **Lekcja 11.4:** Zarządzanie aplikacjami w wielu namespace'ach (RBAC i Operatory).
    * Instalacja Operatora w trybie `AllNamespaces` vs `SingleNamespace`.
    * Jak `OperatorGroups` definiują zasięg działania Operatora.
    * Konfiguracja RBAC, aby Operator mógł zarządzać zasobami w innych projektach.

## Moduł 12 (op-12): Obserwowalność – Monitoring i Logowanie
* **Lekcja 12.1:** **Monitoring (Prometheus & Grafana)** (Architektura, ServiceMonitor).
    * Architektura wbudowanego stosu monitoringu (Prometheus, Grafana, Alertmanager).
    * Jak OCP monitoruje sam siebie.
    * Jak włączyć monitorowanie dla własnych projektów.
    * Użycie `ServiceMonitor` CRD, aby Prometheus automatycznie skrobał metryki z naszej aplikacji.
    * Dostęp do wbudowanych dashboardów Grafana.
* **Lekcja 12.2:** **Logowanie (EFK / Loki)** (Architektura, przeglądanie logów).
    * Architektura stosu logowania (Fluentd na każdym węźle, Loki lub Elasticsearch jako backend, Kibana/Grafana jako UI).
    * Różnica między EFK (Elasticsearch) a Loki (lżejsze, bazujące na etykietach).
    * Przeglądanie logów (infrastruktury i aplikacji) w konsoli OCP.
* **Lekcja 12.3:** Wprowadzenie do Tracingu (Jaeger) i **OpenTelemetry**.
    * Trzeci filar obserwowalności (Metryki, Logi, Tracing).
    * Instalacja Operatora Jaeger.
    * Czym jest Tracing Dystrybuowany (śledzenie żądania przez wiele mikrousług).
    * Rola `OpenTelemetry` (OTel) jako nowego standardu instrumentacji kodu (wysyłanie metryk, logów i śladów).

## Moduł 13 (op-13): Co Dalej? Ścieżka do Poziomu Ekspert
* **Lekcja 13.1:** Przygotowanie do certyfikacji.
    * Ścieżki Red Hat: `EX180` (Containers/Podman), `EX280` (OpenShift Administration), `EX288` (OpenShift Development).
* **Lekcja 13.2:** Społeczność (OKD, fora, blogi).
    * Czym jest OKD (The Community Distribution of OpenShift)?
    * Gdzie szukać pomocy i wiedzy (oficjalna dokumentacja, blogi Red Hat).
* **Lekcja 13.3:** Automatyzacja i IaC (**Ansible** dla OpenShift, **Terraform**).
    * Użycie Ansible do automatyzacji zadań *wewnątrz* OCP (np. tworzenie projektów, wdrażanie aplikacji).
    * Użycie Terraform do provisioningu infrastruktury *dla* OCP (lub klastrów OKD).
* **Lekcja 13.4:** Zarządzanie Cyklem Życia Klastra (**Upgrade i Migracje**).
    * Jak działa proces aktualizacji OCP (Rola CVO, kanały `stable`/`fast`).
    * Proces "over-the-air" (OTA) upgrade (najpierw Control Plane, potem Workery).
    * Koncepcje migracji między klastrami (np. przy użyciu `OADP`/`Velero`).
* **Lekcja 13.5:** Zaawansowane tematy.
    * **OpenShift Service Mesh** (bazujące na Istio) – zaawansowane zarządzanie ruchem (mTLS, Canary).
    * **OpenShift Serverless** (bazujące na Knative) – uruchamianie funkcji, skalowanie do zera.
    * **OpenShift Virtualization** (bazujące na KubeVirt) – uruchamianie maszyn wirtualnych *wewnątrz* Poda.

---

# Ścieżka 2: Administrator Infrastruktury

---

### Moduły Infrastrukturalne (Ścieżka `infra-`)

* **[Moduł 01:** "Pod Maską" – RHCOS i Architektura](./sciezka-infrastruktury/infra-01-pod-maska-rhcos.md)**
* **[Moduł 02:** Instalacja Produkcyjna (IPI vs. UPI) i Integracja z vSphere](./sciezka-infrastruktury/infra-02-instalacja-ipi-upi.md)**
* **[Moduł 03:** Integracja ze Storage (CSI) – Jak podłączyć macierz (NetApp, Dell, IBM)](./sciezka-infrastruktury/infra-03-storage-csi.md)**
* **[Moduł 04:** Integracja Sieciowa (Load Balancery F5, MetalLB)](./sciezka-infrastruktury/infra-04-networking-lb.md)**
* **[Moduł 05:** OpenShift Virtualization (Uruchamianie VM obok kontenerów)](./sciezka-infrastruktury/infra-05-wirtualizacja-kubevirt.md)**
* **[Moduł 06:** Wsparcie Wieloarchitekturowe (IBM Power i Z)](./sciezka-infrastruktury/infra-06-multi-arch-power-z.md)**

## Moduł 01 (infra-01): "Pod Maską" – RHCOS i Architektura
* **Lekcja 1.1:** Czym jest **RHCOS (Red Hat Enterprise Linux CoreOS)**?
    * Dlaczego OCP 4.x działa na RHCOS, a nie na standardowym RHEL?
    * Koncepcja **"Niezmiennego Systemu Operacyjnego" (Immutable OS)**.
    * Dlaczego nie ma `yum` ani `dnf`? Jak instaluje się oprogramowanie?
    * Rola `rpm-ostree` (koncepcja).
* **Lekcja 1.2:** Architektura Węzłów: Control Plane vs. Workers
    * Rola Węzłów Control Plane (Masterów): `etcd`, `kube-apiserver`, `kube-scheduler`.
    * Rola Węzłów Workers (Roboczych): Uruchamianie aplikacji (Podów).
    * Koncepcja Węzłów "Infra" (do uruchamiania komponentów klastra, np. Routera, Rejestru).
* **Lekcja 1.3:** Rola Operatorów Infrastrukturalnych
    * **CVO (Cluster Version Operator):** "Mózg" klastra, pilnuje stanu pożądanego i wersji wszystkich komponentów.
    * **MCO (Machine Config Operator):** "Ręce" klastra, zarządza konfiguracją i aktualizacjami *każdego* węzła RHCOS.
    * Jak MCO stosuje zmiany (np. `kubelet config`) przez `MachineConfigPools`.
* **Lekcja 1.4:** Czym jest **Machine API**?
    * Zarządzanie Węzłami OCP jako zasobami Kubernetes (CRD).
    * `Machine`: Pojedyncza VM-ka lub serwer Bare Metal.
    * `MachineSet`: Odpowiednik `ReplicaSet` dla Węzłów.
    * `MachineHealthCheck`: Automatyczne wykrywanie i zastępowanie uszkodzonych węzłów.
    * Jak skalować klaster (dodawać/usuwać Workery) edytując YAML.

## Moduł 02 (infra-02): Instalacja Produkcyjna (IPI vs. UPI) i Integracja z vSphere
* **Lekcja 2.1:** **IPI vs. UPI** – Dwie drogi instalacji
    * **IPI (Installer-Provisioned Infrastructure):** "Tryb automatyczny".
        * Instalator sam tworzy VM-ki, sieci, load balancery.
        * Idealny dla chmur publicznych (AWS, Azure, GCP) i wspieranych platform (vSphere, RHV).
    * **UPI (User-Provisioned Infrastructure):** "Tryb ręczny".
        * Ty (Admin) musisz przygotować *wszystko*: VM-ki, DNS, Load Balancery.
        * Konieczny dla Bare Metal i niestandardowych wdrożeń.
* **Lekcja 2.2:** Proces Instalacji (Kluczowe kroki)
    * Narzędzie `openshift-install` CLI.
    * Plik `install-config.yaml` – serce konfiguracji (platforma, `pull-secret`, klucze SSH, domeny).
    * Proces "Bootstrap" – rola tymczasowego węzła bootstrap.
* **Lekcja 2.3:** Integracja z **vSphere (IPI)**
    * Wymagania: Dostęp do API vCenter, uprawnienia, template RHCOS OVA.
    * Co `openshift-install` robi automatycznie w vCenter (klonowanie VM, podłączanie sieci, konfiguracja storage).
* **Lekcja 2.4:** Instalacja **Bare Metal (UPI)**
    * Wyzwania: Przygotowanie serwerów (PXE, Redfish/IPMI).
    * Ręczna konfiguracja DNS i Load Balancera (HAProxy, F5).
    * Rola `Bare Metal Operator` (bazujący na Ironic) do automatyzacji provisioningu hostów.

## Moduł 03 (infra-03): Integracja ze Storage (CSI)
* **Lekcja 3.1:** Czym jest **CSI (Container Storage Interface)**?
    * Standard/API, który pozwala Kubernetesowi "rozmawiać" z dowolną macierzą.
    * Zastąpił stary mechanizm "in-tree" wolumenów.
* **Lekcja 3.2:** Rola Admina Storage: Instalacja **Operatora CSI**
    * Każdy dostawca storage (NetApp, Dell, IBM, PureStorage) dostarcza własny Operator CSI.
    * Instalacja Operatora CSI z OperatorHub.
    * Konfiguracja `StorageClass` wskazującej na Operator CSI.
* **Lekcja 3.3:** Przepływ pracy: Od PVC do LUN-a
    * 1. Deweloper tworzy PVC (np. "chcę 10GiB 'fast-storage'").
    * 2. Operator CSI widzi to żądanie.
    * 3. Operator CSI (przez swój `provisioner`) "dzwoni" do API macierzy.
    * 4. Macierz provisionuje LUN/NFS (10GiB), mapuje go do Węzła (Workera) OCP.
    * 5. Węzeł (przez `csi-driver`) montuje wolumen i udostępnia go Podowi.
* **Lekcja 3.4:** ODF (Ceph) vs. Macierz Zewnętrzna (CSI)
    * **ODF (OpenShift Data Foundation):** Storage definiowany programowo (SDS), "wewnątrz" klastra (używa dysków Workerów).
    * **CSI:** Użycie istniejącej, zewnętrznej macierzy sprzętowej.
    * Kiedy wybrać które rozwiązanie? (Wydajność, koszty, istniejąca infrastruktura).

## Moduł 04 (infra-04): Integracja Sieciowa (Load Balancery F5, MetalLB)
* **Lekcja 4.1:** Architektura Sieci (SDN / OVN)
    * Koncepcja sieci nakładkowej (Overlay Network - VXLAN, Geneve).
    * Domyślny CNI (Container Network Interface) w OCP: **OVN-Kubernetes**.
    * (Wspomnienie o starym `openshift-sdn`).
* **Lekcja 4.2:** Ruch Północ-Południe (Ingress)
    * Jak ruch z zewnątrz trafia do klastra?
    * Rola **Zewnętrznego Load Balancera (L4/L7)** (np. F5, Citrix, Nginx, HAProxy).
    * Konfiguracja LB: Kierowanie ruchu (`*.apps.klaster.com`) do Węzłów Roboczych (Worker Nodes) na porty `80/443`.
    * Rola `Ingress Controller` (Router OCP) działającego na Workerach.
* **Lekcja 4.3:** Integracja z **MetalLB** (Dla Bare Metal)
    * Problem: Jak uzyskać `Service` typu `LoadBalancer` (zewnętrzny IP) na Bare Metal?
    * Instalacja Operatora MetalLB.
    * Konfiguracja puli adresów IP (z VLAN-u admina sieci).
    * Jak MetalLB "ogłasza" adresy IP (Tryb L2/ARP lub Tryb BGP).

## Moduł 05 (infra-05): OpenShift Virtualization (KubeVirt)
* **Lekcja 5.1:** Czym jest **OpenShift Virtualization**?
    * Technologia bazująca na open-source **KubeVirt**.
    * Instalacja przez Operator z OperatorHub.
* **Lekcja 5.2:** Koncepcja: VM-ka jako Pod
    * Uruchamianie **tradycyjnych Maszyn Wirtualnych (VM)** *wewnątrz* OpenShift, obok kontenerów.
    * VM-ka jest "opakowana" w specjalny Pod (`virt-launcher`).
    * Dostęp do konsoli VM (VNC/Serial) przez konsolę OCP i `oc`.
* **Lekcja 5.3:** Dlaczego? Konsolidacja i Modernizacja
    * **Jeden panel** do zarządzania starymi VM-kami (legacy apps) i nowymi kontenerami.
    * Stopniowa modernizacja: "Przenieś VM-kę z vSphere do OCP, a potem zacznij ją przepisywać na mikrousługi".
    * Uruchamianie aplikacji "nie-konteneryzowalnych" (np. Windows Server) na OCP.
* **Lekcja 5.4:** Migracja z vSphere (V2V)
    * Narzędzie **Migration Toolkit for Virtualization (MTV)**.
    * Proces importu VM-ki (VMDK) z vCenter bezpośrednio do OpenShift Virtualization.

## Moduł 06 (infra-06): Wsparcie Wieloarchitekturowe (IBM Power i Z)
* **Lekcja 6.1:** OpenShift to nie tylko x86_64
    * Oficjalne wsparcie dla **IBM Power (ppc64le)** i **IBM Z (s390x)**.
* **Lekcja 6.2:** Heterogeniczne Klastry (Mixed-Architecture)
    * Klaster OCP może mieć węzły Control Plane na x86 i węzły Workers na Power/Z.
    * Zarządzanie różnymi typami węzłów przez `MachineConfigPools`.
    * Użycie `NodeSelectors` i `Tolerations`, aby Pody lądowały na właściwej architekturze.
* **Lekcja 6.3:** Jak działają obrazy Multi-Arch?
    * Koncepcja "Manifest List" w rejestrze.
    * Jak OCP (CRI-O) automatycznie pobiera właściwy obraz (x86 lub ppc64le) dla węzła, na którym jest uruchamiany Pod.
* **Lekcja 6.4:** Zastosowania (Use Cases)
    * Uruchamianie obciążeń AIX/IBM i (migracja) lub baz danych (np. Db2, Oracle) na Power, obok aplikacji webowych na x86.
    * Konsolidacja obciążeń mainframe (Linux on Z) na platformie OCP.

---

# Ścieżka 3: Administrator Floty / Bezpieczeństwa

---

### Moduły Zarządzania (Ścieżka `mgmt-`)

* **[Moduł 01:** Zarządzanie Flotą Klastrów (Red Hat ACM)](./sciezka-zarzadzania/mgmt-01-acm-multicluster.md)**
* **[Moduł 02:** Zaawansowane Bezpieczeństwo i Zgodność (Red Hat ACS / StackRox)](./sciezka-zarzadzania/mgmt-02-acs-bezpieczenstwo.md)**
* **[Moduł 03:** Korporacyjne Zarządzanie Tożsamością (SSO, OIDC, SAML, Keycloak)](./sciezka-zarzadzania/mgmt-03-sso-identity.md)**
* **[Moduł 04:** Backup, Restore i Disaster Recovery (OADP / Velero)](./sciezka-zarzadzania/mgmt-04-oadp-backup-dr.md)**
* **[Moduł 05:** Zarządzanie Kosztami (Cost Management / Chargeback)](./sciezka-zarzadzania/mgmt-05-cost-management.md)**

## Moduł 01 (mgmt-01): Zarządzanie Flotą Klastrów (Red Hat ACM)
* **Lekcja 1.1:** Czym jest **Red Hat Advanced Cluster Management (ACM)**?
    * Platforma do zarządzania wieloma klastrami K8s.
* **Lekcja 1.2:** Architektura **Hub & Spoke**
    * **Hub Cluster:** Centralny klaster OCP, na którym zainstalowany jest ACM.
    * **Spoke Clusters:** Zarządzane klastry (mogą to być OCP, EKS, AKS, GKE).
    * Proces importowania istniejącego klastra do ACM.
* **Lekcja 1.3:** Zarządzanie Cyklem Życia Klastra
    * Tworzenie, aktualizowanie i usuwanie klastrów OCP (np. na AWS, vSphere) bezpośrednio z konsoli ACM.
* **Lekcja 1.4:** Zarządzanie Aplikacjami (Multi-Cluster)
    * Obiekty `Subscription`, `Channel`, `PlacementRule`.
    * Jak wdrażać aplikacje (np. z Git lub Helm) na wielu klastrachnocześnie (np. "wdróż na wszystkie klastry w Europie").
* **Lekcja 1.5:** Zarządzanie Politykami i Zgodnością (Governance)
    * Jak ACM wymusza spójne polityki (np. "każdy klaster musi mieć tę rolę RBAC", "zabroń `privileged` SCC") na całej flocie.
    * Dashboard zgodności (Compliance).

## Moduł 02 (mgmt-02): Zaawansowane Bezpieczeństwo i Zgodność (Red Hat ACS)
* **Lekcja 2.1:** Czym jest **Red Hat Advanced Cluster Security (ACS)**?
    * Platforma do bezpieczeństwa "cloud-native" (bazuje na **StackRox**).
    * Architektura: `Central` (w Huba) i `Sensor` (w Spoke'ach).
* **Lekcja 2.2:** Filar #1: Zarządzanie Podatnościami (Shift-Left)
    * Skanowanie obrazów (CI/CD, Rejestry) w poszukiwaniu CVE.
    * **Wyróżnik:** Skanowanie *działających* wdrożeń (Deploymentów) i priorytetyzacja ryzyka.
* **Lekcja 2.3:** Filar #2: Zarządzanie Konfiguracją i Zgodnością (Compliance)
    * Audyty klastra pod kątem standardów (CIS Benchmarks, PCI, HIPAA, NIST).
    * Dashboard i raportowanie zgodności.
* **Lekcja 2.4:** Filar #3: Detekcja Zagrożeń w Czasie Rzeczywistym (Runtime)
    * Jak ACS monitoruje zachowanie *wewnątrz* kontenera (np. uruchomienie powłoki, zapis do `/etc`, podejrzane połączenia sieciowe).
    * Automatyczne reagowanie (np. zabicie Poda).
* **Lekcja 2.5:** Wizualizacja Ryzyka i Sieci
    * Graf sieciowy (Network Graph) – pokazuje, które Pody *faktycznie* ze sobą rozmawiają.
    * Generowanie rekomendowanych `NetworkPolicy` na podstawie obserwacji ruchu.

## Moduł 03 (mgmt-03): Korporacyjne Zarządzanie Tożsamością (SSO)
* **Lekcja 3.1:** Konfiguracja Dostawców Tożsamości (IdP)
    * Obiekt `OAuth` CRD w OCP.
    * Różnica między `htpasswd` (dla labów) a `OIDC` / `SAML` (dla produkcji).
* **Lekcja 3.2:** Integracja z **Active Directory (AD)**
    * Konfiguracja dostawcy tożsamości `LDAP`.
    * Logowanie przy użyciu nazwy użytkownika i hasła z AD.
* **Lekcja 3.3:** Integracja z **Single Sign-On (SSO)**
    * Użycie **OIDC (OpenID Connect)** – nowoczesny standard.
    * Integracja z **Azure AD**, **Okta**, **PingFederate**.
    * Integracja z **Red Hat SSO (Keycloak)**.
* **Lekcja 3.4:** Synchronizacja Grup
    * Jak automatycznie mapować grupy z LDAP / OIDC (np. "Administratorzy VMware" z AD) na `Group` w OpenShift.
    * Użycie `RoleBinding`, aby automatycznie nadawać uprawnienia całym grupom AD.

## Moduł 04 (mgmt-04): Backup, Restore i Disaster Recovery (OADP)
* **Lekcja 4.1:** Czym jest **OADP (OpenShift API for Data Protection)**?
    * Operator Red Hat bazujący na open-source'owym **Velero**.
* **Lekcja 4.2:** Co obejmuje Backup?
    * Backup to nie tylko `PersistentVolumes` (dane).
    * To także **zasoby K8s** (YAML-e: Deploymenty, ConfigMapy, Secrety).
* **Lekcja 4.3:** Architektura (Velero + Restic/Kopia)
    * Rola Velero (backup obiektów K8s).
    * Rola `Restic` lub `Kopia` (backup danych z PV).
    * Konfiguracja `BackupStorageLocation` (gdzie składować backupy – np. S3, MinIO, Azure Blob).
* **Lekcja 4.4:** Scenariusze Użycia
    * **Backup/Restore Projektu:** Odtwarzanie skasowanego `Project` w tym samym klastrze.
    * **Migracja (Migration):** Backup Projektu na Klastrze A, odtworzenie na Klastrze B.
    * **Disaster Recovery (DR):** Użycie replikacji storage (np. ODF Regional-DR) w połączeniu z ACM i OADP do przełączania awaryjnego.

## Moduł 05 (mgmt-05): Zarządzanie Kosztami (Cost Management)
* **Lekcja 5.1:** OpenShift **Cost Management Service**
    * Usługa SaaS w konsoli Red Hat Hybrid Cloud (console.redhat.com).
    * Jak zintegrować klaster OCP (przez Operator), aby wysyłał dane o zużyciu.
* **Lekcja 5.2:** Koncepcje Showback / Chargeback
    * Jak generować raporty zużycia (CPU/RAM/Storage) per `Project`, `Node`, `Cluster`.
    * Tworzenie własnych tagów (etykiet) do kategoryzacji kosztów (np. `cost-center: Dzial-HR`).
    * Analiza kosztów OCP w chmurach publicznych (powiązanie z rachunkiem AWS/Azure).
* **Lekcja 5.3:** Optymalizacja Zasobów (Rightsizing)
    * Identyfikacja "zombie" Podów (nieużywanych) lub Podów z nadmiarowymi `request`.
* **Lekcja 5.4:** **Cluster Autoscaler** (Dla Infrastruktury)
    * Różnica między HPA (Horizontal Pod Autoscaler - skaluje Pody) a **Cluster Autoscaler (CA)** (skaluje Węzły).
    * Jak CA automatycznie dodaje (lub usuwa) *całe Węzły* (VM-ki) do klastra w zależności od zapotrzebowania na zasoby (gdy Pody są `Pending`).
    * Integracja z AWS Auto Scaling Groups, vSphere itp.

---

## Licencja

Treści w tym repozytorium są udostępnione na licencji **GNU General Public License v3.0 (GPLv3)**.

Oznacza to, że masz swobodę uruchamiania, studiowania, udostępniania i modyfikowania oprogramowania (lub w tym przypadku, treści). Wszelkie dzieła pochodne muszą być również dystrybuowane na tych samych warunkach licencyjnych.

Zaleca się umieszczenie pełnej treści licencji w pliku `LICENSE` w głównym katalogu repozytorium. [Pełną treść licencji GPLv3 można znaleźć tutaj](https://www.gnu.org/licenses/gpl-3.0.html).

---

## Historia Wersji

* **Aktualna Wersja:** Pełna reorganizacja repozytorium na trzy oddzielne ścieżki (Operator, Infrastruktura, Zarządzanie Flotą) oraz dodanie szczegółowego konspektu i holistycznej ścieżki przeplatanej do `README.md`.
* **Poprzednia Wersja (Archiwalna):** Początkowa, monolityczna ścieżka nauki.
