# Moduł 5: Kompletny Przewodnik po Sztuce Debugowania OpenShift

---

## Lekcja 5.1: Podstawowy "Triage" – Pierwsza Linia Diagnostyki z `oc get events`

### 5.1.1. Wprowadzenie

W złożonym, rozproszonym systemie, jakim jest OpenShift, problemy rzadko występują w izolacji. Zdolność do szybkiego "triage'u" (wstępnej selekcji) i zrozumienia ogólnej kondycji klastra jest pierwszą i najważniejszą umiejętnością diagnostyczną. Polecenie `oc get events` jest podstawowym narzędziem do tego celu. Działa ono jak system nerwowy klastra, raportując w czasie rzeczywistym o wszystkich znaczących działaniach – od tworzenia podów po błędy planowania i problemy z wolumenami. Zanim zagłębimy się w logi konkretnej aplikacji lub konfigurację pojedynczego zasobu, musimy najpierw spojrzeć na szerszy obraz, aby zidentyfikować wzorce i natychmiastowe przyczyny problemów.

### 5.1.2. `oc get events -w --all-namespaces`: Globalny Puls Klastra

Najpotężniejszym zastosowaniem tego polecenia jest monitorowanie na żywo całego klastra. Służy do tego polecenie `oc get events -w --all-namespaces` (lub `oc get events -wA`).

* Flaga `-w` (lub `--watch`) jest kluczowa. Powoduje ona, że polecenie nie kończy działania po wyświetleniu bieżących zdarzeń, ale pozostaje aktywne, strumieniując nowe zdarzenia w czasie rzeczywistym.[1, 2] Jest to niezbędne podczas aktywnego debugowania awarii lub monitorowania krytycznych operacji.
* Flaga `--all-namespaces` (lub `-A`) zapewnia, że widzimy zdarzenia ze wszystkich projektów w klastrze.[1] Jest to fundamentalne, ponieważ problemy z komponentami systemowymi (np. w przestrzeni nazw `openshift-sdn` lub `openshift-ingress`) często manifestują się jako błędy aplikacji w przestrzeniach nazw użytkowników.

To polecenie działa jak sejsmograf klastra. Administratorzy używają go podczas operacji na dużą skalę, takich jak aktualizacje klastra metodą blue-green lub importowanie nowych obrazów administracyjnych.[3, 4] W takich scenariuszach spodziewany jest "duży wzrost i spadek" liczby zdarzeń (np. zdarzeń `Pulling` i `Created`). Każde inne, nieoczekiwane "trzęsienie ziemi" – nagły zalew zdarzeń `FailedScheduling` lub `FailedMount$ – natychmiast wskazuje na problem systemowy.

Należy jednak zachować ostrożność. Zdarzały się przypadki, gdy polecenie `oc get events -w` w pewnych warunkach (np. podczas masowych, współbieżnych kompilacji) zaczynało odtwarzać stare zdarzenia (np. sprzed dwóch godzin) przemieszane z bieżącymi.[5] Uczy to administratorów, aby zawsze sprawdzali kolumnę `LAST SEEN` (lub `TIMESTAMP`) zdarzenia, a nie tylko polegali na jego nagłym pojawieniu się w strumieniu.

### 5.1.3. Dekodowanie Strumienia Zdarzeń: Interpretacja Kluczowych Błędów

Surowy strumień zdarzeń z całego klastra jest często zbyt "hałaśliwy", aby był użyteczny. Kluczową umiejętnością jest szybkie filtrowanie i identyfikowanie krytycznych błędów. Chociaż można używać narzędzi takich jak `grep` [6], bardziej precyzyjną metodą jest użycie selektorów pola (field selectors) do śledzenia zdarzeń tylko dla konkretnego, problematycznego zasobu:

`oc get events --field-selector involvedObject.name=<nazwa-poda>` [7, 8]

Poniżej znajduje się analiza trzech najczęstszych i najbardziej krytycznych błędów widocznych w strumieniu zdarzeń.

#### 5.1.3.1. Dogłębna analiza `FailedScheduling`

* **Co to oznacza:** Planista (scheduler) Kubernetes nie był w stanie znaleźć odpowiedniego węzła (Node) do uruchomienia Poda.[9]
* **Typowe przyczyny i komunikaty:**
    * **Niewystarczające zasoby:** Komunikat będzie wyglądał następująco: `0/6 nodes are available: 3 insufficient cpu, 3 insufficient memory`.[10] Oznacza to, że żądania (requests) Poda dotyczące CPU lub RAM przekraczają dostępne (alokowalne) zasoby na każdym z węzłów.[9, 11]
    * **Konflikty Taint/Toleration:** Komunikat: `0/6 nodes are available: 3 node(s) had taint {node-role.kubernetes.io/master:}, that the pod didn't tolerate`.[12, 13, 14] Węzły (szczególnie master) mają "tainty", które odpychają Pody. Pod musi mieć odpowiednią "tolerancję" (toleration), aby móc być na nich zaplanowanym.[9]
    * **Niezwiązane wolumeny (PVC):** Komunikat: `pod has unbound immediate PersistentVolumeClaims`.[15] Pod żąda wolumenu (PersistentVolumeClaim), który sam nie jest związany (bound) z żadnym dostępnym wolumenem fizycznym (PersistentVolume).
    * **Konflikty powinowactwa (Affinity):** Komunikat: `0/6 nodes are available: 3 node(s) didn't match pod anti-affinity rules`.[14] Reguły zdefiniowane w Podzie (np. "nie uruchamiaj mnie na tym samym węźle co inny Pod z etykietą `app=backend`") uniemożliwiają znalezienie odpowiedniego miejsca.[9]

#### 5.1.3.2. Dogłębna analiza `FailedMount`

* **Co to oznacza:** Kubelet na węźle (już po zaplanowaniu Poda) nie był w stanie zamontować żądanego wolumenu dla kontenera.[9]
* **Typowe przyczyny i komunikaty:**
    * **Brakujący `Secret` lub `ConfigMap`:** Najczęstsza przyczyna. Komunikat: `MountVolume.SetUp failed for volume "ssh-keys" : secret "ibm-spectrum-scale-ssh-key-secret" not found`.[12, 13] Pod próbuje zamontować `Secret` lub `ConfigMap` jako plik lub wolumen, ale zasób ten nie istnieje w danej przestrzeni nazw.
    * **Problem z dostawcą pamięci masowej:** Błędy związane z `FailedAttachVolume` [9] mogą wskazywać na problemy z bazowym dostawcą chmury (np. AWS EBS, Azure Disk) lub sieciową pamięcią masową (np. Ceph, NFS).

Ten błąd może być mylący i często jest **przejściowy**. W scenariuszach automatyzacji (np. przy użyciu Helm lub Operatorów) Pod jest często tworzony ułamki sekund *przed* `Secretem`, od którego zależy.[13] Wygeneruje to zdarzenie `FailedMount`, ale system powinien automatycznie ponowić próbę i odnieść sukces, gdy tylko `Secret$ stanie się dostępny. Jeśli błąd utrzymuje się (wskazuje na to wysoka wartość w kolumnie `COUNT`), oznacza to, że `Secret` lub `ConfigMap` faktycznie brakuje lub ma nieprawidłową nazwę.

#### 5.1.3.3. Dogłębna analiza `ImagePullBackOff` / `ErrImagePull`

* **Co to oznacza:** Kubelet na węźle nie był w stanie pobrać obrazu kontenera z rejestru.[7, 16]
* **Typowe przyczyny i komunikaty:**
    * **Błędna nazwa obrazu lub tag:** Najprostsza przyczyna. W manifeście Poda znajduje się literówka.[9]
    * **Wymagana autoryzacja:** Komunikat `authentication required` [7] lub podobny. Oznacza to, że obraz znajduje się w rejestrze prywatnym, a węzeł nie ma odpowiednich poświadczeń. Zwykle jest to spowodowane brakującym lub nieprawidłowym `imagePullSecret` powiązanym z kontem serwisowym (ServiceAccount) Poda.[7, 9, 17]
    * **Ograniczenia szybkości (Rate Limiting):** Coraz częstszy problem w przypadku publicznych rejestrów, takich jak Docker Hub. Rejestr odmawia żądania z powodu zbyt wielu pobrań z danego adresu IP.[9]
    * **Problemy z certyfikatami:** Komunikat `x509: certificate signed by unknown authority`.[7] Występuje, gdy klaster próbuje połączyć się z niestandardowym rejestrem używającym certyfikatu self-signed, który nie jest zaufany przez węzły klastra.

Istnieje wyraźna hierarchia diagnostyczna. `oc get events` jest narzędziem makroskopowym (Poziom 1), które identyfikuje "dym" i wskazuje, który zasób (`involvedObject`) "płonie". Następnie administrator używa `oc describe` (Poziom 2), aby zbadać ten konkretny zasób i zlokalizować "ogień". Kluczową umiejętnością jest odróżnienie zdarzeń przejściowych od trwałych, a najlepszym wskaźnikiem jest kolumna `COUNT` – jeśli rośnie, problem jest aktywny i wymaga interwencji.

### 5.1.4. Tabela 1: Dekoder Zdarzeń Poda

| Powód zdarzenia (Reason) | Typowy komunikat (Fragment) | Kategoria problemu | Pierwszy krok diagnostyczny |
| :--- | :--- | :--- | :--- |
| `FailedScheduling` | `0/X nodes are available: Y insufficient cpu...` | Planowanie (Zasoby) | `oc describe pod <pod>` & `oc adm top nodes` |
| `FailedScheduling` | `...node(s) had taint... that the pod didn't tolerate` | Planowanie (Taints) | `oc describe pod <pod>` & `oc describe node <node>` |
| `FailedScheduling` | `...pod has unbound immediate PersistentVolumeClaims` | Planowanie (Storage) | `oc describe pod <pod>` & `oc describe pvc <pvc>` |
| `FailedMount` | `MountVolume.SetUp failed... secret "X" not found` | Konfiguracja / Storage | `oc describe pod <pod>` & `oc get secret X` |
| `FailedMount` | `MountVolume.SetUp failed... ConfigMap "Y" not found` | Konfiguracja / Storage | `oc describe pod <pod>` & `oc get cm Y` |
| `ImagePullBackOff` | `Back-off pulling image...` | Obraz / Rejestr | `oc describe pod <pod>` (Sprawdź sekcję Events) |
| `ErrImagePull` | `authentication required` | Obraz / Rejestr (Auth) | `oc describe pod <pod>` & `oc describe sa default` |
| `FailedSync` | `Error syncing pod...` | Ogólny błąd Kubelet | `oc describe pod <pod>` (Sprawdź sekcję Events) |

---

## Lekcja 5.2: "Zajrzyj do środka" – Głęboka Diagnostyka Zasobów za pomocą `oc describe`

### 5.2.1. Wprowadzenie

Po zidentyfikowaniu problematycznego zasobu za pomocą `oc get events` (naszego narzędzia Poziomu 1), następnym logicznym i najważniejszym krokiem jest użycie `oc describe` (naszego narzędzia Poziomu 2). Podczas gdy `oc get events` pokazuje, *co* dzieje się w klastrze w czasie rzeczywistym, `oc describe [resource][name]` dostarcza skonsolidowany, szczegółowy raport o *stanie zbiorczym* i *historii* pojedynczego zasobu.[18, 19, 20, 21, 22, 23]

