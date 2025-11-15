# Moduł 6: Bezpieczeństwo – „Secure by Default”

---

## Lekcja 6.1: Uwierzytelnianie – Wbudowany Serwer OAuth i Dostawcy Tożsamości (IdP)

### 6.1.1. Rola Wbudowanego Serwera OAuth

Architektura bezpieczeństwa platformy OpenShift rozpoczyna się od rygorystycznego procesu uwierzytelniania. W przeciwieństwie do standardowego Kubernetes, który deleguje uwierzytelnianie na zewnątrz, OpenShift Container Platform (OCP) oraz OpenShift Dedicated (OSD) zawierają wbudowany serwer OAuth.[1, 2, 3] Serwer ten działa jako centralna brama dla wszystkich użytkowników – zarówno deweloperów, jak i administratorów.

Kluczowa rola tego serwera polega na tym, że użytkownicy nie uwierzytelniają się bezpośrednio w API Kubernetes. Zamiast tego, uzyskują oni tokeny dostępu OAuth od serwera OpenShift, a następnie używają tych tokenów do uwierzytelniania swoich żądań do API.[1, 2] Po świeżej instalacji klastra, jedynym dostępnym użytkownikiem jest tymczasowy `kubeadmin`.[2, 4] Dlatego kluczowym zadaniem administratora po instalacji jest skonfigurowanie serwera OAuth w celu zintegrowania go z co najmniej jednym zewnętrznym Dostawcą Tożsamości (IdP), co umożliwi użytkownikom logowanie się i dostęp do klastra.[1, 2]

### 6.1.2. Konfiguracja Dostawców Tożsamości (IdP)

Konfiguracja IdP odbywa się poprzez tworzenie i stosowanie niestandardowych zasobów (Custom Resources - CR), które opisują danego dostawcę.[2, 4] Platforma wspiera szeroki wachlarz standardów korporacyjnych i deweloperskich:

  * **LDAP:** Umożliwia walidację nazw użytkowników i haseł wobec serwera LDAPv3 (np. Active Directory) przy użyciu prostego uwierzytelniania bind.[1, 2]
  * **OpenID Connect (OIDC):** Nowoczesny standard federacji tożsamości, umożliwiający integrację z dowolnym dostawcą zgodnym z OIDC (np. Keycloak, Okta) przy użyciu przepływu Authorization Code Flow.[1] Google jest jednym z przykładów IdP konfigurowanego przez OIDC.[1]
  * **Dostawcy OAuth (GitHub, GitLab):** Pozwala na walidację poświadczeń bezpośrednio wobec serwerów uwierzytelniania GitHub, GitHub Enterprise lub GitLab.[1, 4] Jest to kluczowe dla organizacji zorientowanych na GitOps.
  * **htpasswd:** Umożliwia walidację na podstawie płaskiego pliku `htpasswd` zawierającego hashowane hasła.[2, 4]

### 6.1.3. Filozofia "Secure by Default" w Kontekście IdP

Implementacja filozofii „Secure by Default” jest widoczna w sposobie, w jaki Red Hat pozycjonuje tych dostawców. Podczas gdy dokumentacja OCP (dla wdrożeń on-premise) wymienia `htpasswd` jako standardową opcję [2, 4], dokumentacja dla zarządzanej usługi OpenShift Dedicated (OSD) zawiera krytyczne ostrzeżenie: `htpasswd` jest dołączony *tylko* w celu utworzenia *pojedynczego, statycznego użytkownika administracyjnego* do rozwiązywania problemów i *nie jest wspierany jako dostawca tożsamości do ogólnego użytku*.[1]

To rozróżnienie nie jest przypadkowe. `htpasswd` jest prosty, ale nie skaluje się, nie posiada centralnego zarządzania ani polityk haseł. W usłudze zarządzanej (OSD), gdzie Red Hat gwarantuje bezpieczeństwo i stabilność, użycie `htpasswd` do ogólnego uwierzytelniania jest uznawane za antywzorzec. Platforma domyślnie promuje bezpieczne, scentralizowane i dynamiczne IdP (LDAP, OIDC), degradując statyczne, ryzykowne opcje do roli wyłącznie awaryjnej.

---

## Lekcja 6.2: Autoryzacja – Podstawy Role-Based Access Control (RBAC)

Po pomyślnym uwierzytelnieniu (odpowiedzi na pytanie „Kim jesteś?”), platforma musi odpowiedzieć na drugie, kluczowe pytanie: „Co możesz zrobić?”.[5] W tym miejscu do gry wkracza mechanizm autoryzacji. OpenShift, bazując na Kubernetes, wykorzystuje model Kontroli Dostępu Opartej na Rolach (Role-Based Access Control - RBAC).[5] Obiekty RBAC precyzyjnie określają, czy uwierzytelniony podmiot (użytkownik lub ServiceAccount) ma prawo do wykonania danej akcji w ramach projektu lub całego klastra.

### 6.2.1. Komponenty Modelu RBAC

Model RBAC składa się z trzech podstawowych komponentów [5, 6]:

1.  **Rules (Reguły):** Najmniejsza jednostka uprawnień. Definiuje zestaw dozwolonych czasowników (verbs) (np. `create`, `get`, `list`, `delete`, `patch`) na zestawie obiektów/zasobów (resources) (np. `pods`, `deployments`, `configmaps`).
2.  **Roles (Role):** Kolekcje Reguł. Grupują one reguły w logiczne zestawy uprawnień (np. „uprawnienia dewelopera”).
3.  **Bindings (Wiązania):** Stowarzyszenia (powiązania), które łączą podmiot (Subject) – czyli Użytkownika (User), Grupę (Group) lub Konto Serwisowe (ServiceAccount) – z określoną Rolą.

### 6.2.2. Dwupoziomowa Hierarchia RBAC: Cluster vs. Local

Kluczem do zrozumienia modelu bezpieczeństwa i wielodostępności (multi-tenancy) w OpenShift jest jego dwupoziomowa hierarchia RBAC [5, 6, 7]:

  * **Cluster RBAC (RBAC na Poziomie Klastra):** Obiekty te (tj. `ClusterRole` i `ClusterRoleBinding`) są globalne i mają zastosowanie *we wszystkich projektach* (przestrzeniach nazw) w klastrze.
  * **Local RBAC (RBAC Lokalny/Projektowy):** Obiekty te (tj. `Role` i `RoleBinding`) są ograniczone (scoped) i istnieją *tylko w obrębie pojedynczego projektu*.

Ta dwupoziomowa struktura jest fundamentem efektywnego zarządzania. Dokumentacja stwierdza, że hierarchia ta „pozwala na ponowne wykorzystanie (reuse) w wielu projektach poprzez role klastra, jednocześnie umożliwiając dostosowanie (customization) wewnątrz poszczególnych projektów poprzez role lokalne”.[5]

Mechanizm ten rozwiązuje fundamentalny problem skalowalności uprawnień. Wyobraźmy sobie klaster z 500 projektami (zespołami), gdzie każdy zespół potrzebuje standardowego zestawu uprawnień deweloperskich (np. do tworzenia `ConfigMap`, `Deployment`, `Service`). Bez modelu hierarchicznego, administrator musiałby utworzyć i zarządzać 500 identycznymi, lokalnymi obiektami `Role` (po jednym w każdym projekcie). Aktualizacja tych uprawnień wymagałaby edycji 500 obiektów.

Dzięki modelowi OpenShift, administrator tworzy *jeden* globalny `ClusterRole` (np. `developer-permissions`). Następnie, aby nadać zespołowi A uprawnienia w projekcie A, tworzy *lokalne* `RoleBinding` w projekcie A, które wiąże grupę „Zespół A” z tym *globalnym* `ClusterRole`. Najważniejszą cechą tego modelu jest to, że **`RoleBinding` (Local RBAC) może odwoływać się do `ClusterRole` (Cluster RBAC)**.[5] To połączenie umożliwia „centralną definicję uprawnień” przy jednoczesnej „zdecentralizowanej delegacji dostępu”, co jest esencją „Secure by Default”, minimalizując błędy konfiguracyjne i zapewniając spójność.

---

## Lekcja 6.3: Obiekty RBAC – Definicje i Relacje

Zrozumienie dwupoziomowej hierarchii RBAC wymaga precyzyjnego zdefiniowania czterech kluczowych typów obiektów, które nią zarządzają.

### 6.3.1. Obiekty Definiujące Uprawnienia (Kolekcje Reguł)

  * **Role (Rola):** Jest to obiekt *namespaced*, co oznacza, że istnieje *wewnątrz* konkretnej przestrzeni nazw (projektu). Definiuje uprawnienia (kolekcję reguł) tylko do zasobów w obrębie tej samej przestrzeni nazw.[6, 7]
  * **ClusterRole (Rola Klastra):** Jest to obiekt *globalny* (non-namespaced). Może być używany do definiowania uprawnień na dwa sposoby:
    1.  Do zasobów globalnych, które nie należą do żadnej przestrzeni nazw (np. `nodes`, `clusterroles`, `scc`).
    2.  Do zasobów w przestrzeni nazw (np. `pods`, `services`) w celu ich *ponownego użycia* (reuse) w wielu projektach, jak opisano w Lekcji 6.2.[6, 7]

### 6.3.2. Obiekty Wiążące (Przypisujące Uprawnienia)

  * **RoleBinding (Wiązanie Roli):** Jest to obiekt *namespaced*. Przypisuje uprawnienia (zdefiniowane w `Role` lub `ClusterRole`) podmiotom (Użytkownikom, Grupom, ServiceAccounts) *tylko w obrębie* tej konkretnej przestrzeni nazw, w której `RoleBinding` istnieje.[6, 8]
  * **ClusterRoleBinding (Wiązanie Roli Klastra):** Jest to obiekt *globalny*. Przypisuje uprawnienia (zdefiniowane *tylko* w `ClusterRole`) podmiotom *w całym klastrze*.[6, 8]

