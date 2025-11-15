# Moduł 13: Co Dalej? Ścieżka do Poziomu Ekspert

Niniejszy moduł stanowi zwieńczenie dotychczasowej nauki, przenosząc administratora z poziomu biegłej znajomości codziennych operacji na poziom ekspercki. Opanowanie platformy OpenShift nie kończy się na umiejętności wdrażania aplikacji czy zarządzania klastrem. Prawdziwa ekspertyza polega na strategicznym planowaniu cyklu życia platformy, głębokiej automatyzacji oraz architektonicznym zrozumieniu zaawansowanych komponentów, które przekształcają OpenShift z "platformy do uruchamiania kontenerów" w "centralny system nerwowy nowoczesnego przedsiębiorstwa".

Ten moduł koncentruje się na pięciu filarach ścieżki do poziomu eksperta: walidacji umiejętności poprzez certyfikację, nawigacji w ekosystemie społeczności, opanowaniu automatyzacji i IaC, zarządzaniu złożonym cyklem życia klastra oraz integracji zaawansowanych architektur, takich jak Service Mesh, Serverless i Wirtualizacja.

---

## Lekcja 13.1: Walidacja Umiejętności i Przygotowanie do Certyfikacji

### 13.1.1. Wprowadzenie: Strategiczne Znaczenie Certyfikacji Red Hat

Na ścieżce do poziomu eksperta, certyfikacja Red Hat służy jako kluczowy, formalny mechanizm walidacji. W przeciwieństwie do egzaminów teoretycznych, ścieżka OpenShift opiera się fundamentalnie na egzaminach opartych na wydajności (performance-based).[1, 2, 3] Kandydat nie jest pytany "jak byś coś zrobił", ale otrzymuje działający klaster i listę zadań do wykonania w określonym czasie. Ten format testuje rzeczywiste, praktyczne umiejętności i zdolność do rozwiązywania problemów pod presją, co jest wyznacznikiem prawdziwej biegłości.

Co więcej, każda z omówionych specjalistycznych certyfikacji (`EX180`, `EX280`, `EX288`) jest krokiem w kierunku uzyskania najwyższego poziomu uwierzytelnienia technicznego: Red Hat Certified Architect (RHCA).[2, 3, 4] Status ten wymaga zdobycia pięciu lub więcej specjalistycznych certyfikacji, demonstrując szeroką i głęboką wiedzę w całym portfolio Red Hat.

### 13.1.2. Ścieżka Podstawowa: EX180 (Red Hat Certified Specialist in Containers and Kubernetes)

Egzamin `EX180` waliduje fundamentalne umiejętności wymagane do pracy z technologiami kontenerowymi i stanowi niezbędną podstawę dla obu bardziej zaawansowanych ścieżek.[4, 5] Jest on skierowany do administratorów, deweloperów i inżynierów SRE, którzy są nowi w ekosystemie OpenShift [6] lub chcą ugruntować swoją wiedzę przed podjęciem `EX288`.[7, 8]

Dekonstrukcja celów egzaminu `EX180` ujawnia, że koncentruje się on na pełnym cyklu życia pojedynczego kontenera [6]:

* **Implementacja Obrazów (Podman/Buildah):** Kandydat musi wykazać się biegłą znajomością tworzenia obrazów przy użyciu instrukcji Dockerfile. Obejmuje to rozumienie `FROM` (obraz bazowy), `RUN` (wykonywanie poleceń), `WORKDIR` i `USER` (kontekst pracy i bezpieczeństwo), `ENV` (zmienne środowiskowe) oraz `EXPOSE` (dokumentacja portów). Kluczowa jest znajomość różnic między `ADD` a `COPY` (gdzie `ADD` ma dodatkowe funkcje, takie jak rozpakowywanie archiwów) oraz fundamentalnej różnicy między `CMD` (polecenie domyślne, które może być nadpisane) a `ENTRYPOINT` (główny wykonywalny plik kontenera).[6]
* **Zarządzanie Obrazami (Podman/Skopeo):** Egzamin sprawdza umiejętność interakcji z rejestrami obrazów.[6] Obejmuje to tagowanie, wysyłanie (push) i pobieranie (pull) obrazów z różnych rejestrów, w tym zabezpieczonych prywatnych.[1, 6]
* **Podstawy OpenShift:** Ostatnia część skupia się na podstawowym wdrożeniu. Kandydat musi umieć tworzyć i zarządzać projektami oraz wdrażać aplikacje na trzy podstawowe sposoby: z istniejącego obrazu, z kodu źródłowego (wykorzystując domyślne mechanizmy S2I) oraz z szablonu. Obejmuje to również podstawowe rozwiązywanie problemów, takie jak inspekcja zasobów aplikacji i pobieranie logów.[5, 6]

`EX180` to nie tylko "egzamin z Podmana". To test, który sprawdza, czy kandydat rozumie *cały cykl życia* pojedynczego kontenera, od budowy po wdrożenie w prostym środowisku Kubernetes (OpenShift). Jest to fundament, bez którego niemożliwe jest efektywne administrowanie (`EX280`) lub tworzenie (`EX288`) na dużą skalę.

### 13.1.3. Ścieżka Administracyjna: EX280 (Red Hat Certified OpenShift Administrator)

Egzamin `EX280` jest przeznaczony dla administratorów systemów, administratorów chmury i inżynierów SRE.[9, 10] Koncentruje się on wyłącznie na operacjach "Dnia 2" (Day 2 operations).[9] Egzamin zakłada, że klaster już istnieje; zadaniem kandydata jest jego efektywne zarządzanie, konfiguracja, zabezpieczenie i utrzymanie.[2, 9]

Dekonstrukcja celów egzaminu `EX280` [10, 11, 12]:

* **Zarządzanie Użytkownikami i Uwierzytelnianiem:** Konfiguracja dostawców tożsamości (np. `HTPasswd` dla celów testowych), zarządzanie użytkownikami i grupami oraz, co najważniejsze, kontrolowanie dostępu do zasobów za pomocą Role-Based Access Control (RBAC).[10, 11]
* **Konfiguracja Sieci:** Jest to krytyczny obszar. Obejmuje zarządzanie komponentami sieciowymi, podstawowe rozwiązywanie problemów z Software Defined Network (SDN), tworzenie i zabezpieczanie tras (Routes) (w tym certyfikatami TLS) oraz implementowanie polityk sieciowych (NetworkPolicies) w celu izolacji ruchu między Podami.[10, 11]
* **Zarządzanie Pamięcią Masową:** Tworzenie i wstrzykiwanie konfiguracji do aplikacji za pomocą `Secrets` i `ConfigMaps` oraz rozumienie provisioningu wolumenów trwałych (Persistent Volumes).[10]
* **Operacje na Klastrze:** Obejmuje to zaawansowane konfigurowanie harmonogramowania Podów (Pod Scheduling), skalowanie klastra (ręczne lub automatyczne), monitorowanie stanu klastra i zdarzeń oraz zarządzanie Operatorami z OperatorHub.[9, 10, 11]
* **Wsparcie Deweloperów (Self-Service):** Kluczowy cel, który polega na konfigurowaniu limitów i kwot (Quotas, LimitRanges) oraz zarządzaniu szablonami (Templates), aby umożliwić deweloperom bezpieczne i samodzielne wdrażanie aplikacji.[10, 12]

### 13.1.4. Ścieżka Deweloperska: EX288 (Red Hat Certified OpenShift Application Developer)

Egzamin `EX288` jest skierowany do deweloperów aplikacji i specjalistów DevOps.[7, 8, 13] Skupia się na perspektywie dewelopera, który musi efektywnie wdrażać i zarządzać *cyklem życia aplikacji* na platformie, którą *administruje* ktoś inny.[3, 8, 13]

Dekonstrukcja celów egzaminu `EX288` [3, 13]:

* **Zaawansowane Wdrożenia (Helm/Kustomize):** Ten egzamin wykracza poza proste wdrożenia. Kandydat musi umieć tworzyć i używać chartów `Helm` oraz stosować `Kustomize` do dostosowywania wdrożeń w różnych środowiskach.[3, 13]
* **Cykl Życia Obrazu i Budowania:** Głębokie zanurzenie w mechanizmy budowania OpenShift. Obejmuje to pracę z konfiguracjami budowania (Build Configs), strategią `Source-to-Image` (S2I), konfigurowanie hooków (np. pre-commit) i wyzwalaczy (Triggers - np. automatyczne przebudowanie po zmianie w `ImageStream`).[3]
* **Monitoring i Konfiguracja Aplikacji:** Implementacja monitorowania stanu aplikacji (Health Probes: liveness, readiness), co jest kluczowe dla niezawodnych wdrożeń, oraz wykorzystywanie `ConfigMaps` i `Secrets` do zarządzania konfiguracją aplikacji.[3, 13]
* **Potoki CI/CD (Tekton):** Zrozumienie i praca ze standardowymi definicjami zasobów (CRD) `Tekton` (np. `Pipeline`, `Task`, `PipelineRun`) do definiowania i uruchamiania potoków ciągłej integracji i ciągłego dostarczania wewnątrz OpenShift.[3]

### 13.1.5. Synteza i Wnioski: Model Eksperta "T"