Dla debugowania aplikacji, najczęściej używanym polecenie jest `oc describe pod/<nazwa-poda>`.

### 5.2.2. Anatomia `oc describe pod`

Wynik polecenia `oc describe pod` jest podzielony na kilka kluczowych sekcji. Zrozumienie roli każdej z nich jest niezbędne do szybkiej diagnozy.

* **Sekcja `Status`:** Zapewnia bieżący, ogólny stan Poda, np. `Pending`, `Running`, `Succeeded`, `Failed` lub `Terminated`.[24] Jest to podsumowanie wszystkich poniższych warunków.
* **Sekcja `Conditions`:** Jest to zestaw flag (warunków) Prawda/Fałsz, które określają ogólny `Status`. Najważniejsze z nich to:
    * `PodScheduled`: Czy planista znalazł węzeł dla tego Poda?
    * `Initialized`: Czy wszystkie kontenery `init` zakończyły działanie pomyślnie?
    * `ContainersReady`: Czy wszystkie główne kontenery w Podzie przeszły swoje testy gotowości (readiness probes)?
    * `Ready`: Czy Pod jest w pełni gotowy do przyjmowania ruchu?
    Na przykład, Pod może mieć `Status: Running`, ale `Ready: False`.[25, 26] Oznacza to, że kontener działa, ale jego test gotowości (readiness probe) zawodzi, więc OpenShift (poprzez `Service`) nie będzie kierował do niego ruchu.
* **Sekcja `Events`:** Jest to najważniejsza sekcja do debugowania. Jest to przefiltrowany widok globalnego strumienia zdarzeń, pokazujący *tylko* zdarzenia związane z tym konkretnym Podem.[7, 8, 27, 28, 29] Zamiast przeszukiwać `oc get events` dla całego klastra, można tutaj zobaczyć precyzyjną historię błędów dla danego Poda.

### 5.2.3. Studium Przypadku: Dlaczego mój Pod jest w stanie `Pending`?

Stan `Pending` jest jednym z najczęstszych problemów i doskonale ilustruje moc `oc describe`.

Stan `Pending` oznacza, że definicja Poda została zaakceptowana przez serwer API, ale Pod nie został (jeszcze) uruchomiony na żadnym węźle.[11, 22, 30, 31] Oznacza to prawie wyłącznie **problem z planistą (schedulerem)**. Kontener *nawet nie próbował* się uruchomić, więc szukanie logów aplikacji (`oc logs`) jest bezcelowe.

Po uruchomieniu `oc describe pod/<nazwa-poda>` należy natychmiast przewinąć do sekcji `Events`. Tam znajdzie się przyczyna.

#### 5.2.3.1. Scenariusz 1: Brak zasobów (CPU/RAM)

* **Jak to wygląda:** W sekcji `Events` widoczne jest powtarzające się zdarzenie `FailedScheduling` [32] z komunikatem podobnym do: `0/7 nodes are available: 4 insufficient cpu`.[10]
* **Wyjaśnienie:** Planista sprawdził wszystkie węzły i żądania (requests) Poda dotyczące CPU lub pamięci RAM przekraczają dostępne (alokowalne) zasoby na każdym z nich.[11, 29]
* **Następny krok:** Użyj `oc adm top nodes`, aby zweryfikować, które węzły są pod presją i ile zasobów faktycznie pozostało.[11]
* **Rozwiązanie:** Zmniejsz żądania Poda w jego `DeploymentConfig` / `Deployment`, dodaj więcej węzłów do klastra lub usuń inne obciążenia, aby zwolnić zasoby.

#### 5.2.3.2. Scenariusz 2: Tainty i Tolerancje

* **Jak to wygląda:** Zdarzenie `FailedScheduling` z komunikatem: `0/6 nodes are available: 3 node(s) had taint {node-role.kubernetes.io/master:}, that the pod didn't tolerate`.[12, 13, 14, 33]
* **Wyjaśnienie:** Tainty (skazy) to mechanizm, za pomocą którego węzły "odpychają" Pody. Domyślnie węzły `master$ mają taint `NoSchedule`, aby zapobiec uruchamianiu na nich obciążeń aplikacyjnych. Aby Pod mógł być zaplanowany na węźle z taintem, musi mieć zdefiniowaną odpowiednią `toleration` (tolerancję) w swojej specyfikacji.[11, 30]
* **Rozwiązanie:** Albo dodaj odpowiednią sekcję `tolerations` do specyfikacji Poda, albo (jeśli jest to uzasadnione) usuń taint z węzła za pomocą `oc adm taint node...`.

#### 5.2.3.3. Scenariusz 3: Niezwiązane Wolumeny (PersistentVolumeClaims)

* **Jak to wygląda:** Zdarzenie `FailedScheduling` z komunikatem: `pod has unbound immediate PersistentVolumeClaims`.[15, 34]
* **Wyjaśnienie:** Pod żąda wolumenu (`PVC`), ale system pamięci masowej nie może dynamicznie udostępnić odpowiedniego `PersistentVolume` (PV) lub żaden istniejący `PV` nie pasuje do żądania (np. zła klasa magazynu, niewystarczający rozmiar, konflikt trybu dostępu).
* **Następny krok:** Użyj `oc describe pvc <pvc-name>`, aby zobaczyć, dlaczego `PVC` jest w stanie `Pending` i nie może się związać.

#### 5.2.3.4. Scenariusz 4: Konflikty Powinowactwa (Affinity) / Antypowinowactwa

* **Jak to wygląda:** Zdarzenie `FailedScheduling` z komunikatem: `0/6 nodes are available: 3 node(s) didn't match pod anti-affinity rules`.[14]
* **Wyjaśnienie:** Zaawansowane reguły planowania [35, 36] zdefiniowane w Podzie (np. `podAntiAffinity`) uniemożliwiają planiście znalezienie odpowiedniego węzła. Na przykład reguła "nie uruchamiaj tego Poda na węźle, na którym już działa Pod z etykietą `app=web`" jest niemożliwa do spełnienia, jeśli wszystkie dostępne węzły już mają taki Pod.[14]
* **Rozwiązanie:** Zrewiduj reguły `affinity` w specyfikacji Poda, aby były mniej restrykcyjne, lub dodaj więcej węzłów, aby zapewnić elastyczność planowania.

---

## Lekcja 5.3: "Co mówi aplikacja?" – Mistrzostwo w `oc logs`

### 5.3.1. Wprowadzenie

Gdy `oc describe pod` potwierdzi, że Pod został pomyślnie zaplanowany, a problem nie leży w konfiguracji platformy (jak w przypadku `Pending` czy `ImagePullBackOff`), czas przenieść diagnostykę na poziom aplikacji. Polecenie `oc logs` jest bezpośrednim kanałem do strumieni `stdout` (standardowe wyjście) i `stderr` (standardowe wyjście błędów) kontenera.[37, 38, 39] W architekturze natywnej dla chmury zakłada się, że aplikacje logują wszystkie swoje komunikaty właśnie do tych strumieni, skąd platforma może je przechwytywać.[40]

### 5.3.2. Różnica między `oc logs -f` a `oc logs -p`

Zrozumienie dwóch kluczowych flag tego polecenia jest niezbędne do efektywnego debugowania.

* **`oc logs -f <pod-name>` (Follow):** Flaga `-f` (follow) służy do śledzenia logów na żywo.[40, 41, 42, 43] Po jej użyciu, polecenie pozostaje aktywne i strumieniuje nowe linie logów, gdy tylko pojawią się one na `stdout`/`stderr` kontenera. Jest to idealne narzędzie do monitorowania postępu uruchamiania aplikacji, obserwowania przychodzących żądań w czasie rzeczywistym lub śledzenia procesu kompilacji na żywo (`oc logs -f build/...`).[42, 44]
* **`oc logs -p <pod-name>` (Previous):** Flaga `-p` (previous) jest prawdopodobnie najważniejszym narzędziem do debugowania Poda, który uległ awarii.

### 5.3.3. Studium Przypadku: Rozwiązywanie problemu `CrashLoopBackOff`

Stan `CrashLoopBackOff` jest częstym i frustrującym problemem. Należy jednak zrozumieć, że `CrashLoopBackOff` nie jest *błędem* samym w sobie; jest to *objaw* i dowód na to, że OpenShift działa poprawnie.[45]

Stan ten oznacza, że OpenShift pomyślnie uruchomił kontener, ale proces wewnątrz tego kontenera *zakończył się* (uległ awarii lub po prostu zakończył działanie) z kodem wyjścia innym niż 0. Zgodnie ze swoją deklaratywną naturą ("zapewnij, że ten kontener zawsze działa"), OpenShift natychmiast próbuje uruchomić go ponownie. Gdy to się powtarza, platforma wchodzi w pętlę awarii (crash loop) i inteligentnie zaczyna stosować opóźnienie (back-off) między kolejnymi próbami, aby uniknąć przeciążenia systemu.[46, 47, 48, 49, 50]

Tutaj pojawia się **krytyczna pułapka diagnostyczna**: Inżynier widzi Poda w stanie `CrashLoopBackOff` i uruchamia `oc logs <pod-name>`. Często polecenie to zwraca puste logi lub tylko kilka początkowych linii startowych. Dzieje się tak, ponieważ odpytywana jest *nowa, właśnie uruchomiona instancja* kontenera (np. próba nr 5), która jeszcze nie zdążyła wygenerować błędu.

**Rozwiązaniem jest flaga `-p` (previous).**

Polecenie `oc logs -p <pod-name>` [23, 41, 42, 43, 46, 47, 48, 49, 51, 52, 53, 54, 55, 56] instruuje `oc`, aby pobrał logi z *poprzedniej, zakończonej niepowodzeniem* instancji kontenera (np. próby nr 4). To właśnie tam znajduje się krytyczny ślad stosu (stack trace), komunikat `NullPointerException`, błąd "Błąd połączenia z bazą danych" lub "Nie znaleziono pliku konfiguracyjnego", który spowodował awarię.

Istnieje również alternatywny scenariusz pętli awarii: co, jeśli `oc logs -p` pokazuje, że proces zakończył się z kodem wyjścia 0 ($Exit Code: 0$)?[57] Oznacza to, że aplikacja *nie jest* serwerem. Jest to prawdopodobnie skrypt (np. w Pythonie lub Bashu), który wykonał swoje zadanie i pomyślnie zakończył działanie. Kubernetes/OpenShift oczekuje, że główny proces kontenera będzie działał "wiecznie" (jako proces na pierwszym planie). Jeśli proces się kończy – nawet pomyślnie – platforma traktuje to jako awarię i uruchamia go ponownie, prowadząc do `CrashLoopBackOff`. Jest to częsty błąd przy pakowaniu skryptów wsadowych jako `DeploymentConfig` zamiast `Job` lub `CronJob`.

Na koniec, jeśli zarówno `oc logs`, jak i `oc logs -p` zwracają puste dane, może to oznaczać problem z projektowaniem aplikacji. `oc logs` może przechwytywać *tylko* `stdout` i `stderr`.[37, 58] Jeśli aplikacja została błędnie skonfigurowana do logowania do pliku (np. `/var/log/app.log` lub `synthetic.log` [58]), `oc logs` będzie puste. Obejściem tego problemu jest użycie `oc exec`, omówionego w następnej sekcji, aby ręcznie odczytać ten plik.