### 6.3.3. Wzorce Powiązań

Relacje między tymi obiektami definiują model bezpieczeństwa. Istnieją cztery możliwe kombinacje, ale tylko trzy są praktyczne, a jedna z nich jest dominującym wzorcem:

1.  **`Role` + `RoleBinding` (Lokalna Definicja, Lokalne Przypisanie):** Używane rzadko, tylko do tworzenia bardzo specyficznych, niestandardowych uprawnień, które mają zastosowanie tylko w jednym projekcie i nie nadają się do ponownego użycia.[5]
2.  **`ClusterRole` + `ClusterRoleBinding` (Globalna Definicja, Globalne Przypisanie):** **Najpotężniejsza i najbardziej niebezpieczna** kombinacja. Używana wyłącznie do nadawania globalnych uprawnień administratorom klastra (np. przypisanie `ClusterRole` `cluster-admin` do użytkownika). Błędna konfiguracja tutaj daje podmiotowi dostęp do *wszystkiego* w klastrze.[7]
3.  **`ClusterRole` + `RoleBinding` (Globalna Definicja, Lokalne Przypisanie):** **Najczęstszy i zalecany wzorzec**. Tak właśnie OpenShift zarządza domyślnymi rolami (np. `admin`, `edit`, `view`). Definicja uprawnień (`ClusterRole`) jest jedna, globalna i spójna, ale jest przypisywana (przez `RoleBinding`) *tylko* w kontekście konkretnego projektu.
4.  **`Role` + `ClusterRoleBinding`:** Kombinacja niemożliwa. Globalne `ClusterRoleBinding` nie może odwoływać się do `Role`, ponieważ `Role` istnieje tylko w kontekście przestrzeni nazw, która jest nieznana dla globalnego obiektu.[6, 7]

Model bezpieczeństwa OpenShift jest zbudowany na mistrzowskim wykorzystaniu kombinacji 2 i 3, co pozwala na granularne zarządzanie od poziomu super-administratora (kombinacja 2) do poziomu dewelopera w jednym projekcie (kombinacja 3).

---

## Lekcja 6.4: Domyślne Role w Projekcie – 'admin', 'edit', 'view'

Aby ułatwić zarządzanie i natychmiast wdrożyć zasadę najmniejszych uprawnień (Principle of Least Privilege - PoLP), OpenShift jest dostarczany z zestawem predefiniowanych obiektów `ClusterRole`. Są one gotowe do natychmiastowego użycia w `RoleBinding` (zgodnie ze wzorcem nr 3 z poprzedniej lekcji).[7, 9, 10]

### 6.4.1. Kluczowe Role Domyślne

Trzy najważniejsze domyślne role projektowe to:

  * **`view`:** Rola „tylko do odczytu”. Pozwala użytkownikom na przeglądanie (get, list, watch) większości obiektów w projekcie (np. `pods`, `services`), ale *nie* na ich modyfikowanie. Co ważne, użytkownicy z tą rolą nie mogą również przeglądać obiektów RBAC (takich jak `Roles` czy `RoleBindings`).[10]
  * **`edit`:** Typowa rola „dewelopera”. Pozwala na pełen cykl życia (CRUD) typowych zasobów aplikacyjnych (np. `pods`, `services`, `routes`, `configmaps`). *Nie daje* jednak dostępu do zarządzania uprawnieniami (RBAC), limitami (LimitRanges) ani kwotami (Quotas).[10]
  * **`admin`:** Rola „menedżera projektu” lub „lidera zespołu”. Daje pełną kontrolę nad *wszystkimi* zasobami w projekcie, w tym nad zasobami administracyjnymi, takimi jak kwoty i limity. Co najważniejsze, rola `admin` może zarządzać lokalnymi obiektami `Role` i `RoleBinding`, czyli nadawać i odbierać uprawnienia innym użytkownikom *w obrębie* tego projektu.[10]

Inne kluczowe role domyślne to:

  * **`cluster-admin`:** Super-użytkownik. Może wykonać *dowolną* akcję w *dowolnym* projekcie i na poziomie klastra. Jest to rola używana w `ClusterRoleBinding`.[7, 10]
  * **`basic-user`:** Minimalne uprawnienia pozwalające użytkownikowi na pobieranie podstawowych informacji o projektach i użytkownikach.[7, 10]
  * **`self-provisioner`:** Domyślnie przypisana uwierzytelnionym użytkownikom, pozwala im na tworzenie własnych, nowych projektów.[10]

Poniższa tabela przedstawia matrycę uprawnień dla kluczowych ról, ilustrując wbudowaną segregację obowiązków (Separation of Duties).

**Tabela 1: Matryca Uprawnień dla Domyślnych Ról Projektowych**

| Rola (ClusterRole) | Modyfikacja Zasobów Aplikacji (np. Pods) | Modyfikacja Zasobów Administracyjnych (np. Quotas) | Modyfikacja Lokalnego RBAC (np. RoleBindings) | Zakres Użycia |
| :--- | :--- | :--- | :--- | :--- |
| `view` | Nie (Tylko odczyt) [10] | Nie (Tylko odczyt) | Nie (Tylko odczyt) [10] | Projekt (przez RoleBinding) |
| `edit` | **Tak** [10] | Nie [10] | Nie [10] | Projekt (przez RoleBinding) |
| `admin` | **Tak** [10] | **Tak** [10] | **Tak** [10] | Projekt (przez RoleBinding) |
| `cluster-admin` | **Tak** | **Tak** | **Tak** | **Klaster** (przez ClusterRoleBinding) |

### 6.4.2. Segregacja Obowiązków: `edit` vs `admin`

Istnienie oddzielnych ról `edit` i `admin` jest celowym i kluczowym wyborem architektonicznym wspierającym „Secure by Default”. Najczęstszym użytkownikiem platformy jest deweloper, którego zadaniem jest wdrażanie aplikacji. Zgodnie z PoLP, deweloper (otrzymujący rolę `edit`) nie powinien mieć możliwości modyfikowania własnych uprawnień ani uprawnień kolegów z zespołu.[10]

Gdyby deweloperzy domyślnie otrzymywali rolę `admin`, mogliby (przypadkowo lub celowo) eskalować swoje uprawnienia, na przykład tworząc `RoleBinding` dla swojego konta do roli `cluster-admin` (co dałoby im pełne uprawnienia administratora w tym projekcie). Domyślna rola `edit` jawnie *uniemożliwia* tę ścieżkę ataku, ponieważ nie daje uprawnień do tworzenia `RoleBinding`.[10] OpenShift domyślnie sandboksuje deweloperów do zasobów *aplikacyjnych*, oddzielając ich od zasobów *administracyjnych*.

---

## Lekcja 6.5: Zarządzanie RBAC – Praktyczne Zastosowanie 'oc adm policy'

Zarządzanie RBAC może odbywać się deklaratywnie (za pomocą plików YAML) lub imperatywnie. OpenShift dostarcza potężny zestaw poleceń `oc adm policy`, które umożliwiają administratorom szybkie i skryptowalne zarządzanie powiązaniami RBAC.[8, 11, 12]

Kluczowym poleceniem jest `oc adm policy add-role-to-user`. Przeanalizujmy jego działanie na przykładzie:

`oc adm policy add-role-to-user admin my-user -n my-project` [11]

  * **`oc adm policy add-role-to-user`**: Polecenie nadrzędne do tworzenia powiązania dla podmiotu typu `User`.[8, 11]
  * **`admin`**: Nazwa Roli, która jest przypisywana. W tym przypadku jest to domyślna `ClusterRole` o nazwie `admin`.[11]
  * **`my-user`**: Nazwa podmiotu (Subject), czyli użytkownika, który otrzymuje uprawnienia.
  * **`-n my-project`**: Flaga przestrzeni nazw (projektu).[8, 13] Jest to najważniejszy element tego polecenia, który definiuje jego kontekst jako Local RBAC.

Polecenie `oc adm policy` jest inteligentną abstrakcją, która automatycznie implementuje preferowany wzorzec (Globalna Definicja, Lokalne Przypisanie) omówiony w Lekcji 6.3.

Analiza działania tego polecenia [11] pokazuje, że:

1.  Polecenie *nie* tworzy nowej, lokalnej `Role` o nazwie `admin` w `my-project`.
2.  Zamiast tego, tworzy ono nowy obiekt `RoleBinding.rbac` (wiązanie lokalne) w przestrzeni nazw `my-project`.
3.  Ten nowo utworzony `RoleBinding` odwołuje się (`Role: Kind: ClusterRole, Name: admin`) do istniejącej, globalnej `ClusterRole` o nazwie `admin`.

Narzędzie CLI (`oc`) jest zaprojektowane zgodnie z filozofią „Secure by Default”. Domyślnie prowadzi administratora do stosowania wzorca "globalna definicja, lokalne przypisanie". Użycie flagi `-n` [8] jest tym, co odróżnia tworzenie lokalnego powiązania od tworzenia powiązania globalnego (które wymagałoby innego polecenia, np. `oc adm policy add-cluster-role-to-user`, i nie akceptowałoby flagi `-n`).

---

## Lekcja 6.6: SecurityContextConstraints (SCC) – Kluczowy Wyróżnik OpenShift

Podczas gdy RBAC (Lekcje 6.2-6.5) kontroluje, co *użytkownicy* mogą robić w API, Security Context Constraints (SCC) kontrolują, co *pody* mogą robić w systemie operacyjnym hosta.[14, 15] SCC są zasobami *specyficznymi dla OpenShift* [16, 17] i stanowią jeden z najważniejszych filarów filozofii „Secure by Default”.

### 6.6.1. Definicja i Cel SCC