Analiza tych trzech ścieżek certyfikacyjnych ujawnia kluczową strategię rozwoju kompetencji. Ścieżka do poziomu eksperta OpenShift rzadko jest pojedynczą linią; jest to raczej T-kształtny model kompetencji.

Podstawę (poziomą belkę "T") stanowi `EX180` [4], które zapewnia szeroką, fundamentalną wiedzę na temat kontenerów, obrazów i podstaw Kubernetes. Bez tego fundamentu niemożliwe jest ani efektywne administrowanie, ani tworzenie oprogramowania na platformie.

Następnie ekspert musi wybrać pionową specjalizację (pionową nogę "T"). `EX280` [9] to głęboka specjalizacja w administrowaniu, zabezpieczaniu i optymalizowaniu samej *platformy*. `EX288` [3] to głęboka specjalizacja w budowaniu, wdrażaniu i zarządzaniu cyklem życia *aplikacji na platformie*.

Jednak prawdziwy ekspert, dążący do poziomu architekta (RHCA) [2, 3, 4], rozumie, że te dwie domeny są ze sobą nierozerwalnie związane. Zauważalny jest wzorzec w celach obu egzaminów, który odzwierciedla filozofię DevOps platformy. Kluczowym celem administratora `EX280` jest "Włączenie samoobsługi deweloperów" (Enable Developer Self-Service).[10] Administrator nie wdraża aplikacji; administrator buduje i konfiguruje platformę (ustawia kwoty, szablony, operatory) [12], aby deweloper *mógł* bezpiecznie i samodzielnie wdrażanie aplikacji.

Cele `EX288` [3, 13] są lustrzanym odbiciem tego założenia. Deweloper używa zaawansowanych narzędzi (Helm, Tekton, S2I) do *konsumowania* platformy, którą administrator dla niego przygotował. Egzaminy te testują tę symbiotyczną relację. Ścieżka do eksperta to zrozumienie, że celem OpenShift nie jest po prostu "uruchamianie kontenerów", ale stworzenie wewnętrznej platformy deweloperskiej (Internal Developer Platform - IDP), która automatyzuje, zabezpiecza i przyspiesza ścieżkę od kodu do produkcji.

**Tabela 13.1: Porównanie Ścieżek Certyfikacji Red Hat OpenShift**

| Egzamin | Tytuł Certyfikacji | Główny Fokus (Rola) | Kluczowe Technologie | Grupa Docelowa |
| :--- | :--- | :--- | :--- | :--- |
| **`EX180`** | Red Hat Certified Specialist in Containers and Kubernetes | Fundamenty | Podman, Buildah, Dockerfile, Podstawy OpenShift (Projekty, Wdrożenia) | Administratorzy, Deweloperzy, SRE (początkujący w kontenerach) [4, 6] |
| **`EX280`** | Red Hat Certified OpenShift Administrator | Administracja "Dnia 2" | RBAC, Sieć (SDN, Routes, Policies), Storage (PV/PVC), Operatory, Quotas, Scheduling | Administratorzy Systemów/Chmury, SRE [9, 10] |
| **`EX288`** | Red Hat Certified OpenShift Application Developer | Cykl Życia Aplikacji | Helm, Kustomize, S2I, Build Configs, ImageStreams, Tekton (Pipelines), Health Probes | Deweloperzy Aplikacji, Role DevOps [3, 8, 13] |

---

## Lekcja 13.2: Angaż w Społeczność i Zaawansowane Zasoby Wiedzy

Osiągnięcie poziomu eksperta nie jest możliwe w próżni. Wymaga to aktywnego zaangażowania w dynamiczny ekosystem, który otacza OpenShift, począwszy od jego upstreamowego projektu, OKD.

### 13.2.1. Definicja OKD: Czym jest The Community Distribution of OpenShift?

OKD (wcześniej znane jako OpenShift Origin) jest publicznie dostępnym, wspieranym przez społeczność projektem upstream dla komercyjnego produktu Red Hat OpenShift Container Platform (OCP).[14, 15] OKD to kompletna dystrybucja Kubernetes, zoptymalizowana pod kątem ciągłego rozwoju aplikacji i wdrożeń wielodostępnych (multi-tenant).[16]

Kluczowe różnice między OKD a OCP definiują ich różne przypadki użycia [15, 17]:

1.  **System Operacyjny:** OKD wykorzystuje Fedora CoreOS (FCOS) lub, w nowszych strumieniach, CentOS Stream CoreOS.[17, 18, 19] Są to szybko rozwijające się, najnowocześniejsze systemy operacyjne. Natomiast OCP jest zbudowane wyłącznie na Red Hat Enterprise Linux CoreOS (RHCOS), które bazuje na stabilnym, wspieranym przez przedsiębiorstwa RHEL.[17, 20]
2.  **Model Wsparcia:** OKD jest wspierane przez społeczność (fora, czaty, repozytoria GitHub).[15, 17] OCP jest produktem komercyjnym objętym subskrypcją Red Hat, która gwarantuje wsparcie techniczne 24/7, dostęp do bazy wiedzy i zasobów bezpieczeństwa.[15, 17]
3.  **Cykl Wydawniczy:** OKD jest "upstreamem", co oznacza, że zazwyczaj jest o kilka wydań *przed* OCP.[14, 15] Nowe funkcje i zmiany architektoniczne są testowane i walidowane w OKD, zanim zostaną uznane za wystarczająco stabilne i gotowe do włączenia do produktu korporacyjnego OCP.[14, 15]

OKD jest idealnym rozwiązaniem dla celów edukacyjnych, tworzenia laboratoriów domowych, testowania najnowszych funkcji oraz dla społeczności, która chce aktywnie współtworzyć platformę.[15, 18, 21] OCP jest przeznaczone do stabilnych, długoterminowych wdrożeń produkcyjnych w przedsiębiorstwach.[15]

### 13.2.2. Gdzie Szukać Pomocy i Wiedzy: Nawigacja po Ekosystemie

Ekspert musi wiedzieć, gdzie szukać odpowiedzi. Ekosystem OpenShift oferuje bogactwo zasobów, które można podzielić na trzy kategorie:

1.  **Oficjalna Dokumentacja:**
    * **Dokumentacja OKD (`docs.okd.io`):** Niezbędne źródło do zrozumienia funkcji "upstream" i architektury FCOS.[16, 19, 22]
    * **Dokumentacja OCP (Red Hat Customer Portal):** Oficjalna, wspierana dokumentacja dla wersji produkcyjnych. Jest to podstawowe źródło wiedzy dla administratorów OCP.

2.  **Blogi i Artykuły (Źródło Nowości):**
    * **Oficjalny Blog Red Hat (`redhat.com/en/blog`):** Sekcja ta, wraz z kanałami tematycznymi (np. Automation, AI, Security) [23], dostarcza ogólnych informacji o strategii firmy.
    * **Oficjalny Kanał Blogowy OpenShift (`redhat.com/en/blog/channel/red-hat-openshift`):** Jest to najważniejsze źródło informacji o nowych wydaniach, funkcjach (np. wirtualizacja, AI, bezpieczeństwo) [24] oraz najlepszych praktykach wdrażania.

3.  **Fora i Społeczność (Źródło Rozwiązań):**
    * **Red Hat Customer Portal Discussions:** Oficjalne forum, na którym klienci Red Hat mogą zadawać pytania i otrzymywać pomoc zarówno od społeczności, jak i od inżynierów Red Hat.[25, 26, 27]
    * **Subreddit `r/openshift`:** Wysoce aktywna, profesjonalna społeczność techniczna, na której dyskutuje się zarówno o OCP, jak i OKD. Często można tu znaleźć nieoficjalne, ale skuteczne rozwiązania rzeczywistych problemów.[28]
    * **OpenShift Commons:** Nie jest to typowe forum, ale raczej miejsce spotkań i networkingu dla globalnej społeczności użytkowników, partnerów i współtwórców. Uczestnictwo w Commons (np. w spotkaniach i briefingach) to sposób na bezpośrednią interakcję z twórcami produktu.[29]

### 13.2.3. Synteza i Wnioski: OKD jako "Kryształowa Kula"

Dla administratora na poziomie średniozaawansowanym, OKD może wydawać się po prostu "darmowym OCP". Ekspert postrzega to inaczej. OKD nie służy do "oszczędzania pieniędzy"; służy jako "kryształowa kula".

Fakt, że OKD jest "upstreamem" [14] i miejscem, gdzie "funkcje są testowane" [15], oznacza, że jest to prototyp przyszłych wersji OCP. Ekspert OpenShift uruchamia klaster OKD w swoim laboratorium, aby zobaczyć, jakie zmiany architektoniczne (np. nowe wersje operatorów, zmiany w FCOS, które wkrótce staną się zmianami w RHCOS, nowe podejścia do budowania samego OKD za pomocą Tektona [18, 30]) pojawią się w produkcyjnym OCP za 6 do 12 miesięcy. Pozwala to na strategiczne planowanie przyszłych aktualizacji, testowanie kompatybilności i unikanie problemów, zanim dotrą one do środowiska produkcyjnego.

