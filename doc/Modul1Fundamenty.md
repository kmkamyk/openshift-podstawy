

# **Moduł 1: Fundamenty – Dlaczego OpenShift to nie jest *tylko* Kubernetes?**

## **1.1: Filozofia: Platforma (OCP) vs. Orkiestrator (K8s)**

Analiza fundamentalnych różnic między OpenShift Container Platform (OCP) a Kubernetes (K8s) musi rozpoczynać się nie od analizy kodu, lecz od analizy filozofii. Kubernetes jest projektem open-source; OpenShift jest produktem korporacyjnym.1 Ta fundamentalna rozbieżność w przeznaczeniu i modelu biznesowym jest pierwotną przyczyną wszystkich kolejnych różnic architektonicznych i funkcjonalnych. Kubernetes oferuje elastyczność i modułowość 3, podczas gdy OpenShift dostarcza gotową, "opiniotwórczą" platformę.3

### **Metafora: Kubernetes to Silnik, OpenShift to Samochód**

Centralna metafora, która najtrafniej oddaje relację między tymi dwoma systemami, to porównanie Kubernetesa do silnika, a OpenShift do w pełni funkcjonalnego samochodu.5  
Kubernetes (Silnik)  
Kubernetes, często określany jako "jądro" (kernel) dla chmury 7, jest potężnym, surowym "silnikiem" orkiestracji kontenerów.5 Dostarcza on absolutnie kluczowe, ale podstawowe funkcje: planowanie (scheduling) kontenerów na węzłach, automatyczne skalowanie, samonaprawianie (self-healing) i odnajdywanie usług (service discovery).3 Jest to technologiczny majstersztyk, który sam w sobie nie jest jednak kompletnym rozwiązaniem zdolnym do dostarczania wartości biznesowej.5  
Podobnie jak silnik samochodowy, Kubernetes nie zawiezie nikogo do celu bez dodatkowych, krytycznych komponentów. Wymaga podwozia, układu kierowniczego, hamulców, deski rozdzielczej i systemów bezpieczeństwa.5 W świecie K8s, te komponenty to oddzielne, ręcznie integrowane narzędzia open-source.3 Organizacja musi samodzielnie wybrać, zainstalować, skonfigurować i, co najważniejsze, *utrzymywać* kompatybilność między dziesiątkami dodatków:

* **Logowanie:** (np. stos EFK lub Loki) 3  
* **Monitoring:** (np. Prometheus, Grafana) 3  
* **CI/CD:** (np. Jenkins, GitLab CI, ArgoCD) 3  
* **Ingress (Sieć):** (np. NGINX, Traefik, HAProxy) 10  
* **Rejestr Obrazów:** (np. Harbor, Artifactory) 7

OpenShift (Samochód)  
OpenShift jest kompletnym, gotowym do jazdy "samochodem".5 Wykorzystuje on certyfikowany silnik Kubernetes (OCP jest w 100% zgodny z upstreamowym K8s) 5, ale integruje go ze wszystkimi niezbędnymi komponentami w jeden, spójny, przetestowany i wspierany produkt.7  
W tej metaforze OpenShift dostarcza:

* **Karoserię i Deskę Rozdzielczą:** Zintegrowaną konsolę webową z dedykowanymi widokami dla administratorów i deweloperów.1  
* **Diagnostykę i Monitoring:** Prekonfigurowane i zintegrowane stosy monitoringu (Prometheus) i logowania (Loki/Elasticsearch).3  
* **Systemy Bezpieczeństwa (ABS, Poduszki Powietrzne):** Wbudowane, rygorystyczne domyślne zasady bezpieczeństwa (np. SecurityContextConstraints), zintegrowany RBAC i skaner obrazów (Clair).2  
* **Kluczyki i System Zapłonu:** Uproszczone zarządzanie uwierzytelnianiem i zintegrowany serwer OAuth.9  
* **System Produkcji (Fabryka):** Wbudowane narzędzia deweloperskie, takie jak Source-to-Image (S2I) i potoki CI/CD (OpenShift Pipelines/Tekton).1

Implikacje tej metafory są strategiczne. Kubernetes oferuje maksymalną elastyczność, ale wymaga zespołu ekspertów (mechaników) do zbudowania i utrzymania platformy "samochodu".4 OpenShift oferuje gotową, spójną i wspieraną platformę, która drastycznie przyspiesza dostarczanie aplikacji, kosztem (celowej) rezygnacji z pełnej dowolności w doborze komponentów.4

### **Platforma "Opiniotwórcza" (Opinionated)**

Kluczowym terminem definiującym filozofię OpenShift jest "opinionated" (opiniotwórczy).3 W kontekście inżynierii oprogramowania oznacza to, że platforma została zaprojektowana z myślą o konkretnym, "złotym" sposobie działania (golden path).17 Zamiast oferować nieskończoną elastyczność, platforma "opiniotwórcza" wymusza lub silnie zachęca do stosowania określonych najlepszych praktyk, konwencji i zasad, które jej twórcy uznali za optymalne.17  
OpenShift jest platformą "opiniotwórczą", ponieważ Red Hat, bazując na dekadach doświadczeń w pracy z klientami korporacyjnymi (często w sektorach o wysokich wymaganiach regulacyjnych), podjął kluczowe decyzje architektoniczne *z góry*.16

* Zamiast pytać: "Który z 50 kontrolerów ingress chcesz użyć?", OCP dostarcza zintegrowany i wspierany Route oparty na HAProxy.10  
* Zamiast pytać: "Jak skonfigurujesz monitoring?", OCP dostarcza prekonfigurowany i samoaktualizujący się stos Prometheus/Grafana.3  
* Zamiast pytać: "Jakie zasady bezpieczeństwa dla podów chcesz wdrożyć?", OCP domyślnie blokuje uruchamianie kontenerów jako root.2

To "opiniotwórcze" podejście jest kluczowe dla przedsiębiorstw. Zapewnia ono spójne, przewidywalne, bezpieczne i gotowe do audytu środowisko.16 Deweloperzy otrzymują "tory pływackie" (swim lanes), które pozwalają im działać szybko i bezpiecznie, bez konieczności bycia ekspertami od każdego aspektu infrastruktury chmurowej.16

### **Wartość Dodana OCP: Bezpieczeństwo, DevEx, Komponenty, Wsparcie**

Filozofia "opiniotwórczej platformy" przekłada się na cztery namacalne filary wartości dodanej, które OCP buduje na fundamencie K8s.

1. **Zintegrowane Komponenty:** Czysty K8s to tylko "podstawowe procesy orkiestracji".3 OpenShift integruje dziesiątki kluczowych komponentów w jeden spójny produkt, eliminując potrzebę ręcznej integracji.7 Obejmuje to: wbudowany rejestr obrazów (z opcją skanowania podatności) 12, zintegrowane potoki CI/CD (Jenkins, Tekton) 1, agregację logów, monitoring 3, Service Mesh (oparte na Istio) oraz Serverless (oparte na Knative).7  
2. **Bezpieczeństwo "Out-of-the-Box":** Kubernetes domyślnie stosuje "stosunkowo łagodne" zasady bezpieczeństwa.9 OpenShift jest zaprojektowany z myślą o "większej gotowości regulacyjnej" (greater regulatory-readiness) 1, co jest kluczowe dla sektorów takich jak finanse, zdrowie (HIPAA) czy administracja publiczna. Domyślnie stosuje znacznie surowsze zasady bezpieczeństwa, przede wszystkim SecurityContextConstraints (SCC), które uniemożliwiają uruchamianie kontenerów z uprawnieniami roota.2  
3. **Doświadczenie Deweloperskie (DevEx):** Kubernetes jest platformą infrastrukturalną, podczas gdy OpenShift jest przede wszystkim platformą deweloperską.20 OCP dostarcza bogaty zestaw narzędzi, które abstrahują złożoność K8s i pozwalają deweloperom skupić się na kodzie, a nie na plikach YAML.21 Kluczowe narzędzia DevEx to m.in. mechanizm Source-to-Image (S2I), uproszczone polecenia CLI (np. oc new-app) oraz konsola deweloperska z wizualnym widokiem topologii aplikacji.15  
4. **Wsparcie Enterprise:** Kubernetes jako projekt open-source opiera się na wsparciu społeczności.1 OpenShift to płatny produkt komercyjny firmy Red Hat 1, co gwarantuje pełne, płatne wsparcie techniczne 24/7. Co ważniejsze, obejmuje to 9-letni cykl życia produktu, dedykowany zespół ds. reagowania na zagrożenia (Security Response Team) oraz gwarancje dotyczące aktualizacji bez przestojów (zero downtime patching).7 Dla organizacji, które nie mają czasu, zasobów ani wiedzy, aby samodzielnie wybierać i integrować setki projektów CNCF, OCP oferuje rozwiązanie "od jednego dostawcy".23

Poniższa tabela wizualnie kwantyfikuje tę wartość dodaną, porównując, co jest zawarte w podstawowym projekcie K8s, a co jest zintegrowaną częścią platformy OpenShift.  
**Tabela 1.1: Porównanie Wartości Dodanej: Kubernetes (Projekt) vs. OpenShift (Platforma)**