SCC to kontroler dostępu (admission controller) dla podów.[18] Określa on zestaw warunków, jakie pod musi spełnić, aby zostać uruchomionym w klastrze. Kontrolują one krytyczne z punktu widzenia bezpieczeństwa aspekty systemowe [14, 16, 19]:

  * Czy kontener może być uruchomiony jako uprzywilejowany (`privileged`).
  * Czy kontener może uzyskać dostęp do przestrzeni nazw hosta (np. sieciowej, PID, IPC).
  * Jakie typy woluminów może montować (np. blokując `hostPath`).
  * Z jakim identyfikatorem użytkownika (UID) i grupy (GID) będzie działał proces w kontenerze.
  * Jaki kontekst SELinux zostanie mu przypisany.

### 6.6.2. Podejście Mutujące vs. Walidujące

Fundamentalna różnica filozoficzna między podejściem OpenShift (SCC) a podejściem standardowego Kubernetes (PSA/PSP) leży w koncepcji *mutacji* a *walidacji*.

Standardowy Kubernetes (korzystający z PodSecurityAdmission, Lekcja 6.16) jest *nie-mutujący*.[20] Deweloper wysyła manifest poda. Kontroler PSA *sprawdza* (waliduje) go względem polityki. Jeśli manifest nie jest zgodny (np. nie definiuje `allowPrivilegeEscalation: false`), PSA *odrzuca* poda. Wymaga to od dewelopera jawnego zdefiniowania bezpiecznego kontekstu.

Podejście OpenShift (SCC) jest *proaktywne i mutujące*. Deweloper wysyła ten sam, potencjalnie niezabezpieczony manifest (np. bez zdefiniowanego `securityContext`). Kontroler admisji SCC przechwytuje żądanie. Zamiast je odrzucić, domyślnie stosuje politykę `restricted`.[14] Kontroler *modyfikuje* (mutuje) definicję poda *w locie*, aby był zgodny z tą polityką – w szczególności *przypisuje* mu losowy, nie-rootowy UID z zakresu przydzielonego dla przestrzeni nazw.

Filozofia „Secure by Default” w OpenShift jest proaktywna. Platforma *automatycznie naprawia* (mutuje) obciążenia, aby były bezpieczne, zamiast je po prostu odrzucać. Zwalnia to dewelopera z konieczności bycia ekspertem ds. `securityContext`, jednocześnie *gwarantując* (enforcing) bazowy poziom bezpieczeństwa dla wszystkich uruchamianych obciążeń.

---

## Lekcja 6.7: Analiza Polityki 'restricted' SCC – Blokowanie Uruchomień jako 'root'

Polityka `restricted` SCC jest kamieniem węgielnym bezpieczeństwa OpenShift. Jest to domyślna, najbardziej restrykcyjna polityka SCC stosowana dla większości uwierzytelnionych użytkowników i ich obciążeń.[14, 21, 22, 23]

### 6.7.1. Kluczowe Ograniczenia Polityki `restricted`

Jej kluczowe ograniczenia to [19, 22, 23]:

1.  **Brak uprzywilejowania:** `Ensures that pods cannot run as privileged`. Blokuje kontenery żądające `securityContext.privileged: true`.
2.  **Brak dostępu do hosta:** `Denies access to all host features`. Obejmuje to blokowanie przestrzeni nazw hosta (sieć, PID, IPC) oraz montowania woluminów z katalogów hosta (`host directory volumes`).
3.  **Wymuszenie non-root:** `Requires that a pod is run as a user in a pre-allocated range of UIDs`. Jest to kluczowy mechanizm mutujący (Lekcja 6.6).
4.  **Wymuszenie SELinux:** `Requires that a pod is run with a pre-allocated MCS label`.

Blokowanie uruchomień jako `root` (UID 0) jest krytyczne dla bezpieczeństwa kontenerów. Procesy uprzywilejowane to te działające jako superużytkownik (root) z ID 0 na hoście.[23] Kontener uruchomiony jako `root` lub `privileged` ma uprawnienia roota *wewnątrz* i *na zewnątrz* swojej przestrzeni nazw.[23] Oznacza to, że przełamanie (escape) z takiego kontenera daje atakującemu pełną kontrolę nad węzłem hosta, a potencjalnie nad całym klastrem. Polityka `restricted` eliminuje tę fundamentalną klasę ataku u samego źródła.

### 6.7.2. Problem `CrashLoopBackOff` i Wzorzec GID 0

To rygorystyczne domyślne zachowanie stwarza jednak powszechny problem dla deweloperów. Wiele standardowych obrazów (np. `nginx`, `httpd`) jest zbudowanych w taki sposób, że oczekują uruchomienia jako `root`. Gdy próbują się uruchomić na OpenShift, platforma (zgodnie z `restricted` SCC) nadpisuje ich UID i przypisuje losowy, wysoki numer (np. `1000160000` [24]). Proces w kontenerze, działając jako ten losowy UID, nie może uzyskać dostępu do plików (np. `nginx.conf`), które są własnością `root` (UID 0), co prowadzi do błędu „Permission Denied” i pętli `CrashLoopBackOff`.

Rozwiązanie tego problemu jest eleganckie i ujawnia głębszy mechanizm. Analiza `id` procesu w takim kontenerze [24] często pokazuje: `uid=1000160000 gid=0(root)`. Użytkownik nie jest rootem, ale *jest* w grupie `root` (GID 0). Jak wyjaśniono w [24], GID 0 jest traktowane jako grupa nieuprzywilejowana w tym kontekście. Umożliwia to deweloperom budowanie obrazów kompatybilnych z OpenShift.

Wzorzec „Shift-Left” (Lekcja 6.13) dla Dockerfile w OpenShift wygląda następująco:

```dockerfile
# Jako root, ustaw właścicielem plików grupę root (gid=0) i nadaj jej uprawnienia
USER root
RUN chgrp -R 0 /var/www/html && chmod -R g+rwX /var/www/html
# Przełącz na dowolnego nie-rootowego użytkownika (i tak zostanie nadpisany)
USER 1001
```

Gdy OpenShift uruchomi ten kontener, nadpisze `USER 1001` i ustawi `uid=1000160000`, ale zachowa `gid=0`. Proces (jako UID 1000160000) będzie mógł odczytywać i zapisywać pliki, ponieważ należy do grupy (GID 0), która ma do nich uprawnienia. W ten sposób rygorystyczna polityka bezpieczeństwa *runtime'u* (`restricted` SCC) *bezpośrednio wymusza* na deweloperach stosowanie praktyk „Shift-Left” i budowanie bezpieczniejszych, nieuprzywilejowanych obrazów.[24]

---

## Lekcja 6.8: Porównanie Polityk SCC: 'restricted' vs. 'anyuid' vs. 'privileged'

OpenShift dostarcza domyślne polityki SCC, które reprezentują spektrum od najbardziej restrykcyjnych do najbardziej liberalnych. Zrozumienie trzech kluczowych polityk – `restricted`, `anyuid` i `privileged` – jest kluczowe dla administratora.

  * **`privileged`:** Najbardziej liberalna i niebezpieczna polityka.[22]

      * `allowPrivilegedContainer: true`.
      * Zezwala na dostęp do *wszystkich* funkcji hosta (sieć, PID, IPC) i montowania woluminów hosta (`hostPath`).[22, 25]
      * Zezwala na uruchomienie jako *dowolny* użytkownik (UID), grupa (GID), FSGroup i z *dowolnym* kontekstem SELinux (`RunAsAny`).[22, 25]
      * **Przeznaczenie:** Wyłącznie dla komponentów systemowych i administracyjnych klastra (np. agenci monitoringu, wtyczki CNI/CSI), które *muszą* zarządzać hostem. Należy nadawać ją z najwyższą ostrożnością.[22]

  * **`restricted`:** Najbardziej restrykcyjna polityka domyślna.[22]

      * `allowPrivilegedContainer: false`.
      * Blokuje *wszystkie* funkcje hosta i woluminy hosta.[19, 22]
      * Wymusza uruchomienie jako *prealokowany, nie-rootowy UID* z zakresu przestrzeni nazw (`MustRunAsRange`).[19, 22]
      * **Przeznaczenie:** Domyślna polityka dla wszystkich obciążeń aplikacyjnych użytkowników.[14]

  * **`anyuid`:** Polityka „kompromisowa” lub „tryb zgodności”.[22]

      * Zapewnia wszystkie funkcje bezpieczeństwa `restricted` (np. `allowPrivilegedContainer: false`, brak dostępu do hosta).[14, 22, 26]
      * **Kluczowa różnica:** Zezwala na uruchomienie z *dowolnym UID i GID* (`RunAsAny`).[14, 22, 26] Nie wymusza arbitralnego UID, pozwalając podowi na żądanie uruchomienia z *konkretnym* ID.

Poniższa tabela (oparta na [22, 25]) zapewnia szybki przewodnik decyzyjny.

**Tabela 2: Porównanie Kluczowych Polityk SCC**

| Cecha | `privileged` | `anyuid` | `restricted` |
| :--- | :--- | :--- | :--- |
| `allowPrivilegedContainer` | **Tak** | Nie | Nie |
| Dostęp do Host (PID, IPC, Net) | **Tak** | Nie | Nie |
| Woluminy Hosta | **Tak** | Nie | Nie |
| Strategia `RunAsUser` | `RunAsAny` (Dowolny UID) | `RunAsAny` (Dowolny UID) | `MustRunAsRange` (Arbitralny UID) |
| Wymaga SELinux | `RunAsAny` (Dowolny) | `MustRunAs` (Przydzielony) | `MustRunAs` (Przydzielony) |
| **Typowy Przypadek Użycia** | Administracja klastrem | Aplikacje Legacy (np. baza danych wymagająca UID 999) | Domyślny dla aplikacji |

### 6.8.1. Zastosowanie `anyuid` w Praktyce

