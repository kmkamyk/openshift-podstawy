#!/bin/bash
set -e # Przerwij skrypt, jeśli jakakolwiek komenda się nie powiedzie

# --- Zabawny wpis, o który prosiłeś ---
PLACEHOLDER_MSG="# 🚧 W Budowie! 🚧

Ten moduł jest jeszcze w fazie koncepcyjnej. 
Na razie jest tu tylko ten tekst i moje dobre chęci.

Wróć później... albo zrób Pull Request! 😉
"

echo "=== 1. Tworzenie nowych katalogów... ==="
mkdir -p sciezka-operatora
mkdir -p sciezka-infrastruktury
mkdir -p sciezka-zarzadzania
echo "✅ Katalogi gotowe."

echo ""
echo "=== 2. Przenoszenie i zmiana nazw starych modułów (op-)... ==="
# Używamy `git mv`, aby zachować historię plików
# Zakładamy, że stare pliki są w katalogu 'docs/'

if [ -d "docs" ]; then
    git mv docs/modul-00-przygotowanie.md sciezka-operatora/op-00-przygotowanie.md
    git mv docs/modul-01-fundamenty.md sciezka-operatora/op-01-fundamenty.md
    git mv docs/modul-02-zarzadzanie-obrazami.md sciezka-operatora/op-02-zarzadzanie-obrazami.md
    git mv docs/modul-03-wdrazanie-aplikacji.md sciezka-operatora/op-03-wdrazanie-aplikacji.md
    git mv docs/modul-04-networking.md sciezka-operatora/op-04-networking.md
    git mv docs/modul-05-troubleshooting.md sciezka-operatora/op-05-troubleshooting.md
    git mv docs/modul-06-bezpieczenstwo.md sciezka-operatora/op-06-bezpieczenstwo.md
    git mv docs/modul-07-konfiguracja.md sciezka-operatora/op-07-konfiguracja.md
    git mv docs/modul-08-storage.md sciezka-operatora/op-08-storage.md
    git mv docs/modul-09-skalowanie.md sciezka-operatora/op-09-skalowanie.md
    git mv docs/modul-10-cicd.md sciezka-operatora/op-10-cicd.md
    git mv docs/modul-11-ekosystem-operatorow.md sciezka-operatora/op-11-ekosystem-operatorow.md
    git mv docs/modul-12-obserwowalnosc.md sciezka-operatora/op-12-obserwowalnosc.md
    git mv docs/modul-13-co-dalej.md sciezka-operatora/op-13-co-dalej.md

    echo "✅ Pliki 'op-' przeniesione."

    # Usuń stary katalog 'docs' (rmdir zadziała tylko wtedy, gdy jest pusty)
    rmdir docs
    echo "✅ Stary katalog 'docs/' usunięty."
else
    echo "⚠️  Ostrzeżenie: Katalog 'docs/' nie znaleziony. Pomijam przenoszenie."
fi


echo ""
echo "=== 3. Tworzenie placeholderów dla ścieżki INFRA... ==="
# Lista plików infra-
INFRA_FILES=(
    "infra-01-pod-maska-rhcos.md"
    "infra-02-instalacja-ipi-upi.md"
    "infra-03-storage-csi.md"
    "infra-04-networking-lb.md"
    "infra-05-wirtualizacja-kubevirt.md"
    "infra-06-multi-arch-power-z.md"
)

# Pętla tworząca pliki
for file in "${INFRA_FILES[@]}"; do
    echo -e "$PLACEHOLDER_MSG" > "sciezka-infrastruktury/$file"
done
echo "✅ Pliki 'infra-' gotowe."

echo ""
echo "=== 4. Tworzenie placeholderów dla ścieżki MGMT... ==="
# Lista plików mgmt-
MGMT_FILES=(
    "mgmt-01-acm-multicluster.md"
    "mgmt-02-acs-bezpieczenstwo.md"
    "mgmt-03-sso-identity.md"
    "mgmt-04-oadp-backup-dr.md"
    "mgmt-05-cost-management.md"
)

# Pętla tworząca pliki
for file in "${MGMT_FILES[@]}"; do
    echo -e "$PLACEHOLDER_MSG" > "sciezka-zarzadzania/$file"
done
echo "✅ Pliki 'mgmt-' gotowe."

echo ""
echo "🎉 === SUKCES! === 🎉"
echo "Nowa struktura repozytorium jest gotowa."
echo "Nie zapomnij zaktualizować głównego pliku README.md!"
echo ""
echo "Sprawdź zmiany poleceniem 'git status', a następnie:"
echo "git add ."
echo "git commit -m \"Refactor: Wprowadzenie nowej struktury repozytorium\""