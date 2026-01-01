#!/bin/bash

make
echo "Rozpoczynam testy..."

for input_file in tests/*.imp; do
    base_name=$(basename "$input_file" .imp)
    expected="tests/$base_name.expected"
    stdin="tests/$base_name.input"
    
    # Kompilacja
    echo "PLIK: $input_file"
    ./kompilator "$input_file" "out.mr" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "$base_name: Błąd kompilacji"
        continue
    fi

    # Uruchomienie VM
    # Jeśli nie ma pliku input, użyj pustego
    if [ -f "$stdin" ]; then
        ./mw2025/maszyna-wirtualna out.mr < "$stdin" > temp_out.txt
    else
        ./mw2025/maszyna-wirtualna out.mr > temp_out.txt
    fi

    # Porównanie (diff) diff -w ignoruje białe znaki
    diff -w "$expected" temp_out.txt > /dev/null

    if [ $? -eq 0 ]; then
        echo "$base_name: OK"
    else
        echo "$base_name: Błąd wyniku"
        echo "   Oczekiwano:"
        cat "$expected"
        echo
        echo "   Otrzymano:"
        cat temp_out.txt
    fi
done

rm -f out.mr temp_out.txt