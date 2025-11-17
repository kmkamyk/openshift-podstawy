# Moduł 9: Zaawansowane Zarządzanie i Skalowanie Aplikacji w Środowiskach Kubernetes: Dogłębna Analiza

---

## Lekcja 9.0: Wprowadzenie do Architektury Zarządzania Aplikacjami

Wdrożenie aplikacji w klastrze Kubernetes lub OpenShift jest zaledwie pierwszym etapem jej cyklu życia. Prawdziwa inżynieria systemów natywnych dla chmury rozpoczyna się po wdrożeniu i koncentruje na zapewnieniu odporności, elastyczności oraz efektywności. Zaawansowane zarządzanie aplikacjami opiera się na trzech fundamentalnych filarach, które zostaną szczegółowo przeanalizowane w niniejszym raporcie:

1.  **Obserwowalność Stanu i Samonaprawa (Lekcja 9.1):** Zdolność systemu do ciągłego monitorowania wewnętrznej kondycji aplikacji i automatycznego reagowania na awarie, zakleszczenia lub stany niegotowości. Realizowane jest to za pomocą sond (`livenessProbe`, `readinessProbe`, `startupProbe`).
2.  **Dynamiczna Adaptacja i Elastyczność (Lekcja 9.2):** Mechanizm automatycznego dostosowywania pojemności aplikacji (liczby replik) do zmieniającego się w czasie rzeczywistym obciążenia, co zapewnia wydajność przy jednoczesnej optymalizacji kosztów. Służy do tego `HorizontalPodAutoscaler` (HPA).
3.  **Zarządzanie Pojemnością i Uczciwy Podział (Lekcja 9.3):** Zbiór polityk administracyjnych, które gwarantują sprawiedliwy podział zasobów klastra w środowiskach wielodostępnych (multi-tenant), zapobiegają monopolizacji zasobów i zapewniają przewidywalność działania. Realizowane jest to przez obiekty `ResourceQuota` i `LimitRange`.

Niniejszy raport wykaże, że te trzy lekcje nie są izolowanymi tematami, lecz stanowią głęboko powiązany, cykliczny system sterowania (feedback control loop) niezbędny do autonomicznego zarządzania aplikacjami. Lekcja 9.3 (`ResourceQuota` i `LimitRange`) ustanawia fundamentalne "prawa fizyki" klastra, definiując gwarancje zasobów (`requests`) oraz limity budżetowe. Lekcja 9.2 (HPA) jest bezpośrednio zależna od tych reguł; oblicza ona bowiem procentowe wykorzystanie zasobów w stosunku do zadeklarowanych `requests` i bez nich nie może funkcjonować. Wreszcie, Lekcja 9.1 (Sondy) działa jako kluczowy stabilizator dla procesów skalowania inicjowanych przez Lekcję 9.2. Kiedy HPA tworzy nowe Pody, to `readinessProbe` zapewnia, że nie otrzymają one ruchu przedwcześnie, co zapobiega błędom i zapewnia płynność działania podczas dynamicznego skalowania. Zrozumienie tej współzależności jest kluczowe dla projektowania niezawodnych systemów na dużą skalę.

---

## Lekcja 9.1: Zapewnienie Kondycji i Gotowości Aplikacji za pomocą Sond (Probes)

### 9.1.1. Fundamentalne Cele Sond: "Życie" vs. "Gotowość"

W ekosystemie Kubernetes, sam fakt, że proces kontenera jest uruchomiony, nie jest wystarczającą informacją o stanie aplikacji. Aplikacja może być uruchomiona, ale zawieszona, lub może być w trakcie uruchamiania i jeszcze niegotowa do przyjmiania żądań. Aby umożliwić systemowi orkiestracji (poprzez agenta `kubelet` na węźle) wgląd w wewnętrzny stan kontenera, stosuje się sondy (Probes).

Koncepcja sond opiera się na rozróżnieniu dwóch kluczowych pytań:

1.  **"Czy aplikacja żyje?" (`livenessProbe`):** Czy aplikacja działa i robi postępy? Jeśli nie, może wymagać restartu, aby powrócić do zdrowego stanu.
2.  **"Czy aplikacja jest gotowa przyjąć ruch?" (`readinessProbe`):** Czy aplikacja jest w stanie natychmiast obsłużyć nowe żądanie?.

Rozróżnienie to jest fundamentalne dla stabilności systemu. Jeśli aplikacja jest przeciążona i wolno odpowiada, jej sonda gotowości może zawieść, co jest pożądane (system przestanie wysyłać do niej nowy ruch). Gdyby jednak w tej samej sytuacji skonfigurowano only sondę żywotności, która by zawiodła, system niepotrzebnie zrestartowałby przeciążony, ale wciąż działający kontener, potencjalnie wywołując kaskadową awarię.

### 9.1.2. Analiza `livenessProbe` (Sonda Żywotności)

Sonda żywotności (`livenessProbe`) jest głównym mechanizmem samonaprawczym (self-healing) w Kubernetes. Jej celem jest wykrywanie i reagowanie na stany, w których aplikacja jest technicznie uruchomiona, ale nie jest w stanie "robić postępów" (`unable to make progress`). Klasycznym przykładem jest zakleszczenie (deadlock) w aplikacji wielowątkowej, gdzie proces istnieje, ale jest całkowicie zablokowany.

Mechanizm działania polega na okresowym wykonywaniu testu przez `kubelet`. Jeśli sonda zawiedzie wielokrotnie (liczba prób jest definiowana przez parametr `failureThreshold`), `kubelet` uznaje kontener za "martwy". Podejmuje wówczas drastyczną, ale konieczną akcję: zabija kontener, a następnie restartuje go zgodnie z polityką restartu Poda (`restartPolicy`).

Pomimo swojej użyteczności, `livenessProbe` jest narzędziem, którego niewłaściwa konfiguracja jest częstą przyczyną kaskadowych awarii, zwłaszcza w przypadku aplikacji o długim czasie uruchamiania. Rozważmy scenariusz opisany w: aplikacja potrzebuje 20 sekund na pełne uruchomienie i rozpoczęcie odpowiadania na żądania. Administrator ustawia `livenessProbe` z domyślnym `timeoutSeconds` (1 sekunda) i krótkim `initialDelaySeconds` (np. 10 sekund). Sonda uruchamia się po 10 sekundach, ale aplikacja jeszcze nie odpowiada. Sonda przekracza limit czasu (1s) i zawodzi. Po kilku kolejnych nieudanych próbach (zgodnie z `periodSeconds` i `failureThreshold`), `kubelet` decyduje, że aplikacja jest martwa i ją restartuje, zanim zdążyła ona w ogóle wystartować. Pod wpada w pętlę restartów, znaną jako `CrashLoopBackOff`. Z tego powodu `livenessProbe` nigdy nie powinna być zależna od czynników inicjalizacyjnych; do tego celu służy `startupProbe`.