---

## Lekcja 5.4: Wejście do Kontenera – Diagnostyka Środowiskowa z `oc exec`

### 5.4.1. Wprowadzenie

Po przejściu od makroskopowych zdarzeń (`oc get events`) i pasywnego czytania logów (`oc logs`), przechodzimy do aktywnego, interaktywnego debugowania. Polecenie `oc exec` pozwala na uruchomienie dowolnego polecenia wewnątrz *już działającego* kontenera.[59, 60, 61] Daje nam to możliwość "rozejrzenia się" wewnątrz środowiska Poda, weryfikacji zmiennych środowiskowych, sprawdzenia systemu plików i, co najważniejsze, testowania łączności sieciowej.

### 5.4.2. Krytyczne Ograniczenie: Tylko dla Działających Kontenerów

Zanim przejdziemy dalej, należy zrozumieć fundamentalne ograniczenie: `oc exec` działa **tylko** na kontenerach w stanie `Running`.

Nie można użyć `oc exec` do debugowania Poda w stanie `Pending$ (ponieważ nie ma jeszcze kontenera), `ImagePullBackOff$ (kontener nie mógł zostać utworzony) lub `CrashLoopBackOff`.[62, 63] Próba wykonania `oc exec` na crashującym Podzie zakończy się niepowodzeniem, ponieważ kontener, z którym próbujemy się połączyć, już nie istnieje.[64, 65]

Dlatego `oc exec` jest narzędziem do debugowania Poda, który *działa*, ale *działa niepoprawnie*. Typowe scenariusze to:
* Aplikacja działa, ale jej punkt końcowy API zwraca błąd 500.
* Aplikacja twierdzi w logach, że nie może połączyć się z bazą danych lub innym serwisem.
* Aplikacja działa, ale nie przetwarza danych z zamontowanego wolumenu.

(Problem debugowania Poda w stanie `CrashLoopBackOff` zostanie rozwiązany w Lekcji 5.6 za pomocą polecenia `oc debug`).

### 5.4.3. Uzyskiwanie Powłoki

Najczęstszym zastosowaniem `oc exec` jest uruchomienie interaktywnej powłoki (shell) wewnątrz kontenera:

`oc exec -it <pod-name> -- /bin/bash` [59, 60, 61, 66, 67]

* Flaga `-i` (stdin) i `-t` (TTY) są niezbędne do uzyskania interaktywnego terminala.
* `--` (podwójny myślnik) to separator, który oddziela argumenty polecenia `oc` od polecenia, które ma być wykonane *wewnątrz* kontenera.[61, 68]

Jeśli polecenie zwróci błąd typu `OCI runtime exec failed:... no such file or directory`, oznacza to, że obraz kontenera nie zawiera powłoki `bash`. Dzieje się tak często w minimalistycznych obrazach (np. opartych na `alpine` lub `distroless`). W takim przypadku należy spróbować `oc exec -it <pod-name> -- /bin/sh`.[67, 68, 69]

Platforma OpenShift udostępnia również wygodny skrót: `oc rsh <pod-name>`.[68, 70, 71, 72] Jest on funkcjonalnie równoważny z `oc exec -it <pod-name> -- /bin/sh` i jest często szybszy do wpisania.

### 5.4.4. Checklista Diagnostyki Wewnątrz Kontenera

Po wejściu do powłoki Poda, administrator ma do dyspozycji standardowy zestaw narzędzi Linuksowych (o ile są one zainstalowane w obrazie) do przeprowadzenia pełnej diagnostyki.

#### 5.4.4.1. Weryfikacja Środowiska

Pierwszym krokiem jest sprawdzenie, czy konfiguracja, którą OpenShift miał wstrzyknąć, faktycznie dotarła do kontenera.

* Użyj polecenia `env` lub `printenv`, aby wyświetlić wszystkie zmienne środowiskowe.[73]
* Sprawdź, czy zmienne zdefiniowane w `ConfigMaps` (`envFrom... configMapKeyRef`) lub `Secrets` (`envFrom... secretKeyRef`) są obecne i mają poprawne wartości.[74]
* **Pułapka:** Polecenia uruchamiane bezpośrednio przez `oc exec` lub `oc rsh` (np. `oc rsh <pod> psql -l`) mogą nie ładować plików profilu powłoki, takich jak `.bashrc` lub `.profile`.[75] Oznacza to, że kluczowe zmienne, takie jak `PATH` lub `LD_LIBRARY_PATH`, mogą być nieustawione, co prowadzi do błędów "command not found" lub "library not found". Jeśli polecenie działa po interaktywnym wejściu (`oc rsh`, a następnie `psql -l`), ale nie jako polecenie jednorazowe, rozwiązaniem jest wymuszenie "powłoki logowania" za pomocą flagi `-il`:
    `oc exec -it <pod> -- /bin/bash -il -c "twoje-polecenie-tutaj"`.[61]

#### 5.4.4.2. Inspekcja Systemu Plików

Następnie należy sprawdzić, czy wolumeny i pliki konfiguracyjne są poprawnie zamontowane.

* Użyj `ls -l /path/to/config/volume` lub `df -h`.[76]
* Sprawdź, czy pliki z `ConfigMaps` (np. `app.properties`) istnieją w oczekiwanej ścieżce montowania (np. `/etc/config`).
* Sprawdź, czy wolumeny `PersistentVolumeClaim$ są zamontowane i czy mają poprawne uprawnienia (np. `ls -l /mnt/data`).[68, 76, 77, 78]

#### 5.4.4.3. Testowanie Łączności Sieciowej

Jest to najważniejszy przypadek użycia `oc exec`. Aplikacja w logach twierdzi: "Nie mogę połączyć się z `database-service`".

* **Test DNS:** Użyj `ping database-service`. (Uwaga: `ping` często nie jest instalowany w nowoczesnych obrazach).
* **Test Łączności (DNS + Port):** Najlepszym narzędziem jest `curl`. Nawet jeśli aplikacja nie może połączyć się z PostgreSQL na porcie 5432, można użyć `curl`, aby sprawdzić, czy sam port jest osiągalny:
    `curl -v database-service:5432` [60, 79]
* **Interpretacja:**
    * Jeśli `curl` zwróci `Could not resolve host: database-service`, oznacza to problem z DNS (Service Discovery) w klastrze.
    * Jeśli `curl` zawiesi się i zwróci `Connection timed out` [80], oznacza to, że DNS zadziałał, ale `NetworkPolicy` (polityka sieciowa) blokuje ruch lub `Service` jest błędnie skonfigurowany i nie wskazuje na żadne Pody.
    * Jeśli `curl` zwróci `Connection refused`, oznacza to, że DNS i sieć działają, ale na Podzie `database-service` na porcie 5432 nie nasłuchuje żaden proces.
    * Jeśli `curl` do nazwy serwisu (np. `curl my-pod-zm5g6:8080` [80]) działa, ale `curl` do publicznej `Route` (np. `curl [http://my-route.apps.cluster.com](http://my-route.apps.cluster.com)`) zawodzi, problem leży w konfiguracji `Route` lub `Ingress`, a nie w komunikacji między podami.

---

## Lekcja 5.5: Analiza Problemów z `Build` i `Deployment`

### 5.5.1. Wprowadzenie

Po opanowaniu diagnostyki na poziomie Poda, musimy cofnąć się o krok, aby zbadać obiekty wyższego rzędu, które zarządzają tymi Podami. W OpenShift są to przede wszystkim `BuildConfig` (BC) i `DeploymentConfig` (DC), które automatyzują cykl życia aplikacji od kodu źródłowego do działającego kontenera.

### 5.5.2. Debugowanie Procesów `Build`

Obiekt `BuildConfig` (BC) w OpenShift opisuje, jak wziąć kod źródłowy (np. z Git) i przekształcić go w obraz kontenera (np. za pomocą strategii Source-to-Image (S2I) lub Dockerfile).[81]

Kiedy uruchamiasz kompilację (np. za pomocą `oc start-build`), OpenShift tworzy tymczasowy `Build Pod` (np. o nazwie `my-build-1-build`), który wykonuje całą logikę kompilacji: klonuje repozytorium, buduje artefakty i pcha gotowy obraz do rejestru.[82] Debugowanie `Build` to w rzeczywistości debugowanie tego tymczasowego Poda.

#### 5.5.2.1. Jak czytać logi kompilacji

Istnieją dwa główne sposoby dostępu do logów kompilacji, każdy do innego celu:

1.  **`oc logs -f build/<nazwa-instancji-builda>`** (np. `oc logs -f build/myapp-1`): Służy do śledzenia na żywo *konkretnej*, obecnie działającej instancji kompilacji.[42, 44, 83, 84] Używane, gdy właśnie uruchomiłeś kompilację i chcesz obserwować jej postęp.
2.  **`oc logs bc/<nazwa-buildconfig>`** (np. `oc logs bc/myapp`): Jest to wygodny skrót, który pobiera logi z *ostatniej* kompilacji (zakończonej sukcesem lub niepowodzeniem) powiązanej z tym `BuildConfig`.[82, 84, 85, 86, 87] Jest to najczęściej używane polecenie do diagnozowania nieudanej kompilacji.

#### 5.5.2.2. Typowe błędy i ich debugowanie

* **Problem:** Kompilacja kończy się niepowodzeniem, a `Build Pod` jest natychmiast usuwany, zanim zdążysz go zbadać.[88]
* **Rozwiązanie:** Nie próbuj szukać logów Poda. Zamiast tego użyj `oc logs bc/my-build-config`, które pobiera zachowane logi z obiektu `Build`, który przechowuje historię, nawet po usunięciu Poda.

* **Problem:** Standardowe logi kompilacji są niewystarczające, aby zdiagnozować problem (np. podczas skomplikowanego procesu S2I).
* **Rozwiązanie:** Zwiększ poziom logowania. Można to zrobić, dodając zmienną środowiskową `BUILD_LOGLEVEL` (np. o wartości `5`) do sekcji `strategy` (np. `sourceStrategy` lub `dockerStrategy`) w definicji `BuildConfig`.[85, 87, 89]

* **Problem:** Kompilacja przebiega pomyślnie, ale kończy się niepowodzeniem na ostatnim etapie: pchaniu (push) obrazu do rejestru, z błędem `authentication required`.[90]
* **Rozwiązanie:** `Build` potrzebuje poświadczeń nie tylko do pobrania źródeł (`sourceSecret`), ale także do wypchnięcia obrazu do docelowego rejestru. Sprawdź sekcję `BuildConfig.spec.output` i upewnij się, że zdefiniowano tam poprawny `pushSecret`.[90]

### 5.5.3. Debugowanie Procesów `DeploymentConfig` (DC)

Obiekt `DeploymentConfig` (DC) jest historycznym (specyficznym dla OpenShift) sposobem definiowania, jak aplikacja powinna być wdrażana i aktualizowana.[91, 92] (Nowoczesne klastry faworyzują standardowe obiekty `Deployment$ z Kubernetes).

`DeploymentConfig` definiuje szablon Poda oraz strategię "rolloutu" (np. `Rolling`, `BlueGreen`).[91] Kiedy następuje wyzwalacz (trigger) – na przykład `ImageChangeTrigger` wykryje nowy obraz w `ImageStream` – `DeploymentConfig` tworzy nowy `ReplicationController` (RC) (np. `myapp-3`).[93] Ten nowy `RC` jest następnie odpowiedzialny za uruchomienie nowych Podów, a `DC` zarządza procesem przejścia, np. skalując w dół stary `RC` (`myapp-2$) i skalując w górę nowy `RC` (`myapp-3`).

Problemy z wdrożeniem (deployment) to prawie zawsze problemy z *Podami*. `DeploymentConfig` lub `ReplicationController` tylko orkiestrują Pody. Jeśli wdrożenie "utknie" lub "zawiesi się", to dlatego, że nowe Pody (np. z `myapp-3`) nie mogą przejść w stan `Ready`.

#### 5.5.3.1. Metodologia debugowania `DeploymentConfig`

Jeśli wdrożenie `myapp` utknęło, proces diagnostyczny przebiega od góry do dołu:

1.  **Sprawdź `DC`:** Użyj `oc describe dc/myapp`.[61, 87, 91, 93]
    * Sprawdź, czy `LATEST VERSION` wskazuje na numer wdrożenia, którego oczekujesz.
    * Sprawdź sekcję `Triggers`, aby upewnić się, że są poprawnie skonfigurowane (np. czy obserwują właściwy `ImageStreamTag`).
    * Sprawdź sekcję `Events$ na dole. Powinieneś zobaczyć zdarzenie typu `DeploymentCreated`, np. `Created new deployment "myapp-3" for version 3`.[93]
2.  **Sprawdź `RC`:** `DeploymentConfig` deleguje tworzenie Podów do `ReplicationController`. Znajdź najnowszy `RC`: `oc get rc`.
    * Użyj `oc describe rc/myapp-3`.[93, 94, 95, 96, 97] To jest kluczowy krok. Sekcja `Events` w `RC` pokaże, czy ma on problemy z *tworzeniem* Podów (np. z powodu limitów `ResourceQuota`).
3.  **Sprawdź Pody:** Wdrożenie jest "zablokowane", ponieważ jego nowe Pody nie przechodzą w stan `Ready`.
    * Użyj `oc get pods`, aby znaleźć Pody należące do nowego wdrożenia (będą miały prefiks `myapp-3-xxxxx`).
    * **W tym momencie wracasz do Lekcji 5.1, 5.2 i 5.3.**
    * Uruchom `oc describe pod/myapp-3-xxxxx`.
    * Prawdopodobnie Pod jest w stanie `ImagePullBackOff` (nowy obraz ma błąd lub problem z `Secretem`), `CrashLoopBackOff` (nowy kod aplikacji ulega awarii przy starcie) lub `Running (Not Ready)` (aplikacja działa, ale jej nowy test gotowości zawodzi).

---

## Lekcja 5.6: Zaawansowane Narzędzia: `oc debug` i `oc adm`

### 5.6.1. Wprowadzenie

Po opanowaniu podstawowego zestawu narzędzi (`events`, `describe`, `logs`, `exec`), czas na wprowadzenie poleceń, które albo rozwiązują fundamentalne luki w standardowym procesie debugowania, albo przenoszą nas z roli dewelopera/operatora aplikacji do roli administratora klastra.

### 5.6.2. Potęga `oc debug pod/...`: Narzędzie do `CrashLoopBackOff`

Jak ustalono w Lekcji 5.3 i 5.4, największą bolączką Kubernetes jest debugowanie Poda w stanie `CrashLoopBackOff`. Pod "znika, zanim można uzyskać z niego użyteczne informacje".[64, 65] `oc logs -p` daje nam pasywne logi, ale co, jeśli musimy *interaktywnie* wejść do Poda, aby zbadać środowisko? `oc exec` zawodzi, ponieważ Pod nie jest w stanie `Running`.

**Rozwiązaniem jest `oc debug`.**

Polecenie `oc debug pod/<pod-name>` (lub `oc debug dc/my-dc`, `oc debug deployment/my-deploy$) jest potężnym narzędziem diagnostycznym.[45, 49, 55, 67, 70]

