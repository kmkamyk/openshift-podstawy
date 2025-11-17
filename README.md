# 🚀 Kompleksowy Konspekt OpenShift (Wersja 5.0)

Witaj! To repozytorium to mój osobisty, ustrukturyzowany zbiór zagadnieień dotyczący platformy OpenShift.

Nie jest to szkolenie, lecz mapa drogowa i omówienie tematów, które opracowałem podczas własnej nauki. Repozytorium jest zorganizowane w logiczne ścieżki, które odpowiadają różnym rolom w ekosystemie OpenShift.

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
* [Moduł 00 (op-00): Przygotowanie Laboratorium (OpenShift Local)](./sciezka-operatora/op-00-przygotowanie.md)
* [Moduł 01 (op-01): Fundamenty – "Dlaczego OpenShift?"](./sciezka-operatora/op-01-fundamenty.md)
* [Moduł 02 (infra-01): "Pod Maską" – RHCOS i Architektura](./sciezka-infrastruktury/infra-01-pod-maska-rhcos.md)

### Faza 2: Cykl Życia Aplikacji (Hello World)
* [Moduł 03 (op-02): Zarządzanie Obrazami i Budowanie (S2I)](./sciezka-operatora/op-02-zarzadzanie-obrazami.md)
* [Moduł 04 (op-03): Wdrażanie Aplikacji (DeploymentConfig)](./sciezka-operatora/op-03-wdrazanie-aplikacji.md)
* [Moduł 05 (op-04): Networking Aplikacji (Route)](./sciezka-operatora/op-04-networking.md)
* [Moduł 06 (op-07): Konfiguracja (ConfigMap) i Sekrety](./sciezka-operatora/op-07-konfiguracja.md)
* [Moduł 07 (op-08): Storage (PVC/PV)](./sciezka-operatora/op-08-storage.md)

### Faza 3: Administracja Aplikacją (Zarządzanie i Bezpieczeństwo)
* [Moduł 08 (op-06): Bezpieczeństwo Aplikacji (SCC, RBAC)](./sciezka-operatora/op-06-bezpieczenstwo.md)
* [Moduł 09 (op-09): Skalowanie Aplikacji (HPA, Quotas)](./sciezka-operatora/op-09-skalowanie.md)
* [Moduł 10 (op-05): Troubleshooting Aplikacji](./sciezka-operatora/op-05-troubleshooting.md)
* [Moduł 11 (op-12): Obserwowalność (Monitoring, Logi)](./sciezka-operatora/op-12-obserwowalnosc.md)

### Faza 4: Rozszerzanie Platformy (Automatyzacja i Operatory)
* [Moduł 12 (op-11): Ekosystem Operatorów (OLM)](./sciezka-operatora/op-11-ekosystem-operatorow.md)
* [Moduł 13 (op-10): CI/CD (Tekton, ArgoCD)](./sciezka-operatora/op-10-cicd.md)

### Faza 5: Budowa Klastra Produkcyjnego (Infrastruktura)
* [Moduł 14 (infra-02): Instalacja (IPI vs. UPI) i vSphere](./sciezka-infrastruktury/infra-02-instalacja-ipi-upi.md)
* [Moduł 15 (infra-03): Integracja ze Storage (CSI)](./sciezka-infrastruktury/infra-03-storage-csi.md)
* [Moduł 16 (infra-04): Integracja Sieciowa (MetalLB)](./sciezka-infrastruktury/infra-04-networking-lb.md)
* [Moduł 17 (mgmt-03): Korporacyjne Zarządzanie Tożsamością (SSO)](./sciezka-zarzadzania/mgmt-03-sso-identity.md)

### Faza 6: Zarządzanie w Skali Enterprise (Flota i Bezpieczeństwo)
* [Moduł 18 (mgmt-01): Zarządzanie Flotą Klastrów (Red Hat ACM)](./sciezka-zarzadzania/mgmt-01-acm-multicluster.md)
* [Moduł 19 (mgmt-02): Zaawansowane Bezpieczeństwo (Red Hat ACS)](./sciezka-zarzadzania/mgmt-02-acs-bezpieczenstwo.md)
* [Moduł 20 (mgmt-04): Backup i Disaster Recovery (OADP)](./sciezka-zarzadzania/mgmt-04-oadp-backup-dr.md)
* [Moduł 21 (mgmt-05): Zarządzanie Kosztami i Autoskalowanie Klastra](./sciezka-zarzadzania/mgmt-05-cost-management.md)

### Faza 7: Tematy Zaawansowane i Co Dalej
* [Moduł 22 (infra-05): OpenShift Virtualization (KubeVirt)](./sciezka-infrastruktury/infra-05-wirtualizacja-kubevirt.md)
* [Moduł 23 (infra-06): Wsparcie Wieloarchitekturowe](./sciezka-infrastruktury/infra-06-multi-arch-power-z.md)
* [Moduł 24 (op-13): Co Dalej? (Certyfikacja, Service Mesh, Serverless)](./sciezka-operatora/op-13-co-dalej.md)

---

## 📚 Pełny, Szczegółowy Konspekt (Wersja 5.0)

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
    * Base