### 9.1.3. Analiza `readinessProbe` (Sonda Gotowości)

Sonda gotowości (`readinessProbe`) odpowiada na inne pytanie: czy kontener jest gotowy do przyjmowania ruchu. Jest to kluczowe dla procesów takich jak wdrożenia (rolling updates) oraz skalowanie, ponieważ pozwala uniknąć wysyłania żądań do Poda, który wciąż się ładuje, np. kompiluje JIT, łączy się z bazą danych lub "rozgrzewa" lokalne pamięci podręczne (caches).

Kiedy `readinessProbe` zawodzi, `kubelet` *nie restartuje* kontenera. Zamiast tego, informuje płaszczyznę sterowania, że ten Pod jest w stanie "niegotowy". W rezultacie kontroler `endpoint-controller` usuwa adres IP Poda z listy endpointów powiązanego z nim Serwisu (Service). Ruch przestaje do niego płynąć.

Powszechnym błędem jest myślenie, że `readinessProbe` jest istotna tylko podczas startu Poda. W rzeczywistości, jak potwierdzają źródła, sonda gotowości działa przez cały cykl życia Poda. Jest to kluczowy mechanizm zapewniania odporności. Wyobraźmy sobie aplikację, która tymczasowo traci połączenie z bazą danych lub jest chwilowo przeciążona i nie jest w stanie przyjąć więcej połączeń. Jej `livenessProbe` (która może sprawdzać tylko, czy proces aplikacji istnieje) nadal będzie przechodzić pomyślnie. Jednak `readinessProbe`, która może próbować wykonać proste zapytanie (np. `SELECT 1`), zawiedzie. Kubernetes elegancko wycofa Poda z load balancera, dając mu czas na odzyskanie połączenia lub zasobów. Gdy tylko `readinessProbe` znów zacznie przechodzić pomyślnie, Pod jest automatycznie dodawany z powrotem do puli i zaczyna ponownie obsługiwać ruch.

### 9.1.4. Analiza `startupProbe` (Sonda Startowa)

Sonda startowa (`startupProbe`) została wprowadzona, aby formalnie rozwiązać problem `CrashLoopBackOff` opisany w analizie `livenessProbe`. Jest ona zaprojektowana specjalnie dla wolno startujących aplikacji, takich jak monolityczne aplikacje Java lub aplikacje wymagające skomplikowanej inicjalizacji.

Mechanizm działania `startupProbe` jest unikalny: działa ona *tylko* na początku cyklu życia kontenera. Co najważniejsze, jeśli `startupProbe` jest zdefiniowana, `kubelet` *wyłącza* działanie `livenessProbe` i `readinessProbe` do momentu, aż `startupProbe` zakończy się sukcesem.

Kolejność egzekucji sond jest kluczowa dla stabilności Poda:

1.  Po uruchomieniu kontenera, `kubelet` aktywuje *wyłącznie* `startupProbe`.
2.  Sonda ta jest konfigurowana z bardzo dużą tolerancją na awarie, aby dać aplikacji wystarczająco dużo czasu. Na przykład, konfiguracja w z `failureThreshold: 30` i `periodSeconds: 3` daje aplikacji łącznie 90 sekund na uruchomienie.
3.  W tym czasie `livenessProbe` i `readinessProbe` są całkowicie nieaktywne.
4.  Gdy `startupProbe` w końcu zakończy się sukcesem (np. po 20 sekundach, gdy aplikacja jest gotowa), jest ona wyłączana na stałe dla tego kontenera.
5.  Dopiero w tym momencie `kubelet` aktywuje `livenessProbe` i `readinessProbe`, które od teraz przejmują normalne, okresowe monitorowanie kondycji i gotowości.

Ta sekwencja gwarantuje, że wolno startująca aplikacja nie zostanie przedwcześnie zabita przez zbyt agresywną sondę żywotności.

### 9.1.5. Implementacja i Konfiguracja Sond

Sondy mogą być realizowane za pomocą trzech różnych mechanizmów (handlerów):

1.  **`httpGet`**: Wysyła żądanie HTTP GET na określony adres URL wewnątrz kontenera. Każdy kod odpowiedzi w zakresie 200-399 jest uznawany za sukces. Jest to najczęstszy typ sondy dla aplikacji webowych.
2.  **`tcpSocket`**: Próbuje otworzyć gniazdo TCP na określonym porcie kontenera. Jeśli połączenie zostanie pomyślnie nawiązane, sonda jest uznawana za udaną. Jest to lżejszy mechanizm niż `httpGet`, użyteczny dla usług innych niż HTTP, np. baz danych (jak w przykładzie z portem 3306 dla MySQL).
3.  **`exec`**: Wykonuje polecenie wewnątrz kontenera. Kod wyjścia (exit code) 0 jest uznawany za sukces. Jest to najbardziej elastyczny mechanizm, pozwalający na wykonanie niestandardowych skryptów (np. `cat /tmp/healthy` lub `mongo ping`).

Wybór handlera to kompromis między dokładnością a narzutem. Sonda `tcpSocket` jest bardzo szybka, ale może dać fałszywy pozytywny wynik (port może być otwarty, nawet jeśli aplikacja jest zawieszona). Sonda `httpGet` jest lepsza, ponieważ testuje warstwę aplikacji. Sonda `exec` pozwala na najbardziej złożoną logikę, ale sama wprowadza dodatkowe zależności (np. obecność narzędzia `mongo` w kontenerze) i generuje większy narzut.

Konfiguracja każdej sondy jest kontrolowana przez zestaw precyzyjnych parametrów, których domyślne wartości są kluczowe do zrozumienia.

**Tabela 1: Kluczowe Parametry Konfiguracyjne Sond i Ich Wartości Domyślne**