| Funkcjonalność | Kubernetes (Open Source) | Red Hat OpenShift (Platforma Enterprise) |
| :---- | :---- | :---- |
| **Rdzeń Orkiestracji** | **Zawarte** (Planowanie, Skalowanie, Self-healing) 3 | **Zawarte** (Certyfikowany rdzeń K8s) 5 |
| **System Operacyjny Hosta** | Dowolny (Bring Your Own) | Zintegrowany (Red Hat Enterprise Linux CoreOS) 7 |
| **Rejestr Obrazów** | Wymaga ręcznej integracji (np. Harbor) | **Zintegrowany** (Wbudowany rejestr, skanowanie Clair) 7 |
| **Monitoring & Alerty** | Wymaga ręcznej integracji (np. Prometheus) | **Zintegrowany** (Prekonfigurowany stos Prometheus/Grafana) 3 |
| **Agregacja Logów** | Wymaga ręcznej integracji (np. EFK/Loki) | **Zintegrowany** (Prekonfigurowany stos) 3 |
| **Narzędzia CI/CD** | Wymaga ręcznej integracji (np. Jenkins) | **Zintegrowany** (OpenShift Pipelines/Tekton, Jenkins) 3 |
| **Narzędzia Deweloperskie** | Brak (Tylko API i kubectl) | **Zintegrowany** (S2I, Topology View, DevSpaces) 7 |
| **Konsola Webowa** | Opcjonalna, minimalistyczna (Dashboard) | **Zintegrowana** (Centrum zarządzania dla Admin/Dev) 1 |
| **Zarządzanie Cyklem Życia** | Ręczne (np. kubeadm) lub zależne od dostawcy | **Zautomatyzowane** (Operator-First, CVO) 7 |
| **Wsparcie 24/7** | Społeczność 1 | **Zintegrowane** (Wsparcie Red Hat, SRE) 7 |

Różnice przedstawione w kolejnych lekcjach – w konsoli webowej, architekturze operatorów, zarządzaniu projektami czy narzędziach CLI – nie są przypadkowymi dodatkami. Są one bezpośrednią i logiczną konsekwencją tej fundamentalnej, filozoficznej decyzji: budowy kompletnego, "opiniotwórczego" samochodu korporacyjnego, a nie tylko dostarczania silnika o wysokiej wydajności. Kompletny samochód *musi* mieć deskę rozdzielczą (Lekcja 1.2), zintegrowany komputer pokładowy zdolny do aktualizacji OTA (Lekcja 1.3), predefiniowane fotele z pasami bezpieczeństwa dla pasażerów (Lekcja 1.4) oraz przyjazny dla kierowcy interfejs (Lekcja 1.5).

## **1.2: Różnica \#1 – Doświadczenie Użytkownika (Konsola Webowa)**

Jedną z najbardziej widocznych i natychmiastowych różnic między czystym Kubernetes a OpenShift jest podejście do graficznego interfejsu użytkownika (UI). Ta różnica nie jest kosmetyczna; jest to bezpośrednie odzwierciedlenie filozofii opisanej w Lekcji 1.1. Kubernetes, jako platforma infrastrukturalna 20, stawia na CLI, podczas gdy OpenShift, jako platforma deweloperska, traktuje konsolę webową jako centralny punkt interakcji.

### **K8s: kubectl jest Królem, Opcjonalny Dashboard jest Minimalistyczny**

W ekosystemie Kubernetes, interfejs linii komend kubectl jest podstawowym i preferowanym narzędziem pracy.6 Cała automatyzacja, zarządzanie i interakcja z API odbywa się poprzez kubectl i deklaratywne pliki YAML.  
Oficjalny Kubernetes Dashboard *nie jest* domyślnie instalowany w klastrze.26 Musi zostać dodany ręcznie przez administratora, a obecne wersje wspierają instalację wyłącznie za pomocą Helm.26 Co więcej, dostęp do niego jest historycznie skomplikowany i wymaga ręcznych kroków do skonfigurowania uwierzytelniania 1, takich jak utworzenie dedykowanego ServiceAccount i ręczne wyodrębnienie tokena Bearer do logowania.26  
Funkcjonalnie, Dashboard K8s jest minimalistyczny. Oferuje on przegląd zasobów klastra (węzły, przestrzenie nazw, pody, deploymenty), podstawowe możliwości zarządzania (skalowanie, usuwanie) oraz przeglądanie logów.26 Jest to *dashboard* (panel informacyjny), a nie zintegrowane *centrum zarządzania*. Wiele organizacji uważa go za niewystarczający lub nawet za zagrożenie bezpieczeństwa (ze względu na skomplikowaną konfigurację RBAC) i domyślnie go wyłącza 6, polegając na zewnętrznych, płatnych narzędziach lub wyłącznie na CLI. Zarządzanie RBAC przez dashboard jest ograniczone i nieprzyjazne dla użytkownika.29

### **OCP: Konsola Webowa to Centrum Zarządzania**

W przeciwieństwie do K8s, konsola webowa OpenShift jest kluczowym, w pełni zintegrowanym i wspieranym komponentem platformy.6 Nie jest to opcjonalny dodatek, ale samo serce doświadczenia użytkownika, zarządzane przez własny, dedykowany operator (console-operator).30  
Konsola OCP zapewnia intuicyjny interfejs użytkownika, który rozwiązuje jeden z największych problemów K8s Dashboard: uwierzytelnianie. Dzięki integracji z wbudowanym serwerem OAuth, logowanie odbywa się jednym kliknięciem (Single Sign-On), zamiast wymagać skomplikowanej wymiany tokenów.9  
Kluczową innowacją OCP jest podział konsoli na dwie dedykowane "perspektywy", dostosowane do dwóch różnych typów użytkowników 30:

1. **Administrator Perspective:** Skierowana do operatorów klastra i SRE.  
2. **Developer Perspective:** Skierowana do zespołów deweloperskich budujących aplikacje.

### **Przegląd Widoku Dewelopera (Developer Perspective)**

Perspektywa dewelopera została zaprojektowana, aby *abstrahować* złożoność Kubernetesa i pozwolić programistom skupić się na kodzie i aplikacjach.20

* **Topologia (Topology View):** Jest to centralna i najważniejsza funkcja tego widoku.22 Zamiast prezentować płaską listę zasobów (jak Deployment, Pod, Service), Widok Topologii renderuje *wizualną reprezentację* aplikacji, pokazując powiązania i relacje między komponentami.22 Deweloper natychmiast widzi, że jego Deployment jest połączony z Service, który jest wystawiony na świat przez Route, a wszystko zostało zbudowane przez konkretny Build.  
* **Funkcjonalność:** Deweloperzy mogą wykonywać kluczowe operacje "wizualnie": skalować liczbę podów, przeglądać logi, sprawdzać status budowania (specjalne "dekoratory" na ikonach pokazują status: pending, running, completed, failed) oraz przechodzić jednym kliknięciem do publicznego adresu URL aplikacji.22  
* **Integracja z S2I (Source-to-Image):** Konsola pozwala na tworzenie nowych aplikacji bezpośrednio z repozytorium Git (opcja "From Git") 36, bez konieczności pisania jakichkolwiek plików YAML.  
* **Obserwowalność (Observability):** Deweloper ma natychmiastowy dostęp do metryk, logów i zdarzeń *w kontekście swojej aplikacji*, bez konieczności filtrowania szumu informacyjnego z całego klastra.22

### **Przegląd Widoku Administratora (Administrator Perspective)**

Perspektywa administratora służy do zarządzania kondycją i konfiguracją całej platformy.

* **Zarządzanie Węzłami i Klastrem:** Umożliwia przegląd stanu klastra, kondycji poszczególnych węzłów (Nodes), alokacji i wykorzystania zasobów (CPU, pamięć, dysk).30  
* **Zarządzanie Operatorami (Operator Hub):** Jest to odpowiednik "App Store" dla klastra. Administratorzy mogą przeglądać, instalować i zarządzać cyklem życia operatorów (np. bazy danych, systemy monitorujące, narzędzia CI/CD) bezpośrednio z interfejsu użytkownika.30 Jest to graficzny interfejs dla Operator Lifecycle Manager (OLM), który zostanie omówiony w Lekcji 1.3.  
* **Zarządzanie RBAC:** Zapewnia pełne, wizualne narzędzia do zarządzania dostępem: tworzenia użytkowników, grup oraz konfigurowania ról (Roles) i powiązań ról (RoleBindings).30

Różnice w UI nie są powierzchowne. Odzwierciedlają one fundamentalnie różne podejście do tego, *kto* jest docelowym użytkownikiem. Kubernetes Dashboard jest minimalistycznym narzędziem dla *operatora infrastruktury* (mechanika), który i tak większość czasu spędza w CLI.6 Konsola OpenShift jest dwufunkcyjnym centrum dowodzenia dla dwóch różnych person: *Administratora* (mechanika floty) i *Dewelopera* (kierowcy). Widok Dewelopera z Topologią 22 jest właśnie tą "deską rozdzielczą dla kierowcy", której całkowicie brakuje w standardowym Kubernetesie, a która jest niezbędna do realizacji wizji "samochodu" z Lekcji 1.1.  
**Tabela 1.2: Porównanie Funkcjonalne: Kubernetes Dashboard vs. OpenShift Web Console**

| Funkcja | Kubernetes Dashboard (Opcjonalny) | OpenShift Web Console (Zintegrowana) |
| :---- | :---- | :---- |
| **Instalacja** | Ręczna (Helm), nie domyślna 26 | Zintegrowana, zarządzana przez operatora 30 |
| **Uwierzytelnianie** | Złożone (wymaga ręcznego tokena Bearer) 1 | Zintegrowane (SSO, OAuth, oc login) 9 |
| **Główne Przeznaczenie** | Minimalistyczny przegląd zasobów 26 | Pełne centrum zarządzania platformą 6 |
| **Dedykowane Widoki** | Brak (Jeden widok dla wszystkich) | **Tak** (Administrator vs. Deweloper) 30 |
| **Wizualizacja Aplikacji** | Lista zasobów (Deployments, Pods) 28 | **Widok Topologii** (graf powiązań) 22 |
| **Integracja z Budowaniem** | Brak | **Tak** (Tworzenie z Git, S2I, status budowania) 36 |
| **Zarządzanie Operatorami** | Brak (Wymaga CLI) | **Zintegrowany Operator Hub** (interfejs OLM) 30 |
| **Zarządzanie RBAC** | Ograniczone 29 | Pełne, wizualne zarządzanie (Role, Bindings) 39 |