Co więcej, ekosystem wiedzy odzwierciedla ścieżkę dojrzewania eksperta. Można wyróżnić trzy poziomy zaangażowania:
1.  **Konsumpcja (Proaktywna):** Czytanie dokumentacji i oficjalnych blogów [22, 24], aby zrozumieć, "Co nowego?" i "Jak to działa?".
2.  **Rozwiązywanie Problemów (Reaktywne):** Aktywne korzystanie z forów [25, 28], aby rozwiązać konkretny problem: "Mam błąd, pomóżcie!".
3.  **Współtworzenie (Strategiczne):** Angażowanie się w OpenShift Commons [29], aby wymieniać się wiedzą z innymi ekspertami i współtworzyć najlepsze praktyki: "Jak inni rozwiązują ten problem na dużą skalę?" oraz "Jak mogę wpłynąć na rozwój produktu?".

Ścieżka do poziomu eksperta polega na ewolucji od pasywnej konsumpcji do aktywnego współtworzenia.

**Tabela 13.2: Macierz Różnic: OKD vs. OCP**

| Atrybut | OKD (Community Distribution) | OCP (Container Platform) |
| :--- | :--- | :--- |
| **Podstawowy System Operacyjny** | Fedora CoreOS (FCOS) / CentOS Stream CoreOS [17, 18, 19] | Red Hat Enterprise Linux CoreOS (RHCOS) [17, 20] |
| **Model Wsparcia** | Wsparcie społeczności (fora, `r/openshift`) [15, 17] | Pełne wsparcie korporacyjne Red Hat (subskrypcja) [15, 17] |
| **Cykl Wydawniczy** | Upstream; wydania częstsze, zawiera nowe funkcje (o kilka wersji "przed" OCP) [14, 15] | Stabilny; wydania rzadsze, w pełni przetestowane, z długoterminowym wsparciem (EUS) [15, 31] |
| **Główne Przeznaczenie** | Laboratoria, edukacja, testowanie nowych funkcji, rozwój "upstream" [15, 21] | Stabilne wdrożenia produkcyjne w przedsiębiorstwach [15] |

---

## Lekcja 13.3: Automatyzacja i Infrastruktura jako Kod (IaC) dla OpenShift

### 13.3.1. Rozróżnienie Domen Automatyzacji: "Wewnątrz" vs. "Dla" Klastra

Fundamentalną koncepcją, którą musi opanować ekspert OpenShift, jest rozróżnienie dwóch domen automatyzacji. Wymagają one różnych narzędzi i różnych podejść:

1.  **Automatyzacja *Wewnątrz* Klastra:** Zarządzanie zasobami (Projects, Deployments, Routes, Users) *po* zainstalowaniu klastra. Odbywa się to poprzez interakcję z API Kubernetes/OpenShift.
2.  **Automatyzacja *Dla* Klastra:** Provisioning i zarządzanie infrastrukturą (VM, VPC, Load Balancery, rekordy DNS), na której klaster *będzie działał*. Odbywa się to poprzez interakcję z API dostawcy chmury lub wirtualizacji.

Do tych dwóch domen historycznie przypisane są dwa różne narzędzia: Ansible i Terraform.

### 13.3.2. Ansible: Automatyzacja wewnątrz Klastra OCP

Ansible jest idealnym narzędziem do zarządzania konfiguracją i automatyzacji operacji "Dnia 1" i "Dnia 2" *wewnątrz* istniejącego klastra.[32]

* **Kluczowe Technologie:**
    * **Moduł `kubernetes.core.k8s`:** Jest to podstawowy i najbardziej elastyczny moduł Ansible do zarządzania zasobami Kubernetes.[33, 34] Pozwala on na deklaratywne tworzenie, modyfikowanie i usuwanie dowolnych obiektów API (np. `Project`, `Deployment`, `ConfigMap`) poprzez przekazanie ich definicji YAML bezpośrednio w playbooku.[33]
    * **Kolekcja `redhat.openshift`:** Specjalistyczna kolekcja zawierająca moduły ułatwiające konkretne zadania w OpenShift, np. zarządzanie maszynami wirtualnymi w OpenShift Virtualization.[32]
    * **Operator Ansible Automation Platform (AAP):** Zamiast uruchamiać Ansible z zewnętrznej maszyny, można wdrożyć AAP jako Operator *wewnątrz* OpenShift.[35, 36] Pozwala to na tworzenie playbooków, które działają natywnie w klastrze i reagują na zdarzenia w nim zachodzące.

* **Przykład Użycia:** Typowy scenariusz dla Ansible (przedstawiony w [37]) to playbook, który automatyzuje proces wdrażania aplikacji:
    1.  Używa modułu `k8s` do stworzenia nowego projektu (np. `guestbook`).
    2.  Używa modułu `k8s` do wdrożenia bazy danych (np. Redis-leader).
    3.  Używa modułu `k8s` do wdrożenia replik (np. Redis-follower).
    4.  Używa modułu `k8s` do wdrożenia frontendu.
    5.  Używa modułów `k8s` do skonfigurowania sieci (Services i Routes), aby wystawić aplikację na zewnątrz.[37]

### 13.3.3. Terraform: Provisioning Infrastruktury dla Klastra OCP/OKD

Terraform jest standardem branżowym w dziedzinie Infrastruktury jako Kod (IaC) i koncentruje się na operacjach "Dnia 0": budowaniu i zarządzaniu stanem infrastruktury.[38]

* **Kluczowe Technologie:**
    * **Providerzy Chmurowi (np. `aws`, `azure`, `google`, `vsphere`):** Terraform używa tych providerów do interakcji z API dostawców chmury. Służą one do tworzenia maszyn wirtualnych, sieci VPC, grup bezpieczeństwa, load balancerów i wszystkich innych komponentów potrzebnych do uruchomienia klastra OCP w trybie UPI (User-Provisioned Infrastructure) [38, 39] lub klastra OKD.[40]
    * **Provider `rhcs` (Red Hat Cloud Services):** Jest to oficjalny provider Terraform, który automatyzuje tworzenie i zarządzanie klastrami *zarządzanymi* przez Red Hat, takimi jak ROSA (Red Hat OpenShift Service on AWS).[41] Zamiast budować setki zasobów (VM, role IAM), deweloper definiuje jeden zasób `rhcs_cluster`, a provider zajmuje się resztą.[41]

* **Przykłady Użycia:**
    * Automatyzacja pełnego wdrożenia klastra ROSA na AWS.[41]
    * Provisioning infrastruktury (VM, DNS, LB) dla wdrożenia OCP UPI na VMware.[38]
    * Tworzenie infrastruktury dla klastrów OKD na dowolnej chmurze.[39, 40]

### 13.3.4. Synteza i Wnioski: Dychotomia IaC i jej Zacieranie

Podstawową zasadą, którą kieruje się ekspert, jest dychotomia "Wewnątrz/Na Zewnątrz", którą można ująć w metaforę: **"Terraform buduje dom, a Ansible go mebluje"**.

Terraform, ze swoim modelem zarządzania stanem, jest idealny do budowania i utrzymywania stosunkowo statycznej infrastruktury bazowej (domu).[41] Próba użycia Terraform do zarządzania szybko zmieniającymi się zasobami *wewnątrz* klastra (jak `Deployment` aplikacji) jest możliwa, ale często prowadzi do konfliktów stanu i jest uważana za anty-wzorzec.

Z drugiej strony, Ansible jest idealny do zarządzania konfiguracją i wdrażania aplikacji (meblowania).[37] Jego bezstanowa (domyślnie) natura doskonale pasuje do dynamicznego i idempotentnego charakteru API Kubernetes.

Jednak na najbardziej zaawansowanym poziomie, ta granica zaczyna się zacierać. Nowoczesne, eksperckie wzorce automatyzacji opierają się na **automatyzacji sterowanej z klastra**. Zamiast uruchamiać Terraform czy Ansible z laptopa administratora lub serwera CI, ekspert wdraża *Operatory* tych narzędzi:

1.  **Ansible Automation Platform Operator** [32, 35] jest wdrażany na centralnym "klastrze hub", skąd może zarządzać cyklem życia aplikacji na wielu innych "klastrach spoke".
2.  **HCP Terraform Operator** [42] działa *wewnątrz* Kubernetes, aby umożliwić zarządzanie zasobami Terraform (czyli infrastrukturą *na zewnątrz*) za pomocą natywnych zasobów Kubernetes (CRD).

W tym zaawansowanym modelu, klaster OpenShift staje się nie tylko celem automatyzacji, ale także jej *silnikiem*.

**Tabela 13.3: Porównanie Domen Automatyzacji: Ansible vs. Terraform w Ekosystemie OpenShift**

| Kryterium | Ansible | Terraform |
| :--- | :--- | :--- |
| **Główna Domena** | Zarządzanie zasobami **Wewnątrz** klastra (Operacje Dnia 1/2) [32, 37] | Provisioning infrastruktury **Dla** klastra (Operacje Dnia 0) [38, 41] |
| **Kluczowe Moduły/Providerzy** | `kubernetes.core.k8s` [33], `redhat.openshift` [32], Operator AAP [35] | Providerzy chmurowi (`aws`, `azure`, `vsphere`), Provider `rhcs` [41] |
| **Typowy Scenariusz** | Wdrożenie aplikacji, tworzenie projektów, konfiguracja RBAC [37] | Budowa klastra UPI [38], provisioning klastra ROSA/ARO [41], tworzenie VPC i VM [38] |
| **Model Działania** | Zarządzanie Konfiguracją (Configuration Management) | Zarządzanie Stanem Infrastruktury (Infrastructure State Management) |

---