| Parametr | Wartość domyślna | Cel (Opis) |
| :--- | :--- | :--- |
| `initialDelaySeconds` | 0 sekund | Czas (w sekundach) oczekiwania po starcie kontenera przed pierwszym uruchomieniem sondy. |
| `periodSeconds` | 10 sekund | Jak często (w sekundach) sonda ma być wykonywana (interwał). |
| `timeoutSeconds` | 1 sekunda | Czas (w sekundach), po którym sonda jest uznawana za nieudaną z powodu przekroczenia limitu czasu. |
| `failureThreshold` | 3 | Liczba kolejnych niepowodzeń, po których sonda jest uznawana za "zakończoną niepowodzeniem" (np. restart dla `liveness`). |
| `successThreshold` | 1 | Liczba kolejnych sukcesów wymagana, aby sonda została uznana za "udaną" (szczególnie po wcześniejszym niepowodzeniu). |

Domyślne wartości dla `livenessProbe` (`periodSeconds: 10`, `failureThreshold: 3`, `timeoutSeconds: 1`) oznaczają, że system potrzebuje od 21 do 30 sekund, aby zareagować na trwałą awarię aplikacji. Parametry te muszą być starannie dostosowane do charakterystyki i wymagań danej aplikacji.

---

## Lekcja 9.2: Automatyzacja Skalowania Horyzontalnego za pomocą `HorizontalPodAutoscaler` (HPA)

### 9.2.1. Architektura Autoskalowania w Kubernetes

`HorizontalPodAutoscaler` (HPA) to zasób Kubernetes, który automatycznie aktualizuje zasoby robocze (takie jak `Deployment` lub `StatefulSet`), aby dynamicznie skalować liczbę replik Podów w odpowiedzi na zmieniające się zapotrzebowanie. Jest to fundamentalny mechanizm zapewniania elastyczności aplikacji.

Kluczowe jest rozróżnienie trzech wymiarów autoskalowania w Kubernetes:

1.  **Horizontal Pod Autoscaler (HPA):** Skalowanie "w poziomie". Zwiększa lub zmniejsza liczbę identycznych replik Podów.
2.  **Vertical Pod Autoscaler (VPA):** Skalowanie "w pionie". Dostosowuje zasoby (CPU i pamięć) *istniejących* Podów, zazwyczaj wymagając ich restartu.
3.  **Cluster Autoscaler (CA):** Skalowanie na poziomie klastra. Dodaje lub usuwa całe węzły (Nodes) z klastra, aby dostosować całkowitą pojemność.

HPA i VPA generalnie nie mogą być używane jednocześnie dla tego samego zestawu Podów w oparciu o te same metryki (CPU i pamięć). Powodem jest konflikt w pętli sterowania: HPA podejmuje decyzje o skalowaniu (np. dodaniu Podów) na podstawie *procentowego* wykorzystania zasobów względem `requests`. Z kolei VPA dynamicznie *zmienia* te `requests`. Prowadzi to do destabilizacji systemu (tzw. thrashing), gdzie HPA próbuje skalować w górę, podczas gdy VPA zmienia podstawę jego obliczeń.

Jednocześnie HPA jest w pełni skuteczny tylko wtedy, gdy działa w synergii z Cluster Autoscaler (CA). HPA (działający na poziomie Podów) może zdecydować o dodaniu dziesięciu nowych replik. Jeśli jednak klaster (na poziomie węzłów) nie ma wolnej pojemności, te dziesięć Podów utknie na stałe w stanie `Pending`. W tym momencie do akcji wkracza Cluster Autoscaler (CA), który monitoruje Pody w stanie `Pending` i, jeśli polityka na to pozwala, automatycznie dodaje nowe węzły do klastra, aby pomieścić nowe Pody.

### 9.2.2. Mechanika Pętli Kontrolnej HPA

HPA jest implementowany jako pętla sterowania (control loop) w ramach `kube-controller-manager`. Domyślnie, co 15 sekund (konfigurowalne za pomocą flagi `--horizontal-pod-autoscaler-sync-period`), kontroler HPA wykonuje następujące kroki:

1.  Pobiera metryki dla wszystkich Podów zarządzanych przez dany HPA.
2.  Oblicza aktualne średnie wykorzystanie metryki (np. średnie zużycie CPU).
3.  Na podstawie zdefiniowanego celu (np. `targetCPUUtilizationPercentage: 80`) oblicza pożądaną liczbę replik.
4.  Jeśli pożądana liczba różni się od aktualnej (z uwzględnieniem progów i okresów stabilizacji), HPA aktualizuje pole `replicas` w obiekcie nadrzędnym (np. `Deployment`).
5.  `Deployment` (a właściwie jego `ReplicaSet`) reaguje na tę zmianę, tworząc lub usuwając Pody.

### 9.2.3. Fundamentalna Rola Potoku Metryk

HPA jest całkowicie zależny od dostępności metryk. Domyślnie, do skalowania na podstawie CPU i pamięci, HPA wymaga komponentu klastra o nazwie `Metrics Server`.

Architektura domyślnego potoku metryk wygląda następująco:

1.  `kubelet` na każdym węźle zbiera dane o zużyciu zasobów z CRI (Container Runtime Interface) (np. `containerd`).
2.  `kubelet` udostępnia te zagregowane dane przez swoje Summary API (lub starsze `/stats/summary`).
3.  `Metrics Server` (będący dodatkiem do klastra) cyklicznie pobiera (scrape) dane ze wszystkich Kubeletów.
4.  `Metrics Server` agreguje te dane w pamięci i udostępnia je poprzez Kubernetes Metrics API (np. `metrics.k8s.io`).
5.  Kontroler HPA (a także narzędzia takie jak `kubectl top`) odpytuje ten właśnie API, aby uzyskać dane potrzebne do podejmowania decyzji.

W tym miejscu ujawnia się kluczowe powiązanie między Lekcją 9.2 (HPA) a Lekcją 9.3 (Zasoby). Gdy administrator definiuje HPA, np. `targetCPUUtilizationPercentage: 80`, fundamentalne pytanie brzmi: "80% czego?". Jak potwierdzają źródła, jest to 80% *zadeklarowanego `request.cpu` kontenera*, a nie 80% zasobów węzła.

Przykład:

  * Pod ma zdefiniowane `spec.containers.resources.requests.cpu: 500m`.
  * HPA z celem 80% będzie próbował utrzymać średnie użycie CPU na poziomie 500m * 0.8 = 400m.
  * Jeśli średnie użycie wzrośnie do 500m (100% `request`), HPA obliczy, że potrzebuje 100% / 80% = 1.25 raza więcej replik.

Jak słusznie zauważono w i, bez zdefiniowanych `requests` dla zasobów (CPU lub pamięci), HPA nie jest w stanie obliczyć procentowego wykorzystania i *nie będzie działać* dla metryk zasobowych. Dlatego Lekcja 9.3 (szczególnie `LimitRange` zapewniający domyślne `requests`) jest twardym warunkiem wstępnym dla działania Lekcji 9.2.

