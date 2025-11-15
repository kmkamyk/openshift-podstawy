# Moduł 8: Storage – Trwałość Danych

## Wprowadzenie: Paradygmat Stanowości w Świecie Efemerycznych Kontenerów

Architektura Kubernetes i OpenShift opiera się na fundamentalnym założeniu efemeryczności kontenerów. Kontenery są postrzegane jako nietrwałe jednostki obliczeniowe; mogą być zatrzymywane, niszczone i zastępowane w dowolnym momencie przez orkiestrator. System plików kontenera jest nierozerwalnie związany z jego cyklem życia – gdy kontener jest usuwany, jego dane znikają wraz z nim.[1]

Podczas gdy ten model jest idealny dla aplikacji bezstanowych (stateless), większość rzeczywistych systemów biznesowych – bazy danych, systemy zarządzania treścią (CMS), kolejki komunikatów – ma charakter stanowy (stateful). Aplikacje te wymagają, aby ich dane przetrwały restarty, awarie lub operacje przenoszenia Podów.[2, 1]

Początkowe mechanizmy wolumenów w Kubernetes, takie jak `emptyDir` czy `hostPath`, były niewystarczające. Wolumeny te są powiązane z cyklem życia Poda, a nie aplikacji.[3] W odpowiedzi na to wyzwanie, Kubernetes wprowadził podsystem `PersistentVolume` (PV). Jest to wyspecjalizowane API, które wprowadza kluczową separację: oddziela zarządzanie pamięcią masową (storage) od zarządzania mocą obliczeniową (compute).[4]

Podstawową innowacją jest wprowadzenie dwóch oddzielnych obiektów: `PersistentVolume` (PV) i `PersistentVolumeClaim` (PVC). Ten podział nie jest jedynie techniczną implementacją; reprezentuje on fundamentalny *kontrakt organizacyjny* w modelu DevOps. Rozdziela on odpowiedzialności (separation of concerns) pomiędzy dwiema różnymi rolami [4, 5, 6]:

1.  **Administrator Klastra (Admin):** Odpowiada za infrastrukturę. Udostępnia zasoby pamięci masowej (np. systemy SAN, dyski w chmurze) *klastrowi*. Definiuje on, *co* jest dostępne, *jakie* ma parametry (np. wydajność) i *jakie* są koszty. Jego domeną jest `PersistentVolume` (PV).[3, 5]
2.  **Deweloper (Użytkownik):** Odpowiada za aplikację. Nie musi znać szczegółów implementacyjnych fizycznego storage'u.[2, 7] Musi jedynie zadeklarować *potrzeby* swojej aplikacji (np. "potrzebuję 5Gi szybkiego dysku do zapisu"). Jego domeną jest `PersistentVolumeClaim` (PVC).[3, 4]

Model ten pozwala deweloperom na szybkie i dynamiczne pozyskiwanie zasobów, jednocześnie dając administratorom pełną kontrolę nad infrastrukturą. Niniejszy moduł analizuje ten model, od jego podstaw (PV/PVC), przez mechanizmy automatyzacji (`StorageClass`), aż po zintegrowane, produkcyjne rozwiązania (ODF) i strategie ochrony danych (Snapshot/Backup).

## Lekcja 8.1: `PersistentVolume` (PV) i `PersistentVolumeClaim` (PVC)

### 8.1.1 `PersistentVolume` (PV): "Dysk" jako Zasób Klastra

`PersistentVolume` (PV) to "kawałek pamięci masowej" (piece of storage) w klastrze, który został udostępniony (zaprowizjonowany) przez administratora lub dynamicznie przez `StorageClass`.[4]

Kluczowe cechy obiektu PV:

  * **Zasób Klastra:** PV jest zasobem na poziomie *całego klastra*, podobnie jak Węzeł (Node) jest zasobem klastra.[3, 1, 4] Nie należy do żadnej konkretnej przestrzeni nazw (Namespace).
  * **Niezależny Cykl Życia:** PV ma cykl życia niezależny od jakiegokolwiek Poda, który go używa.[4, 6] Oznacza to, że dane na PV przetrwają usunięcie, restart lub przeniesienie Poda.[2, 1]
  * **Abstrakcja Implementacji:** Obiekt PV zawiera w sobie szczegóły implementacyjne pamięci masowej – czy jest to wolumen NFS, iSCSI, czy specyficzny dysk od dostawcy chmury (np. AWS EBS).[4, 6]

W modelu *statycznego provisioningu* (Static Provisioning), administrator klastra ręcznie tworzy zestaw wolumenów PV. Poniższy przykład definiuje 10GiB wolumen typu `hostPath`, który rezerwuje katalog `/mnt/data` na węźle.[8]

**Manifest Statycznego `PersistentVolume` (PV):**

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: task-pv-volume
  labels:
    app: pv-volume
spec:
  storageClassName: manual # Klucz do ręcznego wiązania
  capacity:
    storage: 10Gi # Całkowita pojemność "dysku"
  accessModes:
    - ReadWriteOnce # Ten dysk wspiera montowanie RW na jednym węźle
  hostPath:
    path: "/mnt/data" # Implementacja: ścieżka na hoście
```

### 8.1.2 `PersistentVolumeClaim` (PVC): "Żądanie" Zasobu

`PersistentVolumeClaim` (PVC) to *żądanie* (request) pamięci masowej przez użytkownika (dewelopera).[2, 4]

Kluczowe cechy obiektu PVC:

  * **Zasób Przestrzeni Nazw:** PVC jest zasobem na poziomie *Namespace* (Projektu w OpenShift), podobnie jak Pod.[3, 4]
  * **Deklaracja Potrzeb:** PVC deklaruje *minimalne* wymagania aplikacji, takie jak rozmiar i tryb dostępu.[2, 4]
  * **Konsument Zasobów:** PVC "konsumuje" zasoby PV, podobnie jak Pod "konsumuje" zasoby Węzła (CPU, Pamięć).[1, 4]

Poniższy przykład PVC reprezentuje żądanie dewelopera, który potrzebuje *co najmniej* 3GiB pamięci masowej, pasującej do klasy `manual` i trybu `ReadWriteOnce`.[8]

**Manifest `PersistentVolumeClaim` (PVC):**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: task-pv-claim # Nazwa w ramach Namespace
spec:
  storageClassName: manual # Żądanie musi pasować do PV
  accessModes:
    - ReadWriteOnce # Jak aplikacja *chce* używać wolumenu
  resources:
    requests:
      storage: 3Gi # Minimalna wymagana pojemność
```

### 8.1.3 Proces Wiązania (Binding) PV i PVC