## Lekcja 13.4: Zaawansowane Zarządzanie Cyklem Życia Klastra

Eksperckie zarządzanie OpenShift w dużej mierze sprowadza się do mistrzowskiego opanowania dwóch procesów: aktualizacji i migracji. Są to najbardziej ryzykowne i złożone operacje w cyklu życia platformy.

### 13.4.1. Anatomia Procesu Aktualizacji "Over-the-Air" (OTA)

Aktualizacje OTA w OpenShift są wysoce ustrukturyzowanym procesem, zaprojektowanym w celu minimalizacji ryzyka.

* **OpenShift Update Service (OSUS):** Sercem procesu jest hostowana przez Red Hat usługa OSUS.[43, 44, 45] Klastry (nawet te w trybie disconnected) kontaktują się z nią, aby otrzymać "graf" (diagram) dostępnych i co najważniejsze, *bezpiecznych* ścieżek aktualizacji.[44, 45] OSUS informuje klaster, czy z wersji X można bezpiecznie przejść do wersji Y.
* **Strategia Kanałów (Channels):** Administratorzy mają kontrolę nad strategią aktualizacji, wybierając odpowiedni kanał [31, 46]:
    * `candidate`: Kompilacje testowe, potencjalnie niestabilne. Używane do testowania nadchodzących wydań, absolutnie niezalecane dla produkcji.[46, 47, 48]
    * `fast`: Zawiera najnowsze wspierane wydania (z-stream), które są udostępniane natychmiast po opublikowaniu erraty.[31, 48]
    * `stable`: Najczęściej wybierany kanał produkcyjny. Zawiera te same wydania co `fast`, ale udostępniane z opóźnieniem (np. tygodniowym). Opóźnienie to pozwala Red Hat SRE i innym klientom na wczesne wykrycie ewentualnych problemów.[31, 48]
    * `eus`: Kanały Extended Update Support, przeznaczone dla wersji o wydłużonym wsparciu (np. 4.10, 4.12), które pozwalają na pozostanie na danej wersji minor przez dłuższy czas.[31, 46]

### 13.4.2. Głęboka Analiza Operatorów Cyklu Życia: CVO i MCO

Aktualizacja OCP to wysoce skoordynowany proces zarządzany w dwóch głównych aktach przez dwa kluczowe operatory.[43]

**Akt 1: Cluster Version Operator (CVO) - "Mózg"**

CVO jest "mózgiem" operacji aktualizacji.[43, 49]
* **Rola:** CVO stale monitoruje OSUS pod kątem dostępnych aktualizacji w wybranym kanale.[43, 44] Gdy administrator zatwierdzi aktualizację, CVO pobiera obraz wydania (release payload) z rejestru (np. quay.io).[49, 50]
* **Proces:** Obraz wydania zawiera kompletny zestaw manifestów YAML dla *wszystkich* komponentów klastra w nowej wersji. CVO rozpakowuje te manifesty i rozpoczyna proces *uzgadniania* (reconcile) obecnego stanu klastra ze stanem docelowym opisanym w manifestach.[44, 49]
* **Kolejność:** CVO aktualizuje komponenty w ścisłej kolejności, zdefiniowanej przez "Runlevels".[44] Najpierw aktualizuje *cały Control Plane* (etcd, API server, controllery).[43, 51] CVO monitoruje stan podległych Operatorów Klastra (np. Operatora sieci, Operatora pamięci masowej) i przechodzi do kolejnych poziomów (Runlevels) tylko wtedy, gdy wszystkie komponenty na poprzednim poziomie zgłoszą stan stabilny i zaktualizowany.[43, 44]

**Akt 2: Machine Config Operator (MCO) - "Wykonawca"**

Gdy CVO zakończy aktualizację Control Plane, do akcji wkracza MCO.[43, 52]
* **Rola:** MCO jest "wykonawcą" odpowiedzialnym za aktualizację samych węzłów (zarówno Control Plane, jak i Workerów).[43]
* **Proces:** MCO zarządza pulami węzłów (Machine Config Pools - MCP). Dla każdej puli, MCO aktualizuje węzły jeden po drugim (lub zgodnie ze strategią zdefiniowaną w polu `maxUnavailable` [43]). Proces dla każdego węzła jest identyczny i zgodny z najlepszymi praktykami Kubernetes [43]:
    1.  Oznaczenie węzła jako `Cordoned` (nie planuj nowych Podów).
    2.  Wykonanie operacji `Drain` (bezpieczna ewakuacja wszystkich istniejących Podów na inne węzły).
    3.  Zastosowanie nowej konfiguracji maszyny (w tym aktualizacja systemu operacyjnego RHCOS i Kubelet).[20, 43]
    4.  Wykonanie `Reboot` węzła.
    5.  Oznaczenie węzła jako `Uncordon` (przywrócenie węzła do służby i umożliwienie planowania Podów).
* **Kolejność:** MCO najpierw aktualizuje pulę węzłów Control Plane, a następnie, gdy Control Plane jest w pełni operacyjny na nowej wersji, przechodzi do aktualizacji pul węzłów roboczych (Worker).[43, 51]

### 13.4.3. Strategie Migracji Między Klastrami: OADP i Velero

Podczas gdy aktualizacje OTA zarządzają cyklem życia *wewnątrz* klastra, migracja zarządza cyklem życia *między* klastrami (np. w scenariuszu Disaster Recovery lub migracji do nowej wersji major).

* **Architektura:**
    * **OADP (OpenShift API for Data Protection):** Jest to oficjalny Operator Red Hat, który instaluje i zarządza komponentami wymaganymi do tworzenia kopii zapasowych i przywracania *aplikacji*.[53, 54, 55]
    * **Velero:** OADP jest w istocie opakowaniem dla popularnego projektu open-source Velero.[54, 56, 57] OADP dodaje do Velero wtyczki (pluginy) specyficzne dla OpenShift.
* **Zakres Działania:** Jest to krytycznie ważna koncepcja. OADP/Velero służy do tworzenia kopii zapasowych i migracji *aplikacji* (obciążeń), a *nie* całego klastra.[58]
* **Co jest backupowane [54, 55, 59]:**
    * **Zasoby Kubernetes/OpenShift:** Wszystkie manifesty YAML definiujące aplikację (Deployments, Services, Routes, ConfigMaps, Secrets itp.).
    * **Wolumeny Trwałe (Persistent Volumes):** Dane aplikacji. Odbywa się to albo poprzez tworzenie natywnych snapshotów na poziomie dostawcy pamięci masowej (np. snapshoty CSI) [60, 61], albo (jeśli snapshoty nie są dostępne) poprzez kopię systemu plików.[56]
    * **Obrazy Wewnętrzne:** OADP/Velero posiada plugin [62] do backupowania obrazów zbudowanych i przechowywanych we wewnętrznym rejestrze OpenShift.[54]
* **Czego *nie* można backupować [54, 55, 58]:**
    * **`etcd`:** Tożsamość i stan całego klastra.
    * **Operatory OpenShift:** Komponenty samego klastra (jak CVO, MCO). Są one częścią instalacji platformy, a nie aplikacji.

### 13.4.4. Synteza i Wnioski: Dwie Strategie Eksperckie

Zrozumienie tych dwóch procesów prowadzi do dwóch kluczowych strategii na poziomie eksperckim.

**1. Strategia Diagnostyczna (Aktualizacje): "Dusza vs Ciało"**
Proces aktualizacji OCP można postrzegać jako dwu-etapową, transakcyjną operę: CVO aktualizuje "duszę" klastra (oprogramowanie Control Plane i jego stan) [49], podczas gdy MCO aktualizuje jego "ciało" (fizyczne lub wirtualne węzły).[43]

Dla eksperta jest to fundamentalne rozróżnienie diagnostyczne. Gdy aktualizacja klastra "utknie", wie on dokładnie, gdzie szukać problemu:
* Jeśli `ClusterVersion` jest w stanie `Progressing=True` od wielu godzin, a wersja jeszcze się nie zmieniła, problem leży po stronie **CVO** lub jednego z podległych Operatorów Klastra, który nie chce zgłosić stanu `stable`.
* Jeśli `ClusterVersion` pokazuje nową wersję, ale węzły (Nodes) pozostają w starych wersjach lub proces aktualizacji węzłów utknął, problem leży po stronie **MCO** i jego `MachineConfigPools` (np. Pod Disruption Budget blokuje operację `Drain` lub nowy RHCOS nie chce się uruchomić).

**2. Strategia DR (Migracje): "Infrastruktura jako Byt Efemeryczny"**
Ograniczenia OADP/Velero (brak backupu `etcd` i Operatorów) [54, 55, 58] nie są wadą; są *cechą* architektury cloud-native, która wymusza zmianę paradygmatu Disaster Recovery (DR).

Administrator na poziomie średniozaawansowanym może próbować "backupować serwer `etcd`". Ekspert wie, że klaster OCP jest traktowany jako byt efemeryczny (cattle, not pets), który powinien być w pełni odtwarzalny z kodu.

Dlatego ekspercka strategia DR łączy lekcje 13.3 i 13.4:
1.  **Krok 1 (IaC - Lekcja 13.3):** W razie katastrofy, nikt nie "przywraca" klastra. Zamiast tego, używa się **Terraform** [38, 41] do *błyskawicznego zbudowania nowego, czystego klastra* (np. w innym regionie AWS).
2.  **Krok 2 (OADP - Lekcja 13.4):** Na ten nowy, pusty klaster, używa się **OADP/Velero** [63] do *przywrócenia stanu aplikacji* (YAML, dane z PV, obrazy) z kopii zapasowej (przechowywanej np. w S3).