#### 5.6.2.1. Jak to działa:
Kluczową rzeczą do zrozumienia jest to, że `oc debug` **nie** łączy się magicznie z crashującym Podem – to niemożliwe. Zamiast tego, wykonuje znacznie sprytniejszą operację:

1.  Odczytuje specyfikację (definicję YAML) Poda, na którym się wzoruje.
2.  Tworzy w klastrze **nowy Pod-kopię** (zwykle z sufiksem `-debug`).
3.  Ten nowy Pod ma *dokładnie tę samą konfigurację*: te same zmienne środowiskowe, te same `ConfigMaps`, te same `Secrets` i te same zamontowane wolumeny.
4.  Następnie `oc debug` **zastępuje (overrides) oryginalny `ENTRYPOINT` lub `CMD`** obrazu kontenera, uruchamiając zamiast niego powłokę (np. `/bin/sh`).[62, 64, 65]

W rezultacie administrator ląduje w interaktywnej powłoce wewnątrz Poda, który ma *identyczne środowisko* jak ten, który ulega awarii, ale który nie próbuje uruchomić zepsutej aplikacji.

#### 5.6.2.2. Praktyczny przepływ pracy z `oc debug`:

1.  Pod `myapp-1-abcde` jest w `CrashLoopBackOff`.
2.  `oc logs -p myapp-1-abcde` pokazuje błąd: `Error: Config file /etc/app/config.ini not found`.
3.  `oc exec` zawodzi, ponieważ Pod nie jest w stanie `Running`.
4.  Administrator uruchamia: `oc debug pod/myapp-1-abcde`.
5.  System odpowiada: `Starting pod/myapp-1-abcde-debug...` i po chwili pojawia się powłoka `sh-4.2#`.
6.  Administrator jest teraz *wewnątrz* Poda debugującego.
7.  Wpisuje `ls -l /etc/app/config.ini`. Wynik: `No such file or directory`. Potwierdza to błąd z logów.
8.  Administrator podejrzewa, że `ConfigMap` zamontował się w złym miejscu. Wpisuje `ls -l /etc/config-volume/`. Wynik: `config.ini`.
9.  **Problem jest znaleziony.** Aplikacja szuka pliku w `/etc/app/`, ale `DeploymentConfig` montuje `ConfigMap` w `/etc/config-volume/`.
10. Administrator wpisuje `exit` i przystępuje do naprawy definicji `volumeMounts` w `DeploymentConfig`.

### 5.6.3. Tabela 3: Porównanie kluczowych poleceń diagnostycznych Poda

Polecenie `oc debug` wypełnia krytyczną lukę między `oc exec` a `oc logs`.

| Polecenie | Wymagany stan Poda | Główne zadanie diagnostyczne |
| :--- | :--- | :--- |
| `oc logs [-p]` | Dowolny (działający, zakończony, crashujący) | Pasywne czytanie `stdout`/`stderr` (co aplikacja *zdążyła* zapisać). |
| `oc exec` | **Musi być `Running`** | Interaktywne badanie *działającej, ale źle funkcjonującej* aplikacji. |
| `oc debug` | Dowolny (szczególnie `CrashLoopBackOff` lub `Pending`) | Interaktywne badanie *środowiska i konfiguracji* Poda, który *nie chce się uruchomić*. |

### 5.6.4. Wprowadzenie do poleceń `oc adm` (Administrator)

Grupa poleceń `oc adm` (administrator) zawiera narzędzia do zarządzania i diagnozowania klastra na poziomie węzłów i całej platformy, a nie tylko pojedynczej aplikacji.

#### 5.6.4.1. `oc adm top nodes`

* **Przypadek użycia:** Jest to bezpośrednia odpowiedź na problem `FailedScheduling` z powodu braku zasobów.[11]
* **Co robi:** Wyświetla bieżące zużycie zasobów (CPU i pamięci) dla wszystkich węzłów (Nodes) w klastrze.[98, 99]
* **Interpretacja:** Ważne jest, aby zrozumieć, co oznaczają te liczby. Pokazują one zużycie (np. `1503m` CPU) oraz procentowe wykorzystanie (np. `100%`). Ten procent *nie* jest liczony względem całkowitej fizycznej pojemności serwera, ale względem zasobów *alokowalnych* (Allocatable) – czyli całkowitej pojemności pomniejszonej o zasoby zarezerwowane dla systemu operacyjnego i samego Kubelet.[100, 101, 102] Węzeł pokazujący 100% CPU% może nadal mieć fizycznie wolne zasoby, ale z perspektywy planisty Kubernetes jest pełny.

#### 5.6.4.2. `oc adm drain`

* **Przypadek użycia:** Przygotowanie węzła do konserwacji (np. aktualizacji jądra, wymiany sprzętu).[103, 104, 105, 106]
* **Co robi:** Polecenie `oc adm drain <node-name>` wykonuje dwie czynności:
    1.  Oznacza węzeł jako `unschedulable` (cordons), aby planista nie umieszczał na nim nowych Podów.
    2.  Bezpiecznie eksmituje (evicts) wszystkie istniejące Pody z tego węzła, pozwalając ich `ReplicationControllers` lub `Deployments` na ponowne utworzenie ich na innych, zdrowych węzłach.[104, 105]
* **Kluczowe flagi:** `--ignore-daemonsets` (ponieważ `DaemonSet` Pody i tak muszą działać na każdym węźle i nie można ich eksmitować) oraz `--delete-local-data` (wymusza usunięcie Podów używających `emptyDir`, których zawartość zostanie utracona).[107]
* **Powrót do służby:** Po zakończeniu konserwacji, administrator używa `oc adm uncordon <node-name>`, aby ponownie oznaczyć węzeł jako `schedulable`.[104, 105]

#### 5.6.4.3. `oc adm must-gather`

* **Przypadek użycia:** Ostateczne narzędzie diagnostyczne, gdy problem wydaje się leżeć w samej platformie OpenShift i wymagana jest pomoc wsparcia technicznego (np. Red Hat Support).[108, 109, 110]
* **Co robi:** Jest to zautomatyzowany kolektor danych diagnostycznych. Uruchamia specjalnego Poda w klastrze, który zbiera ogromną ilość informacji: logi ze wszystkich komponentów systemowych (API, etcd, operatory), definicje wszystkich zasobów (CRD, Pody, Role), informacje o sieci i wiele innych.[111, 112, 113]
* **Wynik:** Tworzy skompresowany plik (np. `must-gather.local...tar.gz`), który można dołączyć do zgłoszenia serwisowego, dając inżynierom wsparcia pełny obraz stanu klastra w momencie wystąpienia problemu.[111]

---

## Lekcja 5.7: Praktyczna Checklista Diagnostyczna: "Mój Pod nie wstaje"

### 5.7.1. Wprowadzenie

Ta sekcja syntetyzuje wszystkie poprzednie lekcje w jeden ustrukturyzowany, praktyczny przepływ pracy. Proces debugowania Poda nie jest przypadkowy; jest to systematyczna procedura eliminacji. Punktem wyjścia jest zawsze wynik polecenia `oc get pods`. Status Poda, który tam widzimy, jednoznacznie dyktuje, który zestaw narzędzi i która sekcja tego przewodnika mają zastosowanie.