Gdy deweloper tworzy PVC, w klastrze uruchamia się proces *wiązania* (binding). Specjalizowany kontroler Kubernetes stale monitoruje nowe obiekty PVC i próbuje znaleźć dla nich pasujący, dostępny (Available) PV.[2, 1]

  * **Relacja 1:1:** Wiązanie jest wyłączne. Jeden PV może być w danym momencie związany (Bound) tylko z jednym PVC.[3, 2, 1]
  * **Logika Dopasowania (w trybie statycznym):**
    1.  **`storageClassName`:** PVC musi żądać *dokładnie* tej samej `storageClassName` co PV.[4] W naszych przykładach jest to `manual`.[8]
    2.  **`capacity`:** Pojemność (capacity) PV musi być *większa lub równa* (\>=) pojemności żądanej (requests.storage) przez PVC.[9] W naszym przykładzie PV (10Gi) \>= PVC (3Gi).[8]
    3.  **`accessModes`:** Zbiór trybów dostępu PV musi *zawierać* (być nadzbiorem) trybów żądanych przez PVC.[9] W naszym przykładzie PV (`ReadWriteOnce`) zawiera PVC (`ReadWriteOnce`).[8]
  * **Statusy:**
      * **`Pending`:** Jeśli PVC zostanie utworzone, ale żaden PV nie spełnia jego wymagań, PVC pozostaje w stanie `Pending`.[2]
      * **`Bound`:** Gdy kontroler znajdzie pasujący PV, wiąże je ze sobą. Oba obiekty przechodzą w stan `Bound`.[2, 7] Dopiero wtedy Pod może użyć PVC.

### 8.1.4 Kluczowe Atrybuty: `accessModes`

`accessModes` definiują, w jaki sposób wolumen może być montowany w systemie. Jest to kluczowy atrybut definiujący możliwości backendu storage'owego.[9, 10]

**Tabela 8.1: Tryby Dostępu (Access Modes) w Kubernetes**

| Tryb | Nazwa | Opis | Typowe Technologie Backendowe |
| :--- | :--- | :--- | :--- |
| `RWO` | `ReadWriteOnce` | Wolumen może być zamontowany jako Read-Write (RW) przez **jeden Węzeł** (Node).[10, 11] | Pamięć blokowa (np. Ceph RBD, AWS EBS, GCE PD, iSCSI).[9] |
| `ROX` | `ReadOnlyMany` | Wolumen może być zamontowany jako Read-Only (RO) przez **wiele Węzłów** (Nodes).[10, 11] | Systemy plików (np. CephFS, NFS).[9] |
| `RWX` | `ReadWriteMany` | Wolumen może być zamontowany jako Read-Write (RW) przez **wiele Węzłów**.[10, 11] | Rozproszone systemy plików (np. CephFS, NFS, Azure File).[9] |
| `RWOP` | `ReadWriteOncePod` | Wolumen może być zamontowany jako Read-Write (RW) przez **jeden Pod**.[10, 11] | Nowszy tryb (od K8s 1.22+), wspierany przez CSI, gwarantujący wyłączność na poziomie Poda. |

Należy zwrócić szczególną uwagę na pułapkę interpretacyjną trybu `RWO` (`ReadWriteOnce`). Definicja mówi o *jednym Węźle*, a nie *jednym Podzie*.[11] Oznacza to, że wiele Podów *na tym samym Węźle* może jednocześnie zamontować ten sam wolumen RWO. W przypadku pamięci blokowej (jak EBS czy RBD), która nie jest klastrowym systemem plików, jednoczesny zapis przez dwa procesy (Pody) prawie na pewno doprowadzi do *uszkodzenia danych*. Tryb `RWOP` (`ReadWriteOncePod`) został wprowadzony właśnie po to, aby rozwiązać ten problem i zagwarantować prawdziwą wyłączność dla Poda, niezależnie od tego, gdzie jest on zaplanowany.[10, 11]

### 8.1.5 Kluczowe Atrybuty: `persistentVolumeReclaimPolicy`

Polityka odzyskiwania (`reclaimPolicy`) jest definiowana na obiekcie `PersistentVolume` (PV) i określa, co klaster ma zrobić z wolumenem (i potencjalnie fizycznym dyskiem), gdy powiązany z nim obiekt `PersistentVolumeClaim` (PVC) zostanie usunięty.[12, 13]

**Tabela 8.2: Polityki Odzyskiwania (Reclaim Policies)**

| Polityka | Opis | Implikacje |
| :--- | :--- | :--- |
| `Retain` | (Zatrzymaj) Po usunięciu PVC, obiekt PV *nie jest* usuwany. Przechodzi w stan `Released`. Dane na dysku pozostają nietknięte.[12, 13] | **Najbezpieczniejsza opcja dla danych produkcyjnych**.[14] Wymaga *ręcznej interwencji* administratora, aby odzyskać dane lub zwolnić PV i dysk do ponownego użycia. |
| `Delete` | (Usuń) Po usunięciu PVC, zarówno obiekt PV, jak i *powiązany z nim fizyczny dysk* (np. wolumen AWS EBS) są automatycznie usuwane.[12, 15] | **Domyślna dla dynamicznego provisioningu**.[13, 15] Wygodna, ale niebezpieczna. *Usunięcie PVC = trwała i nieodwracalna utrata danych.* |
| `Recycle` | (Przetwórz) *Przestarzała (Deprecated)*. Po usunięciu PVC, zawartość wolumenu była czyszczona (np. przez `rm -rf /`), a PV wracał do puli dostępnych wolumenów.[12, 15] | Polityka ta jest obecnie niestosowana i zastąpiona przez mechanizm dynamicznego provisioningu. |

Domyślna polityka `Delete` dla dynamicznie tworzonych wolumenów jest częstą przyczyną utraty danych produkcyjnych.[13] Deweloper, usuwając swoją aplikację (np. poprzez `helm uninstall`), nieświadomie usuwa również PVC, co natychmiastowo i nieodwracalnie niszczy fizyczny dysk z danymi. Najlepszą praktyką dla środowisk produkcyjnych jest definiowanie `StorageClass` (omówionych w następnej lekcji) z polityką `reclaimPolicy: Retain`.[16, 17]

## Lekcja 8.2: `StorageClass` i Dynamic Provisioning

### 8.2.1 Ograniczenia Provisioningu Statycznego

Model statyczny, omówiony w Lekcji 8.1, ma fundamentalne wady operacyjne:

1.  **Wąskie Gardło Administracyjne:** Każde żądanie nowego wolumenu przez dewelopera wymaga ręcznej interwencji administratora (utworzenie dysku w chmurze/SAN, utworzenie manifestu PV, aplikacja w klastrze).[18, 19]
2.  **Niewydajność Zasobów:** Administratorzy, aby uniknąć ciągłych próśb, często tworzą "na zapas" pulę statycznych PV (np. 10x 100GiB).[7] Jeśli deweloper utworzy PVC na 5GiB, zajmie jeden ze 100GiB wolumenów, marnując 95GiB, które nie mogą być użyte przez nikogo innego (z powodu wiązania 1:1).[2]