## **1.3: Różnica \#2 – Architektura "Operator-First"**

Fundamentalna różnica architektoniczna, wprowadzona w OpenShift w wersji 4.x, dotyczy sposobu zarządzania cyklem życia samego klastra. Kubernetes deleguje tę odpowiedzialność na administratora; OpenShift automatyzuje ją za pomocą Wzorca Operatora. Ta zmiana paradygmatu jest jedną z najważniejszych wartości dodanych OCP, przenosząc zarządzanie operacjami Dnia 2 (Day 2 Operations) z człowieka na maszynę.

### **K8s: Kluczowe Funkcje to Dodatki Instalowane Ręcznie**

Czysty Kubernetes zarządza tylko podstawowymi zasobami (Pody, Deploymenty, Serwisy). Wszystko inne – Ingress, Monitoring, Logowanie, Service Mesh – jest traktowane jako "dodatek" (addon).40 Administrator klastra K8s jest odpowiedzialny za *wybór*, *instalację*, *konfigurację* i, co najbardziej problematyczne, *aktualizację* tych wszystkich dodatków.3  
Najpopularniejszym narzędziem do zarządzania tymi pakietami jest Helm.41 Jednak Helm jest *menedżerem pakietów* (jak apt w Ubuntu lub yum w RHEL), a nie *menedżerem cyklu życia*.43 Helm doskonale radzi sobie z operacjami Dnia 1 (instalacja).41 Tworzy szablony i instaluje zasoby. Jednak po instalacji jego rola się kończy.

* Jeśli aplikacja (np. baza danych) ulegnie awarii, Helm jej nie naprawi.  
* Jeśli aplikacja wymaga skomplikowanej procedury aktualizacji (np. migracja schematu bazy danych, backup przed aktualizacją), Helm nie jest w stanie automatycznie wykonać tych operacji Dnia 2\.41  
* Jeśli konfiguracja ulegnie zmianie (tzw. "drift"), Helm nie przywróci automatycznie pożądanego stanu.

### **OCP (od 4.x): Klaster jest Zarządzany przez Operatory**

OpenShift od wersji 4.x w pełni przyjął architekturę "Operator-First".44 Oznacza to, że *każdy* komponent samego klastra – serwer API, kontroler sieci (SDN), stos monitoringu, konsola webowa, rejestr obrazów – jest zarządzany przez dedykowany Operator.45  
Operator to "niestandardowy kontroler" (custom controller) 44, który rozszerza API Kubernetesa. Jego celem jest kodowanie ludzkiej wiedzy operacyjnej (wiedzy eksperta SRE \- Site Reliability Engineer) bezpośrednio w oprogramowaniu.41 W przeciwieństwie do Helma, Operator aktywnie monitoruje stan zasobu, który mu podlega (np. klaster Prometheus) i działa w ciągłej pętli uzgadniania (reconciliation loop), aby doprowadzić stan rzeczywisty do stanu pożądanego.46 Operator zarządza *pełnym cyklem życia* (day 2 operations): instalacją, konfiguracją, automatycznymi aktualizacjami, obsługą awarii i skalowaniem.47

### **Rola CVO (Cluster Version Operator) – Jak OCP Samo Siebie Aktualizuje**

Sercem architektury Operator-First w OCP jest Cluster Version Operator (CVO). Jest to "Operator operatorów", nadrzędny mózg zarządzający wersją i spójnością *całego klastra*.25  
CVO działa w oparciu o "release payload image" – pojedynczy, niemodyfikowalny obraz kontenera, który zawiera *dokładne* manifesty YAML dla *wszystkich* komponentów klastra (wszystkich pozostałych operatorów systemowych) dla konkretnej wersji OCP (np. 4.13.5).25  
Proces aktualizacji klastra OCP, który w świecie K8s jest skomplikowaną, ręczną procedurą, w OCP jest w pełni zautomatyzowany 48:

1. Administrator wyraża intencję aktualizacji, ustawiając pole spec.desiredUpdate w zasobie CVO (np. na wersję 4.13.6).25  
2. CVO łączy się z zewnętrzną usługą Red Hat (OpenShift Update Service \- OSUS), aby zweryfikować dostępne i bezpieczne ścieżki aktualizacji.49  
3. Po zatwierdzeniu, CVO pobiera nowy "release payload" dla wersji 4.13.6.25  
4. CVO metodycznie aktualizuje każdy Operator klastra (operator sieci, operator konsoli, operator monitoringu itd.) do nowej wersji, monitorując jego stan, aż osiągnie stabilność.48  
5. Aktualizacje odbywają się w ściśle określonej kolejności (tzw. Runlevels), aby zapewnić stabilność zależności (np. CRD muszą być zaktualizowane przed kontrolerami, które ich używają).48  
6. Na samym końcu, Machine Config Operator (MCO) – jeden z operatorów zarządzanych przez CVO – dokonuje aktualizacji "w locie" (rolling update) systemu operacyjnego (RHCOS) na wszystkich węzłach klastra, po kolei je drenując i restartując.48

Implikacją jest to, że aktualizacja całego klastra OpenShift – od serwera API, przez sieć, aż po system operacyjny na każdym węźle – sprowadza się do jednej komendy i jest procesem w pełni zautomatyzowanym, transakcyjnym i samonaprawiającym się.53

### **Rola OLM (Operator Lifecycle Manager) – "System Operacyjny" dla Operatorów**

Jeśli CVO zarządza *operatorami systemowymi* (samym klastrem), to Operator Lifecycle Manager (OLM) zarządza *operatorami aplikacyjnymi*.44 OLM to "menedżer pakietów" lub "system operacyjny" dla operatorów, które administrator chce dodatkowo zainstalować w klastrze (np. baza danych Crunchy PostgreSQL, systemy CI/CD, narzędzia firm trzecich).  
OLM jest tym, co zasila Operator Hub (widziany w Lekcji 1.2).44 Zarządza on cyklem życia tych operatorów i rozwiązuje ich zależności za pomocą zestawu własnych zasobów 55:

* **CatalogSource:** Definiuje repozytorium operatorów (odpowiednik PPA w Ubuntu lub repozytorium Helm). Mówi OLM, *skąd* pobierać listę dostępnych operatorów.55  
* **Subscription:** Wyrażenie intencji przez administratora: "Chcę zainstalować operator X i subskrybować aktualizacje z kanału stable".55  
* **InstallPlan:** Automatycznie generowany przez OLM plan, który pokazuje, jakie dokładnie zasoby (CRD, Role, Deployment) zostaną utworzone lub zaktualizowane, aby zainstalować lub zaktualizować dany operator. Oczekuje na zatwierdzenie przez administratora.55  
* **ClusterServiceVersion (CSV):** Metadane definiujące operatora – jego wersja, wymagane uprawnienia (RBAC), definicje CRD, które wprowadza, oraz ikona widoczna w Operator Hub.54

Różnica między Helm (podejście K8s) a Operatorami (podejście OCP) jest często mylona, ale fundamentalna. Nie są one wzajemnie wykluczające (wiele operatorów jest pakowanych w Helm 43), ale reprezentują dwie różne epoki zarządzania oprogramowaniem. Helm to podejście "Dnia 1" (instalacja). Architektura Operator-First w OCP to podejście "Dnia 2" (autonomiczne zarządzanie cyklem życia).  
W świecie K8s+Helm, to *administrator* jest SRE i ponosi pełną odpowiedzialność za stan klastra i jego ręczne aktualizacje. W świecie OCP 4.x, administrator *deleguje* tę odpowiedzialność na platformę – na CVO i OLM. To jest ostateczna realizacja "opiniotwórczej" filozofii: rezygnacja z pełnej, ręcznej kontroli na rzecz zautomatyzowanej, przewidywalnej i wspieranej niezawodności.

## **1.4: Różnica \#3 – Zarządzanie Zespołami (Project vs. Namespace)**

Kolejna kluczowa różnica dotyczy modelu wielodostępności (multi-tenancy) i sposobu, w jaki platforma izoluje zasoby poszczególnych zespołów. Kubernetes dostarcza do tego prymityw o nazwie Namespace, podczas gdy OpenShift rozbudowuje go do konceptu Project. Różnica ta jest kluczowa dla samoobsługi i zarządzania w środowiskach korporacyjnych.

### **K8s: Namespace to tylko Logiczna Granica (Izolacja Nazw)**

Namespace w Kubernetes jest podstawowym mechanizmem izolacji zasobów.58 Jego głównym celem jest zapobieganie kolizjom nazw; na przykład Deployment "app" w przestrzeni nazw ns-dev i Deployment "app" w ns-prod to dwa całkowicie różne obiekty.  
Namespace stanowi również kluczową *granicę bezpieczeństwa*.58 Zasady RBAC, NetworkPolicy oraz Pod Security Standards są najczęściej stosowane w kontekście konkretnej przestrzeni nazw.58  
Jednak sam w sobie Namespace jest tylko *pustym pudełkiem*. Polecenie kubectl create namespace test 60 tworzy jedynie pustą logiczną przestrzeń.

### **OCP: Project to Namespace na Sterydach**