### 9.2.4. Zaawansowane Skalowanie Oparte na Metrykach Niestandardowych i Zewnętrznych

Skalowanie oparte na CPU jest często niewystarczające. Prawdziwym wąskim gardłem aplikacji może być liczba żądań na sekundę lub długość kolejki komunikatów (np. w RabbitMQ lub SQS). W takich przypadkach HPA, używając API w wersji `autoscaling/v2`, może skalować się w oparciu o:

  * **Metryki niestandardowe (Custom Metrics):** Metryki związane z obiektami Kubernetes (np. "żądania na sekundę na Pod"). Wymagają one API `custom.metrics.k8s.io`.
  * **Metryki zewnętrzne (External Metrics):** Metryki niezwiązane z obiektami klastra (np. "długość kolejki"). Wymagają one API `external.metrics.k8s.io`.

Te API nie są dostarczane domyślnie. Muszą być zaimplementowane przez "adapter". Najpopularniejszym rozwiązaniem jest `Prometheus Adapter`.

Adapter ten działa jak tłumacz między HPA a systemem monitoringu Prometheus. System Prometheus zbiera szczegółowe metryki przy użyciu własnego mechanizmu zapytań PromQL. HPA nie rozumie PromQL; oczekuje prostego zapytania o wartość metryki. Administrator konfiguruje `Prometheus Adapter` (zazwyczaj poprzez `values.yaml` podczas instalacji Helm), definiując `rules`. Taka reguła mapuje prostą nazwę metryki dostępną dla HPA (np. `nginx_requests_per_second`) na złożone zapytanie PromQL, które faktycznie oblicza tę wartość (np. `sum(rate(http_requests_total{app="nginx"}[2m]))`).

### 9.2.5. Implementacja Praktyczna (OpenShift/Kubernetes)

HPA można utworzyć na dwa sposoby:

1.  **Podejście Imperatywne (z linii poleceń):**
    Użyteczne do szybkiego testowania. W OpenShift (`oc`) lub Kubernetes (`kubectl`) polecenie `autoscale` tworzy obiekt HPA.
    Przykład:
    `$ oc autoscale deployment/hello-node --min=5 --max=7 --cpu-percent=75`
    To polecenie automatycznie tworzy obiekt HPA powiązany (`scaleTargetRef`) z `deployment/hello-node`, ustawiając minimalną i maksymalną liczbę replik oraz cel CPU.

2.  **Podejście Deklaratywne (YAML):**
    Preferowane w środowiskach produkcyjnych i zgodne z praktykami GitOps. Definiuje się obiekt `HorizontalPodAutoscaler` bezpośrednio w pliku YAML.
    Przykład (bazujący na i):

    ```yaml
    apiVersion: autoscaling/v1
    kind: HorizontalPodAutoscaler
    metadata:
      name: php-server
    spec:
      scaleTargetRef:
        apiVersion: apps/v1
        kind: Deployment
        name: php-server
      minReplicas: 3
      maxReplicas: 8
      targetCPUUtilizationPercentage: 60
    ```

---

## Lekcja 9.3: Zarządzanie Zasobami: `ResourceQuota` i `LimitRange`

### 9.3.1. Fundamenty: `requests` vs. `limits`

Zanim przejdziemy do polityk na poziomie przestrzeni nazw, musimy zdefiniować podstawowe jednostki zarządzania zasobami na poziomie kontenera: `requests` (żądania) i `limits` (limity).

  * **`requests` (Żądania):**
      * **Cel:** Używane przez **Scheduler Kubernetes** (`kube-scheduler`).
      * **Działanie:** Jest to **gwarantowana** minimalna ilość zasobów, którą kontener otrzyma. Scheduler używa sumy `requests` wszystkich kontenerów w Podzie do podjęcia decyzji o umieszczeniu go na węźle. Węzeł musi mieć wystarczająco wolnych, niezaalokowanych zasobów, aby przyjąć Poda.
  * **`limits` (Limity):**
      * **Cel:** Egzekwowane przez **Kubelet** na węźle.
      * **Działanie:** Jest to **twarda górna granica** zasobów, której kontener nie może przekroczyć.
          * W przypadku **CPU**, kontener jest "dławiony" (throttled). Jeśli spróbuje użyć więcej CPU niż jego limit, jądro Linux (poprzez mechanizm CFS, Completely Fair Scheduler) ograniczy jego czas procesora.
          * W przypadku **Pamięci**, przekroczenie limitu jest katastrofalne. Kontener jest natychmiast zabijany przez mechanizm OOM (Out of Memory) Killera jądra.

Kombinacja `requests` i `limits` ma kluczowy, choć nieoczywisty wpływ na stabilność Poda, definiując jego klasę **Quality of Service (QoS)**:

1.  **`Guaranteed` (Gwarantowana):** Pod otrzymuje tę klasę, jeśli *każdy* kontener w Podzie ma zdefiniowane `requests` i `limits` dla CPU i pamięci, oraz `requests` są *równe* `limits`. Pody `Guaranteed` są traktowane priorytetowo i są ostatnimi, które zostaną zabite w przypadku braku zasobów na węźle.
2.  **`Burstable` (Elastyczna):** Pod otrzymuje tę klasę, jeśli ma zdefiniowane `requests` i `limits`, ale nie są one równe (zazwyczaj `requests < limits`), lub gdy przynajmniej jeden kontener ma zdefiniowany przynajmniej jeden `request`. Pody te mogą "burstować" i zużywać więcej zasobów (aż do `limits`), jeśli są one wolne na węźle.
3.  **`BestEffort` (Najlepsza Dostępna):** Pod otrzymuje tę klasę, jeśli nie ma zdefiniowanych *żadnych* `requests` ani `limits`. Pody te są pierwszymi kandydatami do eksmisji (zabicia) przez `kubelet`, gdy na węźle zaczyna brakować zasobów.

### 9.3.2. Analiza `ResourceQuota`: Budżet na Poziomie Projektu/Przestrzeni Nazw

`ResourceQuota` jest kluczowym narzędziem administracyjnym w środowiskach współdzielonych (multi-tenant). Jej celem jest adresowanie obawy, że "jeden zespół lub projekt mógłby użyć więcej niż swoją sprawiedliwą część zasobów", potencjalnie destabilizując cały klaster.