Istnienie polityki `anyuid` jest kluczowe dla zarządzania długiem technicznym i starszymi aplikacjami. Rozważmy typowy przepływ pracy: deweloper próbuje wdrożyć obraz (np. `postgres:14`). Wdrożenie kończy się niepowodzeniem, ponieważ domyślna polityka `restricted` SCC próbuje uruchomić je jako `uid=1000170000`, ale obraz `postgres` *musi* działać jako użytkownik `postgres` (np. UID 999), aby mieć dostęp do swoich plików danych.

Administrator ma trzy opcje:

1.  **Złe rozwiązanie:** Nadać SA poda politykę `privileged`. To zadziała, ale jest skrajnie niebezpieczne – baza danych ma teraz pełny dostęp do hosta.[22]
2.  **Dobre rozwiązanie („Shift-Left”):** Zmusić dewelopera do przebudowania obrazu, aby był zgodny z wzorcem `gid=0` (Lekcja 6.7) i działał z arbitralnym UID.
3.  **Rozwiązanie kompromisowe (Dług Techniczny):** Deweloper nie może lub nie chce przebudować obrazu (np. jest to obraz COTS od zewnętrznego dostawcy). Administrator nadaje SA poda politykę `anyuid`.[22]

Polityka `anyuid` jest kluczowym narzędziem dla administratorów OpenShift do zarządzania *wyjątkami bezpieczeństwa*. Pozwala na uruchomienie starszych lub źle zbudowanych obrazów (które wymagają *konkretnego*, ale *nie-rootowego* UID) bez udzielania im katastrofalnych uprawnień `privileged`.

---

## Lekcja 6.9: Mapowanie SCC do Podów poprzez ServiceAccount (SA)

Pod *nigdy* nie żąda SCC po nazwie (np. `sccName: anyuid` w manifeście). Zamiast tego, SCC jest mu *przypisywany* przez kontroler admisji w sposób pośredni.[18] Centralnym elementem łączącym świat RBAC (kto co może) ze światem SCC (co pody mogą robić) jest **ServiceAccount (SA)**.

Proces admisji i mapowania przebiega następująco:

1.  Deweloper tworzy manifest poda (lub Deployment itp.). Manifest ten określa `serviceAccountName: <nazwa-sa>` (lub używa `default`, jeśli nie określono).[18, 27]
2.  Administrator (wcześniej) powiązał uprawnienia do używania konkretnych SCC z tym SA.
3.  To powiązanie odbywa się w całości za pomocą mechanizmów **RBAC**.[16, 18] Administrator tworzy `Role` (lub `ClusterRole`), które zawiera regułę z `verb: use` na zasobie `scc` i `resourceName: <nazwa-scc>` (np. `resourceName: anyuid`).[16]
4.  Następnie administrator tworzy `RoleBinding` (lub `ClusterRoleBinding`), aby powiązać tę `Role` z `ServiceAccount`.[16]
5.  Gdy pod jest tworzony (krok 1), kontroler admisji OpenShift patrzy na `serviceAccountName` poda.
6.  Sprawdza wszystkie `RoleBindings` i `ClusterRoleBindings` (RBAC), aby znaleźć wszystkie SCC, do których dany SA ma uprawnienia `use`.
7.  Z tej listy dostępnych SCC, kontroler wybiera *najbardziej restrykcyjną*, która nadal *pozwala* na uruchomienie poda (na podstawie pól `securityContext` w manifeście poda lub domyślnych wartości).
8.  Jeśli żaden dostępny SCC nie pasuje (np. SA ma tylko `restricted`, a pod żąda `privileged: true`), pod jest *odrzucany*.

Tożsamość Poda (SA) jest kluczem. Bezpieczeństwo jest zarządzane nie poprzez edycję podów, ale poprzez zarządzanie *uprawnieniami tożsamości poda* (SA) za pomocą standardowych narzędzi RBAC. Jest to elegancki, abstrakcyjny model, który wspiera automatyzację i GitOps. Zamiast zmieniać SCC, administrator po prostu zmienia `RoleBinding` dla SA, aby przyznać mu dostęp do innej polityki (np. z `restricted` na `anyuid`).

---

## Lekcja 6.10: Podstawy ServiceAccount (SA) – Tożsamość dla Aplikacji

ServiceAccount (SA) zapewnia tożsamość dla *procesów* (a nie dla ludzi), które działają wewnątrz Poda.[28, 29] Jest to kluczowy obiekt API, który umożliwia komponentom (np. aplikacji w kontenerze, kontrolerowi replikacji) uwierzytelnianie się i interakcję z API Kubernetes/OpenShift bez konieczności używania poświadczeń zwykłego użytkownika.[29] Przykłady obejmują aplikację monitorującą, która musi odpytywać API o listę podów, lub kontroler replikacji, który musi tworzyć nowe pody.[29]

Każdy SA ma unikalną nazwę użytkownika w formacie: `system:serviceaccount:<project>:<name>`.[29, 30]

### 6.10.1. Sekrety Powiązane z SA

Gdy tworzone jest SA, platforma automatycznie generuje i kojarzy z nim dwa kluczowe sekrety [29, 31]:

1.  **Sekret Tokena API:** Służy do uwierzytelniania w API Kubernetes.
2.  **Sekret Rejestru:** Poświadczenia (credentials) dla wewnętrznego rejestru obrazów OpenShift.

Sekrety te są następnie automatycznie montowane (jako woluminy) do podów, które używają danego SA, umożliwiając im natychmiastową komunikację z API i rejestrem.

### 6.10.2. Ewolucja Bezpieczeństwa Tokenów

Sposób zarządzania tokenami API dla SA przeszedł znaczną ewolucję w kierunku „Secure by Default”. Starsze dokumentacje [29, 31] wspominają o automatycznie generowanych tokenach, które *nie wygasają* (non-expiring). Jest to znaczące ryzyko bezpieczeństwa: jeśli taki statyczny token zostanie skradziony z sekretu, atakujący ma stały dostęp (ograniczony jedynie przez RBAC danego SA).

Nowoczesne wersje Kubernetes i OpenShift (od OCP 4.11+) [29] wprowadzają i preferują „powiązane tokeny konta serwisowego” (Bound Service Account Tokens). Są to tokeny krótkotrwałe, montowane bezpośrednio do poda jako wolumin typu `projected`. Ich kluczowe cechy bezpieczeństwa [29] to:

  * **Ograniczony czas życia (Bounded lifetime):** Tokeny te wygasają i są automatycznie rotowane przez platformę.
  * **Powiązanie z obiektem:** Ich żywotność jest powiązana z żywotnością poda. Gdy pod jest usuwany, token jest unieważniany.

Platforma aktywnie ewoluuje, odchodząc od ryzykownych, statycznych tokenów na rzecz bezpieczniejszych, automatycznie rotowanych tokenów powiązanych z obciążeniem, co drastycznie zmniejsza powierzchnię ataku w przypadku kompromitacji.

---

## Lekcja 6.11: Domyślne Konta Serwisowe – 'default', 'builder', 'deployer'

Filozofia „Secure by Default” w OpenShift jest głęboko osadzona w automatyzacji. Każdy nowo utworzony projekt automatycznie otrzymuje trzy kluczowe obiekty ServiceAccount, z których każdy ma precyzyjnie zdefiniowany, minimalny zestaw uprawnień (PoLP).[29, 31] Ta domyślna segregacja obowiązków (SoD) jest kluczowa dla bezpieczeństwa procesów CI/CD.

1.  **`builder`:**

      * **Użycie:** Używany przez pody budujące (Build Pods), które kompilują kod (np. S2I - Source-to-Image) i tworzą obrazy kontenerów.[29, 31]
      * **Rola:** Domyślnie otrzymuje rolę `system:image-builder`. Kluczowym uprawnieniem tej roli jest możliwość *wypychania* (push) obrazów do wewnętrznego rejestru obrazów (ImageStream) w danym projekcie.[29, 31]

2.  **`deployer`:**

      * **Użycie:** Używany przez pody wdrożeniowe, które zarządzają procesem wdrażania (np. w ramach strategii DeploymentConfig).[29, 31, 32]
      * **Rola:** Domyślnie otrzymuje rolę `system:deployer`. Kluczowym uprawnieniem tej roli jest możliwość *przeglądania i modyfikowania* kontrolerów replikacji i podów w projekcie.[29, 32]

3.  **`default`:**

      * **Użycie:** Domyślna tożsamość. Używana przez *wszystkie inne pody* (tj. pody aplikacyjne), które nie określają jawnie `serviceAccountName` w swoim manifeście.[27, 29, 31, 32]
      * **Rola:** Domyślnie ma bardzo ograniczone uprawnienia.

**Wspólne Uprawnienia:**
Wszystkie trzy SA (oraz wszelkie nowe SA utworzone w projekcie) automatycznie otrzymują rolę `system:image-puller`.[29, 31] Pozwala to każdemu podowi na *pobieranie* (pull) obrazów z wewnętrznego rejestru (ImageStream) *w tym samym projekcie*.

Ta automatyczna segregacja obowiązków jest doskonałym przykładem PoLP w praktyce. Platforma nie używa jednego "super-SA" do wszystkich zadań. Gdyby atakujący skompromitował działającą aplikację (uruchomioną jako SA `default`), skradziony token API nie pozwoliłby mu na:

  * Zbudowanie i wypchnięcie nowego, złośliwego obrazu (ponieważ `default` SA brakuje roli `system:image-builder`).
  * Przejęcie kontroli nad procesem wdrażania (ponieważ `default` SA brakuje roli `system:deployer`).

Promień rażenia (blast radius) w przypadku kompromitacji poda aplikacyjnego jest, domyślnie, drastycznie ograniczony.

---

## Lekcja 6.12: Zarządzanie Sekretami – Przypisywanie Image Pull Secrets do ServiceAccount