Project w OpenShift jest technicznie Namespace w Kubernetes, ale z dodatkowymi adnotacjami, metadanymi i, co najważniejsze, zautomatyzowanym procesem inicjalizacji.61 Każdy Project jest widoczny w API K8s jako Namespace (i odwrotnie), ale Project to coś znacznie więcej.  
Kluczowa różnica polega na tym, że Project to *jednostka współpracy* i *izolacji* zaprojektowana specjalnie dla zespołów deweloperskich.61 W typowej konfiguracji OCP, zwykli użytkownicy (deweloperzy) nie mają uprawnień do wykonania kubectl create namespace. Zamiast tego, wysyłają żądanie utworzenia projektu (np. za pomocą polecenia oc new-project), które uruchamia zautomatyzowany proces *inicjalizacji środowiska*.61

### **Co tworzy oc new-project test?**

Polecenie oc new-project test (lub jego odpowiednik w konsoli webowej) nie tylko tworzy zasób. Uruchamia ono zdefiniowany przez administratora klastra *szablon* projektu (projectRequestTemplate).62 Domyślnie, ten szablon tworzy znacznie więcej niż tylko pusty Namespace 65:

1. **Obiekt Project:** Jest to zasób OCP, który odpowiada zasobowi Namespace w K8s.  
2. **RoleBindings (Uprawnienia Użytkownika):** Automatycznie tworzy RoleBinding o nazwie admin, który przypisuje użytkownikowi *tworzącemu* projekt pełne uprawnienia administracyjne (admin role) *tylko wewnątrz tego projektu*.62 Daje to użytkownikowi pełną kontrolę nad jego własnym środowiskiem, bez możliwości ingerencji w inne projekty.  
3. **ServiceAccounts (Tożsamości dla Maszyn):** Automatycznie tworzy trzy kluczowe konta serwisowe (ServiceAccount), które są niezbędne dla procesów deweloperskich w OCP 65:  
   * builder: Używany przez procesy budowania (S2I, Docker), aby mieć uprawnienia do pobierania kodu i pchania obrazów do wewnętrznego rejestru.  
   * deployer: Używany przez DeploymentConfigs (mechanizm wdrażania OCP) do wdrażania nowych wersji aplikacji.  
   * default: Domyślne konto używane przez pody, które nie określą inaczej.  
4. **Dodatkowe RoleBindings dla ServiceAccounts:** Automatycznie tworzy powiązania ról dla tych ServiceAccounts, aby mogły one wykonywać swoje zadania (np. system:image-builder dla SA builder).65  
5. **Secrets:** Tworzy niezbędne sekrety dla ServiceAccounts, w tym ich tokeny API oraz sekrety typu dockercfg, które pozwalają im uwierzytelniać się we wbudowanym rejestrze obrazów OCP.65  
6. **(Opcjonalnie) Domyślne NetworkPolicy:** Administrator klastra może skonfigurować domyślny szablon projektu tak, aby automatycznie dodawał domyślne zasady sieciowe, np. politykę "deny-all" (domyślna blokada wszelkiego ruchu) lub "allow-from-same-namespace" (zezwalaj na ruch tylko w obrębie projektu).69  
7. **(Opcjonalnie) Domyślne LimitRanges i ResourceQuotas:** Szablon może również automatycznie stosować domyślne limity zasobów (np. maksymalna ilość pamięci RAM dla poda) oraz kwoty (np. maksymalna łączna pamięć RAM dla projektu).69

### **Porównanie z kubectl create namespace test**

Polecenie kubectl create namespace test 60 tworzy *tylko* obiekt Namespace. Nic więcej. W tym Namespace nie ma domyślnie żadnych RoleBindings (poza systemowymi), żadnych dodatkowych ServiceAccounts (builder, deployer), żadnych NetworkPolicy ani LimitRanges. Jest to puste, niefunkcjonalne środowisko, które staje się użyteczne dla dewelopera dopiero wtedy, gdy administrator ręcznie skonfiguruje *wszystkie* powyższe zasoby.  
Różnica ta ilustruje podejście OCP do *samoobsługowej wielodostępności*. Namespace w K8s to tylko "pusta działka budowlana". Project w OCP to "fabryka środowisk deweloperskich". Administrator OCP nie buduje ręcznie każdego środowiska; zamiast tego projektuje *szablon fabryczny* (projectRequestTemplate 62), a następnie deleguje uprawnienia do "produkowania" gotowych, zgodnych ze standardami środowisk samym deweloperom.  
**Tabela 1.4: Analiza Porównawcza Wyników Poleceń: kubectl create namespace test vs. oc new-project test**

| Zasób Utworzony/Skonfigurowany | kubectl create namespace test | oc new-project test (Domyślny Szablon) |
| :---- | :---- | :---- |
| Obiekt Namespace | **Tak** | **Tak** (jako obiekt Project) 61 |
| RoleBinding dla twórcy (np. admin) | Nie | **Tak** 62 |
| ServiceAccount (builder) | Nie | **Tak** 65 |
| ServiceAccount (deployer) | Nie | **Tak** 65 |
| ServiceAccount (default) | Tak (minimalny) | **Tak** (z dodatkowymi sekretami) 66 |
| Secrets (dla SA, dockercfg) | Nie | **Tak** (Wiele, np. 9\) 65 |
| RoleBindings dla SA | Nie | **Tak** (Wiele, np. 3\) 65 |
| Domyślne LimitRanges / Quotas | Nie | **Tak** (Jeśli skonfigurowane w szablonie) 73 |
| Domyślne NetworkPolicy | Nie | **Tak** (Jeśli skonfigurowane w szablonie) 70 |
| **Wynik** | **Puste pudełko** | **Gotowe środowisko dla zespołu** |

## **1.5: Różnica \#4 – Narzędzie Lini Komend (oc vs. kubectl)**

Różnice filozoficzne i architektoniczne między OCP i K8s znajdują również odzwierciedlenie w narzędziach linii komend. Kubernetes dostarcza kubectl, podczas gdy OpenShift dostarcza oc. Na pierwszy rzut oka mogą wydawać się tożsame, jednak oc jest kluczowym elementem ekosystemu OCP, zaprojektowanym w celu radykalnego uproszczenia przepływów pracy deweloperów i administratorów.

### **oc to Nadzbiór kubectl**

Narzędzie oc (OpenShift CLI) jest zbudowane na bazie kodu kubectl (Kubernetes CLI).74 Jest to dosłownie *nadzbiór* (superset) poleceń kubectl.76  
Oznacza to, że każda poprawna komenda kubectl (np. kubectl get pods) zadziała, jeśli zastąpimy kubectl przez oc (np. oc get pods).14 Ta cecha zapewnia pełną kompatybilność wsteczną dla istniejących skryptów K8s oraz dla użytkowników, którzy są już przyzwyczajeni do pracy z kubectl.74 Użytkownik może zarządzać zarówno zasobami K8s (Pods, Services), jak i zasobami OCP (Routes, BuildConfigs) za pomocą jednego narzędzia oc.14

### **Kluczowe Komendy Tylko w oc**

Prawdziwa wartość oc leży w dodatkowych poleceniach, które nie istnieją w kubectl. Polecenia te są zaprojektowane do interakcji z zasobami specyficznymi dla OpenShift oraz, co ważniejsze, do automatyzacji skomplikowanych *przepływów pracy* (workflows).

* **oc login (vs skomplikowane zarządzanie kubeconfig)**  
  * W kubectl, uwierzytelnianie jest procesem zewnętrznym. Użytkownik musi ręcznie skonfigurować swój plik kubeconfig, często poprzez skomplikowane procesy OIDC lub ręczne pobieranie tokenów Bearer.14  
  * oc login to zintegrowane polecenie, które łączy się z wbudowanym serwerem OpenShift OAuth. Automatycznie otwiera przeglądarkę w celu uwierzytelnienia (np. przez LDAP, GitHub lub inne SSO), pobiera token i bezpiecznie zapisuje go w kubeconfig użytkownika.14 Jest to "kluczyk do samochodu" z Lekcji 1.1 – proste i niezawodne.  
* **oc new-project (vs create namespace \+ edycja RBAC)**  
  * Jak omówiono szczegółowo w Lekcji 1.4, to polecenie to nie jest prosty alias dla kubectl create namespace. Jest to *proces inicjalizacji środowiska*, który tworzy Project, ServiceAccounts, RoleBindings i inne niezbędne zasoby, dostarczając deweloperowi gotowe do pracy środowisko.14  
* **oc new-app (Buduje aplikację z Git – zajawka S2I)**  
  * Jest to jedno z najpotężniejszych poleceń oc, stanowiące rdzeń DevEx w OpenShift.80 Polecenie oc new-app https://github.com/moje/repozytorium.git 82 wykonuje automatycznie cały szereg skomplikowanych kroków:  
    1. Analizuje repozytorium Git.  
    2. Wykrywa strategię budowania (np. widzi plik pom.xml i wybiera strategię S2I dla Javy).82  
    3. Tworzy zasób BuildConfig, który definiuje *jak* budować obraz.  
    4. Tworzy zasób ImageStream, który śledzi wersje obrazu we wbudowanym rejestrze.  
    5. Tworzy zasób DeploymentConfig (lub Deployment), który definiuje *jak* wdrażać aplikację.  
    6. Tworzy zasób Service, aby udostępnić aplikację wewnątrz klastra.  
  * W świecie kubectl ten jeden krok wymagałby od dewelopera ręcznego napisania, przetestowania i zaaplikowania 4-5 różnych, skomplikowanych plików YAML.  
* **oc start-build (Do ręcznego triggerowania BuildConfig)**  
  * Ponieważ OCP ma natywny, pierwszoklasowy zasób BuildConfig, oc dostarcza polecenie do interakcji z nim. oc start-build pozwala na ręczne uruchomienie procesu budowania (np. po wypchnięciu zmian do Git).14  
  * Posiada niezwykle użyteczne flagi, takie jak \--follow (do strumieniowania logów z budowania w czasie rzeczywistym) lub \--wait (do wstrzymania skryptu do czasu ukończenia budowania).83  
