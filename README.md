# Ścieżka Nauki: Od Podstaw K8s do Poziomu Średniozaawansowanego w OpenShift

To repozytorium dokumentuje moją osobistą ścieżkę nauki platformy OpenShift (w wersji 4.x). Agenda ta powstała jako ustrukturyzowany plan, który przygotowałem na własne potrzeby, aby przejść od podstaw Kubernetesa do zagadnień specyficznych dla OpenShift.

Plan szkoleniowy został pierwotnie wygenerowany przy pomocy Gemini, aby zapewnić logiczną kolejność i pokrycie materiału. Następnie, poszczególne moduły zostały uzupełnione o szczegółowe lekcje w oparciu o analizę dokumentacji technicznej i dostępne zasoby (proces "deepsearch").

## Cel Repozytorium

Głównym celem jest usystematyzowanie wiedzy i stworzenie "mapy drogowej" dla procesu nauki. Repozytorium to nie jest oficjalnym kursem, lecz zbiorem zagadnień, które uznałem za kluczowe do zrozumienia platformy. Dzielę się tym w nadziei, że taka struktura może być przydatna również dla innych osób rozpoczynających pracę z OpenShift.

## Struktura Agendy

Całość podzielona jest na moduły, które progresywnie budują wiedzę:

* **Moduł 0: Przygotowanie Laboratorium**
    * Koncentruje się na uruchomieniu środowiska testowego przy użyciu **OpenShift Local** (dawniej CRC).

* **Moduł 1: Fundamenty**
    * Wyjaśnia kluczowe różnice filozoficzne i techniczne między "czystym" Kubernetesem (K8s) a OpenShift (OCP), m.in. `Project` vs `Namespace`, `oc` vs `kubectl` oraz architektura bazująca na Operatorach.

* **Moduł 2: Budowanie Aplikacji**
    * Omawia zintegrowany rejestr, obiekty `ImageStream` oraz strategie budowania, ze szczególnym uwzględnieniem **S2I (Source-to-Image)**.

* **Moduł 3: Wdrażanie Aplikacji**
    * Porównuje `Deployment` (K8s) z `DeploymentConfig` (OCP) i omawia strategie wdrożeniowe (Rolling, Recreate).

* **Moduł 4: Sieć**
    * Skupia się na obiekcie `Route` (odpowiednik Ingress) oraz podstawach izolacji sieciowej za pomocą `NetworkPolicy`.

* **Moduł 5: Troubleshooting**
    * Przegląd podstawowych komend diagnostycznych (`oc get events`, `oc describe`, `oc logs`, `oc debug`).

* **Moduł 6: Bezpieczeństwo**
    * Omawia RBAC, `ServiceAccount` oraz fundamentalny dla OCP koncept **SecurityContextConstraints (SCC)**.

* **Moduł 7: Konfiguracja**
    * Zarządzanie `ConfigMap` i `Secret` oraz koncepcja `Service Binding`.

* **Moduł 8: Storage**
    * Koncepcje `PV`, `PVC`, `StorageClass` oraz wprowadzenie do OpenShift Data Foundation (ODF).

* **Moduł 9: Skalowanie**
    * Sondy (`liveness`, `readiness`), `HorizontalPodAutoscaler` (HPA) oraz zarządzanie zasobami (`ResourceQuota`, `LimitRange`).

* **Moduł 10: CI/CD**
    * Przegląd trzech podejść: "Legacy" (Jenkins), "Cloud Native" (OpenShift Pipelines / Tekton) oraz "GitOps" (OpenShift GitOps / ArgoCD).

* **Moduł 11: Ekosystem Operatorów (OLM)**
    * Zarządzanie cyklem życia oprogramowania za pomocą Operator Lifecycle Manager i OperatorHub.

* **Moduł 12: Obserwowalność**
    * Wbudowany stos monitoringu (Prometheus, Grafana) i logowania (Loki/EFK) oraz wprowadzenie do tracingu (Jaeger).

* **Moduł 13: Co Dalej?**
    * Wprowadzenie do tematów zaawansowanych (Service Mesh, Serverless, Virtualization) i ścieżek certyfikacji.