Domyślne uprawnienia (Lekcja 6.11) pozwalają na pobieranie obrazów z *wewnętrznego* rejestru OpenShift. Jednak w scenariuszach korporacyjnych, aplikacje często zależą od obrazów przechowywanych w *prywatnych, zewnętrznych* rejestrach (np. Docker Hub, Red Hat Quay.io, Artifactory). Aby pobrać taki obraz, pod potrzebuje poświadczeń (tokena lub pary login/hasło).[33]

Administrator musi najpierw utworzyć `Secret` typu `kubernetes.io/dockerconfigjson`, który zawiera te poświadczenia. Następnie ma dwie metody dostarczenia tego sekretu do poda [34]:

1.  **Metoda 1 (Jawna, w Podzie):** Deweloper jawnie dodaje sekcję `imagePullSecrets: [name: <pull_secret_name>]` do specyfikacji Poda (lub Deploymentu).
2.  **Metoda 2 (Abstrakcyjna, w SA):** Administrator *łączy* (links) sekret z ServiceAccount. Każdy pod używający tego SA *automatycznie* otrzyma ten `imagePullSecret`, bez konieczności jawnego definiowania go w manifeście poda.

Metoda 2 jest implementowana za pomocą prostego polecenia [34, 35]:
`oc secrets link <sa-name> <pull_secret_name> --for=pull`

Na przykład, aby umożliwić wszystkim domyślnym podom aplikacyjnym pobieranie obrazów z prywatnego rejestru, administrator wykona:
`oc secrets link default my-docker-hub-secret --for=pull`

Stan ten można zweryfikować, sprawdzając definicję YAML konta serwisowego (`oc get serviceaccount default -o yaml`), gdzie sekret pojawi się na liście `imagePullSecrets`.[34]

Metoda 2 (łączenie z SA) jest fundamentalnie bezpieczniejsza i bardziej zgodna z filozofią „Secure by Default” oraz praktykami DevSecOps. Metoda 1 (jawna w podzie) jest problematyczna: wymaga, aby deweloper znał nazwę sekretu (co może być wyciekiem informacji) i pamiętał o dodaniu go do *każdego* manifestu wdrożenia.

Metoda 2 tworzy czystą abstrakcję. Administrator jest odpowiedzialny za *jednorazowe* skonfigurowanie projektu i powiązanie sekretu z SA (można to nawet zautomatyzować w szablonie projektu [35]). Deweloper po prostu wdraża aplikację, używając `default` SA. Platforma OpenShift *automatycznie wstrzykuje* niezbędne `imagePullSecrets` (zdefiniowane w SA) do definicji poda podczas jego tworzenia. Deweloper nie musi (i nie powinien) zarządzać poświadczeniami ani nawet znać ich nazw.

---

## Lekcja 6.13: Koncepcja 'Shift-Left' Security w Kontekście DevSecOps

„Shift-Left” Security jest fundamentalną zasadą nowoczesnej praktyki DevSecOps.[36] Nazwa odnosi się do osi czasu Cyklu Życia Oprogramowania (SDLC), wizualizowanego jako proces od lewej (planowanie, kodowanie) do prawej (wdrożenie, utrzymanie). „Shift-Left” oznacza przesuwanie zagadnień, testów i walidacji bezpieczeństwa jak najwcześniej – czyli „w lewo” – w tym procesie.[37, 38]

Jest to strategiczne przejście od modelu *reaktywnego* (np. łatanie podatności wykrytych w produkcji) do modelu *proaktywnego* (np. zapobieganie wprowadzeniu podatności do kodu).[39] W kontekście kontenerów i OpenShift, praktyki „Shift-Left” obejmują [38, 39, 40]:

  * **Static Application Security Testing (SAST):** Skanowanie kodu źródłowego (np. Javy, Pythona) pod kątem wzorców podatności, takich jak wstrzyknięcie SQL.[37]
  * **Software Composition Analysis (SCA):** Skanowanie zależności (np. `pom.xml`, `package.json`) pod kątem znanych podatności (CVE) w bibliotekach firm trzecich.
  * **Skanowanie Obrazów Kontenerów:** Skanowanie obrazów (np. `Dockerfile`, gotowych obrazów) pod kątem znanych podatności w pakietach systemu operacyjnego lub bibliotekach *przed* wypchnięciem ich do rejestru lub wdrożeniem na klaster.

Główną korzyścią jest drastyczne obniżenie kosztu naprawy.[37, 38] Znalezienie i naprawienie luki w kodzie, który deweloper właśnie napisał, jest tysiące razy tańsze i szybsze niż koordynowanie awaryjnej poprawki w systemie produkcyjnym.

Polityki bezpieczeństwa OpenShift (SCC, Lekcja 6.7) działają jako potężny, *wymuszający* mechanizm dla praktyk „Shift-Left”. Deweloper może zignorować zalecenia bezpieczeństwa i zbudować obraz, który wymaga uruchomienia jako `root` (UID 0). Potok CI/CD (bez skanowania) może zbudować i wypchnąć ten obraz. Jednak w momencie próby wdrożenia na OpenShift, kontroler admisji SCC przechwyci poda. Zastosuje politykę `restricted` [14], nadpisze UID na losowy i wdrożenie *zakończy się niepowodzeniem* (CrashLoopBackOff z błędem „Permission Denied”).

W ten sposób rygorystyczne bezpieczeństwo *runtime'u* („Secure by Default”) w OpenShift *wymusza* na zespołach deweloperskich przyjęcie praktyk „Shift-Left”. Nie mogą one dłużej ignorować bezpieczeństwa budowanych obrazów (np. zasady non-root). Platforma tworzy pętlę sprzężenia zwrotnego: „Twoje wdrożenie zawiodło, ponieważ obraz jest niezgodny z polityką bezpieczeństwa. Wróć, napraw obraz (zastosuj „Shift-Left”) i spróbuj ponownie”.

---

## Lekcja 6.14: Skanowanie Obrazów: Red Hat Quay i Komponent Clair

Jedną z metod implementacji „Shift-Left” jest użycie zintegrowanego stosu technologicznego Red Hat, który składa się z rejestru Red Hat Quay oraz zintegrowanego silnika skanowania Clair.

  * **Red Hat Quay:** Jest to prywatny, korporacyjny rejestr obrazów kontenerów, zaprojektowany do przechowywania i dystrybucji obrazów w organizacji.[41]
  * **Clair:** Jest to silnik skanowania podatności o otwartym kodzie źródłowym, zwykle wdrażany jako zestaw mikrousług, który jest głęboko *zintegrowany* z Quay.[41, 42, 43] Clair (obecnie w wersji V4, zastępującej V2 [44]) wykonuje statyczną analizę obrazów kontenerów w celu wykrycia znanych podatności (CVE).[41]

Proces skanowania jest zautomatyzowany: gdy nowy obraz jest wypychany (`docker push`) do rejestru Quay, Quay automatycznie uruchamia skanowanie za pomocą Clair.[43] Clair analizuje warstwy obrazu, identyfikuje pakiety systemu operacyjnego (np. RPM, DEB) oraz zależności aplikacji (np. Python, Java, Node.js), a następnie porównuje je z aktualizowanymi na bieżąco bazami danych podatności.[41] Wyniki są następnie udostępniane w interfejsie użytkownika Quay, dostarczając deweloperom i zespołom bezpieczeństwa natychmiastowy raport o stanie obrazu.

Podczas wdrażania Quay na platformie OpenShift, *zdecydowanie zalecaną* metodą jest użycie **Operatora Quay**.[41] Jest to kluczowy element strategii „Secure by Default”. Zamiast ręcznej, skomplikowanej instalacji i konfiguracji obu komponentów, administrator po prostu instaluje Operator Quay. Operator ten automatycznie wdraża i konfiguruje *zarówno* Quay, jak i Clair, zapewniając, że skanowanie bezpieczeństwa jest włączone i poprawnie skonfigurowane „out-of-the-box”.[41]

Tworzy to kompletny, zautomatyzowany i bezpieczny łańcuch dostaw oprogramowania: deweloper (lub potok CI) wypycha obraz do Quay, a Quay/Clair automatycznie go skanuje. Następnie, kontrolery admisji w OpenShift mogą być skonfigurowane tak, aby *blokowały* pobieranie (pull) obrazów z Quay, które posiadają krytyczne podatności, domykając pętlę DevSecOps.

---

## Lekcja 6.15: Integracja Skanowania w Potoku CI/CD – Przykład z Użyciem Trivy

Alternatywnym (lub uzupełniającym) podejściem do zintegrowanego rejestru (Quay) jest integracja skanowania podatności bezpośrednio z potokiem CI/CD. Pozwala to na jeszcze wcześniejsze wykrywanie problemów – zanim obraz w ogóle trafi do rejestru.

W ekosystemie OpenShift, natywnym rozwiązaniem CI/CD jest **OpenShift Pipelines**, które bazuje na projekcie **Tekton**. W połączeniu z popularnym skanerem open-source, takim jak **Trivy** [39, 45, 46], można zbudować wysoce bezpieczny potok.

Potok Tekton (zdefiniowany jako `Pipeline` w YAML) składa się z zadań (Tasks). Potok `ci-pipeline` opisany w [47] implementuje wyrafinowaną strategię „obrony w głąb” (Defense in Depth) poprzez uruchamianie zadania `trivy-scan` w wielu krytycznych punktach:

1.  **Skanowanie Artefaktów:** Po zbudowaniu artefaktu (np. pliku `.jar`), ale *przed* zbudowaniem obrazu Docker. Wykrywa to podatności w bibliotekach (np. `log4j`). Jest to *najszybsza i najtańsza* pętla informacji zwrotnej dla dewelopera, który może naprawić `pom.xml` lub `package.json` bez kosztownego przebudowywania obrazu.
2.  **Skanowanie Lokalne Obrazu:** Po zbudowaniu obrazu lokalnie przez potok. Wykrywa to podatności w *obrazie bazowym* (np. podatny `curl` lub `openssl` w `FROM debian:10`). Jest to drugi poziom obrony, sprawdzający warstwy systemu operacyjnego.
3.  **Skanowanie Zdalne Obrazu:** Po wypchnięciu obrazu do zdalnego repozytorium (np. Artifactory, Quay). Działa to jako ostateczna *walidacja* i *punkt audytu*. Potwierdza, że obraz w rejestrze (tzw. „złoty obraz”) jest dokładnie tym, co zostało przeskanowane i jest wolny od luk. Ten raport ze skanowania może być następnie użyty przez kontrolery admisji do zablokowania wdrożenia.[40]

To wielopunktowe skanowanie nie jest redundancją. Jest to dojrzała praktyka DevSecOps, która stosuje „obronę w głąb”, dostarczając odpowiednich informacji zwrotnych na odpowiednim etapie, minimalizując tarcie dla deweloperów, jednocześnie maksymalizując bezpieczeństwo.

---

## Lekcja 6.16: Ewolucja Zabezpieczeń Kubernetes: PodSecurityAdmission (PSA) vs. PodSecurityPolicy (PSP)

Aby zrozumieć nowoczesne podejście OpenShift do bezpieczeństwa podów, konieczny jest kontekst historyczny ewolucji standardów Kubernetes.

Przez wiele lat, standardowym mechanizmem Kubernetes do egzekwowania polityk bezpieczeństwa podów był `PodSecurityPolicy` (PSP). PSP został jednak oficjalnie *zastrzeżony* (deprecated) w Kubernetes v1.21 [48, 49] i *całkowicie usunięty* w v1.25.[48, 50, 51] Głównymi przyczynami były: wysoka złożoność konfiguracji i zarządzania, brak elastyczności [52] oraz trudny do przewidzenia, *mutujący* (mutating) charakter, który często prowadził do nieoczekiwanych problemów z wdrożeniami.[20]

PSP został zastąpiony przez nowy, wbudowany kontroler admisji o nazwie `PodSecurityAdmission` (PSA).[48, 50, 53, 54] Kluczową różnicą jest to, że PSA jest *nie-mutujący*.[20] Nie modyfikuje on podów; jedynie je waliduje.

PSA egzekwuje zestaw predefiniowanych polityk zwanych **Pod Security Standards (PSS)**.[48, 55] Istnieją trzy oficjalne profile (poziomy) PSS [55, 56, 57]:

1.  **`privileged`:** Najmniej restrykcyjny. Zasadniczo wyłącza wszystkie zabezpieczenia i zezwala na znane eskalacje uprawnień.
2.  **`baseline`:** Minimalnie restrykcyjny. Blokuje znane wektory eskalacji uprawnień, ale poza tym jest dość liberalny (np. nadal pozwala na uruchomienie jako root).
3.  **`restricted`:** Najbardziej restrykcyjny. Wymusza najlepsze praktyki bezpieczeństwa (np. uruchomienie jako non-root, blokowanie eskalacji, ograniczone woluminy).

Wprowadzenie PSA przez upstream Kubernetes stworzyło dla OpenShift fundamentalny problem zgodności. Model bezpieczeństwa OpenShift od zawsze opierał się na *własnym*, potężnym i *mutującym* mechanizmie: SecurityContextConstraints (SCC) (Lekcja 6.6).

Red Hat stanął przed dylematem: Jak zachować zgodność z upstream Kubernetes (PSA) i jednocześnie utrzymać swój nadrzędny, sprawdzony i bardziej granularny (np. `anyuid`) model bezpieczeństwa (SCC)? Gdyby OpenShift po prostu włączył PSA z domyślnym `enforce=restricted`, *wszystkie* mechanizmy mutujące SCC (np. automatyczne przypisywanie UID) przestałyby działać, ponieważ nie-mutujący PSA odrzucałby te pody, zanim SCC zdążyłby je naprawić. Rozwiązanie tego dylematu jest opisane w Lekcji 6.18.

---

## Lekcja 6.17: Implementacja PSA – Etykiety 'warn', 'enforce' i 'audit' na Poziomie Namespace

Mechanizm konfiguracyjny `PodSecurityAdmission` (PSA) jest radykalnie prostszy niż w przypadku `PodSecurityPolicy` (PSP). Zamiast złożonych obiektów RBAC i powiązań, PSA jest konfigurowany wyłącznie poprzez *dodawanie etykiet* do obiektu `Namespace`.[50, 55, 58]

Konfiguracja ta pozwala administratorowi określić, który *profil* PSS (`privileged`, `baseline` lub `restricted`) ma być zastosowany dla każdego z trzech *trybów* (modes) działania.[55, 57]

**Trzy Tryby (Modes) Działania PSA:**

1.  **`enforce`:** Tryb blokujący. Naruszenia polityki powodują *natychmiastowe odrzucenie* poda przez API serwer.
      * Etykieta: `pod-security.kubernetes.io/enforce: <profil>`
2.  **`audit`:** Tryb audytu. Naruszenia polityki są *dozwolone*, ale każde zdarzenie naruszenia jest *rejestrowane* w logu audytu API serwera do późniejszej analizy.
      * Etykieta: `pod-security.kubernetes.io/audit: <profil>`
3.  **`warn`:** Tryb ostrzegawczy. Naruszenia polityki są *dozwolone*, ale użytkownik (lub system CI/CD) tworzący poda otrzymuje *natychmiastowe ostrzeżenie* (warning) w konsoli lub odpowiedzi API.
      * Etykieta: `pod-security.kubernetes.io/warn: <profil>`

Administrator może mieszać te tryby, np. egzekwować (enforce) poziom `baseline` (aby blokować znane eskalacje), ale tylko ostrzegać (warn) i audytować (audit) na poziomie `restricted`, aby zebrać dane o niezgodności bez blokowania wdrożeń.[58]

Kluczową cechą PSA jest jego nie-mutujący charakter.[20] Jeśli przestrzeń nazw ma etykietę `pod-security.kubernetes.io/enforce=restricted`, a deweloper wyśle manifest poda, który nie jest *już* zgodny z tą polityką (np. nie ma `runAsNonRoot: true`), kontroler PSA *odrzuci* poda.[57] Przenosi to 100% odpowiedzialności za zgodność na dewelopera lub potok CI/CD, co jest fundamentalnie sprzeczne z filozofią „automatycznej naprawy” (mutacji) stosowaną przez SCC w OpenShift.

---

## Lekcja 6.18: Synchronizacja SCC i PSA w OpenShift – Rola Etykiety 'podSecurityLabelSync'

OpenShift (od wersji 4.11+) implementuje eleganckie rozwiązanie, które harmonizuje jego własny, mutujący model SCC z nie-mutującym standardem Kubernetes PSA. Platforma uruchamia *oba* kontrolery admisji [59], ale inteligentnie nimi zarządza, aby zachować zgodność i bezpieczeństwo.

Rozwiązanie to składa się z dwóch części:

**1. Globalna Konfiguracja PSA (Wyłączenie Blokowania)**
Domyślna, globalna konfiguracja PSA w OpenShift jest ustawiona następująco [57, 60]:

  * `enforce: privileged`
  * `warn: restricted`
  * `audit: restricted`

Ustawienie `enforce: privileged` jest kluczowe. Oznacza to, że kontroler PSA *domyślnie niczego nie blokuje*. Faktyczne *blokowanie* (enforcement) jest nadal w całości obsługiwane przez *nadrzędny* i bardziej granularny kontroler SCC (Lekcja 6.6).

**2. Kontroler Synchronizacji Etykiet (Zarządzanie Ostrzeżeniami)**
OpenShift wprowadza dodatkowy, specjalny kontroler, który *synchronizuje* stan uprawnień SCC z etykietami PSA.[60, 61, 62] Proces ten, kontrolowany przez etykietę `security.openshift.io/scc.podSecurityLabelSync: "true"` [57, 61], działa następująco:

1.  Kontroler synchronizacji stale monitoruje wszystkie `ServiceAccounts` w danej przestrzeni nazw.
2.  Sprawdza, do jakich polityk SCC te SA mają dostęp (poprzez RBAC, jak w Lekcji 6.9).
3.  Identyfikuje *najbardziej liberalną* politykę SCC, do której dostęp ma *jakikolwiek* SA w tej przestrzeni nazw (np. `restricted`, `anyuid`, `privileged`).
4.  *Mapuje* tę politykę SCC na jej najbliższy odpowiednik profilu PSA (np. `restricted` SCC -\> `restricted` PSA; `anyuid` SCC -\> `baseline` PSA; `privileged` SCC -\> `privileged` PSA).
5.  Na koniec, *automatycznie ustawia* etykiety `pod-security.kubernetes.io/warn` i `pod-security.kubernetes.io/audit` w tej przestrzeni nazw na ten zmapowany, najwyższy profil.[60, 61, 62]

**Efekt Końcowy (Harmonia Systemów):**

Ten mechanizm synchronizacji jest genialnym rozwiązaniem, które zachowuje filozofię „Secure by Default” OpenShift, jednocześnie zapewniając pełną zgodność ze standardem K8s (PSA).

Rozważmy przykład z Lekcji 6.8: administrator chce zezwolić na uruchomienie obrazu `postgres` (wymagającego UID 999) w projekcie `legacy-app`.