Obiekt `ResourceQuota` definiuje ograniczenia na *agregatowe* (sumaryczne) zużycie zasobów *na poziomie całej przestrzeni nazw* (w OpenShift nazywanej Projektem).

`ResourceQuota` może limitować trzy główne kategorie zasobów:

1.  **Zasoby Obliczeniowe:** Ustawia twardy limit (`hard`) na *sumę* zasobów wszystkich Podów w przestrzeni nazw. Przykłady pól: `requests.cpu`, `limits.cpu`, `requests.memory`, `limits.memory`.
2.  **Zasoby Storage:** Ogranicza całkowitą ilość przestrzeni dyskowej (`requests.storage`) oraz łączną liczbę wolumenów (`persistentvolumeclaims`).
3.  **Liczba Obiektów:** Ogranicza maksymalną liczbę obiektów danego typu, jakie mogą istnieć w przestrzeni nazw, np. `pods`, `services`, `secrets`, `configmaps` czy `replicationcontrollers`.

Quota jest egzekwowana na etapie "admission control". Gdy użytkownik próbuje utworzyć nowy obiekt (np. Poda), system sprawdza, czy suma zasobów (w tym nowego Poda) przekroczyłaby zdefiniowany limit `hard`. Jeśli tak, żądanie jest odrzucane ze statusem HTTP 403 Forbidden i komunikatem wyjaśniającym, który limit zostałby naruszony.

### 9.3.3. Analiza `LimitRange`: Domyślne Wartości i Ograniczenia dla Poszczególnych Podów

`LimitRange` również działa na poziomie przestrzeni nazw, jednak w przeciwieństwie do `ResourceQuota`, nie dotyczy sumarycznego zużycia. Zamiast tego `LimitRange` egzekwuje politykę na *poszczególnych* obiektach (takich jak Pod, Kontener lub PVC) w momencie ich tworzenia.

`LimitRange` pełni dwie główne funkcje:

1.  **Ustawianie Domyślnych Wartości:** Automatycznie wstrzykuje (`inject`) wartości domyślne do kontenerów, które ich nie definiują. Najważniejsze z nich to `defaultRequest` (domyślne żądanie) i `default` (domyślny limit).
2.  **Egzekwowanie Ograniczeń:** Weryfikuje, czy wartości podane przez użytkownika mieszczą się w dozwolonych granicach, np. `max` (maksymalny limit, o jaki można poprosić) i `min` (minimalny limit).

`ResourceQuota` i `LimitRange` działają w potężnej synergii, która jest kluczowa dla zarządzania klastrem. Rozważmy następujący scenariusz:

1.  Administrator ustawia `ResourceQuota` w przestrzeni nazw, aby ograniczyć całkowite `requests.cpu` do 10 rdzeni.
2.  `ResourceQuota` ma kluczowy skutek uboczny: aby móc śledzić sumę `requests`, wymusza, aby *każdy* nowy Pod definiował `requests.cpu`. Jeśli deweloper spróbuje utworzyć Poda bez `requests`, kontroler `ResourceQuota` odrzuci go.
3.  To frustruje deweloperów, którzy nie chcą pamiętać o dodawaniu `requests` do każdego Poda testowego.
4.  Aby rozwiązać ten problem, administrator tworzy `LimitRange` w tej samej przestrzeni nazw i ustawia `defaultRequest: { cpu: "100m" }`.
5.  Teraz, gdy deweloper wdraża Poda *bez* zdefiniowanych `requests`:
    a. Kontroler `LimitRange` (będący kontrolerem *mutującym*) przechwytuje żądanie i *wstrzykuje* do definicji Poda `requests.cpu: "100m"`.
    b. Następnie kontroler `ResourceQuota` (będący kontrolerem *walidującym*) sprawdza Poda, widzi, że ma on `requests` (dodane w poprzednim kroku), i akceptuje go (zakładając, że budżet 10 rdzeni nie został jeszcze przekroczony).

W ten sposób `ResourceQuota` ustawia budżet, a `LimitRange` zapewnia, że Pody *automatycznie* spełniają minimalne wymagania `ResourceQuota`, jednocześnie zapobiegając nadmiernym żądaniom (poprzez ustawienie `max` limit).

**Tabela 2: Porównanie `ResourceQuota` vs. `LimitRange`**

| Cecha | `ResourceQuota` | `LimitRange` |
| :--- | :--- | :--- |
| **Zasięg (Scope)** | Poziom Przestrzeni Nazw (Agregat / Suma). | Poziom Obiektu (Pojedynczy Pod/Kontener). |
| **Główny Cel** | Budżetowanie i sprawiedliwy podział zasobów. | Walidacja i ustawianie wartości domyślnych. |
| **Działanie (Admission)** | Odrzuca (Rejects), jeśli *suma* zasobów przekroczy limit. | Mutuje (Mutates) dodając domyślne LUB Waliduje (Validates) min/max. |
| **Przykład Polityki** | "Zespół A nie może użyć więcej niż 10 CPU łącznie". | "Każdy kontener w zespole A domyślnie dostaje 100m CPU i nie może prosić o więcej niż 2 CPU". |

---

## Lekcja 9.4: Synteza: Kompletny Model Zarządzania Cyklem Życia Aplikacji

Trzy przeanalizowane lekcje łączą się w jeden, spójny i holistyczny przepływ pracy, który definiuje autonomiczne zarządzanie aplikacją w Kubernetes. Rozważmy pełny scenariusz end-to-end:

### 9.4.1. Faza 0: Konfiguracja Platformy (Lekcja 9.3)
Administrator klastra tworzy przestrzeń nazw "production-team-a" dla nowego zespołu.

1.  Aby kontrolować koszty i zapewnić sprawiedliwy podział, administrator tworzy `ResourceQuota`, ograniczając zespół do sumarycznego użycia 50 CPU, 250Gi RAM i 10 wolumenów PVC.
2.  Aby ułatwić pracę deweloperom i zapewnić zgodność z HPA (jak zobaczymy za chwilę), administrator tworzy `LimitRange`, który (a) ustawia `defaultRequest: { cpu: 200m }` dla wszystkich kontenerów oraz (b) wymusza `max: { cpu: 2 }`, aby zapobiec tworzeniu "potworów".

### 9.4.2. Faza 1: Wdrożenie Aplikacji (Lekcja 9.3 + 9.1)
Deweloper wdraża swoją aplikację (jako `Deployment`), definiując w niej sondy (`startupProbe`, `readinessProbe`, `livenessProbe`), ale zapomina o ustawieniu `requests` i `limits`.