W tym modelu **IaC (Terraform) chroni stan infrastruktury**, podczas gdy **OADP (Velero) chroni stan aplikacji**. Jest to jedyna skalowalna i niezawodna metoda DR dla dynamicznych platform kontenerowych.

**Tabela 13.4: Architektura Procesu Aktualizacji OCP: CVO vs. MCO**

| Operator | Pełna Nazwa | Główna Odpowiedzialność | Etap Aktualizacji | Kluczowe Obiekty Zarządzane |
| :--- | :--- | :--- | :--- | :--- |
| **CVO** | Cluster Version Operator | "Mózg" - Uzgadnianie manifestów oprogramowania [43, 44, 49] | Akt 1: Aktualizacja Control Plane [51] | `ClusterVersion`, `ClusterOperator` |
| **MCO** | Machine Config Operator | "Wykonawca" - Aktualizacja węzłów (OS i Kubelet) [43, 52] | Akt 2: Aktualizacja Węzłów (Control Plane, potem Workery) [43, 51] | `MachineConfigPool`, `MachineConfig` |

---

## Lekcja 13.5: Wprowadzenie do Zaawansowanych Architektur Platformy

Ostatnim krokiem na ścieżce do poziomu eksperta jest opanowanie technologii, które rozszerzają podstawowe możliwości OpenShift, przekształcając go w kompleksową platformę do obsługi każdego rodzaju obciążeń.

### 13.5.1. OpenShift Service Mesh (bazujące na Istio)

* **Problem:** W miarę wzrostu liczby mikroserwisów, zarządzanie komunikacją między nimi, jej zabezpieczanie i monitorowanie staje się wykładniczo trudniejsze.[64]
* **Architektura:** OpenShift Service Mesh bazuje na projekcie Istio i dzieli się na dwie płaszczyzny [65, 66, 67]:
    1.  **Control Plane (Płaszczyzna Kontroli):** Komponent `Istiod`. Jest to centralny "mózg" siatki. `Istiod` zarządza konfiguracją wszystkich proxy i działa jako Certificate Authority (CA), automatycznie wystawiając i rotując certyfikaty dla mTLS.[66, 68]
    2.  **Data Plane (Płaszczyzna Danych):** Składa się z proxy `Envoy`, wdrażanych jako *sidecar* (dodatkowy kontener) w każdym Podzie aplikacji.[66, 67] Ten proxy przechwytuje *cały* ruch sieciowy wchodzący i wychodzący z aplikacji, bez wiedzy samej aplikacji.[65]
* **Kluczowe Zastosowania:**
    * **Bezpieczeństwo (mTLS):** Najważniejsza funkcja. Service Mesh może automatycznie wymusić wzajemne uwierzytelnianie i szyfrowanie (mTLS) dla *całej* komunikacji między serwisami w siatce.[66, 68, 69]
    * **Zarządzanie Ruchem (Canary):** Ponieważ `Envoy` kontroluje cały ruch, `Istiod` może go precyzyjnie instruować. Pozwala to na zaawansowane strategie wdrażania, takie jak "prześlij 10% ruchu użytkowników do nowej wersji `app:v2`, a pozostałe 90% do stabilnej `app:v1`". Umożliwia to bezpieczne testowanie nowych wersji na produkcji.[70, 71, 72, 73]

### 13.5.2. OpenShift Serverless (bazujące na Knative)

* **Problem:** Wiele aplikacji nie musi działać 24/7. Tradycyjne wdrożenia rezerwują zasoby (CPU, pamięć) nawet wtedy, gdy są bezczynne. Ponadto, rośnie zapotrzebowanie na architektury sterowane zdarzeniami (event-driven).[74, 75, 76]
* **Architektura:** OpenShift Serverless bazuje na projekcie Knative, który składa się z dwóch głównych komponentów [75, 76, 77]:
    1.  **Knative Serving:** Odpowiada za zarządzanie obciążeniem (workload). Umożliwia błyskawiczne wdrażanie, automatyczne skalowanie w górę (pod wpływem obciążenia) oraz, co najważniejsze, *skalowanie do zera*.[75]
    2.  **Knative Eventing:** Zapewnia infrastrukturę do konsumowania i produkowania zdarzeń (np. z Kafka [74], z repozytorium Git, z timerów). Odpowiada za oddzielenie (decoupling) producentów zdarzeń od konsumentów.[75, 78]
* **Kluczowa Koncepcja: Skalowanie do Zera (Scale to Zero) [79, 80, 81]:**
    * Jest to domyślne zachowanie w Knative, kontrolowane przez flagę `enable-scale-to-zero: true`.[79]
    * Gdy usługa Knative (Knative Service) nie otrzymuje żadnego ruchu przez określony czas, **KnativePodAutoscaler (KPA)** [79] automatycznie skaluje liczbę jej replik (Podów) do zera, zwalniając wszystkie zasoby.
    * Gdy pojawi się nowe żądanie, komponenty sieciowe Knative przechwytują je, "wstrzymują", błyskawicznie uruchamiają nowy Pod aplikacji (tzw. "cold start") i dopiero wtedy przekazują mu żądanie.
    * Parametr `scale-to-zero-grace-period` (domyślnie 30 sekund) [79] kontroluje, jak długo system czeka z usunięciem ostatniej repliki, aby zapewnić płynne przejęcie ruchu i uniknąć "gubienia" żądań.[79]

### 13.5.3. OpenShift Virtualization (bazujące na KubeVirt)

* **Problem:** Przedsiębiorstwa nie działają wyłącznie na kontenerach. Ogromna większość obciążeń "legacy" (starszych aplikacji) nadal działa na maszynach wirtualnych (VM). Jak zmodernizować centrum danych bez przepisywania setek aplikacji?.[82, 83, 84]
* **Architektura:** OpenShift Virtualization bazuje na projekcie KubeVirt.[83] Jest to fundamentalna zmiana paradygmatu:
    * **Kluczowa Koncepcja:** Maszyna wirtualna nie działa *obok* Poda. Maszyna wirtualna działa **wewnątrz** Poda.[83]
    * **Komponenty [82, 84]:** KubeVirt rozszerza API Kubernetes o nowe CRD do zarządzania VM. Gdy użytkownik tworzy obiekt `VirtualMachine`:
        1.  `virt-controller` (Control Plane) widzi ten obiekt i zleca utworzenie Poda.
        2.  `virt-handler` (DaemonSet na każdym węźle) przygotowuje zasoby na węźle.
        3.  Kubernetes uruchamia specjalny Pod o nazwie `virt-launcher`.
        4.  Głównym procesem wewnątrz tego Poda `virt-launcher` jest instancja `libvirtd` i `QEMU/KVM`, która *jest* właściwą maszyną wirtualną.
* **Kluczowe Zastosowania:**
    * **Ujednolicone Zarządzanie:** Administratorzy mogą używać tych samych narzędzi (CLI `oc`, konsola webowa OpenShift, monitoring Prometheus, logowanie) do zarządzania zarówno kontenerami, jak i maszynami wirtualnymi.[82, 85]
    * **Stopniowa Modernizacja:** Najważniejszy przypadek użycia. Zespół może przenieść (zmigrować) swoją starszą, monolityczną aplikację (np. JBoss na Windows Server) jako VM do OpenShift Virtualization. Następnie, tuż obok tej VM, może zacząć budować nowe mikroserwisy w kontenerach, które stopniowo przejmują funkcje monolitu. VM i kontenery współdzielą tę samą sieć i pamięć masową platformy.[82, 83]

### 13.5.4. Synteza i Wnioski: Trzy Osie Ekspansji i Nowy Wymiar Diagnostyki

Te trzy zaawansowane technologie nie są przypadkowym zbiorem dodatków. Reprezentują one trzy główne osie strategicznej ekspansji platformy OpenShift, które ekspert musi rozumieć:

1.  **OpenShift Service Mesh (Istio):** Rozszerza platformę **horyzontalnie** (w poprzek usług), aby zarządzać złożonością komunikacji Wschód-Zachód (East-West) i zapewnić bezpieczeństwo "zero-trust".[64]
2.  **OpenShift Serverless (Knative):** Rozszerza platformę **wertykalnie** (w modelu aplikacyjnym), aby wspierać efemeryczne, sterowane zdarzeniami obciążenia (Functions-as-a-Service) i optymalizować koszty.[75]
3.  **OpenShift Virtualization (KubeVirt):** Rozszerza platformę **wstecz w czasie** (kompatybilność), aby zarządzać tradycyjnymi obciążeniami (VM) i umożliwić migrację oraz modernizację "legacy".[83]

Jednakże, wprowadzenie tych technologii, zwłaszcza Service Mesh i Wirtualizacji, ma głęboką implikację, którą ekspert musi opanować: **zmieniają one fundamentalnie definicję "Poda" i przenoszą złożoność na Płaszczyznę Danych (Data Plane).**