1.  Administrator zarządza bezpieczeństwem *tylko w jeden sposób*: poprzez SCC/RBAC. Nadaje `default` SA w projekcie `legacy-app` uprawnienia `use` do polityki `anyuid` SCC.
2.  Kontroler synchronizacji [60] natychmiast to wykrywa. Widzi, że najwyższym uprawnieniem w projekcie jest `anyuid`.
3.  Mapuje `anyuid` na profil `baseline` PSA.
4.  Automatycznie zmienia etykiety przestrzeni nazw na: `pod-security.kubernetes.io/warn=baseline` i `pod-security.kubernetes.io/audit=baseline`.
5.  Gdy deweloper wdraża poda `postgres`:
    a.  Kontroler **SCC** (mutujący) widzi, że SA ma `anyuid` i *zezwala* na uruchomienie poda z UID 999. Pod *działa*.
    b.  Kontroler **PSA** (nie-mutujący) widzi ten sam pod. Sprawdza go względem etykiet `warn` i `audit` (ustawionych na `baseline`). Pod jest zgodny z `baseline`. PSA *nie generuje żadnych ostrzeżeń ani logów audytu*.

System jest *cichy*. Administratorzy nie są zalewani fałszywymi alarmami PSA dla podów, które *jawnie* zatwierdzili za pomocą bardziej granularnego systemu SCC. OpenShift używa SCC do *egzekwowania* polityki, a zsynchronizowanego PSA do *raportowania zgodności* ze standardami K8s. Jest to idealna harmonia między własną, nadrzędną filozofią bezpieczeństwa a zgodnością z otwartym standardem.

---

## Cytowane prace