1.  Żądanie utworzenia Poda jest przechwytywane przez kontroler `LimitRange`, który automatycznie wstrzykuje do definicji kontenera `requests: { cpu: 200m }` oraz domyślny limit.
2.  Następnie kontroler `ResourceQuota` sprawdza *zmodyfikowanego* Poda. Widzi on `request` 200m CPU. Sprawdza budżet przestrzeni nazw i akceptuje Poda (ponieważ 200m jest znacznie poniżej limitu 50 CPU).

### 9.4.3. Faza 2: Uruchomienie Poda (Lekcja 9.1)
Pod zostaje zaplanowany na węźle, `kubelet` uruchamia kontener.

1.  Natychmiast aktywowana jest *tylko* `startupProbe`. Sondy `liveness` i `readiness` są wstrzymane.
2.  Aplikacja (np. Java) potrzebuje 45 sekund na inicjalizację. `startupProbe` (z `failureThreshold: 30`, `periodSeconds: 3`) cierpliwie czeka.
3.  Po 45 sekundach aplikacja jest zainicjalizowana, `startupProbe` przechodzi pomyślnie i jest wyłączana na stałe.
4.  `kubelet` aktywuje `readinessProbe`. Sonda sprawdza (np. rozgrzanie cache) i po kolejnych 5 sekundach przechodzi pomyślnie.
5.  Dopiero *teraz* Pod zostaje dodany do endpointów Serwisu i zaczyna przyjmować ruch. `livenessProbe` również staje się aktywna, monitorując stan zakleszczenia.

### 9.4.4. Faza 3: Autoskalowanie (Lekcja 9.2 + 9.3 + 9.1)
Deweloper zdefiniował również HPA dla swojego wdrożenia z celem `targetCPUUtilizationPercentage: 80`.

1.  Nadchodzi duży ruch. `Metrics Server` zbiera dane o użyciu.
2.  Średnie użycie CPU w Podach wzrasta do 180m.
3.  Kontroler HPA oblicza: Aktualne użycie (180m) / `request` (200m, wstrzyknięty przez `LimitRange`) = 90%.
4.  Ponieważ 90% jest większe niż cel 80%, pętla kontrolna HPA decyduje o skalowaniu w górę i dodaje nowe Pody.
5.  Nowo utworzone Pody *powtarzają* całą sekwencję z Fazy 2 (`startupProbe` -> `readinessProbe`). Gwarantuje to, że żaden z nowych Podów nie otrzyma ruchu, dopóki nie będzie w 100% gotowy. Jest to kluczowa synergia między HPA (Lekcja 9.2) a `readinessProbe` (Lekcja 9.1).
6.  HPA będzie kontynuować dodawanie Podów, aż średnie użycie spadnie do 80% LUB osiągnięta zostanie `maxReplicas` LUB suma `requests.cpu` wszystkich Podów osiągnie limit 50 CPU z `ResourceQuota` (Lekcja 9.3).

### 9.4.5. Faza 4: Samonaprawa i Odporność (Lekcja 9.1)
Jeden z dziesięciu działających Podów napotyka wewnętrzne zakleszczenie (deadlock).

1.  Jego `readinessProbe` (np. `httpGet`) może nadal przechodzić, ale `livenessProbe` (np. `exec` sprawdzający głębszą logikę) zawodzi.
2.  Po `failureThreshold` (np. 3) próbach, `kubelet` siłowo restartuje *tylko ten jeden* kontener.
3.  Dzięki `readinessProbe`, ruch nie był kierowany do tego Poda w momencie, gdy zawodził. HPA i pozostałe 9 Podów działają bez zakłóceń. System sam się naprawił.

### 9.4.6. Wniosek Końcowy

Analiza Modułu 9 wykazuje, że `Probes` (Lekcja 9.1), `HorizontalPodAutoscaler` (Lekcja 9.2) oraz `ResourceQuota` i `LimitRange` (Lekcja 9.3) nie są oddzielnymi, zaawansowanymi funkcjami. Stanowią one zintegrowany, autonomiczny system zarządzania cyklem życia aplikacji.

`LimitRange` i `ResourceQuota` (Lekcja 9.3) stanowią fundament, definiując reguły, budżety i gwarancje zasobów, które są niezbędne do działania HPA. `Metrics Server` i HPA (Lekcja 9.2) zapewniają elastyczność i adaptację do obciążenia, opierając swoje decyzje na regułach z Lekcji 9.3. Wreszcie, Sondy (Lekcja 9.1) gwarantują stabilność i odporność całego tego dynamicznego systemu, zapewniając, że ani startujące Pody, ani niestabilne Pody, ani Pody w trakcie awarii nie wpłyną negatywnie na użytkownika końcowego. Opanowanie ich *współdziałania* jest tym, co odróżnia administratora systemu od architekta platformy natywnej dla chmury.

---

## Cytowane prace

