# Ścieżka Nauki: Od Podstaw K8s do Poziomu Średniozaawansowanego w OpenShift

To repozytorium dokumentuje moją osobistą ścieżkę nauki platformy OpenShift (w wersji 4.x). Agenda ta powstała jako ustrukturyzowany plan, który przygotowałem na własne potrzeby, aby przejść od podstaw Kubernetesa do zagadnień specyficznych dla OpenShift.

Plan szkoleniowy został pierwotnie wygenerowany przy pomocy Gemini, aby zapewnić logiczną kolejność i pokrycie materiału. Następnie, poszczególne moduły zostały uzupełnione o szczegółowe lekcje w oparciu o analizę dokumentacji technicznej i dostępne zasoby (proces "deepsearch").

## Cel Repozytorium

Głównym celem jest usystematyzowanie wiedzy i stworzenie "mapy drogowej" dla procesu nauki. Repozytorium to nie jest oficjalnym kursem, lecz zbiorem zagadnień, które uznałem za kluczowe do zrozumienia platformy. Dzielę się tym w nadziei, że taka struktura może być przydatna również dla innych osób rozpoczynających pracę z OpenShift.

## Struktura Agendy

Całość podzielona jest na moduły, które progresywnie budują wiedzę.

* **[Moduł 0: Przygotowanie Laboratorium](./docs/modul-00-przygotowanie.md)**
    * Koncentruje się na uruchomieniu środowiska testowego przy użyciu **OpenShift Local** (dawniej CRC).

* **[Moduł 1: Fundamenty](./docs/modul-01-fundamenty.md)**
    * Wyjaśnia kluczowe różnice filozoficzne i techniczne między "czystym" Kubernetesem (K8s) a OpenShift (OCP), m.in. `Project` vs `Namespace`, `oc` vs `kubectl` oraz architektura bazująca na Operatorach.

* **[Moduł 2: Budowanie Aplikacji](./docs/modul-02-budowanie-aplikacji.md)**
    * Omawia zintegrowany rejestr, obiekty `ImageStream` oraz strategie budowania, ze szczególnym uwzględnieniem **S2I (Source-to-Image)**.

* **[Moduł 3: Wdrażanie Aplikacji](./docs/modul-03-wdrazanie-aplikacji.md)**
    * Porównuje `Deployment` (K8s) z `DeploymentConfig` (OCP) i omawia strategie wdrożeniowe (Rolling, Recreate).

* **[Moduł 4: Sieć](./docs/modul-04-networking.md)**
    * Skupia się na obiekcie `Route` (odpowiednik Ingress) oraz podstawach izolacji sieciowej za pomocą `NetworkPolicy`.

* **[Moduł 5: Troubleshooting](./docs/modul-05-troubleshooting.md)**
    * Przegląd podstawowych komend diagnostycznych (`oc get events`, `oc describe`, `oc logs`, `oc debug`).

* **[Moduł 6: Bezpieczeństwo](./docs/modul-06-bezpieczenstwo.md)**
    * Omawia RBAC, `ServiceAccount` oraz fundamentalny dla OCP koncept **SecurityContextConstraints (SCC)**.

* **[Moduł 7: Konfiguracja](./docs/modul-07-konfiguracja.md)**
    * Zarządzanie `ConfigMap` i `Secret` oraz koncepcja `Service Binding`.

* **[Moduł 8: Storage](./docs/modul-08-storage.md)**
    * Koncepcje `PV`, `PVC`, `StorageClass` oraz wprowadzenie do OpenShift Data Foundation (ODF).

* **[Moduł 9: Skalowanie](./docs/modul-09-skalowanie.md)**
    * Sondy (`liveness`, `readiness`), `HorizontalPodAutoscaler` (HPA) oraz zarządzanie zasobami (`ResourceQuota`, `LimitRange`).

* **[Moduł 10: CI/CD](./docs/modul-10-cicd.md)**
    * Przegląd trzech podejść: "Legacy" (Jenkins), "Cloud Native" (OpenShift Pipelines / Tekton) oraz "GitOps" (OpenShift GitOps / ArgoCD).

* **[Moduł 11: Ekosystem Operatorów (OLM)](./docs/modul-11-ekosystem-operatorow.md)**
    * Zarządzanie cyklem życia oprogramowania za pomocą Operator Lifecycle Manager i OperatorHub.

* **[Moduł 12: Obserwowalność](./docs/modul-12-obserwowalnosc.md)**
    * Wbudowany stos monitoringu (Prometheus, Grafana) i logowania (Loki/EFK) oraz wprowadzenie do tracingu (Jaeger).

* **[Moduł 13: Co Dalej?](./docs/modul-13-co-dalej.md)**
    * Wprowadzenie do tematów zaawansowanych (Service Mesh, Serverless, Virtualization) i ścieżek certyfikacji.