1. Chapter 4\. Configuring identity providers | Authentication and ..., otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_dedicated/4/html/authentication\_and\_authorization/sd-configuring-identity-providers](https://docs.redhat.com/en/documentation/openshift_dedicated/4/html/authentication_and_authorization/sd-configuring-identity-providers)  
2. Chapter 6\. Understanding identity provider configuration | Authentication and authorization | OpenShift Container Platform | 4.9 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.9/html/authentication\_and\_authorization/understanding-identity-provider](https://docs.redhat.com/en/documentation/openshift_container_platform/4.9/html/authentication_and_authorization/understanding-identity-provider)  
3. Chapter 13\. Configuring authentication and user agent | Configuring Clusters | OpenShift Container Platform | 3.11 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.11/html/configuring\_clusters/install-config-configuring-authentication](https://docs.redhat.com/en/documentation/openshift_container_platform/3.11/html/configuring_clusters/install-config-configuring-authentication)  
4. Chapter 7\. Configuring identity providers | Authentication and authorization | OpenShift Container Platform | 4.8 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/authentication\_and\_authorization/configuring-identity-providers](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/authentication_and_authorization/configuring-identity-providers)  
5. Chapter 8\. Using RBAC to define and apply permissions ..., otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.18/html/authentication\_and\_authorization/using-rbac](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/authentication_and_authorization/using-rbac)  
6. Chapter 8\. Using RBAC to define and apply permissions ..., otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/authentication\_and\_authorization/using-rbac](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/authentication_and_authorization/using-rbac)  
7. Chapter 7\. Using RBAC to define and apply permissions | Authentication and authorization | OpenShift Dedicated | 4 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_dedicated/4/html/authentication\_and\_authorization/using-rbac](https://docs.redhat.com/en/documentation/openshift_dedicated/4/html/authentication_and_authorization/using-rbac)  
8. Chapter 10\. Managing Role-based Access Control (RBAC) | Cluster Administration | OpenShift Container Platform \- Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.11/html/cluster\_administration/admin-guide-manage-rbac](https://docs.redhat.com/en/documentation/openshift_container_platform/3.11/html/cluster_administration/admin-guide-manage-rbac)  
9. Working with projects \- Projects | Building applications | OKD 4.19 \- OKD Documentation, otwierano: listopada 15, 2025, [https://docs.okd.io/4.19/applications/projects/working-with-projects.html](https://docs.okd.io/4.19/applications/projects/working-with-projects.html)  
10. How to customize OpenShift roles for RBAC permissions \- Red Hat, otwierano: listopada 15, 2025, [https://www.redhat.com/en/blog/rbac-openshift-role](https://www.redhat.com/en/blog/rbac-openshift-role)  
11. 5.6. Adding roles to users | Authentication and authorization ..., otwierano: listopada 15, 2025, [https://docs.redhat.com/zh-cn/documentation/openshift\_container\_platform/4.5/html/authentication\_and\_authorization/adding-roles\_using-rbac](https://docs.redhat.com/zh-cn/documentation/openshift_container_platform/4.5/html/authentication_and_authorization/adding-roles_using-rbac)  
12. Chapter 3\. User and Role Management | Administrator Solutions | OpenShift Container Platform | 3.7 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.7/html/administrator\_solutions/user-and-role-management](https://docs.redhat.com/en/documentation/openshift_container_platform/3.7/html/administrator_solutions/user-and-role-management)  
13. What is option \-n for in OpenShift "oc adm policy add-role-to-group" ? \- Stack Overflow, otwierano: listopada 15, 2025, [https://stackoverflow.com/questions/39496795/what-is-option-n-for-in-openshift-oc-adm-policy-add-role-to-group](https://stackoverflow.com/questions/39496795/what-is-option-n-for-in-openshift-oc-adm-policy-add-role-to-group)  
14. Red Hat OpenShift security context constraints \- IBM Cloud Docs, otwierano: listopada 15, 2025, [https://cloud.ibm.com/docs/openshift?topic=openshift-openshift\_scc](https://cloud.ibm.com/docs/openshift?topic=openshift-openshift_scc)  
15. SCC Overview \- KodeKloud Notes, otwierano: listopada 15, 2025, [https://notes.kodekloud.com/docs/OpenShift-4/Openshift-Security/SCC-Overview](https://notes.kodekloud.com/docs/OpenShift-4/Openshift-Security/SCC-Overview)  
16. How to manage service accounts and security context constraints in ..., otwierano: listopada 15, 2025, [https://www.redhat.com/en/blog/security-context-constraint-configuration](https://www.redhat.com/en/blog/security-context-constraint-configuration)  
17. Understanding OpenShift Security Context Constraints: The Complete Guide \- kifarunix.com, otwierano: listopada 15, 2025, [https://kifarunix.com/understanding-openshift-security-context-constraints/](https://kifarunix.com/understanding-openshift-security-context-constraints/)  
18. How an SCC specifies permissions \- IBM Developer, otwierano: listopada 15, 2025, [https://developer.ibm.com/learningpaths/secure-context-constraints-openshift/scc-permissions](https://developer.ibm.com/learningpaths/secure-context-constraints-openshift/scc-permissions)  
19. Chapter 13\. Managing security context constraints | Authentication and authorization | OpenShift Dedicated | 4 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_dedicated/4/html/authentication\_and\_authorization/managing-pod-security-policies](https://docs.redhat.com/en/documentation/openshift_dedicated/4/html/authentication_and_authorization/managing-pod-security-policies)  
20. Migrate from PodSecurityPolicy to the Built-In PodSecurity Admission Controller, otwierano: listopada 15, 2025, [https://kubernetes.io/docs/tasks/configure-pod-container/migrate-from-psp/](https://kubernetes.io/docs/tasks/configure-pod-container/migrate-from-psp/)  
21. Mastering Pod Security in OpenShift: The Power of Security Context Constraints (SCCs), otwierano: listopada 15, 2025, [https://www.cloudthat.com/resources/blog/mastering-pod-security-in-openshift-the-power-of-security-context-constraints-sccs](https://www.cloudthat.com/resources/blog/mastering-pod-security-in-openshift-the-power-of-security-context-constraints-sccs)  
22. Chapter 15\. Managing security context constraints | Authentication ..., otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.11/html/authentication\_and\_authorization/managing-pod-security-policies](https://docs.redhat.com/en/documentation/openshift_container_platform/4.11/html/authentication_and_authorization/managing-pod-security-policies)  
23. Managing SCCs in OpenShift \- Red Hat, otwierano: listopada 15, 2025, [https://www.redhat.com/en/blog/managing-sccs-in-openshift](https://www.redhat.com/en/blog/managing-sccs-in-openshift)  
24. Please explain why non-root user is in root group : r/openshift \- Reddit, otwierano: listopada 15, 2025, [https://www.reddit.com/r/openshift/comments/qaxth8/please\_explain\_why\_nonroot\_user\_is\_in\_root\_group/](https://www.reddit.com/r/openshift/comments/qaxth8/please_explain_why_nonroot_user_is_in_root_group/)  
25. Chapter 15\. Managing Security Context Constraints | Cluster Administration | OpenShift Container Platform | 3.11 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.11/html/cluster\_administration/admin-guide-manage-scc](https://docs.redhat.com/en/documentation/openshift_container_platform/3.11/html/cluster_administration/admin-guide-manage-scc)  
26. Chapter 15\. Managing security context constraints | Authentication and authorization | OpenShift Container Platform | 4.8 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/authentication\_and\_authorization/managing-pod-security-policies](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/authentication_and_authorization/managing-pod-security-policies)  
27. Permissions :: OpenShift Starter Guides, otwierano: listopada 15, 2025, [https://redhat-scholars.github.io/openshift-starter-guides/rhs-openshift-starter-guides/parksmap-permissions.html](https://redhat-scholars.github.io/openshift-starter-guides/rhs-openshift-starter-guides/parksmap-permissions.html)  
28. Configure Service Accounts for Pods \- Kubernetes, otwierano: listopada 15, 2025, [https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)  
29. Chapter 11\. Using service accounts in applications | Authentication ..., otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.13/html/authentication\_and\_authorization/using-service-accounts](https://docs.redhat.com/en/documentation/openshift_container_platform/4.13/html/authentication_and_authorization/using-service-accounts)  
30. Chapter 10\. Understanding and creating service accounts | Authentication and authorization | OpenShift Container Platform | 4.8 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/authentication\_and\_authorization/understanding-and-creating-service-accounts](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/authentication_and_authorization/understanding-and-creating-service-accounts)  
31. Chapter 12\. Service Accounts | Developer Guide | OpenShift Container Platform | 3.11, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.11/html/developer\_guide/dev-guide-service-accounts](https://docs.redhat.com/en/documentation/openshift_container_platform/3.11/html/developer_guide/dev-guide-service-accounts)  
32. Chapter 11\. Using service accounts in applications | Authentication and authorization | OpenShift Container Platform | 4.9 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.9/html/authentication\_and\_authorization/using-service-accounts](https://docs.redhat.com/en/documentation/openshift_container_platform/4.9/html/authentication_and_authorization/using-service-accounts)  
33. Chapter 5\. Managing images | Images | Red Hat OpenShift Service on AWS classic architecture | 4, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/red\_hat\_openshift\_service\_on\_aws\_classic\_architecture/4/html/images/managing-images](https://docs.redhat.com/en/documentation/red_hat_openshift_service_on_aws_classic_architecture/4/html/images/managing-images)  
34. Using image pull secrets \- Managing images | Images | OKD 4.18, otwierano: listopada 15, 2025, [https://docs.okd.io/4.18/openshift\_images/managing\_images/using-image-pull-secrets.html](https://docs.okd.io/4.18/openshift_images/managing_images/using-image-pull-secrets.html)  
35. Adding pull secrets to service accounts in OpenShift automatically \- Stack Overflow, otwierano: listopada 15, 2025, [https://stackoverflow.com/questions/65663868/adding-pull-secrets-to-service-accounts-in-openshift-automatically](https://stackoverflow.com/questions/65663868/adding-pull-secrets-to-service-accounts-in-openshift-automatically)  
36. Shift left vs. shift right \- Red Hat, otwierano: listopada 15, 2025, [https://www.redhat.com/en/topics/devops/shift-left-vs-shift-right](https://www.redhat.com/en/topics/devops/shift-left-vs-shift-right)  
37. Shift-Left Security: What It Means, Why It Matters, and Best Practices, otwierano: listopada 15, 2025, [https://www.aquasec.com/cloud-native-academy/devsecops/shift-left-devops/](https://www.aquasec.com/cloud-native-academy/devsecops/shift-left-devops/)  
38. What is Shift Left? Security, Testing & More Explained | CrowdStrike, otwierano: listopada 15, 2025, [https://www.crowdstrike.com/en-us/cybersecurity-101/cloud-security/shift-left-security/](https://www.crowdstrike.com/en-us/cybersecurity-101/cloud-security/shift-left-security/)  
39. Shift-Left Security in Agile Development | by DevOps Security Hub | Oct, 2025 \- Medium, otwierano: listopada 15, 2025, [https://medium.com/@devopshub/shift-left-security-in-agile-development-ea46e0aa05ec](https://medium.com/@devopshub/shift-left-security-in-agile-development-ea46e0aa05ec)  
40. Shift Left: Moving Container Security into the Dev, Test, and Build Process \- Trend Micro, otwierano: listopada 15, 2025, [https://www.trendmicro.com/explore/amea\_knowledge\_hub/00847-hcs-en-blg](https://www.trendmicro.com/explore/amea_knowledge_hub/00847-hcs-en-blg)  
41. Chapter 7\. Clair Security Scanning | Manage Red Hat Quay | Red ..., otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/red\_hat\_quay/3.6/html/manage\_red\_hat\_quay/clair-intro2](https://docs.redhat.com/en/documentation/red_hat_quay/3.6/html/manage_red_hat_quay/clair-intro2)  
42. Red Hat Quay architecture, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/red\_hat\_quay/3/html-single/red\_hat\_quay\_architecture/index](https://docs.redhat.com/en/documentation/red_hat_quay/3/html-single/red_hat_quay_architecture/index)  
43. Chapter 3\. Red Hat Quay Security Scanning with Clair, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/red\_hat\_quay/2.9/html/manage\_red\_hat\_quay/quay-security-scanner](https://docs.redhat.com/en/documentation/red_hat_quay/2.9/html/manage_red_hat_quay/quay-security-scanner)  
44. Chapter 7\. Clair Security Scanning | Manage Red Hat Quay, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/red\_hat\_quay/3.7/html/manage\_red\_hat\_quay/clair-intro2](https://docs.redhat.com/en/documentation/red_hat_quay/3.7/html/manage_red_hat_quay/clair-intro2)  
45. How to Scan Docker Image with Trivy in CICD Pipeline running in a Jenkins Container | Step-by-Step \- YouTube, otwierano: listopada 15, 2025, [https://www.youtube.com/watch?v=sLtCtvuZ7jE](https://www.youtube.com/watch?v=sLtCtvuZ7jE)  
46. Easy CI/CD Integration & Reports with Trivy | Container Security | Part 16 \- YouTube, otwierano: listopada 15, 2025, [https://www.youtube.com/watch?v=mGovATzXQpo](https://www.youtube.com/watch?v=mGovATzXQpo)  
47. How to use Tekton to set up a CI pipeline with OpenShift Pipelines, otwierano: listopada 15, 2025, [https://www.redhat.com/en/blog/cicd-pipeline-openshift-tekton](https://www.redhat.com/en/blog/cicd-pipeline-openshift-tekton)  
48. From Pod Security Policies to Pod Security Standards – a Migration Guide | Wiz Blog, otwierano: listopada 15, 2025, [https://www.wiz.io/blog/from-pod-security-policies-to-pod-security-standards-a-migration-guide](https://www.wiz.io/blog/from-pod-security-policies-to-pod-security-standards-a-migration-guide)  
49. PodSecurityPolicy Deprecation: Past, Present, and Future \- Kubernetes, otwierano: listopada 15, 2025, [https://kubernetes.io/blog/2021/04/06/podsecuritypolicy-deprecation-past-present-and-future/](https://kubernetes.io/blog/2021/04/06/podsecuritypolicy-deprecation-past-present-and-future/)  
50. Kubernetes v1.25: Pod Security Admission Controller in Stable, otwierano: listopada 15, 2025, [https://kubernetes.io/blog/2022/08/25/pod-security-admission-stable/](https://kubernetes.io/blog/2022/08/25/pod-security-admission-stable/)  
51. Pod Security Policies \- Kubernetes, otwierano: listopada 15, 2025, [https://kubernetes.io/docs/concepts/security/pod-security-policy/](https://kubernetes.io/docs/concepts/security/pod-security-policy/)  
52. Chapter 9: Pod Security Admission \- Kubernetes Guides \- Apptio, otwierano: listopada 15, 2025, [https://www.apptio.com/topics/kubernetes/best-practices/pod-security-admission/](https://www.apptio.com/topics/kubernetes/best-practices/pod-security-admission/)  
53. Pod Security Standard and Security Context Constraints requirements \- IBM, otwierano: listopada 15, 2025, [https://www.ibm.com/docs/en/secure-proxy/6.2.0?topic=planning-pod-security-standard-security-context-constraints-requirements](https://www.ibm.com/docs/en/secure-proxy/6.2.0?topic=planning-pod-security-standard-security-context-constraints-requirements)  
54. Pod Security Standard, Pod Security Policy and Security Context Constraints requirements, otwierano: listopada 15, 2025, [https://www.ibm.com/docs/en/connect-direct/6.2.0?topic=planning-pod-security-standard-pod-security-policy-security-context-constraints-requirements](https://www.ibm.com/docs/en/connect-direct/6.2.0?topic=planning-pod-security-standard-pod-security-policy-security-context-constraints-requirements)  
55. Pod Security Admission \- Kubernetes, otwierano: listopada 15, 2025, [https://kubernetes.io/docs/concepts/security/pod-security-admission/](https://kubernetes.io/docs/concepts/security/pod-security-admission/)  
56. Chapter 2\. Pod Security Admission | Using the Red Hat build of Cryostat Operator to configure Cryostat, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/red\_hat\_build\_of\_cryostat/2/html/using\_the\_red\_hat\_build\_of\_cryostat\_operator\_to\_configure\_cryostat/pod-security-admission\_assembly\_cryostat-operator](https://docs.redhat.com/en/documentation/red_hat_build_of_cryostat/2/html/using_the_red_hat_build_of_cryostat_operator_to_configure_cryostat/pod-security-admission_assembly_cryostat-operator)  
57. Chapter 16\. Understanding and managing pod security admission ..., otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.14/html/authentication\_and\_authorization/understanding-and-managing-pod-security-admission](https://docs.redhat.com/en/documentation/openshift_container_platform/4.14/html/authentication_and_authorization/understanding-and-managing-pod-security-admission)  
58. Enforce Pod Security Standards with Namespace Labels \- Kubernetes, otwierano: listopada 15, 2025, [https://kubernetes.io/docs/tasks/configure-pod-container/enforce-standards-namespace-labels/](https://kubernetes.io/docs/tasks/configure-pod-container/enforce-standards-namespace-labels/)  
59. Configuring Pod Security admission \- IBM Cloud Docs, otwierano: listopada 15, 2025, [https://cloud.ibm.com/docs/openshift?topic=openshift-pod-security-admission](https://cloud.ibm.com/docs/openshift?topic=openshift-pod-security-admission)  
60. Chapter 16\. Understanding and managing pod security admission | Authentication and authorization | OpenShift Container Platform | 4.11 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.11/html/authentication\_and\_authorization/understanding-and-managing-pod-security-admission](https://docs.redhat.com/en/documentation/openshift_container_platform/4.11/html/authentication_and_authorization/understanding-and-managing-pod-security-admission)  
61. Chapter 16\. Understanding and managing pod security admission | Authentication and authorization | OpenShift Container Platform \- Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.13/html/authentication\_and\_authorization/understanding-and-managing-pod-security-admission](https://docs.redhat.com/en/documentation/openshift_container_platform/4.13/html/authentication_and_authorization/understanding-and-managing-pod-security-admission)  
62. Chapter 16\. Understanding and managing pod security admission | Authentication and authorization | OpenShift Container Platform | 4.18 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.18/html/authentication\_and\_authorization/understanding-and-managing-pod-security-admission](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/authentication_and_authorization/understanding-and-managing-pod-security-admission)