Administrator na poziomie średniozaawansowanym myśli o Podzie jako o "kontenerze z aplikacją". Ekspert musi rozumieć, że:
* W Service Mesh, Pod to *dwa* procesy: aplikacja + wstrzyknięty proxy `Envoy`.[66]
* W Virtualization, Pod to *jeden* proces `virt-launcher`, który zawiera w sobie *cały system operacyjny gościa*.[84]

Dla eksperta oznacza to, że diagnostyka problemów z wydajnością lub siecią staje się o rząd wielkości trudniejsza. Problem nie jest już tylko w aplikacji. Pytania, które musi zadać ekspert, brzmią:
* "Czy moja aplikacja działa wolno, czy to sidecar `Envoy` zużywa całe CPU, wykonując szyfrowanie mTLS?"
* "Czy mój Pod zużywa 32 GB pamięci, czy to proces QEMU *wewnątrz* tego Poda zarezerwował pamięć dla Windows Server?"

Opanowanie umiejętności debugowania tej nowej, złożonej Płaszczyzny Danych jest ostatecznym wyznacznikiem poziomu eksperckiego.

**Tabela 13.5: Przegląd Zaawansowanych Architektur OpenShift**

| Technologia | Bazowy Projekt Open Source | Problem Biznesowy (Dlaczego?) | Kluczowa Zmiana Architektoniczna (Jak?) |
| :--- | :--- | :--- | :--- |
| **OpenShift Service Mesh** | Istio [86, 87] | Złożoność i bezpieczeństwo komunikacji mikroserwisów [64] | Wstrzykiwanie "sidecar" proxy (`Envoy`) do każdego Poda (Data Plane) [66, 67] |
| **OpenShift Serverless** | Knative [75] | Niewykorzystane zasoby, potrzeba FaaS, aplikacje sterowane zdarzeniami [74, 76] | Control Plane (KPA) do automatycznego skalowania Podów do zera [79, 81] |
| **OpenShift Virtualization** | KubeVirt [82, 83] | Wsparcie dla aplikacji "legacy" (VM), strategia migracji i modernizacji [83, 84] | Uruchomienie pełnej maszyny wirtualnej (KVM/QEMU) wewnątrz standardowego Poda (`virt-launcher`) [82, 84] |

### 13.5.5. Wnioski z Modułu 13

Ukończenie tego modułu oznacza przejście od roli administratora-wykonawcy do roli architekta-stratega. Ekspert nie tylko wie, *jak* klikać w konsoli, ale rozumie *dlaczego* platforma działa w określony sposób.

Ekspert rozumie symbiotyczną relację między administratorem (`EX280`) a deweloperem (`EX288`). Wykorzystuje OKD (`13.2`) jako "kryształową kulę" do prognozowania przyszłości OCP. Stosuje właściwe narzędzia IaC do właściwych zadań (`13.3`), używając Terraform do budowy "domu" i Ansible do jego "meblowania".

Co najważniejsze, ekspert opanował najbardziej ryzykowne procesy: aktualizację (`13.4`), rozumiejąc taniec między CVO ("duszą") a MCO ("ciałem"), oraz migrację (`13.4`), łącząc IaC z OADP w strategię DR, która traktuje infrastrukturę jako efemeryczną. Wreszcie, ekspert strategicznie rozszerza platformę (`13.5`), aby zarządzać ruchem horyzontalnym (Service Mesh), obciążeniami efemerycznymi (Serverless) i kompatybilnością wsteczną (Virtualization), będąc jednocześnie gotowym do diagnozowania problemów w nowej, złożonej Płaszczyźnie Danych.

---

## Cytowane prace

