#!/bin/bash

# Zatrzymanie skryptu kombinacją Ctrl+C
trap "echo ' Przerwano przez użytkownika!'; rm -f tmp_*.ss tmp_*.p2p; exit 1" INT

# ================= KONFIGURACJA =================
EXE="./main"
INPUT_ROOT="ch9-1.1/inputs"
RESULTS_DIR="results"
ALGOS=("dijkstra" "dial" "radix")
# ALGOS=("dijkstra") # Odkomentuj do szybkich testów tylko jednego algorytmu

# Lista rodzin (zgodna z nazwami folderów)
FAMILIES=("Random4-n" "Random4-C" "Long-n" "Square-n" "Long-C" "Square-C" "USA-road-d")

# Limit czasu na jeden test (ważne dla Diala przy dużych wagach)
TIME_LIMIT="600s" 

if [ ! -f "$EXE" ]; then
    echo "BŁĄD: Nie znaleziono pliku wykonywalnego $EXE (skompiluj jako 'main')"
    exit 1
fi

echo "=== Rozpoczynam generowanie testów ==="

for FAMILY in "${FAMILIES[@]}"; do
    FAMILY_DIR="$INPUT_ROOT/$FAMILY"
    
    if [ ! -d "$FAMILY_DIR" ]; then
        echo "Pominięto: $FAMILY (brak katalogu)"
        continue
    fi

    echo "------------------------------------------------"
    echo "Rodzina: $FAMILY"
    mkdir -p "$RESULTS_DIR/$FAMILY"

    # Pobieramy listę grafów posortowaną naturalnie (wersyjnie)
    GR_FILES=$(ls "$FAMILY_DIR"/*.gr 2>/dev/null | sort -V)
    
    if [ -z "$GR_FILES" ]; then
        echo "  Brak plików .gr"
        continue
    fi

    # Znalezienie największego pliku (ostatni na liście) dla testów P2P
    LAST_GR_FILE=$(echo "$GR_FILES" | tail -n 1)

    for GR_FILE in $GR_FILES; do
        BASENAME=$(basename "$GR_FILE" .gr)
        
        # 1. WYCIĄGNIĘCIE LICZBY WIERZCHOŁKÓW (N)
        # Szukamy linii zaczynającej się od "p", format: p sp n m
        # awk '{print $3}' wyciąga trzecią kolumnę (n)
        N=$(grep "^p" "$GR_FILE" | head -n 1 | awk '{print $3}')

        if [ -z "$N" ]; then
            echo "  BŁĄD: Nie udało się odczytać N z pliku $BASENAME"
            continue
        fi

        echo "  Graf: $BASENAME (N=$N)"

        # 2. GENEROWANIE PLIKÓW WEJŚCIOWYCH .SS (Single Source)
        
        # A) Najmniejszy indeks (zawsze 1)
        echo "s 1" > tmp_min.ss

        # B) 5 losowych wierzchołków (jednostajnie losowo)
        # shuf -i LO-HI -n COUNT generuje unikalne liczby
        shuf -i 1-"$N" -n 5 | awk '{print "s " $1}' > tmp_rand.ss

        # 3. URUCHAMIANIE TESTÓW SS DLA WSZYSTKICH ALGORYTMÓW
        for ALGO in "${ALGOS[@]}"; do
            # Pliki wynikowe
            RES_MIN="$RESULTS_DIR/$FAMILY/${BASENAME}_${ALGO}_min.res"
            RES_RAND="$RESULTS_DIR/$FAMILY/${BASENAME}_${ALGO}_rand.res"

            # Uruchomienie dla min indeksu (s 1)
            timeout $TIME_LIMIT $EXE -a "$ALGO" -d "$GR_FILE" -ss tmp_min.ss -oss "$RES_MIN"
            
            # Uruchomienie dla 5 losowych (średnia liczona później w Excelu/Pythonie)
            timeout $TIME_LIMIT $EXE -a "$ALGO" -d "$GR_FILE" -ss tmp_rand.ss -oss "$RES_RAND"
        done

        # 4. TESTY P2P (TYLKO DLA NAJWIĘKSZEJ INSTANCJI)
        if [ "$GR_FILE" == "$LAST_GR_FILE" ]; then
            echo "    -> To największa instancja. Uruchamiam testy P2P..."

            # A) Najmniejszy - Największy (1 -> N)
            echo "q 1 $N" > tmp_minmax.p2p

            # B) 4 losowe pary
            # Generujemy 4 linie, każda to "q <los> <los>"
            > tmp_rand.p2p # czyścimy plik
            for i in {1..4}; do
                u=$(shuf -i 1-"$N" -n 1)
                v=$(shuf -i 1-"$N" -n 1)
                echo "q $u $v" >> tmp_rand.p2p
            done

            for ALGO in "${ALGOS[@]}"; do
                RES_P2P_MM="$RESULTS_DIR/$FAMILY/${BASENAME}_${ALGO}_p2p_minmax.res"
                RES_P2P_RND="$RESULTS_DIR/$FAMILY/${BASENAME}_${ALGO}_p2p_rand.res"

                # Min-Max
                timeout $TIME_LIMIT $EXE -a "$ALGO" -d "$GR_FILE" -p2p tmp_minmax.p2p -op2p "$RES_P2P_MM"
                
                # 4 Losowe pary
                timeout $TIME_LIMIT $EXE -a "$ALGO" -d "$GR_FILE" -p2p tmp_rand.p2p -op2p "$RES_P2P_RND"
            done
        fi
    done
done

# Sprzątanie plików tymczasowych
rm -f tmp_min.ss tmp_rand.ss tmp_minmax.p2p tmp_rand.p2p

echo "=== Zakończono testy ==="
echo "Dane do wykresów znajdują się w folderze: $RESULTS_DIR"