### 8.2.2 `StorageClass`: "Fabryka" Wolumenów (PV)

`StorageClass` (SC) to obiekt API Kubernetes, który rozwiązuje powyższe problemy. Zamiast ręcznie tworzyć PV, administratorzy tworzą `StorageClass`, który działa jak "fabryka" lub "szablon" dla wolumenów.[20]

`StorageClass` *opisuje* "klasę" lub "profil" oferowanej pamięci masowej, definiując [20]:

  * **`provisioner`:** "Sterownik" lub oprogramowanie, które wie, *jak* fizycznie utworzyć dysk (np. sterownik dla AWS EBS, GCE PD, Ceph RBD).
  * **`parameters`:** Parametry przekazywane do `provisioner` (np. `type: pd-ssd` dla szybkiego dysku, lub `type: pd-standard` dla wolnego).[21]
  * **`reclaimPolicy`:** Polityka odzyskiwania (np. `Retain` lub `Delete`), która zostanie automatycznie zastosowana do *wszystkich* PV utworzonych przez tę klasę.[17]
  * **Inne Opcje:** `allowVolumeExpansion` (czy można powiększać wolumeny), `volumeBindingMode` (kiedy ma nastąpić wiązanie).

**Manifest `StorageClass` (na przykładzie GCE):**

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd # Nazwa, której deweloper użyje w PVC
provisioner: kubernetes.io/gce-pd # "Sterownik" dla Google Cloud [21]
parameters:
  type: pd-ssd # Chcemy szybki dysk SSD [21]