1. How Do You Prepare for Red Hat's Containers Exam (EX180/EX188)? \- Hackers4U, otwierano: listopada 15, 2025, [https://www.hackers4u.com/how-do-you-prepare-for-red-hats-containers-exam-ex180ex188](https://www.hackers4u.com/how-do-you-prepare-for-red-hats-containers-exam-ex180ex188)  
2. Red Hat Certified Specialist in OpenShift Administration exam (EX280), otwierano: listopada 15, 2025, [https://www.umbctraining.com/courses/red-hat-certified-specialist-ex280/](https://www.umbctraining.com/courses/red-hat-certified-specialist-ex280/)  
3. Red Hat Certified OpenShift Application Developer exam | EX288, otwierano: listopada 15, 2025, [https://www.redhat.com/en/services/training/ex288-red-hat-certified-openshift-application-developer-exam](https://www.redhat.com/en/services/training/ex288-red-hat-certified-openshift-application-developer-exam)  
4. Red Hat Certified Specialist in Containers and Kubernetes exam (EX180), otwierano: listopada 15, 2025, [https://www.umbctraining.com/courses/red-hat-certified-specialist-ex180/](https://www.umbctraining.com/courses/red-hat-certified-specialist-ex180/)  
5. Red Hat Certified Specialist in Containers and Kubernetes, otwierano: listopada 15, 2025, [https://www.redhat.com/en/services/certification/red-hat-certified-specialist-in-containers-and-kubernetes](https://www.redhat.com/en/services/certification/red-hat-certified-specialist-in-containers-and-kubernetes)  
6. Retired \- Red Hat Certified Specialist in Containers and Kubernetes ..., otwierano: listopada 15, 2025, [https://www.redhat.com/en/services/training/ex180-red-hat-certified-specialist-containers-kubernetes-exam](https://www.redhat.com/en/services/training/ex180-red-hat-certified-specialist-containers-kubernetes-exam)  
7. Red Hat Certified OpenShift Application Developer Exam (EX288) \- Global Knowledge, otwierano: listopada 15, 2025, [https://www.globalknowledge.com/us-en/course/171628/red-hat-certified-openshift-application-developer-exam-ex288/](https://www.globalknowledge.com/us-en/course/171628/red-hat-certified-openshift-application-developer-exam-ex288/)  
8. Red Hat Certified Specialist in OpenShift Application Development, otwierano: listopada 15, 2025, [https://www.redhat.com/en/services/certification/rhcs-openshift-application-development](https://www.redhat.com/en/services/certification/rhcs-openshift-application-development)  
9. Red Hat Certified Specialist in OpenShift Administration, otwierano: listopada 15, 2025, [https://www.redhat.com/en/services/certification/rhcs-paas](https://www.redhat.com/en/services/certification/rhcs-paas)  
10. Red Hat Certified OpenShift Administrator exam | EX280, otwierano: listopada 15, 2025, [https://www.redhat.com/en/services/training/red-hat-certified-openshift-administrator-exam](https://www.redhat.com/en/services/training/red-hat-certified-openshift-administrator-exam)  
11. Red Hat Certified OpenShift Administrator Exam (EX280K) \- Global Knowledge, otwierano: listopada 15, 2025, [https://www.globalknowledge.com/us-en/course/90190/red-hat-certified-openshift-administrator-exam-ex280k/](https://www.globalknowledge.com/us-en/course/90190/red-hat-certified-openshift-administrator-exam-ex280k/)  
12. Red Hat OpenShift Administration II: Configuring a Production Cluster | DO280, otwierano: listopada 15, 2025, [https://www.redhat.com/en/services/training/red-hat-openshift-administration-ii-configuring-a-production-cluster](https://www.redhat.com/en/services/training/red-hat-openshift-administration-ii-configuring-a-production-cluster)  
13. Red Hat Certified OpenShift Application Developer exam | EX288, otwierano: listopada 15, 2025, [https://www.redhat.com/en/services/training/ex288-red-hat-certified-specialist-openshift-application-development-exam?section=Overview](https://www.redhat.com/en/services/training/ex288-red-hat-certified-specialist-openshift-application-development-exam?section=Overview)  
14. otwierano: listopada 15, 2025, [https://www.redhat.com/en/topics/containers/red-hat-openshift-okd\#:\~:text=OKD%20is%20the%20upstream%20project,are%20trialed%20for%20enterprise%20use.](https://www.redhat.com/en/topics/containers/red-hat-openshift-okd#:~:text=OKD%20is%20the%20upstream%20project,are%20trialed%20for%20enterprise%20use.)  
15. Red Hat OpenShift vs. OKD, otwierano: listopada 15, 2025, [https://www.redhat.com/en/topics/containers/red-hat-openshift-okd](https://www.redhat.com/en/topics/containers/red-hat-openshift-okd)  
16. OKD Documentation: Home, otwierano: listopada 15, 2025, [https://docs.okd.io/](https://docs.okd.io/)  
17. Differences between Red Hat Openshift Container Platform (OCP) and OKD \- Reddit, otwierano: listopada 15, 2025, [https://www.reddit.com/r/openshift/comments/qbw0ai/differences\_between\_red\_hat\_openshift\_container/](https://www.reddit.com/r/openshift/comments/qbw0ai/differences_between_red_hat_openshift_container/)  
18. OKD Streams: Building the Next Generation of OKD Together \- Red Hat, otwierano: listopada 15, 2025, [https://www.redhat.com/en/blog/okd-streams-building-the-next-generation-of-okd-together](https://www.redhat.com/en/blog/okd-streams-building-the-next-generation-of-okd-together)  
19. Documentation | OKD Kubernetes Platform, otwierano: listopada 15, 2025, [https://okd.io/docs/documentation/](https://okd.io/docs/documentation/)  
20. OpenShift Architecture: Tutorial, Examples, Instructions \- Densify, otwierano: listopada 15, 2025, [https://www.densify.com/openshift-tutorial/openshift-architecture/](https://www.densify.com/openshift-tutorial/openshift-architecture/)  
21. Kubernetes at Scale on any Infrastructure | OKD Kubernetes Platform, otwierano: listopada 15, 2025, [https://okd.io/](https://okd.io/)  
22. Welcome | Overview | OKD 4, otwierano: listopada 15, 2025, [https://docs.okd.io/latest/welcome/index.html](https://docs.okd.io/latest/welcome/index.html)  
23. The official Red Hat blog, otwierano: listopada 15, 2025, [https://www.redhat.com/en/blog](https://www.redhat.com/en/blog)  
24. Red Hat OpenShift, otwierano: listopada 15, 2025, [https://www.redhat.com/en/blog/channel/red-hat-openshift](https://www.redhat.com/en/blog/channel/red-hat-openshift)  
25. Access to 24x7 support and knowledge \- Red Hat Customer Portal, otwierano: listopada 15, 2025, [https://access.redhat.com/discussions/?start=0\&tags=openshift](https://access.redhat.com/discussions/?start=0&tags=openshift)  
26. Red Hat Community discussions, otwierano: listopada 15, 2025, [https://access.redhat.com/discussions/](https://access.redhat.com/discussions/)  
27. Customer Portal Community, otwierano: listopada 15, 2025, [https://access.redhat.com/community/](https://access.redhat.com/community/)  
28. OpenShift \- Reddit, otwierano: listopada 15, 2025, [https://www.reddit.com/r/openshift/](https://www.reddit.com/r/openshift/)  
29. OpenShift Commons, otwierano: listopada 15, 2025, [https://commons.openshift.org/](https://commons.openshift.org/)  
30. State of affairs in OKD CI/CD | OKD Kubernetes Platform, otwierano: listopada 15, 2025, [https://okd.io/blog/2023/07/18/state-of-Affairs-in-OKD-CI-CD/](https://okd.io/blog/2023/07/18/state-of-Affairs-in-OKD-CI-CD/)  
31. Chapter 4\. Understanding update channels and releases | Updating clusters | OpenShift Container Platform | 4.10 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.10/html/updating\_clusters/understanding-upgrade-channels-releases](https://docs.redhat.com/en/documentation/openshift_container_platform/4.10/html/updating_clusters/understanding-upgrade-channels-releases)  
32. Ansible Automation Platform for OpenShift Virtualization in Multi-cluster Environment, otwierano: listopada 15, 2025, [https://www.redhat.com/en/blog/ansible-automation-platform-openshift-virtualization-multi-cluster-environment](https://www.redhat.com/en/blog/ansible-automation-platform-openshift-virtualization-multi-cluster-environment)  
33. kubernetes.core.k8s module – Manage Kubernetes (K8s) objects ..., otwierano: listopada 15, 2025, [https://docs.ansible.com/ansible/latest/collections/kubernetes/core/k8s\_module.html](https://docs.ansible.com/ansible/latest/collections/kubernetes/core/k8s_module.html)  
34. Scaling OpenShift Container Resources using Ansible \- Densify, otwierano: listopada 15, 2025, [https://www.densify.com/blog/scaling-openshift-container-resources-ansible/](https://www.densify.com/blog/scaling-openshift-container-resources-ansible/)  
35. Installing on OpenShift Container Platform | Red Hat Ansible Automation Platform | 2.5, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/red\_hat\_ansible\_automation\_platform/2.5/html-single/installing\_on\_openshift\_container\_platform/index](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.5/html-single/installing_on_openshift_container_platform/index)  
36. Deploying the Red Hat Ansible Automation Platform operator on OpenShift Container Platform, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/red\_hat\_ansible\_automation\_platform/2.2/html-single/deploying\_the\_red\_hat\_ansible\_automation\_platform\_operator\_on\_openshift\_container\_platform/index](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.2/html-single/deploying_the_red_hat_ansible_automation_platform_operator_on_openshift_container_platform/index)  
37. Automate OpenShift with Red Hat Ansible Automation Platform, otwierano: listopada 15, 2025, [https://www.redhat.com/en/blog/automate-openshift-with-red-hat-ansible-automation-platform](https://www.redhat.com/en/blog/automate-openshift-with-red-hat-ansible-automation-platform)  
38. How to Install OpenShift 4.6 using Terraform on VMware with UPI, otwierano: listopada 15, 2025, [https://www.redhat.com/en/blog/how-to-install-openshift-4.6-on-vmware-with-upi](https://www.redhat.com/en/blog/how-to-install-openshift-4.6-on-vmware-with-upi)  
39. Deploy Private Openshift OKD Cluster 4.17 in AWS | by Gary Gan | Medium, otwierano: listopada 15, 2025, [https://medium.com/@yiwugan/deploy-private-openshift-okd-cluster-4-17-in-aws-492dc7f3fe29](https://medium.com/@yiwugan/deploy-private-openshift-okd-cluster-4-17-in-aws-492dc7f3fe29)  
40. dio/AWS-OKD-Terraform: Create infrastructure with Terraform and AWS, install OpenShift. Party\! \- GitHub, otwierano: listopada 15, 2025, [https://github.com/dio/AWS-OKD-Terraform](https://github.com/dio/AWS-OKD-Terraform)  
41. Build ROSA Clusters with Terraform | Containers \- Amazon AWS, otwierano: listopada 15, 2025, [https://aws.amazon.com/blogs/containers/build-rosa-clusters-with-terraform/](https://aws.amazon.com/blogs/containers/build-rosa-clusters-with-terraform/)  
42. HCP Terraform Operator is now certified on Red Hat OpenShift \- HashiCorp, otwierano: listopada 15, 2025, [https://www.hashicorp.com/en/blog/hcp-terraform-operator-is-now-certified-on-red-hat-openshift](https://www.hashicorp.com/en/blog/hcp-terraform-operator-is-now-certified-on-red-hat-openshift)  
43. The Ultimate Guide to OpenShift Update for Cluster Administrators, otwierano: listopada 15, 2025, [https://www.redhat.com/en/blog/the-ultimate-guide-to-openshift-update-for-cluster-administrators](https://www.redhat.com/en/blog/the-ultimate-guide-to-openshift-update-for-cluster-administrators)  
44. Chapter 2\. Understanding OpenShift updates | Updating clusters ..., otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.13/html/updating\_clusters/understanding-openshift-updates-1](https://docs.redhat.com/en/documentation/openshift_container_platform/4.13/html/updating_clusters/understanding-openshift-updates-1)  
45. Chapter 1\. Understanding the OpenShift Update Service \- Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.7/html/updating\_clusters/understanding-the-update-service](https://docs.redhat.com/en/documentation/openshift_container_platform/4.7/html/updating_clusters/understanding-the-update-service)  
46. Chapter 4\. Understanding upgrade channels and releases | Updating clusters | OpenShift Container Platform | 4.6 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.6/html/updating\_clusters/understanding-upgrade-channels-releases](https://docs.redhat.com/en/documentation/openshift_container_platform/4.6/html/updating_clusters/understanding-upgrade-channels-releases)  
47. Understanding OpenShift Upgrade Channels \- Reddit, otwierano: listopada 15, 2025, [https://www.reddit.com/r/openshift/comments/1is1fgz/understanding\_openshift\_upgrade\_channels/](https://www.reddit.com/r/openshift/comments/1is1fgz/understanding_openshift_upgrade_channels/)  
48. Chapter 3\. Understanding upgrade channels and releases | Updating clusters | OpenShift Container Platform | 4.9 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.9/html/updating\_clusters/understanding-upgrade-channels-releases](https://docs.redhat.com/en/documentation/openshift_container_platform/4.9/html/updating_clusters/understanding-upgrade-channels-releases)  
49. openshift/cluster-version-operator \- GitHub, otwierano: listopada 15, 2025, [https://github.com/openshift/cluster-version-operator](https://github.com/openshift/cluster-version-operator)  
50. How OpenShift 4.x Upgrade process works | by Kedar Salunkhe \- Medium, otwierano: listopada 15, 2025, [https://medium.com/@kedardeworks/openshift-4-upgrades-e9ebc771fc36](https://medium.com/@kedardeworks/openshift-4-upgrades-e9ebc771fc36)  
51. OpenShift 4.x Upgrade Process Explained | by Kedar Salunkhe \- Medium, otwierano: listopada 15, 2025, [https://medium.com/@kedardeworks/openshift-4-x-upgrade-process-explained-6e8957d64ef4](https://medium.com/@kedardeworks/openshift-4-x-upgrade-process-explained-6e8957d64ef4)  
52. Introduction to OpenShift updates \- Understanding OpenShift updates | Updating clusters | OKD 4.16 \- OKD Documentation, otwierano: listopada 15, 2025, [https://docs.okd.io/4.16/updating/understanding\_updates/intro-to-updates.html](https://docs.okd.io/4.16/updating/understanding_updates/intro-to-updates.html)  
53. Chapter 4\. Application backup and restore | Backup and restore | OpenShift Container Platform | 4.8 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/backup\_and\_restore/application-backup-and-restore](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/backup_and_restore/application-backup-and-restore)  
54. OpenShift APIs for Data Protection (OADP) FAQ \- Red Hat Customer ..., otwierano: listopada 15, 2025, [https://access.redhat.com/articles/5456281](https://access.redhat.com/articles/5456281)  
55. Introduction to OpenShift API for Data Protection \- OADP Application ..., otwierano: listopada 15, 2025, [https://docs.okd.io/4.18/backup\_and\_restore/application\_backup\_and\_restore/oadp-intro.html](https://docs.okd.io/4.18/backup_and_restore/application_backup_and_restore/oadp-intro.html)  
56. Back up Kubernetes persistent volumes using OADP \- Red Hat Developer, otwierano: listopada 15, 2025, [https://developers.redhat.com/articles/2023/08/07/back-kubernetes-persistent-volumes-using-oadp](https://developers.redhat.com/articles/2023/08/07/back-kubernetes-persistent-volumes-using-oadp)  
57. Kubernetes Backups: Velero and Broadcom \- Reddit, otwierano: listopada 15, 2025, [https://www.reddit.com/r/kubernetes/comments/1nogng0/kubernetes\_backups\_velero\_and\_broadcom/](https://www.reddit.com/r/kubernetes/comments/1nogng0/kubernetes_backups_velero_and_broadcom/)  
58. Chapter 4\. OADP Application backup and restore | Backup and restore | OpenShift Container Platform | 4.12 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.12/html/backup\_and\_restore/oadp-application-backup-and-restore](https://docs.redhat.com/en/documentation/openshift_container_platform/4.12/html/backup_and_restore/oadp-application-backup-and-restore)  
59. otwierano: listopada 15, 2025, [https://docs.okd.io/4.18/backup\_and\_restore/application\_backup\_and\_restore/oadp-intro.html\#:\~:text=The%20OpenShift%20API%20for%20Data,persistent%20volumes%2C%20and%20internal%20images.](https://docs.okd.io/4.18/backup_and_restore/application_backup_and_restore/oadp-intro.html#:~:text=The%20OpenShift%20API%20for%20Data,persistent%20volumes%2C%20and%20internal%20images.)  
60. OpenShift API for Data Protection \- Red Hat Ecosystem Catalog, otwierano: listopada 15, 2025, [https://catalog.redhat.com/en/software/container-stacks/detail/646f70952ca122cdf3314a83](https://catalog.redhat.com/en/software/container-stacks/detail/646f70952ca122cdf3314a83)  
61. Backup and restore | OpenShift Container Platform | 4.16 \- Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.16/html/backup\_and\_restore/backup-restore-overview](https://docs.redhat.com/en/documentation/openshift_container_platform/4.16/html/backup_and_restore/backup-restore-overview)  
62. General Velero plugin for backup and restore of openshift workloads. \- GitHub, otwierano: listopada 15, 2025, [https://github.com/openshift/openshift-velero-plugin](https://github.com/openshift/openshift-velero-plugin)  
63. Migrate an App from one cluster to another \- NetApp Docs, otwierano: listopada 15, 2025, [https://docs.netapp.com/us-en/netapp-solutions-cloud/openshift/os-dp-velero-migrate.html](https://docs.netapp.com/us-en/netapp-solutions-cloud/openshift/os-dp-velero-migrate.html)  
64. Istio Architecture for Kubernetes: The Ultimate Guide \- Groundcover, otwierano: listopada 15, 2025, [https://www.groundcover.com/blog/istio-architecture](https://www.groundcover.com/blog/istio-architecture)  
65. Enterprise Service Mesh: Reference Architecture with OpenShift & Istio | Kong Inc., otwierano: listopada 15, 2025, [https://konghq.com/blog/engineering/service-mesh-reference-architecture-openshift-istio-kong](https://konghq.com/blog/engineering/service-mesh-reference-architecture-openshift-istio-kong)  
66. Istio / Architecture, otwierano: listopada 15, 2025, [https://istio.io/latest/docs/ops/deployment/architecture/](https://istio.io/latest/docs/ops/deployment/architecture/)  
67. Chapter 1\. Service Mesh Architecture | Service Mesh | OpenShift Container Platform | 4.1 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.1/html/service\_mesh/service-mesh-architecture](https://docs.redhat.com/en/documentation/openshift_container_platform/4.1/html/service_mesh/service-mesh-architecture)  
68. Use service mesh and mTLS to establish secure routes and TLS ..., otwierano: listopada 15, 2025, [https://www.redhat.com/en/blog/service-mesh-mtls](https://www.redhat.com/en/blog/service-mesh-mtls)  
69. What is Istio? \- Red Hat, otwierano: listopada 15, 2025, [https://www.redhat.com/en/topics/microservices/what-is-istio](https://www.redhat.com/en/topics/microservices/what-is-istio)  
70. OpenShift Service Mesh: Architecture, Deployment & Examples | Solo.io, otwierano: listopada 15, 2025, [https://www.solo.io/topics/openshift/openshift-service-mesh](https://www.solo.io/topics/openshift/openshift-service-mesh)  
71. Canary deployment strategy with OpenShift Service Mesh | Red Hat ..., otwierano: listopada 15, 2025, [https://developers.redhat.com/articles/2024/03/26/canary-deployment-strategy-openshift-service-mesh](https://developers.redhat.com/articles/2024/03/26/canary-deployment-strategy-openshift-service-mesh)  
72. OpenShift Service Mesh: Tutorial & Examples \- Densify, otwierano: listopada 15, 2025, [https://www.densify.com/openshift-tutorial/openshift-service-mesh/](https://www.densify.com/openshift-tutorial/openshift-service-mesh/)  
73. Canary deployments in OpenShift Service Mesh \- Rcarrata's Blog, otwierano: listopada 15, 2025, [https://rcarrata.com/istio/canary-in-service-mesh/](https://rcarrata.com/istio/canary-in-service-mesh/)  
74. How to scale smarter with OpenShift Serverless and Knative | Red Hat Developer, otwierano: listopada 15, 2025, [https://developers.redhat.com/articles/2025/05/06/how-scale-smarter-openshift-serverless-and-knative](https://developers.redhat.com/articles/2025/05/06/how-scale-smarter-openshift-serverless-and-knative)  
75. OpenShift Serverless: Guide & Tutorial \- Densify, otwierano: listopada 15, 2025, [https://www.densify.com/openshift-tutorial/openshift-serverless/](https://www.densify.com/openshift-tutorial/openshift-serverless/)  
76. Knative: Home, otwierano: listopada 15, 2025, [https://knative.dev/](https://knative.dev/)  
77. Chapter 3\. Installing Serverless | Serverless | OpenShift Container Platform | 4.9, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.9/html/serverless/installing-serverless](https://docs.redhat.com/en/documentation/openshift_container_platform/4.9/html/serverless/installing-serverless)  
78. Chapter 1\. Knative Eventing | Eventing | Red Hat OpenShift Serverless | 1.28, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/red\_hat\_openshift\_serverless/1.28/html/eventing/knative-eventing-overview](https://docs.redhat.com/en/documentation/red_hat_openshift_serverless/1.28/html/eventing/knative-eventing-overview)  
79. Configuring scale to zero \- Knative, otwierano: listopada 15, 2025, [https://knative.dev/docs/serving/autoscaling/scale-to-zero/](https://knative.dev/docs/serving/autoscaling/scale-to-zero/)  
80. Red Hat applications and OpenShift Serverless \- Azure Red Hat OpenShift | Microsoft Learn, otwierano: listopada 15, 2025, [https://learn.microsoft.com/en-us/azure/openshift/howto-deploy-with-serverless](https://learn.microsoft.com/en-us/azure/openshift/howto-deploy-with-serverless)  
81. Chapter 9\. Knative Serving | Serverless applications | OpenShift Container Platform | 4.3, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.3/html/serverless\_applications/knative-serving](https://docs.redhat.com/en/documentation/openshift_container_platform/4.3/html/serverless_applications/knative-serving)  
82. OpenShift Virtualization: How It Works, Core Architecture, and ..., otwierano: listopada 15, 2025, [https://www.ksolves.com/blog/openshift/understanding-openshift-virtualization](https://www.ksolves.com/blog/openshift/understanding-openshift-virtualization)  
83. What is KubeVirt? \- Red Hat, otwierano: listopada 15, 2025, [https://www.redhat.com/en/topics/virtualization/what-is-kubevirt](https://www.redhat.com/en/topics/virtualization/what-is-kubevirt)  
84. Key Concepts and Best Practices for OpenShift Virtualization \- Trilio, otwierano: listopada 15, 2025, [https://trilio.io/openshift-virtualization/](https://trilio.io/openshift-virtualization/)  
85. OpenShift KubeVirt: The Basics & How to Get Started \- Tigera.io, otwierano: listopada 15, 2025, [https://www.tigera.io/learn/guides/kubernetes-networking/openshift-kubevirt/](https://www.tigera.io/learn/guides/kubernetes-networking/openshift-kubevirt/)  
86. Red Hat OpenShift Service Mesh, otwierano: listopada 15, 2025, [https://www.redhat.com/en/technologies/cloud-computing/openshift/what-is-openshift-service-mesh](https://www.redhat.com/en/technologies/cloud-computing/openshift/what-is-openshift-service-mesh)  
87. Introducing OpenShift Service Mesh 3.1 \- Red Hat, otwierano: listopada 15, 2025, [https://www.redhat.com/en/blog/introducing-openshift-service-mesh-31](https://www.redhat.com/en/blog/introducing-openshift-service-mesh-31)