### 5.7.2. Cykl Życia Awarii Poda

Zamiast traktować błędy jako losową listę, należy je postrzegać jako logiczną sekwencję awarii w "cyklu życia" Poda. Kubelet na węźle próbuje uruchomić Poda w następującej kolejności:

1.  **Planowanie (Scheduler):** Czy Pod może być gdzieś umieszczony?
    * *Błąd:* `Pending` (z powodem `FailedScheduling`).
2.  **Pobieranie Obrazu (Kubelet):** Czy można pobrać obrazy kontenerów?
    * *Błąd:* `ImagePullBackOff` / `ErrImagePull`.
3.  **Konfiguracja Kontenera (Kubelet):** Czy wszystkie `Secrets` i `ConfigMaps$ są na miejscu, aby skonfigurować kontener?
    * *Błąd:* `CreateContainerConfigError`.
4.  **Uruchomienie Kontenera (Runtime):** Czy proces wewnątrz kontenera uruchomił się i pozostał uruchomiony?
    * *Błąd:* `CrashLoopBackOff`.
5.  **Testy Gotowości (Kubelet):** Czy uruchomiony kontener zgłasza, że jest gotowy do przyjmowania ruchu?
    * *Błąd:* `STATUS: Running`, `READY: 0/1`.

Poniższa checklista jest zbudowana wokół tej właśnie sekwencji.

### 5.7.3. Tabela 4: Ostateczna Checklista Rozwiązywania Problemów z Podem

#### 5.7.3.1. Scenariusz 1: `STATUS: Pending`

* **Co to oznacza:** Problem z planistą (Schedulerem). Kontener nawet nie próbował się uruchomić.[11, 31]
* **Krok 1: Weryfikacja:** Uruchom `oc describe pod <pod-name>`. Przewiń na dół do sekcji `Events`.[21, 22, 29]
* **Krok 2: Działanie (na podstawie komunikatu zdarzenia):**
    * **Komunikat:** `FailedScheduling (insufficient cpu/memory)`.[10]
    * **Działanie:** Sprawdź bieżące wykorzystanie węzłów za pomocą `oc adm top nodes`.[11] Rozważ zmniejszenie `requests` Poda w jego `DeploymentConfig` lub dodanie nowych węzłów do klastra.
    * **Komunikat:** `FailedScheduling (...didn't tolerate taint...)`.[12, 14, 33]
    * **Działanie:** Sprawdź tainty na węzłach (`oc describe node <node-name> | grep Taints`). Dodaj odpowiednią `toleration` do `spec.template.spec` Poda w jego `DeploymentConfig`.
    * **Komunikat:** `FailedScheduling (...unbound immediate PersistentVolumeClaims)`.[15]
    * **Działanie:** Problem leży w pamięci masowej. Uruchom `oc describe pvc <nazwa-pvc>` i sprawdź jego zdarzenia, aby zobaczyć, dlaczego nie może się związać (np. zła `storageClassName` lub brak dostępnych `PV`).
    * **Komunikat:** `FailedMount` (Technicznie może się zdarzyć po `Pending`, ale jest powiązane).
    * **Działanie:** Sprawdź komunikat błędu. Zazwyczaj jest to `secret "my-secret" not found` [12, 13] lub `ConfigMap "my-config" not found`.[114] Zweryfikuj, czy te zasoby istnieją w tej samej przestrzeni nazw.

#### 5.7.3.2. Scenariusz 2: `STATUS: ImagePullBackOff` / `ErrImagePull`

* **Co to oznacza:** Problem z rejestrem lub obrazem. Kubelet znalazł węzeł, ale nie może pobrać obrazu kontenera.[115, 116, 117]
* **Krok 1: Weryfikacja:** Uruchom `oc describe pod <pod-name>`.[7]
    * Dokładnie sprawdź pole `Image:$ w definicji kontenera. Czy nazwa rejestru, obrazu i tag są w 100% poprawne?.[9]
    * Sprawdź sekcję `Events`. Zobaczysz tam dokładny powód błędu, np. `manifest unknown` (zły tag) lub `authentication required`.[7]
* **Krok 2: Działanie:**
    * **Jeśli błędny tag/nazwa:** Popraw pole `image:` w `DeploymentConfig` i wdróż ponownie.
    * **Jeśli problem z `ImageStream`:** (Specyficzne dla OpenShift) Użyj `oc describe is/<nazwa-is>` [118, 119], aby sprawdzić, czy `ImageStreamTag` został poprawnie zaimportowany z zewnętrznego rejestru.
    * **Jeśli problem z autoryzacją (`authentication required`):** [7, 17, 120, 121]
        1.  Sprawdź, czy `Secret` z poświadczeniami istnieje: `oc get secret <nazwa-sekretu-rejestru>`.
        2.  Sprawdź, czy `ServiceAccount` (konto serwisowe), na którym działa Pod (domyślnie `default`), ma ten `Secret` podłączony do pobierania obrazów. Uruchom `oc describe sa default` i poszukaj `Secretu` w sekcji `Image pull secrets:`.
        3.  Jeśli go brakuje, podłącz go: `oc secrets link default <nazwa-sekretu-rejestru> --for=pull`.[7, 8]

#### 5.7.3.3. Scenariusz 3: `STATUS: CreateContainerConfigError`

* **Co to oznacza:** Konfiguracja Poda jest uszkodzona. Obraz został pobrany, ale Kubelet nie może uruchomić kontenera, ponieważ brakuje zasobu konfiguracyjnego, do którego się odwołuje.[114, 115, 122, 123]
* **Krok 1: Weryfikacja:** Uruchom `oc describe pod <pod-name>`. Sekcja `Events$ powie Ci *dokładnie*, czego brakuje.[114]
    * **Przykład:** `Events:... Error: ConfigMap "my-app-config" not found` [114] lub `Error: secret "my-db-secret" not found`.[122, 124]
* **Krok 2: Działanie:**
    * Sprawdź pisownię nazwy zasobu w `DeploymentConfig`.
    * Sprawdź, czy `ConfigMap` lub `Secret` o tej nazwie istnieje w *tej samej* przestrzeni nazw: `oc get configmap my-app-config`.
    * Jeśli nie, utwórz brakujący zasób.

#### 5.7.3.4. Scenariusz 4: `STATUS: CrashLoopBackOff`

* **Co to oznacza:** Problem z aplikacją. Platforma zrobiła wszystko poprawnie (zaplanowała, pobrała obraz, skonfigurowała), ale proces wewnątrz kontenera uruchomił się i natychmiast zakończył z błędem.[50, 115, 117, 125]
* **Krok 1: Weryfikacja (Logi):** Uruchom `oc logs -p <pod-name>`.[49, 55]
    * Przeanalizuj logi z *poprzedniego* uruchomienia. Szukaj śladów stosu (np. `Java NullPointerException`), błędów konfiguracyjnych (np. `File not found`) lub błędów połączenia (np. `Connection refused to database`).
* **Krok 2: Działanie (Debugowanie interaktywne):**
    * Jeśli logi są niejasne lub puste, użyj `oc debug pod/<pod-name>`.[49, 64, 65, 70]
    * Po wejściu do powłoki debugującej, ręcznie uruchom proces aplikacji (np. `java -jar /app.jar`) i obserwuj błędy na konsoli.
    * Użyj narzędzi (jak w Lekcji 5.4): sprawdź `env`, `ls -l` na wolumenach konfiguracyjnych i `curl` do testowania połączeń z zależnościami (np. bazą danych).

#### 5.7.3.5. Scenariusz 5: `STATUS: Running`, `READY: 0/1`

* **Co to oznacza:** Aplikacja działa, ale jej *test gotowości (readiness probe)* kończy się niepowodzeniem. OpenShift uważa, że aplikacja nie jest gotowa do przyjmowania ruchu.[117]
* **Krok 1: Weryfikacja:** Uruchom `oc describe pod <pod-name>`.
    * Znajdź sekcję `Readiness Probe` i zobacz, jak jest skonfigurowana (np. `httpGet` na ścieżce `/healthz` na porcie 8080).
    * Sprawdź sekcję `Events$. Zobaczysz powtarzające się ostrzeżenia, np. `Readiness probe failed: HTTP GET http://...: 503 Service Unavailable`.
* **Krok 2: Działanie:**
    * Użyj `oc exec -it <pod-name> -- /bin/bash`.
    * Będąc wewnątrz Poda, *ręcznie* wykonaj test gotowości: `curl localhost:8080/healthz`.
    * Prawdopodobnie polecenie `curl$ zwróci błąd 503 lub inny, który możesz teraz debugować. Może to oznaczać, że aplikacja jeszcze się uruchamia (`initialDelaySeconds` jest zbyt krótkie) lub że punkt końcowy `/healthz` ma błąd w kodzie.

---

## Cytowane prace

1. Upgrading Clusters | OpenShift Container Platform | 3.11 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.11/html-single/upgrading\_clusters/index](https://docs.redhat.com/en/documentation/openshift_container_platform/3.11/html-single/upgrading_clusters/index)  
2. Chapter 3\. Performing blue-green cluster upgrades \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.11/html/upgrading\_clusters/upgrading-blue-green-deployments](https://docs.redhat.com/en/documentation/openshift_container_platform/3.11/html/upgrading_clusters/upgrading-blue-green-deployments)  
3. Chapter 5\. Upgrading a Cluster | Installation and Configuration | OpenShift Container Platform | 3.4 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.4/html/installation\_and\_configuration/upgrading-a-cluster](https://docs.redhat.com/en/documentation/openshift_container_platform/3.4/html/installation_and_configuration/upgrading-a-cluster)  
4. Blue-Green Deployments \- Upgrading a Cluster | Installation and Configuration | OpenShift Origin Branch Build \- Fedora, otwierano: listopada 14, 2025, [https://miminar.fedorapeople.org/openshift-docs/prometheus-metrics-registered/install\_config/upgrading/blue\_green\_deployments.html](https://miminar.fedorapeople.org/openshift-docs/prometheus-metrics-registered/install_config/upgrading/blue_green_deployments.html)  
5. 1327644 – oc/kubectl get events \-w showing old events from 2 hours prior, otwierano: listopada 14, 2025, [https://bugzilla.redhat.com/show\_bug.cgi?id=1327644](https://bugzilla.redhat.com/show_bug.cgi?id=1327644)  
6. Monitoring cluster events and logs \- Container security \- OKD Documentation, otwierano: listopada 14, 2025, [https://docs.okd.io/4.16/security/container\_security/security-monitoring.html](https://docs.okd.io/4.16/security/container_security/security-monitoring.html)  
7. Mastering Pod Error Troubleshooting in OpenShift: ImagePullBackOff & CrashLoopBackOff | by Pravin More | Medium, otwierano: listopada 14, 2025, [https://medium.com/@morepravin1989/mastering-pod-error-troubleshooting-in-openshift-imagepullbackoff-crashloopbackoff-bac81832071a](https://medium.com/@morepravin1989/mastering-pod-error-troubleshooting-in-openshift-imagepullbackoff-crashloopbackoff-bac81832071a)  
8. Pod Error Troubleshooting in OpenShift | by Pravin More | Medium, otwierano: listopada 14, 2025, [https://medium.com/@morepravin1989/pod-error-troubleshooting-in-openshift-6904518f2375](https://medium.com/@morepravin1989/pod-error-troubleshooting-in-openshift-6904518f2375)  
9. How to use Kubernetes events for effective alerting and monitoring | CNCF, otwierano: listopada 14, 2025, [https://www.cncf.io/blog/2023/03/13/how-to-use-kubernetes-events-for-effective-alerting-and-monitoring/](https://www.cncf.io/blog/2023/03/13/how-to-use-kubernetes-events-for-effective-alerting-and-monitoring/)  
10. Troubleshooting \- OpenShift Examples, otwierano: listopada 14, 2025, [https://examples.openshift.pub/troubleshooting/](https://examples.openshift.pub/troubleshooting/)  
11. OpenShift Pending Pods \- Doctor Droid, otwierano: listopada 14, 2025, [https://drdroid.io/stack-diagnosis/openshift-pending-pods](https://drdroid.io/stack-diagnosis/openshift-pending-pods)  
12. IBM Storage Scale Container Native Storage Access 5.2.1, otwierano: listopada 14, 2025, [https://www.ibm.com/docs/en/STXKQY\_CNS\_SHR\_5.2.1/pdf/scale\_cns\_521x.pdf](https://www.ibm.com/docs/en/STXKQY_CNS_SHR_5.2.1/pdf/scale_cns_521x.pdf)  
13. IBM Storage Scale Container Native Storage Access 5.1.9, otwierano: listopada 14, 2025, [https://www.ibm.com/docs/en/STXKQY\_CNS\_SHR\_5.1.9/pdf/scale\_cns\_519x.pdf](https://www.ibm.com/docs/en/STXKQY_CNS_SHR_5.1.9/pdf/scale_cns_519x.pdf)  
14. Anti-Affinity OpenShift: Tutorial & Instructions \- Densify, otwierano: listopada 14, 2025, [https://www.densify.com/openshift-tutorial/anti-affinity-openshift/](https://www.densify.com/openshift-tutorial/anti-affinity-openshift/)  
15. Search OpenShift CI, otwierano: listopada 14, 2025, [https://search.ci.openshift.org/?search=event+happened+](https://search.ci.openshift.org/?search=event+happened+)  
16. Chapter 13\. Logging, events, and monitoring | OpenShift Virtualization \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.9/html/virtualization/logging-events-and-monitoring](https://docs.redhat.com/en/documentation/openshift_container_platform/4.9/html/virtualization/logging-events-and-monitoring)  
17. Troubleshoot with Kubernetes events \- Datadog, otwierano: listopada 14, 2025, [https://www.datadoghq.com/blog/monitor-kubernetes-events/](https://www.datadoghq.com/blog/monitor-kubernetes-events/)  
18. Chapter 7\. Troubleshooting | Support | OpenShift Container Platform | 4.9 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.9/html/support/troubleshooting](https://docs.redhat.com/en/documentation/openshift_container_platform/4.9/html/support/troubleshooting)  
19. Chapter 7\. Troubleshooting | Support | OpenShift Container Platform | 4.14, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.14/html/support/troubleshooting](https://docs.redhat.com/en/documentation/openshift_container_platform/4.14/html/support/troubleshooting)  
20. Chapter 5\. Troubleshooting | Support | OpenShift Container Platform | 4.5 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.5/html/support/troubleshooting](https://docs.redhat.com/en/documentation/openshift_container_platform/4.5/html/support/troubleshooting)  
21. Troubleshooting \- IBM, otwierano: listopada 14, 2025, [https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/24.0.0?topic=manager-troubleshooting](https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/24.0.0?topic=manager-troubleshooting)  
22. Chapter 7\. Troubleshooting | Support | OpenShift Container Platform | 4.16, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.16/html/support/troubleshooting](https://docs.redhat.com/en/documentation/openshift_container_platform/4.16/html/support/troubleshooting)  
23. OpenShift Container Platform 4.16 Nodes \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.16/pdf/nodes/OpenShift\_Container\_Platform-4.16-Nodes-en-US.pdf](https://docs.redhat.com/en/documentation/openshift_container_platform/4.16/pdf/nodes/OpenShift_Container_Platform-4.16-Nodes-en-US.pdf)  
24. Chapter 2\. Working with pods | Nodes | OpenShift Container Platform | 4.8, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/nodes/working-with-pods](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/nodes/working-with-pods)  
25. Chapter 1\. Working with pods | Nodes | OpenShift Container Platform | 4.1 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.1/html/nodes/working-with-pods](https://docs.redhat.com/en/documentation/openshift_container_platform/4.1/html/nodes/working-with-pods)  
26. Chapter 2\. Working with pods | Nodes | OpenShift Container Platform | 4.12, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.12/html/nodes/working-with-pods](https://docs.redhat.com/en/documentation/openshift_container_platform/4.12/html/nodes/working-with-pods)  
27. Chapter 13\. Logging, events, and monitoring | OpenShift Virtualization \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/openshift\_virtualization/logging-events-and-monitoring](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/openshift_virtualization/logging-events-and-monitoring)  
28. Viewing Operator status \- Administrator tasks | Operators | OKD 4.19 \- OKD Documentation, otwierano: listopada 14, 2025, [https://docs.okd.io/4.19/operators/admin/olm-status.html](https://docs.okd.io/4.19/operators/admin/olm-status.html)  
29. OpenShift PodTerminated \- Doctor Droid, otwierano: listopada 14, 2025, [https://drdroid.io/stack-diagnosis/openshift-podterminated](https://drdroid.io/stack-diagnosis/openshift-podterminated)  
30. Chapter 4\. Controlling pod placement onto nodes (scheduling) | Nodes | OpenShift Container Platform | 4.11 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.11/html/nodes/controlling-pod-placement-onto-nodes-scheduling](https://docs.redhat.com/en/documentation/openshift_container_platform/4.11/html/nodes/controlling-pod-placement-onto-nodes-scheduling)  
31. Top 100 Kubernetes Interview Questions and Answers 2025 \- Turing, otwierano: listopada 14, 2025, [https://www.turing.com/interview-questions/kubernetes](https://www.turing.com/interview-questions/kubernetes)  
32. Chapter 8\. Working with clusters | Nodes | OpenShift Container Platform | 4.10, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.10/html/nodes/working-with-clusters](https://docs.redhat.com/en/documentation/openshift_container_platform/4.10/html/nodes/working-with-clusters)  
33. Error installing in Openshift Codeready Containers \- Portworx forum, otwierano: listopada 14, 2025, [https://forums.portworx.com/t/error-installing-in-openshift-codeready-containers/503](https://forums.portworx.com/t/error-installing-in-openshift-codeready-containers/503)  
34. Solved: Pending Pods \- Red Hat Learning Community, otwierano: listopada 14, 2025, [https://learn.redhat.com/t5/DO280-Red-Hat-OpenShift/Pending-Pods/td-p/35635](https://learn.redhat.com/t5/DO280-Red-Hat-OpenShift/Pending-Pods/td-p/35635)  
35. Chapter 2\. Controlling pod placement onto nodes (scheduling) \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.4/html/nodes/controlling-pod-placement-onto-nodes-scheduling](https://docs.redhat.com/en/documentation/openshift_container_platform/4.4/html/nodes/controlling-pod-placement-onto-nodes-scheduling)  
36. Chapter 3\. Controlling pod placement onto nodes (scheduling) \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.9/html/nodes/controlling-pod-placement-onto-nodes-scheduling](https://docs.redhat.com/en/documentation/openshift_container_platform/4.9/html/nodes/controlling-pod-placement-onto-nodes-scheduling)  
37. Logging :: OpenShift Starter Guides, otwierano: listopada 14, 2025, [https://redhat-scholars.github.io/openshift-starter-guides/rhs-openshift-starter-guides/4.11/parksmap-logging.html](https://redhat-scholars.github.io/openshift-starter-guides/rhs-openshift-starter-guides/4.11/parksmap-logging.html)  
38. Logging \- OpenShift Dedicated Workshop, otwierano: listopada 14, 2025, [https://www.osdworkshop.io/9-logging/](https://www.osdworkshop.io/9-logging/)  
39. Chapter 2\. OpenShift CLI (oc) | CLI tools \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.10/html/cli\_tools/openshift-cli-oc](https://docs.redhat.com/en/documentation/openshift_container_platform/4.10/html/cli_tools/openshift-cli-oc)  
40. Chapter 6\. Viewing cluster logs | Logging | OpenShift Container Platform | 4.2, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.2/html/logging/cluster-logging-viewing](https://docs.redhat.com/en/documentation/openshift_container_platform/4.2/html/logging/cluster-logging-viewing)  
41. OpenShift Container Platform 4.11 Nodes \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.11/pdf/nodes/OpenShift\_Container\_Platform-4.11-Nodes-en-US.pdf](https://docs.redhat.com/en/documentation/openshift_container_platform/4.11/pdf/nodes/OpenShift_Container_Platform-4.11-Nodes-en-US.pdf)  
42. OpenShift Container Platform 3.11 Developer Guide \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.11/pdf/developer\_guide/developer-guide-english.pdf](https://docs.redhat.com/en/documentation/openshift_container_platform/3.11/pdf/developer_guide/developer-guide-english.pdf)  
43. OpenShift Container Platform 4.17 Nodes \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.17/pdf/nodes/OpenShift\_Container\_Platform-4.17-Nodes-en-US.pdf](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/pdf/nodes/OpenShift_Container_Platform-4.17-Nodes-en-US.pdf)  
44. Command-Line Walkthrough | Getting Started | OpenShift Container Platform Branch Build, otwierano: listopada 14, 2025, [https://miminar.fedorapeople.org/\_preview/openshift-enterprise/registry-redeploy/getting\_started/developers\_cli.html](https://miminar.fedorapeople.org/_preview/openshift-enterprise/registry-redeploy/getting_started/developers_cli.html)  
45. Openshift CrashLoopBackOff \- Stack Overflow, otwierano: listopada 14, 2025, [https://stackoverflow.com/questions/75699565/openshift-crashloopbackoff](https://stackoverflow.com/questions/75699565/openshift-crashloopbackoff)  
46. IBM Spectrum Scale : Container Native Storage Access Guide, otwierano: listopada 14, 2025, [https://www.ibm.com/docs/en/STXKQY\_CNS\_SHR\_5.1.9/pdf/scale\_cns\_515x.pdf](https://www.ibm.com/docs/en/STXKQY_CNS_SHR_5.1.9/pdf/scale_cns_515x.pdf)  
47. IBM Spectrum Scale : Container Native Storage Access Guide, otwierano: listopada 14, 2025, [https://www.ibm.com/docs/en/STXKQY\_CNS\_SHR\_5.1.9/pdf/scale\_cns\_513x.pdf](https://www.ibm.com/docs/en/STXKQY_CNS_SHR_5.1.9/pdf/scale_cns_513x.pdf)  
48. IBM Spectrum Scale Container Native Storage Access Guide 5.1.2.1, otwierano: listopada 14, 2025, [https://www.ibm.com/docs/en/STXKQY\_CNS\_SHR\_5.1.9/pdf/scale\_cns\_5121.pdf](https://www.ibm.com/docs/en/STXKQY_CNS_SHR_5.1.9/pdf/scale_cns_5121.pdf)  
49. OpenShift Troubleshooting Resources \- Red Hat Partner Connect, otwierano: listopada 14, 2025, [https://connect.redhat.com/en/blog/openshift-troubleshooting-resources](https://connect.redhat.com/en/blog/openshift-troubleshooting-resources)  
50. Troubleshoot and Fix Kubernetes CrashLoopBackoff Status \- Komodor, otwierano: listopada 14, 2025, [https://komodor.com/learn/how-to-fix-crashloopbackoff-kubernetes-error/](https://komodor.com/learn/how-to-fix-crashloopbackoff-kubernetes-error/)  
51. OpenShift Container Platform 4.13 Nodes \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.13/pdf/nodes/OpenShift\_Container\_Platform-4.13-Nodes-en-US.pdf](https://docs.redhat.com/en/documentation/openshift_container_platform/4.13/pdf/nodes/OpenShift_Container_Platform-4.13-Nodes-en-US.pdf)  
52. OpenShift Container Platform 4.14 Nodes \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.14/pdf/nodes/OpenShift\_Container\_Platform-4.14-Nodes-en-US.pdf](https://docs.redhat.com/en/documentation/openshift_container_platform/4.14/pdf/nodes/OpenShift_Container_Platform-4.14-Nodes-en-US.pdf)  
53. OpenShift Dedicated 4 Nodes \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en-us/documentation/openshift\_dedicated/4/pdf/nodes/OpenShift\_Dedicated-4-Nodes-en-US.pdf](https://docs.redhat.com/en-us/documentation/openshift_dedicated/4/pdf/nodes/OpenShift_Dedicated-4-Nodes-en-US.pdf)  
54. OpenShift \- Container \- Platform 4.5 Nodes en US PDF \- Scribd, otwierano: listopada 14, 2025, [https://www.scribd.com/document/488853139/OpenShift-Container-Platform-4-5-Nodes-en-US-pdf](https://www.scribd.com/document/488853139/OpenShift-Container-Platform-4-5-Nodes-en-US-pdf)  
55. Debugging CrashLoopBackOff for an image running as root in openshift origin, otwierano: listopada 14, 2025, [https://stackoverflow.com/questions/38844372/debugging-crashloopbackoff-for-an-image-running-as-root-in-openshift-origin](https://stackoverflow.com/questions/38844372/debugging-crashloopbackoff-for-an-image-running-as-root-in-openshift-origin)  
56. OpenShift Container Platform 3.5 Developer Guide \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.5/pdf/developer\_guide/OpenShift\_Container\_Platform-3.5-Developer\_Guide-en-US.pdf](https://docs.redhat.com/en/documentation/openshift_container_platform/3.5/pdf/developer_guide/OpenShift_Container_Platform-3.5-Developer_Guide-en-US.pdf)  
57. subnet-router pod crashlooping on openshift · Issue \#4178 \- GitHub, otwierano: listopada 14, 2025, [https://github.com/tailscale/tailscale/issues/4178](https://github.com/tailscale/tailscale/issues/4178)  
58. Not able to get python stdout logs in container to "oc logs" \- Stack Overflow, otwierano: listopada 14, 2025, [https://stackoverflow.com/questions/55689398/not-able-to-get-python-stdout-logs-in-container-to-oc-logs](https://stackoverflow.com/questions/55689398/not-able-to-get-python-stdout-logs-in-container-to-oc-logs)  
59. Chapter 6\. Working with containers | Nodes | OpenShift Container Platform | 4.8, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/nodes/working-with-containers](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/nodes/working-with-containers)  
60. Debugging app deployments \- IBM Cloud Docs, otwierano: listopada 14, 2025, [https://cloud.ibm.com/docs/openshift?topic=openshift-debug\_apps](https://cloud.ibm.com/docs/openshift?topic=openshift-debug_apps)  
61. Chapter 2\. OpenShift CLI (oc) \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/cli\_tools/openshift-cli-oc](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/cli_tools/openshift-cli-oc)  
62. Troubleshooting OpenShift Clusters and Workloads | by Martin Heinz \- Medium, otwierano: listopada 14, 2025, [https://medium.com/@martin.heinz/troubleshooting-openshift-clusters-and-workloads-382664018935](https://medium.com/@martin.heinz/troubleshooting-openshift-clusters-and-workloads-382664018935)  
63. Troubleshooting OpenShift Clusters and Workloads | Martin Heinz | Personal Website & Blog, otwierano: listopada 14, 2025, [https://martinheinz.dev/blog/26](https://martinheinz.dev/blog/26)  
64. A visual guide on troubleshooting Kubernetes deployments | Hacker News, otwierano: listopada 14, 2025, [https://news.ycombinator.com/item?id=21711748](https://news.ycombinator.com/item?id=21711748)  
65. Is there a way to prevent Kubernetes from killing and restarting a pod (from a d... | Hacker News, otwierano: listopada 14, 2025, [https://news.ycombinator.com/item?id=21713206](https://news.ycombinator.com/item?id=21713206)  
66. Using the IBM Block Storage CSI driver in a Red Hat OpenShift environment, otwierano: listopada 14, 2025, [https://www.redbooks.ibm.com/redpapers/pdfs/redp5613.pdf](https://www.redbooks.ibm.com/redpapers/pdfs/redp5613.pdf)  
67. Basic commands \- Container Platform Utrecht University, otwierano: listopada 14, 2025, [https://docs.cp.its.uu.nl/content/basics/basic-commands/](https://docs.cp.its.uu.nl/content/basics/basic-commands/)  
68. Connecting to a Containers :: OpenShift Starter Guides, otwierano: listopada 14, 2025, [https://redhat-scholars.github.io/openshift-starter-guides/rhs-openshift-starter-guides/4.11/parksmap-rsh.html](https://redhat-scholars.github.io/openshift-starter-guides/rhs-openshift-starter-guides/4.11/parksmap-rsh.html)  
69. Logging for egress firewall and network policy rules \- OKD Documentation, otwierano: listopada 14, 2025, [https://docs.okd.io/4.13/networking/ovn\_kubernetes\_network\_provider/logging-network-policy.html](https://docs.okd.io/4.13/networking/ovn_kubernetes_network_provider/logging-network-policy.html)  
70. Troubleshooting OpenShift Pods and Network Issues: A Guide for Administrators \- Medium, otwierano: listopada 14, 2025, [https://medium.com/@ibrahim.patel89/troubleshooting-openshift-pods-and-network-issues-a-guide-for-administrators-f739c8af378e](https://medium.com/@ibrahim.patel89/troubleshooting-openshift-pods-and-network-issues-a-guide-for-administrators-f739c8af378e)  
71. OpenShift: Practical Experience \- GS UK Conference, otwierano: listopada 14, 2025, [https://conferences.gse.org.uk/2020/presentations/1AB.pdf](https://conferences.gse.org.uk/2020/presentations/1AB.pdf)  
72. how to debug container images using openshift \- Stack Overflow, otwierano: listopada 14, 2025, [https://stackoverflow.com/questions/41771430/how-to-debug-container-images-using-openshift](https://stackoverflow.com/questions/41771430/how-to-debug-container-images-using-openshift)  
73. OpenShift \- List environment variables using the oc set env command \- FreeKB, otwierano: listopada 14, 2025, [https://www.freekb.net/Article?id=4141](https://www.freekb.net/Article?id=4141)  
74. Chapter 21\. ConfigMaps | Developer Guide | OpenShift Container Platform | 3.11, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.11/html/developer\_guide/dev-guide-configmaps](https://docs.redhat.com/en/documentation/openshift_container_platform/3.11/html/developer_guide/dev-guide-configmaps)  
75. accessing/passing openshift pod environment variables within scripted “oc rsh” calls \- Stack Overflow, otwierano: listopada 14, 2025, [https://stackoverflow.com/questions/56534884/accessing-passing-openshift-pod-environment-variables-within-scripted-oc-rsh-c](https://stackoverflow.com/questions/56534884/accessing-passing-openshift-pod-environment-variables-within-scripted-oc-rsh-c)  
76. Chapter 21\. Configuring for Azure | Configuring Clusters | OpenShift Container Platform | 3.10 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.10/html/configuring\_clusters/install-config-configuring-azure](https://docs.redhat.com/en/documentation/openshift_container_platform/3.10/html/configuring_clusters/install-config-configuring-azure)  
77. We want to start running all containers by default with /dev/fuse. · Issue \#362 · openshift/enhancements \- GitHub, otwierano: listopada 14, 2025, [https://github.com/openshift/enhancements/issues/362](https://github.com/openshift/enhancements/issues/362)  
78. Linux Capabilities in OpenShift \- Red Hat, otwierano: listopada 14, 2025, [https://www.redhat.com/en/blog/linux-capabilities-in-openshift](https://www.redhat.com/en/blog/linux-capabilities-in-openshift)  
79. Chapter 39\. Troubleshooting OpenShift SDN | Cluster Administration \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.11/html/cluster\_administration/admin-guide-sdn-troubleshooting](https://docs.redhat.com/en/documentation/openshift_container_platform/3.11/html/cluster_administration/admin-guide-sdn-troubleshooting)  
80. OpenShift \- Resolve "Connection timed out" \- FreeKB, otwierano: listopada 14, 2025, [https://www.freekb.net/Article?id=4535](https://www.freekb.net/Article?id=4535)  
81. An example OpenShift cronjob, demonstrating many features of Kubernetes and OpenShift \- GitHub, otwierano: listopada 14, 2025, [https://github.com/clcollins/openshift-cronjob-example](https://github.com/clcollins/openshift-cronjob-example)  
82. Logging, Monitoring, and Debugging \- Deploying to OpenShift \[Book\] \- O'Reilly, otwierano: listopada 14, 2025, [https://www.oreilly.com/library/view/deploying-to-openshift/9781491957158/ch18.html](https://www.oreilly.com/library/view/deploying-to-openshift/9781491957158/ch18.html)  
83. Chapter 7\. Builds | Developer Guide | OpenShift Container Platform | 3.4, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.4/html/developer\_guide/builds](https://docs.redhat.com/en/documentation/openshift_container_platform/3.4/html/developer_guide/builds)  
84. OpenShift CheatSheet \- by Darius Murawski \- Medium, otwierano: listopada 14, 2025, [https://medium.com/@dariusmurawski/openshift-cheatsheet-ad4950e21060](https://medium.com/@dariusmurawski/openshift-cheatsheet-ad4950e21060)  
85. OpenShift Container Platform Troubleshooting Guide \- techbloc.net, otwierano: listopada 14, 2025, [https://techbloc.net/archives/3716](https://techbloc.net/archives/3716)  
86. Use VS Code to debug .NET applications \- Red Hat Developer, otwierano: listopada 14, 2025, [https://developers.redhat.com/articles/2022/01/07/debug-net-applications-running-kubernetes-vs-code](https://developers.redhat.com/articles/2022/01/07/debug-net-applications-running-kubernetes-vs-code)  
87. Red Hat OpenShift Container Platform, otwierano: listopada 14, 2025, [https://access.redhat.com/sites/default/files/attachments/openshift\_get\_the\_most\_out\_of\_support.pdf](https://access.redhat.com/sites/default/files/attachments/openshift_get_the_most_out_of_support.pdf)  
88. How to get a file out of a failed build-pod from OpenShift? \- Server Fault, otwierano: listopada 14, 2025, [https://serverfault.com/questions/950091/how-to-get-a-file-out-of-a-failed-build-pod-from-openshift](https://serverfault.com/questions/950091/how-to-get-a-file-out-of-a-failed-build-pod-from-openshift)  
89. 7.5. Accessing build logs | Builds | OpenShift Container Platform \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/zh-cn/documentation/openshift\_container\_platform/4.5/html/builds/builds-basic-access-build-logs\_basic-build-operations](https://docs.redhat.com/zh-cn/documentation/openshift_container_platform/4.5/html/builds/builds-basic-access-build-logs_basic-build-operations)  
90. BuildConfig & Buildah: Failed to push image: authentication required : r/openshift \- Reddit, otwierano: listopada 14, 2025, [https://www.reddit.com/r/openshift/comments/1ll1xv2/buildconfig\_buildah\_failed\_to\_push\_image/](https://www.reddit.com/r/openshift/comments/1ll1xv2/buildconfig_buildah_failed_to_push_image/)  
91. Chapter 5\. Deployments | Applications | OpenShift Container Platform | 4.1 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.1/html/applications/deployments](https://docs.redhat.com/en/documentation/openshift_container_platform/4.1/html/applications/deployments)  
92. How to check deployment health on Red Hat OpenShift, otwierano: listopada 14, 2025, [https://www.redhat.com/en/blog/check-health-openshift](https://www.redhat.com/en/blog/check-health-openshift)  
93. Running 'oc describe dc' should show volume information. · Issue \#7671 · openshift/origin, otwierano: listopada 14, 2025, [https://github.com/openshift/origin/issues/7671](https://github.com/openshift/origin/issues/7671)  
94. Cluster Administration | OpenShift Container Platform | 3.5 \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.5/html-single/cluster\_administration/index](https://docs.redhat.com/en/documentation/openshift_container_platform/3.5/html-single/cluster_administration/index)  
95. Chapter 8\. Managing Networking | Cluster Administration | OpenShift Container Platform | 3.7 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.7/html/cluster\_administration/admin-guide-manage-networking](https://docs.redhat.com/en/documentation/openshift_container_platform/3.7/html/cluster_administration/admin-guide-manage-networking)  
96. Chapter 6\. Managing Networking | Cluster Administration | OpenShift Container Platform | 3.5 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.5/html/cluster\_administration/admin-guide-manage-networking](https://docs.redhat.com/en/documentation/openshift_container_platform/3.5/html/cluster_administration/admin-guide-manage-networking)  
97. native Fabric 8 on openshift \- Stack Overflow, otwierano: listopada 14, 2025, [https://stackoverflow.com/questions/37311034/native-fabric-8-on-openshift](https://stackoverflow.com/questions/37311034/native-fabric-8-on-openshift)  
98. Chapter 5\. Working with nodes | Nodes | OpenShift Container Platform | 4.8 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/nodes/working-with-nodes](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/nodes/working-with-nodes)  
99. Viewing and listing the nodes in your cluster \- Working with nodes \- OKD Documentation, otwierano: listopada 14, 2025, [https://docs.okd.io/4.13/nodes/nodes/nodes-nodes-viewing.html](https://docs.okd.io/4.13/nodes/nodes/nodes-nodes-viewing.html)  
100. How to gather baseline metrics on Kubernetes resource utilization \- Red Hat, otwierano: listopada 14, 2025, [https://www.redhat.com/en/blog/openshift-usage-metrics](https://www.redhat.com/en/blog/openshift-usage-metrics)  
101. Using oc adm top to Monitor Memory Usage \- Red Hat, otwierano: listopada 14, 2025, [https://www.redhat.com/en/blog/using-oc-adm-top-to-monitor-memory-usage](https://www.redhat.com/en/blog/using-oc-adm-top-to-monitor-memory-usage)  
102. Gathering Baseline Openshift Usage Information from Metrics, otwierano: listopada 14, 2025, [https://myopenshiftblog.com/gathering-baseline-openshift-usage-information-from-metrics/](https://myopenshiftblog.com/gathering-baseline-openshift-usage-information-from-metrics/)  
103. Chapter 11\. Node maintenance | OpenShift Virtualization \- Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/openshift\_virtualization/node-maintenance](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/openshift_virtualization/node-maintenance)  
104. Node maintenance \- KubeVirt user guide, otwierano: listopada 14, 2025, [https://kubevirt.io/user-guide/cluster\_admin/node\_maintenance/](https://kubevirt.io/user-guide/cluster_admin/node_maintenance/)  
105. Red Hat OpenShift maintenance \- IBM, otwierano: listopada 14, 2025, [https://www.ibm.com/docs/en/scalecontainernative/5.2.1?topic=maintenance-red-hat-openshift](https://www.ibm.com/docs/en/scalecontainernative/5.2.1?topic=maintenance-red-hat-openshift)  
106. Chapter 6\. Working with nodes | Nodes | OpenShift Container Platform | 4.10 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.10/html/nodes/working-with-nodes](https://docs.redhat.com/en/documentation/openshift_container_platform/4.10/html/nodes/working-with-nodes)  
107. OpenShift Cluster — How to Drain or Evacuate a Node for Maintenance \- Medium, otwierano: listopada 14, 2025, [https://medium.com/techbeatly/openshift-cluster-how-to-drain-or-evacuate-a-node-for-maintenance-e9bf051e4a4e](https://medium.com/techbeatly/openshift-cluster-how-to-drain-or-evacuate-a-node-for-maintenance-e9bf051e4a4e)  
108. must-gather \- IBM, otwierano: listopada 14, 2025, [https://www.ibm.com/docs/en/scalecontainernative/5.2.2?topic=cluster-must-gather](https://www.ibm.com/docs/en/scalecontainernative/5.2.2?topic=cluster-must-gather)  
109. Chapter 5\. Gathering data about your cluster | Support | OpenShift Container Platform | 4.10, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.10/html/support/gathering-cluster-data](https://docs.redhat.com/en/documentation/openshift_container_platform/4.10/html/support/gathering-cluster-data)  
110. Chapter 3\. Gathering diagnostic information for support | Understanding OpenShift GitOps, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/red\_hat\_openshift\_gitops/1.10/html/understanding\_openshift\_gitops/gathering-gitops-diagnostic-information-for-support](https://docs.redhat.com/en/documentation/red_hat_openshift_gitops/1.10/html/understanding_openshift_gitops/gathering-gitops-diagnostic-information-for-support)  
111. Gathering data about your cluster | Support \- OKD Documentation, otwierano: listopada 14, 2025, [https://docs.okd.io/latest/support/gathering-cluster-data.html](https://docs.okd.io/latest/support/gathering-cluster-data.html)  
112. Chapter 3\. Gathering data about your cluster | Support | OpenShift Container Platform | 4.5 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.5/html/support/gathering-cluster-data](https://docs.redhat.com/en/documentation/openshift_container_platform/4.5/html/support/gathering-cluster-data)  
113. otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.5/html/support/gathering-cluster-data\#:\~:text=The%20oc%20adm%20must%2Dgather%20CLI%20command%20collects%20the%20information,Service%20logs](https://docs.redhat.com/en/documentation/openshift_container_platform/4.5/html/support/gathering-cluster-data#:~:text=The%20oc%20adm%20must%2Dgather%20CLI%20command%20collects%20the%20information,Service%20logs)  
114. Fixing Kubernetes CreateContainerConfigError & CreateContainerError \- Spacelift, otwierano: listopada 14, 2025, [https://spacelift.io/blog/createcontainerconfigerror](https://spacelift.io/blog/createcontainerconfigerror)  
115. Amazon EKS and Kubernetes Container Insights with enhanced observability metrics, otwierano: listopada 14, 2025, [https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-metrics-enhanced-EKS.html](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-metrics-enhanced-EKS.html)  
116. IBM Cloud Private System Administrator s Guide, otwierano: listopada 14, 2025, [https://www.redbooks.ibm.com/redbooks/pdfs/sg248440.pdf](https://www.redbooks.ibm.com/redbooks/pdfs/sg248440.pdf)  
117. 11 Pro Ways to Troubleshoot Application Failures with Kubernetes \- overcast blog, otwierano: listopada 14, 2025, [https://overcast.blog/11-pro-ways-to-troubleshoot-application-failures-with-kubernetes-f9c1a5e290a4](https://overcast.blog/11-pro-ways-to-troubleshoot-application-failures-with-kubernetes-f9c1a5e290a4)  
118. Chapter 6\. Resolved issues | Release notes | Red Hat OpenShift AI Cloud Service | 1, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/red\_hat\_openshift\_ai\_cloud\_service/1/html/release\_notes/resolved-issues\_relnotes](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_cloud_service/1/html/release_notes/resolved-issues_relnotes)  
119. cannot use imagestream from job · Issue \#13161 · openshift/origin \- GitHub, otwierano: listopada 14, 2025, [https://github.com/openshift/origin/issues/13161](https://github.com/openshift/origin/issues/13161)  
120. Troubleshooting Guide to Resolving 500 Errors in Kubernetes Production Environments \- DevOpsSchool.com, otwierano: listopada 14, 2025, [https://www.devopsschool.com/blog/troubleshooting-guide-to-resolving-500-errors-in-kubernetes-production-environments/](https://www.devopsschool.com/blog/troubleshooting-guide-to-resolving-500-errors-in-kubernetes-production-environments/)  
121. Chapter 7\. Troubleshooting | Support | OpenShift Container Platform | 4.12 | Red Hat Documentation, otwierano: listopada 14, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.12/html/support/troubleshooting](https://docs.redhat.com/en/documentation/openshift_container_platform/4.12/html/support/troubleshooting)  
122. Fix CreateContainerConfigError & CreateContainerError \- Groundcover, otwierano: listopada 14, 2025, [https://www.groundcover.com/kubernetes-troubleshooting/createcontainerconfigerror-createcontainererror](https://www.groundcover.com/kubernetes-troubleshooting/createcontainerconfigerror-createcontainererror)  
123. How to Resolve A CreateContainerConfigError \- RealTheory, otwierano: listopada 14, 2025, [https://resources.realtheory.io/docs/how-to-resolve-a-createcontainerconfigerror](https://resources.realtheory.io/docs/how-to-resolve-a-createcontainerconfigerror)  
124. Fix CreateContainerError, CreateContainerConfigError in K8s \- Komodor, otwierano: listopada 14, 2025, [https://komodor.com/learn/how-to-fix-createcontainerconfigerror-and-createcontainer-errors/](https://komodor.com/learn/how-to-fix-createcontainerconfigerror-and-createcontainer-errors/)  
125. SAP Data Hub 2 on OpenShift Container Platform 3 \- Red Hat Customer Portal, otwierano: listopada 14, 2025, [https://access.redhat.com/articles/3630111](https://access.redhat.com/articles/3630111)