reclaimPolicy: Retain # Polityka dla PV stworzonych przez tę SC [17]
allowVolumeExpansion: true # Zezwalaj na powiększanie [14]
volumeBindingMode: Immediate
```

### 8.2.3 Przepływ Dynamicznego Provisioningu

Dynamiczne provisionowanie (Dynamic Provisioning) całkowicie zmienia przepływ pracy, eliminując administratora z pętli decyzyjnej.[18, 19] Proces ten jest wyzwalany "na żądanie" (on-demand) przez samo utworzenie PVC przez dewelopera.[3, 7]

**Przepływ zdarzeń (krok po kroku):**

1.  **Administrator** (jednorazowo): Tworzy w klastrze obiekt `StorageClass` (np. `fast-ssd` z `provisioner:...gce-pd`).[18, 21]
2.  **Deweloper:** Tworzy *tylko* `PersistentVolumeClaim` (PVC), podając w `spec.storageClassName` nazwę żądanej klasy (np. `fast-ssd`) i żądany rozmiar (np. 3Gi).[7, 19]
3.  **Kontroler Kubernetes:** Odbiera PVC. Sprawdza, czy istnieją *statyczne* PV pasujące do niego. Nie znajduje żadnego.
4.  **Krok Kluczowy:** Kontroler widzi, że PVC żąda `storageClassName: fast-ssd`. Odnajduje definicję tej klasy i jej `provisioner`.
5.  **Kontroler Kubernetes:** Wywołuje ten `provisioner` (np. `gce-pd`), przekazując mu żądanie (np. "utwórz dysk 3Gi typu pd-ssd", na podstawie `parameters` z SC i `requests` z PVC).[22]
6.  **Provisioner:** Komunikuje się z API chmury (np. Google Cloud API) i *tworzy fizyczny dysk* 3Gi SSD.[22]
7.  **Provisioner:** Po pomyślnym utworzeniu dysku, tworzy w API Kubernetes obiekt `PersistentVolume` (PV) (o pojemności 3Gi), który *reprezentuje* ten nowy, fizyczny dysk.[22]
8.  **Kontroler Kubernetes:** Widzi nowy PV, który idealnie pasuje do czekającego PVC dewelopera (ponieważ został dla niego stworzony).
9.  **Kontroler Kubernetes:** *Automatycznie wiąże (binduje)* ten nowy PV z PVC dewelopera.
10. **Wynik:** PVC zmienia stan z `Pending` na `Bound` w ciągu kilku sekund, a Pod dewelopera może natychmiast zacząć go używać.

### 8.2.4 Domyślna `StorageClass` w OpenShift Local (HostPath Provisioner)

Klaster może posiadać jedną `StorageClass` oznaczoną specjalną adnotacją: `storageclass.kubernetes.io/is-default-class: "true"`.[18, 23, 24]

Jeśli deweloper utworzy PVC *nie podając* żadnej wartości w `spec.storageClassName`, Kubernetes automatycznie użyje tej domyślnej klasy.[18] Jest to mechanizm zapewniający, że żądania PVC działają "out-of-the-box".

W środowiskach deweloperskich, takich jak OpenShift Local (dawniej CodeReady Containers) lub OKD z wirtualizacją, często domyślnie instalowany jest `Hostpath Provisioner` (HPP).[25, 26, 27]

  * **Jak działa HPP:** HPP to `provisioner`, który w odpowiedzi na żądanie PVC nie komunikuje się z żadną chmurą, lecz po prostu tworzy *katalog* na *lokalnym dysku węzła*, na którym działa (np. w `/var/myvolumes/pvc-<nazwa>`).[26]
  * **Implikacje i Ograniczenia:**
      * `HostPath Provisioner` jest rozwiązaniem *wyłącznie* deweloperskim i *nieprodukcyjnym*.
      * Jego podstawową wadą jest to, że dane są *fizycznie związane z jednym, konkretnym węzłem*.[26, 28]
      * Jeśli Pod ulegnie awarii, a orkiestrator OpenShift (Scheduler) przeniesie go na *inny, zdrowy węzła* (co jest standardową procedurą zapewniania wysokiej dostępności), Pod ten straci dostęp do swoich danych, które pozostały na pierwszym węźle.
      * To zachowanie jest fundamentalnie sprzeczne z paradygmatem wysokiej dostępności i mobilności workloadów w OpenShift. Ponadto, HPP często zapisuje dane na partycji systemowej, co grozi jej zapełnieniem i destabilizacją węzła.[26]

## Lekcja 8.3: Wprowadzenie do OpenShift Data Foundation (Rook/Ceph)

### 8.3.1 "Błogosławione" Rozwiązanie: Czym jest ODF?

O ile `hostPath` jest nieprodukcyjny, a tradycyjne systemy NFS/SAN wymagają zewnętrznej, skomplikowanej administracji, o tyle OpenShift Data Foundation (ODF) jest preferowanym ("błogosławionym") rozwiązaniem storage dla platformy OpenShift.

  * **Definicja:** ODF to wysoce dostępna, zintegrowana platforma Software-Defined Storage (SDS) zaprojektowana specjalnie dla kontenerów i obciążeń OpenShift.[29, 30]
  * **Integracja:** Kluczową zaletą ODF jest to, że jest *głęboko zintegrowany* z OpenShift. Jest wdrażany i zarządzany jako Operator, a jego komponenty działają jako Pody *wewnątrz* klastra.[31, 32]
  * **Rebranding:** Należy pamiętać, że OpenShift Data Foundation (ODF) to nowsza nazwa dla produktu wcześniej znanego jako *OpenShift Container Storage (OCS)*.[33] W dokumentacji i interfejsie obie nazwy mogą pojawiać się zamiennie.[34, 35]

### 8.3.2 Architektura ODF: Operators, Rook i Ceph

ODF jest doskonałym przykładem architektury opartej na wzorcu Operatora (Operator Pattern). Zamiast zarządzać zewnętrzną macierzą, administratorzy instalują Operatory, które *budują* i *autonomicznie zarządzają* rozproszonym systemem storage, wykorzystując dyski podłączone do węzłów roboczych.[30, 36]

Główne komponenty architektury ODF:

1.  **ODF Operator:** Jest to meta-operator, który zarządza instalacją i cyklem życia pozostałych komponentów.[37]
2.  **Rook-Ceph Operator:** Rook to "orkiestrator" pamięci masowej dla Kubernetes.[38] Rook wie, jak wziąć definicję klastra Ceph i przełożyć ją na obiekty Kubernetes (Pody, Service, ConfigMaps). Automatyzuje wdrażanie, skalowanie, monitorowanie i aktualizacje Ceph.[37, 38]
3.  **Ceph:** To "mózg i mięśnie" całego rozwiązania.[38, 39] Ceph to dojrzały, potężny, zunifikowany i rozproszony system SDS. Odpowiada za replikację danych (zapewniając wysoką dostępność), samonaprawianie i udostępnianie różnych typów pamięci masowej. Jego demony (takie jak OSD - przechowujące dane, i MON - monitorujące klaster) działają jako Pody w klastrze OpenShift.[32]
4.  **NooBaa (Multicloud Gateway - MCG):** Jest to komponent ODF odpowiedzialny za dostarczanie warstwy Object Storage (S3) oraz federację danych między różnymi chmurami.[30, 37, 39]

### 8.3.3 Co Dostarcza ODF? (Block, File, Object)

Siłą ODF, dziedziczoną po Ceph, jest zdolność do dostarczania *wszystkich trzech* głównych typów pamięci masowej z jednego, zunifikowanego backendu. ODF automatycznie tworzy odpowiednie `StorageClasses` dla każdego z tych typów.[30, 39]

**Tabela 8.3: Typy Pamięci Masowej oferowane przez OpenShift Data Foundation**

| Typ Storage | Technologia ODF | Tryb Dostępu K8s | Charakterystyka | Scenariusz Użycia [29, 30, 39] |
| :--- | :--- | :--- | :--- | :--- |
| **Block Storage** | Ceph RBD (RADOS Block Device) | `ReadWriteOnce` (RWO) [40, 41] | Dostęp na poziomie bloku (jak surowy dysk). Niskie opóźnienia, wysoka wydajność I/O (IOPS).[42, 43] | Bazy danych (np. PostgreSQL, MySQL), kolejki (np. Kafka). Aplikacje wymagające wyłącznego, szybkiego dostępu. |
| **File Storage** | CephFS (Ceph File System) | `ReadWriteMany` (RWX) [44, 40] | Współdzielony, rozproszony system plików zgodny z POSIX. Dostępny dla wielu Podów jednocześnie.[45] | Aplikacje webowe (np. WordPress, Drupal), współdzielone katalogi CI/CD (np. Jenkins), agregacja logów.[30, 46] |
| **Object Storage** | Ceph RGW (RADOS Gateway) / NooBaa | API S3 (przez `ObjectBucketClaim`) | Dostęp przez API HTTP (S3-compatible). Nieskończona skalowalność, idealny dla danych niestrukturalnych.[45, 47] | Backupy, archiwa, repozytoria artefaktów (np. Nexus), składowanie multimediów dla aplikacji.[33] |

ODF w pełni realizuje obietnicę abstrakcji. Deweloper nie musi wiedzieć, czym jest Ceph RBD ani CephFS.[36] Administrator udostępnia mu dwie główne klasy, np. `ocs-storagecluster-ceph-rbd` (dla RWO) [40] i `ocs-storagecluster-cephfs` (dla RWX).[46] Deweloper wybiera `StorageClass` na podstawie *wymaganej funkcjonalności* (RWO vs RWX), a ODF automatycznie i dynamicznie provisionuje wolumen przy użyciu *odpowiedniej technologii* backendowej.

## Lekcja 8.4: Wprowadzenie do Snapshotów i Backup/Restore (Koncepcja)

Posiadanie trwałego wolumenu (PV) rozwiązuje problem efemeryczności kontenerów, ale nie chroni przed utratą danych (np. awarią dysku, błędem ludzkim czy atakiem ransomware). W tym celu potrzebne są mechanizmy snapshotów i backupu.

### 8.4.1 `VolumeSnapshot`: "Zamrożenie Czasu" dla Danych

`VolumeSnapshot` to obiekt API (zdefiniowany jako Custom Resource Definition - CRD), który pozwala na gestandaryzowany sposób tworzenia *migawki* (snapshotu) stanu wolumenu w danym punkcie czasu (point-in-time copy).[48, 49]

  * **Wymagania:** Mechanizm ten działa tylko dla sterowników pamięci masowej zgodnych ze standardem CSI (Container Storage Interface) i wspierających funkcję snapshot.[48, 50] ODF (Ceph) w pełni wspiera tę funkcjonalność.
  * **Architektura (Analogia do PV/PVC):** Model snapshotów jest logiczną kopią modelu wolumenów [48]:
      * `VolumeSnapshotClass` (jak `StorageClass`): Definiuje *jak* tworzyć snapshot (np. `deletionPolicy`).[51]
      * `VolumeSnapshot` (jak `PVC`): Jest to *żądanie* (request) utworzenia snapshotu dla *konkretnego, istniejącego PVC*.[48, 52]
      * `VolumeSnapshotContent` (jak `PV`): Reprezentuje *wynikowy* obiekt snapshotu, fizycznie istniejący w backendzie storage'owym.[48]

**Użycie:**

1.  **Tworzenie Snapshota:** Deweloper tworzy prosty manifest `VolumeSnapshot` wskazujący w `spec.source.persistentVolumeClaimName` nazwę PVC, którego migawkę chce wykonać.[52, 53]
2.  **Odtwarzanie ze Snapshota:** Deweloper tworzy *nowy* obiekt `PersistentVolumeClaim`. W jego definicji, w polu `spec.dataSource`, wskazuje na `VolumeSnapshot` jako źródło danych.[50, 53] Klaster tworzy wtedy nowy PV, który jest klonem danych ze snapshotu.

Snapshoty są idealne do szybkich operacji odtworzeniowych, np. wykonania migawki bazy danych tuż przed ryzykowną migracją schematu.[48, 53]

### 8.4.2 Kluczowa Różnica: Snapshot vs. Backup

Pojęcia snapshot i backup są często mylone, co prowadzi do katastrofalnych w skutkach błędów w strategii ochrony danych.[53]

**Snapshot TO NIE JEST Backup.**

Analiza tego stwierdzenia wymaga odpowiedzi na pytanie: *gdzie fizycznie przechowywany jest snapshot?*

  * **Snapshot (`VolumeSnapshot`):** Zazwyczaj jest przechowywany *na tym samym systemie storage*, co oryginalny wolumen.[54] Na przykład snapshot wolumenu ODF (Ceph) jest przechowywany w tym samym klastrze Ceph.

      * *Zaleta:* Tworzenie i odtwarzanie jest *niemal natychmiastowe* (często jest to operacja na metadanych, tzw. copy-on-write).
      * *Wada:* Snapshot jest w tej samej *domenie awarii* co dane źródłowe. Jeśli cały system storage (np. klaster ODF) ulegnie awarii, administrator *traci zarówno dane oryginalne, jak i wszystkie ich snapshoty*.[54]

  * **Backup (Kopia Zapasowa):** Z definicji jest to kopia danych *przeniesiona* do *zewnętrznej* (off-site) i niezależnej domeny awarii.[55] Najczęściej jest to zewnętrzny serwer S3, zlokalizowany w innej strefie dostępności lub nawet innym regionie geograficznym.[56]

**Wniosek:**
**Snapshot** chroni przed *logicznym* uszkodzeniem danych (np. przypadkowym `DROP TABLE` lub błędem aplikacji).
**Backup** chroni przed *fizyczną* lub *totalną* katastrofą (np. awarią macierzy, zniszczeniem centrum danych, usunięciem całego klastra OpenShift).[54]

### 8.4.3 Koncepcja Narzędzi: Velero i OADP

Problem z backupem w Kubernetes jest złożony. Aplikacja to nie tylko dane na PV. To również (a może przede wszystkim) zbiór *metadanych* – dziesiątki obiektów YAML definiujących `Deployment`, `ConfigMap`, `Secret`, `Service`, `Route` itd..[54, 56]

Potrzebne jest narzędzie, które rozumie *zarówno* dane (PV), jak i metadane (obiekty K8s).

  * **Velero (Open Source):**

      * **Definicja:** Velero to narzędzie open source (obecnie pod egidą VMware) zaprojektowane do bezpiecznego backupu, odtwarzania i migracji zasobów klastra Kubernetes i trwałych wolumenów.[57, 58]
      * **Jak działa (koncepcyjnie):**
        1.  **Metadane:** Velero (działając na podstawie CRD `Backup`) pyta API Kubernetes o wszystkie obiekty (np. w danym namespace) i pakuje je do archiwum `tar.gz`.[59]
        2.  **Przechowywanie:** Wysyła to archiwum `tar.gz` (zawierające YAML-e) do *zewnętrznego* bucketu S3.[59, 56]
        3.  **Dane (PV):** Równolegle, dla każdego PVC objętego backupem, Velero (poprzez swoje pluginy) *wywołuje* API `VolumeSnapshot` (jeśli jest wspierane przez sterownik CSI).[60, 61]

  * **OADP (OpenShift API for Data Protection):**

      * **Definicja:** OADP to *produkt* Red Hat bazujący w 100% na Velero.[62, 63] Jest to "Velero na sterydach", w pełni zintegrowane z OpenShift, dostarczane i zarządzane jako Operator.[62, 64]
      * **Wartość Dodana:** OADP dostarcza pluginy specyficzne dla OpenShift (np. do backupu `ImageStreams`), jest wspierany przez Red Hat i zarządzany cyklem życia przez Operatora.

Pełna strategia Disaster Recovery (DR) łączy te koncepcje. Standardowy backup Velero/OADP (zgodnie z [61] i [60]) tworzy backup YAML-i (w S3) i *lokalny* snapshot (na macierzy). To nadal nie chroni przed awarią macierzy.[54]

Dlatego zaawansowane implementacje (np. OADP z wtyczką Data Mover jak VolSync) realizują pełen przepływ [65]:

1.  Velero/OADP tworzy *lokalny* `VolumeSnapshot`.
2.  Velero/OADP (poprzez Data Mover) *kopiuje dane z tego snapshotu* do *tego samego S3*, gdzie przechowywane są YAML-e.
3.  Po pomyślnym transferze, lokalny snapshot jest usuwany.

Dopiero w tym modelu *zarówno* metadane (YAML), jak i dane (PV) znajdują się bezpiecznie w zewnętrznej lokalizacji, gotowe do odtworzenia po prawdziwej katastrofie.

#### **Cytowane prace**

1. Kubernetes Persistent Volume Tutorial with PVCs \- Portworx, otwierano: listopada 15, 2025, [https://portworx.com/tutorial-kubernetes-persistent-volumes/](https://portworx.com/tutorial-kubernetes-persistent-volumes/)  
2. What Is a Persistent Volume Claim (PVC) in Kubernetes? \- Zesty.co, otwierano: listopada 15, 2025, [https://zesty.co/finops-glossary/kubernetes-persistent-volume-claim/](https://zesty.co/finops-glossary/kubernetes-persistent-volume-claim/)  
3. The State of Apps 4: PersistentVolumes and PersistentVolumeClaims \- Kubermatic, otwierano: listopada 15, 2025, [https://www.kubermatic.com/blog/keeping-the-state-of-apps-4-persistentvolumes-and-persistentvolum/](https://www.kubermatic.com/blog/keeping-the-state-of-apps-4-persistentvolumes-and-persistentvolum/)  
4. Persistent Volumes \- Kubernetes, otwierano: listopada 15, 2025, [https://kubernetes.io/docs/concepts/storage/persistent-volumes/](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)  
5. Persistent storage for Kubernetes \- Amazon AWS, otwierano: listopada 15, 2025, [https://aws.amazon.com/blogs/storage/persistent-storage-for-kubernetes/](https://aws.amazon.com/blogs/storage/persistent-storage-for-kubernetes/)  
6. Simplifying Persistent Storage in Kubernetes: A Deep Dive into PVs, PVCs, and SCs, otwierano: listopada 15, 2025, [https://dev.to/piyushbagani15/simplifying-persistent-storage-in-kubernetes-a-deep-dive-into-pvs-pvcs-and-scs-1p3c](https://dev.to/piyushbagani15/simplifying-persistent-storage-in-kubernetes-a-deep-dive-into-pvs-pvcs-and-scs-1p3c)  
7. Kubernetes Persistent Volume Claims Explained | NetApp, otwierano: listopada 15, 2025, [https://www.netapp.com/learn/cvo-blg-kubernetes-persistent-volume-claims-explained/](https://www.netapp.com/learn/cvo-blg-kubernetes-persistent-volume-claims-explained/)  
8. How to Bind a PVC to a Specific PV | Baeldung on Ops, otwierano: listopada 15, 2025, [https://www.baeldung.com/ops/kubernetes-persistent-volume-claim-bind-pv](https://www.baeldung.com/ops/kubernetes-persistent-volume-claim-bind-pv)  
9. What is the difference between persistent volume (PV) and persistent volume claim (PVC) in simple terms? \- Stack Overflow, otwierano: listopada 15, 2025, [https://stackoverflow.com/questions/48956049/what-is-the-difference-between-persistent-volume-pv-and-persistent-volume-clai](https://stackoverflow.com/questions/48956049/what-is-the-difference-between-persistent-volume-pv-and-persistent-volume-clai)  
10. The logic behind PV and PVC? : r/kubernetes \- Reddit, otwierano: listopada 15, 2025, [https://www.reddit.com/r/kubernetes/comments/17kspnx/the\_logic\_behind\_pv\_and\_pvc/](https://www.reddit.com/r/kubernetes/comments/17kspnx/the_logic_behind_pv_and_pvc/)  
11. Configure a Pod to Use a PersistentVolume for Storage | Kubernetes, otwierano: listopada 15, 2025, [https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/](https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/)  
12. Chapter 3\. Understanding persistent storage | Storage | OpenShift Container Platform | 4.9, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.9/html/storage/understanding-persistent-storage](https://docs.redhat.com/en/documentation/openshift_container_platform/4.9/html/storage/understanding-persistent-storage)  
13. Understanding Access Modes of Persistent Volumes in Kubernetes | Baeldung on Ops, otwierano: listopada 15, 2025, [https://www.baeldung.com/ops/kubernetes-access-modes-persistent-volumes](https://www.baeldung.com/ops/kubernetes-access-modes-persistent-volumes)  
14. kubernetes persistent volume accessmode \- Stack Overflow, otwierano: listopada 15, 2025, [https://stackoverflow.com/questions/37649541/kubernetes-persistent-volume-accessmode](https://stackoverflow.com/questions/37649541/kubernetes-persistent-volume-accessmode)  
15. Change the Reclaim Policy of a PersistentVolume \- Kubernetes, otwierano: listopada 15, 2025, [https://kubernetes.io/docs/tasks/administer-cluster/change-pv-reclaim-policy/](https://kubernetes.io/docs/tasks/administer-cluster/change-pv-reclaim-policy/)  
16. Chapter 2\. Understanding persistent storage | Storage | OpenShift Container Platform | 4.3, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.3/html/storage/understanding-persistent-storage](https://docs.redhat.com/en/documentation/openshift_container_platform/4.3/html/storage/understanding-persistent-storage)  
17. PV data persistence : r/kubernetes \- Reddit, otwierano: listopada 15, 2025, [https://www.reddit.com/r/kubernetes/comments/1c0xz83/pv\_data\_persistence/](https://www.reddit.com/r/kubernetes/comments/1c0xz83/pv_data_persistence/)  
18. What is the difference between PersistentVolumeReclaimPolicy value \- like Delet . . . \- Kubernetes \- KodeKloud \- DevOps Learning Community, otwierano: listopada 15, 2025, [https://kodekloud.com/community/t/what-is-the-difference-between-persistentvolumereclaimpolicy-value-like-delet/18638](https://kodekloud.com/community/t/what-is-the-difference-between-persistentvolumereclaimpolicy-value-like-delet/18638)  
19. How to create a new storageclass with RECLAIMPOLICY: Retain in VKS, otwierano: listopada 15, 2025, [https://knowledge.broadcom.com/external/article/398198/how-to-create-a-new-storageclass-with-re.html](https://knowledge.broadcom.com/external/article/398198/how-to-create-a-new-storageclass-with-re.html)  
20. Storage class requirements \- IBM, otwierano: listopada 15, 2025, [https://www.ibm.com/docs/en/tarm/8.14.5?topic=requirements-storage-class](https://www.ibm.com/docs/en/tarm/8.14.5?topic=requirements-storage-class)  
21. Dynamic Volume Provisioning | Kubernetes, otwierano: listopada 15, 2025, [https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/)  
22. Understanding Dynamic Provisioning in Kubernetes \- StorageClass.info CSI Drivers, otwierano: listopada 15, 2025, [https://storageclass.info/glossary/dynamic-provisioning-in-kubernetes](https://storageclass.info/glossary/dynamic-provisioning-in-kubernetes)  
23. Kubernetes StorageClass: Concepts and Common Operations \- NetApp, otwierano: listopada 15, 2025, [https://www.netapp.com/blog/cvo-blg-kubernetes-storageclass-concepts-and-common-operations/](https://www.netapp.com/blog/cvo-blg-kubernetes-storageclass-concepts-and-common-operations/)  
24. Storage Classes | Kubernetes, otwierano: listopada 15, 2025, [https://kubernetes.io/docs/concepts/storage/storage-classes/](https://kubernetes.io/docs/concepts/storage/storage-classes/)  
25. Dynamic Provisioning and Storage Classes in Kubernetes, otwierano: listopada 15, 2025, [https://kubernetes.io/blog/2016/10/dynamic-provisioning-and-storage-in-kubernetes/](https://kubernetes.io/blog/2016/10/dynamic-provisioning-and-storage-in-kubernetes/)  
26. Understanding Storage Classes, PVs, and PVCs in Kubernetes | by Saraswathi Lakshman, otwierano: listopada 15, 2025, [https://saraswathilakshman.medium.com/understanding-storage-classes-pvs-and-pvcs-in-kubernetes-45f9375cfff3](https://saraswathilakshman.medium.com/understanding-storage-classes-pvs-and-pvcs-in-kubernetes-45f9375cfff3)  
27. Change the default StorageClass | Kubernetes, otwierano: listopada 15, 2025, [https://kubernetes.io/docs/tasks/administer-cluster/change-default-storage-class/](https://kubernetes.io/docs/tasks/administer-cluster/change-default-storage-class/)  
28. How to create and use a local Storage Class for SNO (Part 2\) \- Interloc Solutions, otwierano: listopada 15, 2025, [https://www.interlocsolutions.com/blog/how-to-create-and-use-a-local-storage-class-for-sno-part-2](https://www.interlocsolutions.com/blog/how-to-create-and-use-a-local-storage-class-for-sno-part-2)  
29. Chapter 9\. Storage | Virtualization | OpenShift Container Platform \- Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.14/html/virtualization/storage](https://docs.redhat.com/en/documentation/openshift_container_platform/4.14/html/virtualization/storage)  
30. Configuring local storage by using the hostpath provisioner \- OKD Documentation, otwierano: listopada 15, 2025, [https://docs.okd.io/4.18/virt/storage/virt-configuring-local-storage-with-hpp.html](https://docs.okd.io/4.18/virt/storage/virt-configuring-local-storage-with-hpp.html)  
31. Chapter 10\. Storage | Virtualization | Red Hat OpenShift Service on AWS classic architecture, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/red\_hat\_openshift\_service\_on\_aws\_classic\_architecture/4/html/virtualization/storage](https://docs.redhat.com/en/documentation/red_hat_openshift_service_on_aws_classic_architecture/4/html/virtualization/storage)  
32. Chapter 5\. Persistent storage using local storage | Storage | OpenShift Container Platform | 4.19 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.19/html/storage/persistent-storage-using-local-storage](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/storage/persistent-storage-using-local-storage)  
33. otwierano: listopada 15, 2025, [https://cloud.ibm.com/docs/openshift?topic=openshift-ocs-storage-prep\#:\~:text=OpenShift%20Data%20Foundation%3F-,OpenShift%20Data%20Foundation%20is%20a%20highly%20available%20storage%20solution%20that,on%20IBM%20Cloud%C2%AE%20clusters.](https://cloud.ibm.com/docs/openshift?topic=openshift-ocs-storage-prep#:~:text=OpenShift%20Data%20Foundation%3F-,OpenShift%20Data%20Foundation%20is%20a%20highly%20available%20storage%20solution%20that,on%20IBM%20Cloud%C2%AE%20clusters.)  
34. Running OpenShift Data Foundation on OCI with Availability Architecture \- Oracle Blogs, otwierano: listopada 15, 2025, [https://blogs.oracle.com/cloud-infrastructure/post/openshift-data-foundation-oci-availability-arch](https://blogs.oracle.com/cloud-infrastructure/post/openshift-data-foundation-oci-availability-arch)  
35. Red Hat OpenShift Data Foundation, otwierano: listopada 15, 2025, [https://www.redhat.com/en/technologies/cloud-computing/openshift-data-foundation](https://www.redhat.com/en/technologies/cloud-computing/openshift-data-foundation)  
36. Persistent storage using Red Hat OpenShift Data Foundation \- OKD Documentation, otwierano: listopada 15, 2025, [https://docs.okd.io/latest/storage/persistent\_storage/persistent-storage-ocs.html](https://docs.okd.io/latest/storage/persistent_storage/persistent-storage-ocs.html)  
37. Upgrading to OpenShift Data Foundation \- Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/red\_hat\_openshift\_data\_foundation/4.9/html-single/upgrading\_to\_openshift\_data\_foundation/index](https://docs.redhat.com/en/documentation/red_hat_openshift_data_foundation/4.9/html-single/upgrading_to_openshift_data_foundation/index)  
38. Chapter 3\. Updating Red Hat OpenShift Container Storage 4.8 to Red Hat OpenShift Data Foundation 4.9 | Upgrading to OpenShift Data Foundation | Red Hat OpenShift Data Foundation | 4.9 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/red\_hat\_openshift\_data\_foundation/4.9/html/upgrading\_to\_openshift\_data\_foundation/updating-ocs-to-odf\_rhodf](https://docs.redhat.com/en/documentation/red_hat_openshift_data_foundation/4.9/html/upgrading_to_openshift_data_foundation/updating-ocs-to-odf_rhodf)  
39. Understanding OpenShift Data Foundation \- IBM Cloud Docs, otwierano: listopada 15, 2025, [https://cloud.ibm.com/docs/openshift?topic=openshift-ocs-storage-prep](https://cloud.ibm.com/docs/openshift?topic=openshift-ocs-storage-prep)  
40. Getting started with Red Hat OpenShift Data Foundation on IBM Power Systems, otwierano: listopada 15, 2025, [https://developer.ibm.com/tutorials/getting-started-odf-on-power/](https://developer.ibm.com/tutorials/getting-started-odf-on-power/)  
41. Chapter 2\. Architecture of OpenShift Data Foundation | Planning your deployment \- Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/red\_hat\_openshift\_data\_foundation/4.9/html/planning\_your\_deployment/odf-architecture\_rhodf](https://docs.redhat.com/en/documentation/red_hat_openshift_data_foundation/4.9/html/planning_your_deployment/odf-architecture_rhodf)  
42. Red Hat OpenShift Data Foundation architecture, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/red\_hat\_openshift\_data\_foundation/4.9/html-single/red\_hat\_openshift\_data\_foundation\_architecture/index](https://docs.redhat.com/en/documentation/red_hat_openshift_data_foundation/4.9/html-single/red_hat_openshift_data_foundation_architecture/index)  
43. Chapter 1\. Introduction to OpenShift Data Foundation \- Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/red\_hat\_openshift\_data\_foundation/4.9/html/red\_hat\_openshift\_data\_foundation\_architecture/introduction-to-openshift-data-foundation-4\_rhodf](https://docs.redhat.com/en/documentation/red_hat_openshift_data_foundation/4.9/html/red_hat_openshift_data_foundation_architecture/introduction-to-openshift-data-foundation-4_rhodf)  
44. Expand Persistent Volume Claim Persistent storage resource ReadWriteOnce (RWO) ReadWriteMany (RWX) Ceph File System (CephFS) Ceph RADOS Block Devices (RBDs) ReadWriteOncePod (RWOP) Filesystem Persistent Volume Claim \- IBM, otwierano: listopada 15, 2025, [https://www.ibm.com/docs/en/fusion-software/2.9.x?topic=claims-expanding-persistent-volume](https://www.ibm.com/docs/en/fusion-software/2.9.x?topic=claims-expanding-persistent-volume)  
45. Managing and allocating storage resources | Red Hat OpenShift Data Foundation | 4.12, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/red\_hat\_openshift\_data\_foundation/4.12/html-single/managing\_and\_allocating\_storage\_resources/index](https://docs.redhat.com/en/documentation/red_hat_openshift_data_foundation/4.12/html-single/managing_and_allocating_storage_resources/index)  
46. Block vs File vs Object Storage \- Difference Between Data Storage Services \- Amazon AWS, otwierano: listopada 15, 2025, [https://aws.amazon.com/compare/the-difference-between-block-file-object-storage/](https://aws.amazon.com/compare/the-difference-between-block-file-object-storage/)  
47. Object storage vs. block storage: How are they different? | Cloudflare, otwierano: listopada 15, 2025, [https://www.cloudflare.com/learning/cloud/object-storage-vs-block-storage/](https://www.cloudflare.com/learning/cloud/object-storage-vs-block-storage/)  
48. Deploying and Managing OpenShift Data Foundation :: OCS Training \- GitHub Pages, otwierano: listopada 15, 2025, [https://red-hat-storage.github.io/ocs-training/training/ocs4/odf.html](https://red-hat-storage.github.io/ocs-training/training/ocs4/odf.html)  
49. Object vs. File vs. Block Storage: What's the Difference? | IBM, otwierano: listopada 15, 2025, [https://www.ibm.com/think/topics/object-vs-file-vs-block-storage](https://www.ibm.com/think/topics/object-vs-file-vs-block-storage)  
50. Managing OpenShift Container Storage \- Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/red\_hat\_openshift\_container\_storage/4.2/html-single/managing\_openshift\_container\_storage/index](https://docs.redhat.com/en/documentation/red_hat_openshift_container_storage/4.2/html-single/managing_openshift_container_storage/index)  
51. Volume Snapshots | Kubernetes, otwierano: listopada 15, 2025, [https://kubernetes.io/docs/concepts/storage/volume-snapshots/](https://kubernetes.io/docs/concepts/storage/volume-snapshots/)  
52. Complete Guide to Kubernetes VolumeSnapshot, PVC Backup and Restore, and Automated… \- Ibrahim Halil Koyuncu, otwierano: listopada 15, 2025, [https://ibrahimhkoyuncu.medium.com/kubernetes-complete-guide-to-kubernetes-volumesnapshot-pvc-backup-and-restore-and-automated-2aade2a3a90a](https://ibrahimhkoyuncu.medium.com/kubernetes-complete-guide-to-kubernetes-volumesnapshot-pvc-backup-and-restore-and-automated-2aade2a3a90a)  
53. Using EBS Snapshots for persistent storage with your EKS cluster \- Amazon AWS, otwierano: listopada 15, 2025, [https://aws.amazon.com/blogs/containers/using-ebs-snapshots-for-persistent-storage-with-your-eks-cluster/](https://aws.amazon.com/blogs/containers/using-ebs-snapshots-for-persistent-storage-with-your-eks-cluster/)  
54. Volume Snapshot Classes \- Kubernetes, otwierano: listopada 15, 2025, [https://kubernetes.io/docs/concepts/storage/volume-snapshot-classes/](https://kubernetes.io/docs/concepts/storage/volume-snapshot-classes/)  
55. Kubernetes Snapshots and Backups \- Portworx Documentation, otwierano: listopada 15, 2025, [https://docs.portworx.com/portworx-enterprise/concepts/kubernetes-storage-101/snapshots](https://docs.portworx.com/portworx-enterprise/concepts/kubernetes-storage-101/snapshots)  
56. Linux Legacy Backup and Restore VS Openshift Volumes Snapshot or OADP Operator | by Peaceworld Abbas | Medium, otwierano: listopada 15, 2025, [https://medium.com/@peaceworld.abbas/linux-legacy-backup-and-restore-vs-openshift-volumes-snapshot-or-oadp-operator-92e876f05603](https://medium.com/@peaceworld.abbas/linux-legacy-backup-and-restore-vs-openshift-volumes-snapshot-or-oadp-operator-92e876f05603)  
57. About volume snapshots | Google Kubernetes Engine (GKE), otwierano: listopada 15, 2025, [https://docs.cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/volume-snapshots](https://docs.cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/volume-snapshots)  
58. Processing a backup with OADP \- IBM, otwierano: listopada 15, 2025, [https://www.ibm.com/docs/en/rhocp-ibm-z?topic=restore-processing-backup-oadp](https://www.ibm.com/docs/en/rhocp-ibm-z?topic=restore-processing-backup-oadp)  
59. Can VolumeSnapshot be used for Disaster Recovery? : r/kubernetes \- Reddit, otwierano: listopada 15, 2025, [https://www.reddit.com/r/kubernetes/comments/1labmlo/can\_volumesnapshot\_be\_used\_for\_disaster\_recovery/](https://www.reddit.com/r/kubernetes/comments/1labmlo/can_volumesnapshot_be_used_for_disaster_recovery/)  
60. How Velero Works, otwierano: listopada 15, 2025, [https://velero.io/docs/v1.4/how-velero-works/](https://velero.io/docs/v1.4/how-velero-works/)  
61. Chapter 4\. Application backup and restore | Backup and restore | OpenShift Container Platform | 4.8 | Red Hat Documentation, otwierano: listopada 15, 2025, [https://docs.redhat.com/en/documentation/openshift\_container\_platform/4.8/html/backup\_and\_restore/application-backup-and-restore](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/backup_and_restore/application-backup-and-restore)  
62. otwierano: listopada 15, 2025, [https://velero.io/\#:\~:text=Velero%20is%20an%20open%20source,cluster%20resources%20and%20persistent%20volumes.](https://velero.io/#:~:text=Velero%20is%20an%20open%20source,cluster%20resources%20and%20persistent%20volumes.)  
63. Velero, otwierano: listopada 15, 2025, [https://velero.io/](https://velero.io/)  
64. Velero. This repository focuses on the… | by Omarbenabdejlil | Sep, 2025, otwierano: listopada 15, 2025, [https://medium.com/@omarbenabdejlil.dev/velero-0d7ba852ec3b](https://medium.com/@omarbenabdejlil.dev/velero-0d7ba852ec3b)  
65. Backing up applications \- OADP Application backup and restore \- OKD Documentation, otwierano: listopada 15, 2025, [https://docs.okd.io/latest/backup\_and\_restore/application\_backup\_and\_restore/backing\_up\_and\_restoring/backing-up-applications.html](https://docs.okd.io/latest/backup_and_restore/application_backup_and_restore/backing_up_and_restoring/backing-up-applications.html)  
66. Get started with OpenShift APIs for Data Protection \- Red Hat Developer, otwierano: listopada 15, 2025, [https://developers.redhat.com/articles/2024/11/04/get-started-openshift-apis-data-protection](https://developers.redhat.com/articles/2024/11/04/get-started-openshift-apis-data-protection)  
67. OpenShift APIs for Data Protection (OADP) FAQ \- Red Hat Customer Portal, otwierano: listopada 15, 2025, [https://access.redhat.com/articles/5456281](https://access.redhat.com/articles/5456281)  
68. openshift/oadp-operator \- GitHub, otwierano: listopada 15, 2025, [https://github.com/openshift/oadp-operator](https://github.com/openshift/oadp-operator)  
69. Storage Architecture \- Rook Ceph Documentation, otwierano: listopada 15, 2025, [https://rook.io/docs/rook/v1.14/Getting-Started/storage-architecture/](https://rook.io/docs/rook/v1.14/Getting-Started/storage-architecture/)