* **oc status (Szybki podgląd projektu)**  
  * kubectl nie ma prostego odpowiednika. kubectl get all jest często niekompletne i zbyt szczegółowe.  
  * oc status daje administratorowi szybki, skonsolidowany, tekstowy przegląd "co się dzieje" w bieżącym projekcie – jakie są serwisy, jakie deploymenty nimi zarządzają i jaki jest ich aktualny stan.14  
* **oc policy add-role-to-user... (Łatwiejsze zarządzanie RBAC)**  
  * Zarządzanie RBAC w kubectl jest uciążliwe i wymaga ręcznego tworzenia lub edytowania plików YAML dla Role i RoleBinding.84  
  * oc dostarcza polecenia "przyjazne dla człowieka", takie jak oc adm policy add-role-to-user \<rola\> \<użytkownik\> 85 lub oc adm policy add-role-to-group....85 Te polecenia upraszczają 90% codziennych zadań związanych z zarządzaniem uprawnieniami.87

Narzędzia te pokazują fundamentalną różnicę w podejściu. kubectl jest *deklaratywny* i *zorientowany na zasoby*. Użytkownik mówi mu: "weź *ten* plik YAML i stwórz *ten* zasób". oc jest również *imperatywny* i *zorientowany na przepływ pracy (workflow)*. Użytkownik mówi mu: "weź *ten* kod źródłowy i stwórz *aplikację*".81 oc jest realizacją filozofii DevEx 20; pozwala użytkownikowi być *deweloperem*, podczas gdy kubectl wymaga od użytkownika bycia *ekspertem Kubernetesa*.  
**Tabela 1.5: Kluczowe Polecenia oc i ich Odpowiedniki (lub ich brak) w kubectl**

| Zadanie (Workflow) | kubectl (Podejście Standardowe) | oc (Podejście OpenShift) | Wartość Dodana oc |
| :---- | :---- | :---- | :---- |
| **Logowanie do Klastra** | Ręczna konfiguracja kubeconfig 14 | oc login \[server-url\] 78 | Zintegrowane uwierzytelnianie OAuth 14 |
| **Tworzenie Środowiska Zespołu** | kubectl create namespace test \+ 10 ręcznych kroków (RBAC, SA) | oc new-project test 62 | "Środowisko-w-pudełku" (Lekcja 1.4) |
| **Wdrożenie Aplikacji z Git** | Wymaga ręcznego Dockerfile, Deployment.yaml, Service.yaml | oc new-app \[git-repo-url\] 82 | "Source-to-Deploy" bez YAML 81 |
| **Uruchomienie Procesu Budowania** | Zależne od zewnętrznego systemu CI (np. Jenkins job) | oc start-build \[buildconfig-name\] 83 | Natywna integracja z obiektem BuildConfig |
| **Dodanie Uprawnień Admina** | kubectl create rolebinding... \--user=... (złożona składnia) | oc adm policy add-role-to-user admin jan.kowalski 85 | Czytelność i prostota 85 |
| **Sprawdzenie Stanu Projektu** | kubectl get all (niekompletne) lub wiele komend | oc status 14 | Szybki, skonsolidowany przegląd 14 |

## **1.6: Zajawka Kluczowych Różnic (Co poznamy dalej?)**

Moduł 1 ustanowił fundamentalną różnicę filozoficzną: Kubernetes to "silnik" 5, a OpenShift to kompletna, "opiniotwórcza" platforma.16 Omówiliśmy, jak ta filozofia manifestuje się w doświadczeniu użytkownika (Konsola Webowa) 6, architekturze zarządzania (Operator-First) 44 oraz narzędziach (Project, oc CLI).14  
W kolejnych modułach zbadamy, jak ta sama filozofia "platformy" prowadzi do głębokich różnic technicznych w trzech kluczowych obszarach: sieci, procesach budowania i bezpieczeństwie.

### **Sieć: Ingress (K8s) vs. Route (OCP) \-\> Moduł 4**

* **Różnica na wysokim poziomie:** Ingress w Kubernetes to tylko *specyfikacja* (zbiór reguł), która sama w sobie nic nie robi. Wymaga ona zewnętrznego, ręcznie instalowanego *kontrolera* (np. NGINX Ingress Controller, Traefik), który odczyta te reguły i je zaimplementuje.10  
* Route w OpenShift to w pełni zintegrowane rozwiązanie, które zawiera zarówno specyfikację, jak i *wbudowany, domyślny kontroler* (Router OCP, oparty na HAProxy).9  
* **Kluczowe funkcje Route:** Ponieważ Route był historycznie pierwszy i zainspirował powstanie Ingress 89, oferuje on wbudowane, zaawansowane funkcje, których brak w standardowym Ingress. Należą do nich:  
  * **Terminacja TLS Re-encryption:** Ruch jest szyfrowany od klienta do routera OCP, tam deszyfrowany, analizowany, a następnie *ponownie szyfrowany* przed wysłaniem do poda w klastrze.9  
  * **Terminacja TLS Passthrough:** Router przekazuje zaszyfrowany ruch bezpośrednio do poda, pozwalając aplikacji na zarządzanie własnymi certyfikatami.9  
  * **Rozdzielanie Ruchu (Traffic Splitting):** Route natywnie obsługuje scenariusze Blue/Green i Canary, pozwalając na skierowanie procentu ruchu do różnych serwisów (np. 90% ruchu do v1, 10% do v2).9

### **Budowanie: Dockerfile (K8s) vs. S2I (Source-to-Image) (OCP) \-\> Moduł 2**

* **Różnica na wysokim poziomie:** W świecie K8s, budowanie obrazów kontenerów jest procesem *zewnętrznym*. Deweloper pisze Dockerfile, uruchamia docker build (lub buildah build) na swojej maszynie lub w zewnętrznym systemie CI (np. Jenkins), a następnie *wypycha* (push) gotowy obraz do rejestru. Kubernetes tylko *pobiera* (pull) ten gotowy obraz.91  
* OpenShift *internalizuje* proces budowania. Dostarcza natywny zasób BuildConfig, który definiuje, jak budować obraz *wewnątrz klastra*.92  
* **Kluczowe funkcje S2I:** Najpopularniejszą strategią budowania w OCP jest Source-to-Image (S2I).92  
  * **Abstrakcja:** Deweloper *nie musi pisać pliku Dockerfile*.91 Po prostu dostarcza swój kod źródłowy (np. Javy, Pythona).  
  * **Proces:** S2I inteligentnie łączy ten kod z "obrazem budującym" (builder image), który zawiera wszystkie narzędzia (np. maven, pip). Kompiluje kod i umieszcza artefakty (np. plik .jar) w "obrazie wynikowym" (runtime image), tworząc zoptymalizowany, gotowy do uruchomienia obraz.92  
  * **Korzyści:** Jest to szybsze (S2I wspiera budowanie przyrostowe 92), bezpieczniejsze (proces budowania nie wymaga uprawnień root 94) i znacznie prostsze dla deweloperów, którzy nie muszą być ekspertami od optymalizacji Dockerfile.91

### **Bezpieczeństwo: PodSecurity (K8s) vs. SecurityContextConstraints (SCC) (OCP) \-\> Moduł 6**

* **Różnica na wysokim poziomie:** Kubernetes, po wycofaniu PodSecurityPolicy (PSP) 95, przeszedł na mechanizm Pod Security Admission (PSA), który opiera się na Pod Security Standards (PSS).96 PSS jest mechanizmem na poziomie klastra, który wymusza jedną z trzech polityk (privileged, baseline, restricted) poprzez *zastosowanie etykiet do Namespace*.96  
* OpenShift od samego początku używał znacznie bardziej granularnego mechanizmu o nazwie SecurityContextConstraints (SCC).13  
* **Kluczowe funkcje SCC:** SCC to nie jest polityka na poziomie Namespace. Jest to zasób, który definiuje zestaw uprawnień (np. "możliwość uruchomienia jako root", "możliwość montowania wolumenów hosta", "możliwość użycia hostNetwork"). Te uprawnienia są następnie przyznawane *bezpośrednio użytkownikom i ServiceAccounts* poprzez standardowy mechanizm RBAC (Role-Based Access Control).13  
* **Jak działają razem:** W nowoczesnym OpenShift, PSS i SCC działają *razem*.96 OCP używa PSS do globalnego egzekwowania standardów, ale nadal polega na SCC do szczegółowej, opartej na RBAC kontroli dostępu. Kluczową różnicą jest to, że domyślna instalacja OCP jest *znacznie bardziej restrykcyjna* niż domyślna instalacja K8s, natychmiast blokując możliwość uruchamiania kontenerów jako root dla większości użytkowników.13

Te trzy obszary idealnie podsumowują centralną tezę Modułu 1\. W każdym przypadku obserwujemy ten sam wzorzec: Kubernetes dostarcza *możliwości* (API Ingress, API Pod) lub zakłada *procesy zewnętrzne* (budowanie obrazów), oczekując, że użytkownik samodzielnie zintegruje resztę. OpenShift dostarcza *kompletne, zintegrowane, "opiniotwórcze" rozwiązania* (Route z routerem, S2I w klastrze, SCC zintegrowane z RBAC) jako część spójnego, wspieranego produktu.  
**Tabela 1.6: Podsumowanie Zaawansowanych Różnic (Sieć, Budowanie, Bezpieczeństwo)**