1. Kubernetes Limits vs. Requests: Key Differences and How They Work | Spot.io, otwierano: listopada 15, 2025, [https://spot.io/resources/kubernetes-architecture/kubernetes-limits-vs-requests-key-differences-and-how-they-work/](https://spot.io/resources/kubernetes-architecture/kubernetes-limits-vs-requests-key-differences-and-how-they-work/)  
2. Resource Management for Pods and Containers \- Kubernetes, otwierano: listopada 15, 2025, [https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)  
3. Resource Quotas \- Kubernetes, otwierano: listopada 15, 2025, [https://kubernetes.io/docs/concepts/policy/resource-quotas/](https://kubernetes.io/docs/concepts/policy/resource-quotas/)  
4. Auto Scaling in Kubernetes for more CPU resources by HPA and CA \- Medium, otwierano: listopada 15, 2025, [https://medium.com/@kennethtcp/auto-scaling-in-kubernetes-for-more-cpu-resources-by-hpa-and-ca-8b8db4f75654](https://medium.com/@kennethtcp/auto-scaling-in-kubernetes-for-more-cpu-resources-by-hpa-and-ca-8b8db4f75654)  
5. Chapter 2\. Working with pods | Nodes | OpenShift Container Platform | 4.10, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.10/html/nodes/working-with-pods](https://docs.redhat.com/en/documentation/openshift_container_platform/4.10/html/nodes/working-with-pods)  
6. Liveness, Readiness, and Startup Probes \- Kubernetes, otwierano: listopada 15, 2025, [https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/](https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/)  
7. Kubernetes Chronicles:(K8s\#10)|K8s Series | Deep Dive into Liveness, Readiness, and Startup Probes. | by VenuMadhav Palugula \- FAUN.dev(), otwierano: listopada 15, 2025, [https://faun.pub/kubernetes-chronicles-k8s-10-k8s-series-deep-dive-into-liveness-readiness-and-startup-probes-22f92936ed50](https://faun.pub/kubernetes-chronicles-k8s-10-k8s-series-deep-dive-into-liveness-readiness-and-startup-probes-22f92936ed50)  
8. Configure Liveness, Readiness and Startup Probes \- Kubernetes, otwierano: listopada 15, 2025, [https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)  
9. Practical Guide to Kubernetes Probes \- Civo.com, otwierano: listopada 15, 2025, [https://www.civo.com/learn/practical-guide-to-the-kubernetes-probes](https://www.civo.com/learn/practical-guide-to-the-kubernetes-probes)  
10. Understanding Kubernetes Probes: Liveness, Readiness, and Startup | by Pradeep Patil, otwierano: listopada 15, 2025, [https://medium.com/@patilpradeep1990/understanding-kubernetes-probes-liveness-readiness-and-startup-8df8e8185e03](https://medium.com/@patilpradeep1990/understanding-kubernetes-probes-liveness-readiness-and-startup-8df8e8185e03)  
11. Chapter 11\. Monitoring application health by using health checks | Building applications | OpenShift Container Platform | 4.9 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.9/html/building\_applications/application-health](https://docs.redhat.com/en/documentation/openshift_container_platform/4.9/html/building_applications/application-health)  
12. Readiness vs. Liveness probes: what is the difference? (and startup probes\!) \- Medium, otwierano: listopada 15, 2025, [https://medium.com/@jrkessl/readiness-vs-liveness-probes-what-is-the-difference-and-startup-probes-215560f043e4](https://medium.com/@jrkessl/readiness-vs-liveness-probes-what-is-the-difference-and-startup-probes-215560f043e4)  
13. Kubernetes Readiness Probes \- Examples & Common Pitfalls \- vCluster, otwierano: listopada 15, 2025, [https://www.vcluster.com/blog/kubernetes-readiness-probes-examples-and-common-pitfalls](https://www.vcluster.com/blog/kubernetes-readiness-probes-examples-and-common-pitfalls)  
14. Kubernetes Readiness Probe: A Simple Guide with Examples \- KodeKloud, otwierano: listopada 15, 2025, [https://kodekloud.com/blog/kubernetes-readiness-probe/](https://kodekloud.com/blog/kubernetes-readiness-probe/)  
15. Are liveness and readiness probes running in the whole lifecycle of a pod? \- Reddit, otwierano: listopada 15, 2025, [https://www.reddit.com/r/openshift/comments/sy1gle/are\_liveness\_and\_readiness\_probes\_running\_in\_the/](https://www.reddit.com/r/openshift/comments/sy1gle/are_liveness_and_readiness_probes_running_in_the/)  
16. Kubernetes Liveness Probes: Configuration & Best Practices \- Groundcover, otwierano: listopada 15, 2025, [https://www.groundcover.com/blog/kubernetes-liveness-probe](https://www.groundcover.com/blog/kubernetes-liveness-probe)  
17. Liveness and Readiness Probes \- Red Hat, otwierano: listopada 15, 2025, [https://www.redhat.com/en/blog/liveness-and-readiness-probes](https://www.redhat.com/en/blog/liveness-and-readiness-probes)  
18. Guide to Kubernetes Liveness Probes with Examples \- Spacelift, otwierano: listopada 15, 2025, [https://spacelift.io/blog/kubernetes-liveness-probe](https://spacelift.io/blog/kubernetes-liveness-probe)  
19. Kubernetes Liveness Probe: Tutorial & Examples \- Apptio, otwierano: listopada 15, 2025, [https://www.apptio.com/blog/kubernetes-liveness-probe/](https://www.apptio.com/blog/kubernetes-liveness-probe/)  
20. Deep dive into K8s Probes \- DEV Community, otwierano: listopada 15, 2025, [https://dev.to/sre\_panchanan/deep-dive-into-k8s-probes-4fmk](https://dev.to/sre_panchanan/deep-dive-into-k8s-probes-4fmk)  
21. Kubernetes Readiness Probes: Guide & Examples \- Groundcover, otwierano: listopada 15, 2025, [https://www.groundcover.com/blog/kubernetes-readiness-probe](https://www.groundcover.com/blog/kubernetes-readiness-probe)  
22. How does the failureThreshold work in liveness & readiness probes? Does it have to be consecutive failures? \- Stack Overflow, otwierano: listopada 15, 2025, [https://stackoverflow.com/questions/74714076/how-does-the-failurethreshold-work-in-liveness-readiness-probes-does-it-have](https://stackoverflow.com/questions/74714076/how-does-the-failurethreshold-work-in-liveness-readiness-probes-does-it-have)  
23. Metrics Server and HPA in Kubernetes | by Chetan Atole \- Medium, otwierano: listopada 15, 2025, [https://medium.com/@chetanatole99/metrics-server-and-hpa-in-kubernetes-ec94fb607e9b](https://medium.com/@chetanatole99/metrics-server-and-hpa-in-kubernetes-ec94fb607e9b)  
24. HorizontalPodAutoscaler Walkthrough \- Kubernetes, otwierano: listopada 15, 2025, [https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/)  
25. Horizontal Pod Autoscaling \- Kubernetes, otwierano: listopada 15, 2025, [https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)  
26. Kubernetes HPA \[Horizontal Pod Autoscaler\] Guide \- Spacelift, otwierano: listopada 15, 2025, [https://spacelift.io/blog/kubernetes-hpa-horizontal-pod-autoscaler](https://spacelift.io/blog/kubernetes-hpa-horizontal-pod-autoscaler)  
27. Chapter 2: Horizontal Autoscaling \- Kubernetes Guides \- Apptio, otwierano: listopada 15, 2025, [https://www.apptio.com/topics/kubernetes/autoscaling/horizontal/](https://www.apptio.com/topics/kubernetes/autoscaling/horizontal/)  
28. What Is Kubernetes HPA? A Guide To Pod Autoscaling In K8s \- CloudZero, otwierano: listopada 15, 2025, [https://www.cloudzero.com/blog/kubernetes-hpa/](https://www.cloudzero.com/blog/kubernetes-hpa/)  
29. Kubernetes Metrics 101: A Guide to Metrics Server \- Plural, otwierano: listopada 15, 2025, [https://www.plural.sh/blog/kubernetes-metrics-server-guide/](https://www.plural.sh/blog/kubernetes-metrics-server-guide/)  
30. Resource metrics pipeline \- Kubernetes, otwierano: listopada 15, 2025, [https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/](https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/)  
31. Automatically scaling pods with the horizontal pod autoscaler \- Working with pods | Nodes | OKD 4.16 \- OKD Documentation, otwierano: listopada 15, 2025, [https://docs.okd.io/4.16/nodes/pods/nodes-pods-autoscaling.html](https://docs.okd.io/4.16/nodes/pods/nodes-pods-autoscaling.html)  
32. Set up Kubernetes scaling via Prometheus & Custom Metrics \- LiveWyer, otwierano: listopada 15, 2025, [https://livewyer.io/blog/set-up-kubernetes-scaling-via-prometheus-custom-metrics/](https://livewyer.io/blog/set-up-kubernetes-scaling-via-prometheus-custom-metrics/)  
33. Configuring the Kubernetes Horizontal Pod Autoscaler to scale based on custom metrics from Prometheus \- BigBinary, otwierano: listopada 15, 2025, [https://www.bigbinary.com/blog/prometheus-adapter](https://www.bigbinary.com/blog/prometheus-adapter)  
34. Using Prometheus and Custom Metrics APIs for Kubernetes Rightsizing \- overcast blog, otwierano: listopada 15, 2025, [https://overcast.blog/using-prometheus-and-custom-metrics-apis-for-kubernetes-rightsizing-a3de7f366b4e](https://overcast.blog/using-prometheus-and-custom-metrics-apis-for-kubernetes-rightsizing-a3de7f366b4e)  
35. Optimizing Kubernetes resources with Horizontal Pod Autoscaling via Custom Metrics and the Prometheus Adapter | by Weeking | Deezer I/O, otwierano: listopada 15, 2025, [https://deezer.io/optimizing-kubernetes-resources-with-horizontal-pod-autoscaling-via-custom-metrics-and-the-a76c1a66ff1c](https://deezer.io/optimizing-kubernetes-resources-with-horizontal-pod-autoscaling-via-custom-metrics-and-the-a76c1a66ff1c)  
36. Chapter 25\. Pod Autoscaling | Developer Guide | OpenShift Container Platform | 3.11, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.11/html/developer\_guide/dev-guide-pod-autoscaling](https://docs.redhat.com/en/documentation/openshift_container_platform/3.11/html/developer_guide/dev-guide-pod-autoscaling)  
37. Kubernetes CPU limits and requests: A deep dive \- Datadog, otwierano: listopada 15, 2025, [https://www.datadoghq.com/blog/kubernetes-cpu-requests-limits/](https://www.datadoghq.com/blog/kubernetes-cpu-requests-limits/)  
38. Kubernetes requests vs limits: Why adding them to your Pods and Namespaces matters, otwierano: listopada 15, 2025, [https://cloud.google.com/blog/products/containers-kubernetes/kubernetes-best-practices-resource-requests-and-limits](https://cloud.google.com/blog/products/containers-kubernetes/kubernetes-best-practices-resource-requests-and-limits)  
39. Best Practices for Achieving Isolation in Kubernetes Multi-Tenant Environments \- vCluster, otwierano: listopada 15, 2025, [https://www.vcluster.com/blog/best-practices-for-achieving-isolation-in-kubernetes-multi-tenant-environments](https://www.vcluster.com/blog/best-practices-for-achieving-isolation-in-kubernetes-multi-tenant-environments)  
40. Chapter 14\. Quotas and Limit Ranges | Developer Guide | OpenShift Container Platform | 3.11 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/3.11/html/developer\_guide/dev-guide-compute-resources](https://docs.redhat.com/en/documentation/openshift_container_platform/3.11/html/developer_guide/dev-guide-compute-resources)  
41. Guide to Kubernetes Resource Quota: Examples & Pros and Cons \- Groundcover, otwierano: listopada 15, 2025, [https://www.groundcover.com/blog/kubernetes-resource-quota](https://www.groundcover.com/blog/kubernetes-resource-quota)  
42. Kubernetes Resource Quotas: How to Set & Enforce Limits \- Bacancy Technology, otwierano: listopada 15, 2025, [https://www.bacancytechnology.com/blog/kubernetes-resource-quota](https://www.bacancytechnology.com/blog/kubernetes-resource-quota)  
43. A Hands-On Guide to Kubernetes Resource Quotas & Limit Ranges ⚙️ | by Anvesh Muppeda | Medium, otwierano: listopada 15, 2025, [https://medium.com/@muppedaanvesh/a-hand-on-guide-to-kubernetes-resource-quotas-limit-ranges-%EF%B8%8F-8b9f8cc770c5](https://medium.com/@muppedaanvesh/a-hand-on-guide-to-kubernetes-resource-quotas-limit-ranges-%EF%B8%8F-8b9f8cc770c5)  
44. Compute Resource Quotas | Scalability and performance | OKD 4, otwierano: listopada 15, 2025, [https://docs.okd.io/latest/scalability\_and\_performance/compute-resource-quotas.html](https://docs.okd.io/latest/scalability_and_performance/compute-resource-quotas.html)  
45. Limit Ranges | Kubernetes, otwierano: listopada 15, 2025, [https://kubernetes.io/docs/concepts/policy/limit-range/](https://kubernetes.io/docs/concepts/policy/limit-range/)  
46. Kubernetes Resource Quota: Tutorial & Best Practices \- CloudBolt, otwierano: listopada 15, 2025, [https://www.cloudbolt.io/kubernetes-pod-scheduling/kubernetes-resource-quota/](https://www.cloudbolt.io/kubernetes-pod-scheduling/kubernetes-resource-quota/)  
47. OpenShift- limit/Quota/LimitRange | by Khemnath chauhan \- Medium, otwierano: listopada 15, 2025, [https://be-reliable-engineer.medium.com/openshift-quota-limitrange-6247ea1451bb](https://be-reliable-engineer.medium.com/openshift-quota-limitrange-6247ea1451bb)  
48. Relation between LimitRange's default, defaultRequest, max and min limits \- Stack Overflow, otwierano: listopada 15, 2025, [https://stackoverflow.com/questions/61356073/relation-between-limitranges-default-defaultrequest-max-and-min-limits](https://stackoverflow.com/questions/61356073/relation-between-limitranges-default-defaultrequest-max-and-min-limits)