| Obszar | Kubernetes (Podejście Standardowe) | OpenShift (Podejście Zintegrowane) | Kluczowa Różnica |
| :---- | :---- | :---- | :---- |
| **Sieć Zewnętrzna** | Ingress (Specyfikacja) \+ Kontroler (Zewnętrzny) 10 | Route (Specyfikacja \+ Wbudowany Kontroler HAProxy) 9 | Route natywnie obsługuje traffic-splitting i zaawansowane TLS (re-encrypt, passthrough) 89 |
| **Proces Budowania** | Zewnętrzny (docker build, Dockerfile) 91 | Wewnętrzny (BuildConfig, strategia S2I) 92 | S2I abstrahuje Dockerfile, dając bezpieczniejszy i szybszy proces dla deweloperów 92 |
| **Bezpieczeństwo Podów** | Pod Security Standards (PSS) (na Namespace) 96 | SecurityContextConstraints (SCC) (na Użytkownika/SA) \+ PSS 96 | SCC to granularny mechanizm oparty na RBAC; OCP domyślnie blokuje root 13 |

#### **Cytowane prace**

1. OpenShift vs. Kubernetes: What's the Difference? \- IBM, otwierano: listopada 14, 2025, [https://www.ibm.com/think/topics/openshift-vs-kubernetes](https://www.ibm.com/think/topics/openshift-vs-kubernetes)  
2. 10 most important differences between OpenShift and Kubernetes \- Cloudowski, otwierano: listopada 14, 2025, [https://cloudowski.com/articles/10-most-important-differences-between-openshift-and-kubernetes/](https://cloudowski.com/articles/10-most-important-differences-between-openshift-and-kubernetes/)  
3. What are the Differences Between Openshift vs Kubernetes? \- Folio3 Cloud, otwierano: listopada 14, 2025, [https://cloud.folio3.com/blog/openshift-vs-kubernetes/](https://cloud.folio3.com/blog/openshift-vs-kubernetes/)  
4. OpenShift vs Kubernetes: Which Container Orchestration Tool is the Right Fit for Your Business? \- OpenMetal, otwierano: listopada 14, 2025, [https://openmetal.io/resources/blog/openshift-vs-kubernetes/](https://openmetal.io/resources/blog/openshift-vs-kubernetes/)  
5. A Guide to Enterprise Kubernetes with OpenShift \- Red Hat, otwierano: listopada 14, 2025, [https://www.redhat.com/en/blog/enterprise-kubernetes-with-openshift-part-one](https://www.redhat.com/en/blog/enterprise-kubernetes-with-openshift-part-one)  
6. OpenShift vs. Kubernetes: Key Differences Explained \- DataCamp, otwierano: listopada 14, 2025, [https://www.datacamp.com/blog/openshift-vs-kubernetes](https://www.datacamp.com/blog/openshift-vs-kubernetes)  
7. Red Hat OpenShift vs. Kubernetes: What's the difference?, otwierano: listopada 14, 2025, [https://www.redhat.com/en/technologies/cloud-computing/openshift/red-hat-openshift-kubernetes](https://www.redhat.com/en/technologies/cloud-computing/openshift/red-hat-openshift-kubernetes)  
8. OpenShift vs. Kubernetes: Understanding the differences \- Dynatrace, otwierano: listopada 14, 2025, [https://www.dynatrace.com/news/blog/openshift-vs-kubernetes/](https://www.dynatrace.com/news/blog/openshift-vs-kubernetes/)  
9. OpenShift vs. Kubernetes: 7 Key Differences \- Solo.io, otwierano: listopada 14, 2025, [https://www.solo.io/topics/openshift/openshift-vs-kubernetes](https://www.solo.io/topics/openshift/openshift-vs-kubernetes)  
10. OpenShift vs Kubernetes: Everything you need to know, otwierano: listopada 14, 2025, [https://www.xavor.com/blog/openshift-vs-kubernetes/](https://www.xavor.com/blog/openshift-vs-kubernetes/)  
11. OpenShift and Kubernetes: What's the difference? \- Red Hat, otwierano: listopada 14, 2025, [https://www.redhat.com/en/blog/openshift-and-kubernetes-whats-difference](https://www.redhat.com/en/blog/openshift-and-kubernetes-whats-difference)  
12. OpenShift Security: How to Protect Your Kubernetes Environment \- Trilio, otwierano: listopada 14, 2025, [https://trilio.io/resources/openshift-security/](https://trilio.io/resources/openshift-security/)  
13. Migrate your Kubernetes pod security policies to OpenShift security context constraints, otwierano: listopada 14, 2025, [https://developer.ibm.com/articles/migrate-kubernetes-pod-security-policies-openshift-security-context-constraints/](https://developer.ibm.com/articles/migrate-kubernetes-pod-security-policies-openshift-security-context-constraints/)  
14. Openshift: Comprehensive Guide: oc vs kubectl CLI \- DevOpsSchool ..., otwierano: listopada 14, 2025, [https://www.devopsschool.com/blog/openshift-comprehensive-guide-oc-vs-kubectl-cli/](https://www.devopsschool.com/blog/openshift-comprehensive-guide-oc-vs-kubectl-cli/)  
15. OpenShift vs Kubernetes: What's the Difference? \- Portworx, otwierano: listopada 14, 2025, [https://portworx.com/knowledge-hub/openshift-vs-kubernetes-whats-the-difference/](https://portworx.com/knowledge-hub/openshift-vs-kubernetes-whats-the-difference/)  
16. Application modernization: The importance of an opinionated workflow, otwierano: listopada 14, 2025, [https://www.redhat.com/en/blog/application-modernization-importance-opinionated-workflow](https://www.redhat.com/en/blog/application-modernization-importance-opinionated-workflow)  
17. What is with people calling their work “opinionated”? : r/github \- Reddit, otwierano: listopada 14, 2025, [https://www.reddit.com/r/github/comments/11zue7r/what\_is\_with\_people\_calling\_their\_work\_opinionated/](https://www.reddit.com/r/github/comments/11zue7r/what_is_with_people_calling_their_work_opinionated/)  
18. What is opinionated software? \- Stack Overflow, otwierano: listopada 14, 2025, [https://stackoverflow.com/questions/802050/what-is-opinionated-software](https://stackoverflow.com/questions/802050/what-is-opinionated-software)  
19. OpenShift Architecture \- Darshana Dinushal \- Medium, otwierano: listopada 14, 2025, [https://darshanadinushal.medium.com/openshift-architecture-63c9e2974abe](https://darshanadinushal.medium.com/openshift-architecture-63c9e2974abe)  
20. What's the philosophy behind openshift? : r/kubernetes \- Reddit, otwierano: listopada 14, 2025, [https://www.reddit.com/r/kubernetes/comments/1i5ojcr/whats\_the\_philosophy\_behind\_openshift/](https://www.reddit.com/r/kubernetes/comments/1i5ojcr/whats_the_philosophy_behind_openshift/)  
21. Kubernetes 101 for OpenShift developers, Part 1: Components, otwierano: listopada 14, 2025, [https://developers.redhat.com/articles/2022/12/21/kubernetes-101-openshift-developers-part-1-components](https://developers.redhat.com/articles/2022/12/21/kubernetes-101-openshift-developers-part-1-components)  
22. Chapter 4\. Viewing application composition using the Topology view ..., otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.9/html/building\_applications/odc-viewing-application-composition-using-topology-view](https://docs.redhat.com/en/documentation/openshift_container_platform/4.9/html/building_applications/odc-viewing-application-composition-using-topology-view)  
23. Can someone help me understand why Openshift is used? : r/kubernetes \- Reddit, otwierano: listopada 14, 2025, [https://www.reddit.com/r/kubernetes/comments/1g0wa98/can\_someone\_help\_me\_understand\_why\_openshift\_is/](https://www.reddit.com/r/kubernetes/comments/1g0wa98/can_someone_help_me_understand_why_openshift_is/)  
24. Red Hat OpenShift Kubernetes Engine, otwierano: listopada 14, 2025, [https://www.redhat.com/en/technologies/cloud-computing/openshift/kubernetes-engine](https://www.redhat.com/en/technologies/cloud-computing/openshift/kubernetes-engine)  
25. openshift/cluster-version-operator \- GitHub, otwierano: listopada 14, 2025, [https://github.com/openshift/cluster-version-operator](https://github.com/openshift/cluster-version-operator)  
26. Deploy and Access the Kubernetes Dashboard | Kubernetes, otwierano: listopada 14, 2025, [https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)  
27. kubernetes/dashboard: General-purpose web UI for Kubernetes clusters \- GitHub, otwierano: listopada 14, 2025, [https://github.com/kubernetes/dashboard](https://github.com/kubernetes/dashboard)  
28. Kubernetes Dashboard: Tutorial, Best Practices & Alternatives \- Spacelift, otwierano: listopada 14, 2025, [https://spacelift.io/blog/kubernetes-dashboard](https://spacelift.io/blog/kubernetes-dashboard)  
29. Top 5 Alternatives to Kubernetes Dashboard \- Devtron, otwierano: listopada 14, 2025, [https://devtron.ai/blog/best-5-alternatives-to-kubernetes-dashboard/](https://devtron.ai/blog/best-5-alternatives-to-kubernetes-dashboard/)  
30. Web console | OpenShift Container Platform | 4.6 | Red Hat ..., otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.6/html-single/web\_console/index](https://docs.redhat.com/en/documentation/openshift_container_platform/4.6/html-single/web_console/index)  
31. Chapter 1\. Web Console Overview | Web console | OpenShift Container Platform | 4.10 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.10/html/web\_console/web-console-overview](https://docs.redhat.com/en/documentation/openshift_container_platform/4.10/html/web_console/web-console-overview)  
32. Chapter 1\. Web Console Overview | Web console | OpenShift Container Platform | 4.8, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/web\_console/web-console-overview](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/web_console/web-console-overview)  
33. Chapter 5\. About the Developer perspective in the web console | Web console | OpenShift Container Platform | 4.2 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.2/html/web\_console/odc-about-developer-perspective](https://docs.redhat.com/en/documentation/openshift_container_platform/4.2/html/web_console/odc-about-developer-perspective)  
34. Topology \- OpenShift Design, otwierano: listopada 14, 2025, [http://openshift.github.io/openshift-origin-design/designs/developer/topology/](http://openshift.github.io/openshift-origin-design/designs/developer/topology/)  
35. OpenShift topology view: A milestone towards a better developer experience \- Red Hat, otwierano: listopada 14, 2025, [https://www.redhat.com/en/blog/openshift-topology-view-milestone-towards-better-developer-experience](https://www.redhat.com/en/blog/openshift-topology-view-milestone-towards-better-developer-experience)  
36. Web console | OpenShift Container Platform | 4.8 \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html-single/web\_console/index](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html-single/web_console/index)  
37. Chapter 3\. Creating applications | Building applications | OpenShift Container Platform | 4.12, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.12/html/building\_applications/creating-applications](https://docs.redhat.com/en/documentation/openshift_container_platform/4.12/html/building_applications/creating-applications)  
38. OpenShift 101 \- IBM Developer, otwierano: listopada 14, 2025, [https://developer.ibm.com/articles/openshift-101/](https://developer.ibm.com/articles/openshift-101/)  
39. Web console overview \- OKD Documentation, otwierano: listopada 14, 2025, [https://docs.okd.io/latest/web\_console/web-console-overview.html](https://docs.okd.io/latest/web_console/web-console-overview.html)  
40. Installing Addons | Kubernetes, otwierano: listopada 14, 2025, [https://kubernetes.io/docs/concepts/cluster-administration/addons/](https://kubernetes.io/docs/concepts/cluster-administration/addons/)  
41. Kubernetes Operator vs HELM Explained \- Edge Delta, otwierano: listopada 14, 2025, [https://edgedelta.com/company/knowledge-center/kubernetes-operator-vs-helm](https://edgedelta.com/company/knowledge-center/kubernetes-operator-vs-helm)  
42. Using Helm with Red Hat OpenShift, otwierano: listopada 14, 2025, [https://www.redhat.com/en/technologies/cloud-computing/openshift/helm](https://www.redhat.com/en/technologies/cloud-computing/openshift/helm)  
43. Helm chart vs Operator \- which do you prefer? : r/kubernetes \- Reddit, otwierano: listopada 14, 2025, [https://www.reddit.com/r/kubernetes/comments/16s7nw8/helm\_chart\_vs\_operator\_which\_do\_you\_prefer/](https://www.reddit.com/r/kubernetes/comments/16s7nw8/helm_chart_vs_operator_which_do_you_prefer/)  
44. OpenShift Operators: Tutorial & Instructions \- Densify, otwierano: listopada 14, 2025, [https://www.densify.com/openshift-tutorial/openshift-operators/](https://www.densify.com/openshift-tutorial/openshift-operators/)  
45. Chapter 1\. Architecture overview | Architecture | OpenShift Container Platform | 4.10 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.10/html/architecture/architecture-overview](https://docs.redhat.com/en/documentation/openshift_container_platform/4.10/html/architecture/architecture-overview)  
46. Red Hat OpenShift Operators: Concept and working example in Golang, otwierano: listopada 14, 2025, [https://www.redhat.com/en/blog/red-hat-openshift-operators-concept-and-working-example-golang](https://www.redhat.com/en/blog/red-hat-openshift-operators-concept-and-working-example-golang)  
47. Operator vs. Helm: Finding the best fit for your Kubernetes applications \- Datadog, otwierano: listopada 14, 2025, [https://www.datadoghq.com/blog/datadog-operator-helm/](https://www.datadoghq.com/blog/datadog-operator-helm/)  
48. Chapter 2\. Understanding OpenShift updates | Updating clusters ..., otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.13/html/updating\_clusters/understanding-openshift-updates-1](https://docs.redhat.com/en/documentation/openshift_container_platform/4.13/html/updating_clusters/understanding-openshift-updates-1)  
49. Openshift Update Service — Upgrading clusters the right way | by Hillay Amir | Medium, otwierano: listopada 14, 2025, [https://medium.com/@hillayamir/openshift-update-service-your-personal-over-the-air-update-service-776b43230011](https://medium.com/@hillayamir/openshift-update-service-your-personal-over-the-air-update-service-776b43230011)  
50. The Ultimate Guide to OpenShift Update for Cluster Administrators \- Red Hat, otwierano: listopada 14, 2025, [https://www.redhat.com/en/blog/the-ultimate-guide-to-openshift-update-for-cluster-administrators](https://www.redhat.com/en/blog/the-ultimate-guide-to-openshift-update-for-cluster-administrators)  
51. Chapter 3\. Installation and update | Architecture | OpenShift Container Platform | 4.10, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.10/html/architecture/architecture-installation](https://docs.redhat.com/en/documentation/openshift_container_platform/4.10/html/architecture/architecture-installation)  
52. Introduction to OpenShift updates \- OKD Documentation, otwierano: listopada 14, 2025, [https://docs.okd.io/4.17/updating/understanding\_updates/intro-to-updates.html](https://docs.okd.io/4.17/updating/understanding_updates/intro-to-updates.html)  
53. Red Hat Partner Conference \- Zoom on OCP 4 \- Devoteam, otwierano: listopada 14, 2025, [https://www.devoteam.com/news-and-pr/red-hat-partner-conference-zoom-on-ocp-4/](https://www.devoteam.com/news-and-pr/red-hat-partner-conference-zoom-on-ocp-4/)  
54. Chapter 2\. Understanding the Operator Lifecycle Manager (OLM) \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.2/html/operators/understanding-the-operator-lifecycle-manager-olm](https://docs.redhat.com/en/documentation/openshift_container_platform/4.2/html/operators/understanding-the-operator-lifecycle-manager-olm)  
55. Operator Lifecycle Manager concepts and resources \- OKD ..., otwierano: listopada 14, 2025, [https://docs.okd.io/4.18/operators/understanding/olm/olm-understanding-olm.html](https://docs.okd.io/4.18/operators/understanding/olm/olm-understanding-olm.html)  
56. Understanding OpenShift's Operator Lifecycle Manager (OLM) \- IBM TechXchange Community, otwierano: listopada 14, 2025, [https://community.ibm.com/community/user/blogs/manogya-sharma/2025/07/04/understanding-openshifts-operator-lifecycle-manage](https://community.ibm.com/community/user/blogs/manogya-sharma/2025/07/04/understanding-openshifts-operator-lifecycle-manage)  
57. Ask an OpenShift Admin Office Hour \- Operator Lifecycle Manager Deepdive \- Red Hat, otwierano: listopada 14, 2025, [https://www.redhat.com/en/blog/ask-an-openshift-admin-office-hour-operator-lifecycle-manager-deepdive](https://www.redhat.com/en/blog/ask-an-openshift-admin-office-hour-operator-lifecycle-manager-deepdive)  
58. Can someone explain the difference between namespaces and project in Kubernetes clearly? \- Reddit, otwierano: listopada 14, 2025, [https://www.reddit.com/r/kubernetes/comments/f9l59p/can\_someone\_explain\_the\_difference\_between/](https://www.reddit.com/r/kubernetes/comments/f9l59p/can_someone_explain_the_difference_between/)  
59. Network Policies \- Kubernetes, otwierano: listopada 14, 2025, [https://kubernetes.io/docs/concepts/services-networking/network-policies/](https://kubernetes.io/docs/concepts/services-networking/network-policies/)  
60. What are the differences between "oc new-project" and "oc create ..., otwierano: listopada 14, 2025, [https://access.redhat.com/solutions/5662561](https://access.redhat.com/solutions/5662561)  
61. What is the difference between objects project and namespace in Openshift 4.x, otwierano: listopada 14, 2025, [https://serverfault.com/questions/1025637/what-is-the-difference-between-objects-project-and-namespace-in-openshift-4-x](https://serverfault.com/questions/1025637/what-is-the-difference-between-objects-project-and-namespace-in-openshift-4-x)  
62. Configuring project creation \- Projects | Building applications | OKD 4.19, otwierano: listopada 14, 2025, [https://docs.okd.io/4.19/applications/projects/configuring-project-creation.html](https://docs.okd.io/4.19/applications/projects/configuring-project-creation.html)  
63. namespaces vs projects : r/openshift \- Reddit, otwierano: listopada 14, 2025, [https://www.reddit.com/r/openshift/comments/78jcpk/namespaces\_vs\_projects/](https://www.reddit.com/r/openshift/comments/78jcpk/namespaces_vs_projects/)  
64. Automating the Template for New OpenShift Projects, otwierano: listopada 14, 2025, [https://blog.andyserver.com/2018/01/automating-template-new-openshift-projects/](https://blog.andyserver.com/2018/01/automating-template-new-openshift-projects/)  
65. How Does a New Project's Resources Get Provisioned? : r/openshift, otwierano: listopada 14, 2025, [https://www.reddit.com/r/openshift/comments/mgp7bz/how\_does\_a\_new\_projects\_resources\_get\_provisioned/](https://www.reddit.com/r/openshift/comments/mgp7bz/how_does_a_new_projects_resources_get_provisioned/)  
66. Chapter 12\. Service Accounts | Developer Guide | OpenShift Container Platform | 3.11, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.11/html/developer\_guide/dev-guide-service-accounts](https://docs.redhat.com/en/documentation/openshift_container_platform/3.11/html/developer_guide/dev-guide-service-accounts)  
67. Chapter 10\. Understanding and creating service accounts | Authentication and authorization | OpenShift Container Platform | 4.8 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/authentication\_and\_authorization/understanding-and-creating-service-accounts](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/authentication_and_authorization/understanding-and-creating-service-accounts)  
68. Chapter 9\. Using service accounts in applications | Authentication and authorization | OpenShift Dedicated | 4 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_dedicated/4/html/authentication\_and\_authorization/using-service-accounts](https://docs.redhat.com/en/documentation/openshift_dedicated/4/html/authentication_and_authorization/using-service-accounts)  
69. Chapter 25\. Setting Limit Ranges | Cluster Administration | OpenShift Container Platform | 3.11 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.11/html/cluster\_administration/admin-guide-limits](https://docs.redhat.com/en/documentation/openshift_container_platform/3.11/html/cluster_administration/admin-guide-limits)  
70. Defining a default network policy for projects \- Network security \- OKD Documentation, otwierano: listopada 14, 2025, [https://docs.okd.io/4.18/networking/network\_security/network\_policy/default-network-policy.html](https://docs.okd.io/4.18/networking/network_security/network_policy/default-network-policy.html)  
71. Chapter 12\. Network policy | Networking | OpenShift Container Platform | 4.9 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.9/html/networking/network-policy](https://docs.redhat.com/en/documentation/openshift_container_platform/4.9/html/networking/network-policy)  
72. Chapter 7\. Configuring network policy with OpenShift SDN \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.1/html/networking/configuring-networkpolicy](https://docs.redhat.com/en/documentation/openshift_container_platform/4.1/html/networking/configuring-networkpolicy)  
73. Quotas and Limit Ranges | Developer Guide | OpenShift Origin Latest \- Huihoo, otwierano: listopada 14, 2025, [https://docs.huihoo.com/openshift/origin-latest/dev\_guide/compute\_resources.html](https://docs.huihoo.com/openshift/origin-latest/dev_guide/compute_resources.html)  
74. Chapter 6\. Differences Between oc and kubectl | CLI Reference | OpenShift Container Platform | 3.11 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.11/html/cli\_reference/cli-reference-differences-oc-kubectl](https://docs.redhat.com/en/documentation/openshift_container_platform/3.11/html/cli_reference/cli-reference-differences-oc-kubectl)  
75. Chapter 6\. Differences Between oc and kubectl | CLI Reference | OpenShift Container Platform | 3.10 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/it/documentation/openshift\_container\_platform/3.10/html/cli\_reference/cli-reference-differences-oc-kubectl](https://docs.redhat.com/it/documentation/openshift_container_platform/3.10/html/cli_reference/cli-reference-differences-oc-kubectl)  
76. OpenShift CLI (oc) \- Arm Learning Paths, otwierano: listopada 14, 2025, [https://learn.arm.com/install-guides/oc/](https://learn.arm.com/install-guides/oc/)  
77. Chapter 3\. Logging in to the cluster | Installing on RHV | OpenShift Container Platform | 4.4 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.4/html/installing\_on\_rhv/cli-logging-in-kubeadmin\_installing-rhv-default](https://docs.redhat.com/en/documentation/openshift_container_platform/4.4/html/installing_on_rhv/cli-logging-in-kubeadmin_installing-rhv-default)  
78. Chapter 3\. Managing CLI Profiles | CLI Reference | OpenShift Container Platform | 3.11 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.11/html/cli\_reference/cli-reference-manage-cli-profiles](https://docs.redhat.com/en/documentation/openshift_container_platform/3.11/html/cli_reference/cli-reference-manage-cli-profiles)  
79. Is there a better way to retrieve a login command? \- openshift \- Reddit, otwierano: listopada 14, 2025, [https://www.reddit.com/r/openshift/comments/141bo2y/is\_there\_a\_better\_way\_to\_retrieve\_a\_login\_command/](https://www.reddit.com/r/openshift/comments/141bo2y/is_there_a_better_way_to_retrieve_a_login_command/)  
80. Key Differences Between Kubernetes and OpenShift | DigitalOcean, otwierano: listopada 14, 2025, [https://www.digitalocean.com/community/questions/key-differences-between-kubernetes-and-openshift](https://www.digitalocean.com/community/questions/key-differences-between-kubernetes-and-openshift)  
81. Deep Dive into OpenShift's 'oc new-app' Command | by Jimin \- Medium, otwierano: listopada 14, 2025, [https://jiminbyun.medium.com/deep-dive-into-openshifts-oc-new-app-command-cc16281e322](https://jiminbyun.medium.com/deep-dive-into-openshifts-oc-new-app-command-cc16281e322)  
82. Creating applications by using the CLI \- OKD Documentation, otwierano: listopada 14, 2025, [https://docs.okd.io/latest/applications/creating\_applications/creating-applications-using-cli.html](https://docs.okd.io/latest/applications/creating_applications/creating-applications-using-cli.html)  
83. oc-start-build(1) — oc \- openSUSE Manpages Server, otwierano: listopada 14, 2025, [https://manpages.opensuse.org/Tumbleweed/oc/oc-start-build.1.en.html](https://manpages.opensuse.org/Tumbleweed/oc/oc-start-build.1.en.html)  
84. Openshift Platform Permissions Best Practice — RBAC | by Tommer Amber \- Medium, otwierano: listopada 14, 2025, [https://medium.com/@tamber/openshift-platform-permissions-best-practice-rbac-d0d9a1c7468f](https://medium.com/@tamber/openshift-platform-permissions-best-practice-rbac-d0d9a1c7468f)  
85. OpenShift \- Add or Remove a Role Binding from a User Group or Service Account, otwierano: listopada 14, 2025, [https://www.freekb.net/Article?id=4182](https://www.freekb.net/Article?id=4182)  
86. What is option \-n for in OpenShift "oc adm policy add-role-to-group" ? \- Stack Overflow, otwierano: listopada 14, 2025, [https://stackoverflow.com/questions/39496795/what-is-option-n-for-in-openshift-oc-adm-policy-add-role-to-group](https://stackoverflow.com/questions/39496795/what-is-option-n-for-in-openshift-oc-adm-policy-add-role-to-group)  
87. 5.6. Adding roles to users | Authentication and authorization | OpenShift Container Platform | 4.5 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/zh-cn/documentation/openshift\_container\_platform/4.5/html/authentication\_and\_authorization/adding-roles\_using-rbac](https://docs.redhat.com/zh-cn/documentation/openshift_container_platform/4.5/html/authentication_and_authorization/adding-roles_using-rbac)  
88. Chapter 10\. Managing Role-based Access Control (RBAC) | Cluster Administration | OpenShift Container Platform \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.11/html/cluster\_administration/admin-guide-manage-rbac](https://docs.redhat.com/en/documentation/openshift_container_platform/3.11/html/cluster_administration/admin-guide-manage-rbac)  
89. Kubernetes Ingress vs OpenShift Route \- Red Hat, otwierano: listopada 14, 2025, [https://www.redhat.com/en/blog/kubernetes-ingress-vs-openshift-route](https://www.redhat.com/en/blog/kubernetes-ingress-vs-openshift-route)  
90. OpenShift/OKD, what is the difference between deployment, service, route, ingress?, otwierano: listopada 14, 2025, [https://stackoverflow.com/questions/75086775/openshift-okd-what-is-the-difference-between-deployment-service-route-ingres](https://stackoverflow.com/questions/75086775/openshift-okd-what-is-the-difference-between-deployment-service-route-ingres)  
91. Understanding the Red Hat OpenShift Build Process: S2I vs Docker Builds | by Pravin More, otwierano: listopada 14, 2025, [https://medium.com/@morepravin1989/understanding-the-red-hat-openshift-build-process-s2i-vs-docker-builds-3ac1a55fc1b0](https://medium.com/@morepravin1989/understanding-the-red-hat-openshift-build-process-s2i-vs-docker-builds-3ac1a55fc1b0)  
92. Chapter 2\. Builds | CI/CD | OpenShift Container Platform | 4.10 | Red ..., otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.10/html/cicd/builds](https://docs.redhat.com/en/documentation/openshift_container_platform/4.10/html/cicd/builds)  
93. Chapter 1\. Understanding image builds | Builds | OpenShift Container Platform | 4.5, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.5/html/builds/understanding-image-builds](https://docs.redhat.com/en/documentation/openshift_container_platform/4.5/html/builds/understanding-image-builds)  
94. OpenShift Concepts, otwierano: listopada 14, 2025, [https://www.rosaworkshop.io/ostoy/2-concepts/](https://www.rosaworkshop.io/ostoy/2-concepts/)  
95. Pod Security Standards (PSS) and Security Context Constraints (SCC) \- NetApp Docs, otwierano: listopada 14, 2025, [https://docs.netapp.com/us-en/trident/trident-reference/pod-security.html](https://docs.netapp.com/us-en/trident/trident-reference/pod-security.html)  
96. Pod Admission and SCCs Version 2 in OpenShift \- Red Hat, otwierano: listopada 14, 2025, [https://www.redhat.com/en/blog/pod-admission-and-sccs-version-2-in-openshift](https://www.redhat.com/en/blog/pod-admission-and-sccs-version-2-in-openshift)  
97. Chapter 15\. Managing security context constraints | Authentication and authorization | OpenShift Container Platform | 4.10 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.10/html/authentication\_and\_authorization/managing-pod-security-policies](https://docs.redhat.com/en/documentation/openshift_container_platform/4.10/html/authentication_and_authorization/managing-pod-security-policies)
