import os
import re
import pandas as pd
import matplotlib.pyplot as plt
import sys

# Konfiguracja
RESULTS_DIR = "results"
OUTPUT_DIR = "report"
FAMILIES = ["Random4-n", "Random4-C", "Long-n", "Square-n", "Long-C", "Square-C", "USA-road-d"]

if not os.path.exists(OUTPUT_DIR):
    os.makedirs(OUTPUT_DIR)

def parse_time_file(filepath):
    """Zwraca listę czasów z pliku .res"""
    times = []
    try:
        with open(filepath, 'r') as f:
            for line in f:
                if line.startswith('t '):
                    times.append(float(line.strip().split()[1]))
                elif "TIMEOUT" in line or "MLE" in line:
                    return None # Oznaczenie błędu/braku wyniku
    except FileNotFoundError:
        return None
    return times

def parse_dist_file(filepath):
    """Zwraca listę dystansów z pliku .res"""
    dists = []
    try:
        with open(filepath, 'r') as f:
            for line in f:
                if line.startswith('d '):
                    # Format: d u v dist
                    parts = line.strip().split()
                    dists.append(int(parts[3]))
                elif "MLE" in line or "TIMEOUT" in line:
                    return ["BŁĄD"]
    except FileNotFoundError:
        return ["BRAK"]
    return dists

def get_sort_key(instance_name):
    """Pomocnicza funkcja do bezpiecznego sortowania instancji"""
    parts = instance_name.split('.')
    
    # Przypadek 1: Grafy syntetyczne np. Long-C.8.0 -> sortujemy po 8
    if len(parts) >= 2:
        try:
            return int(parts[-2])
        except ValueError:
            pass # To nie liczba, idziemy dalej
            
    # Przypadek 2: USA-road np. USA-road-d.BAY -> sortujemy alfabetycznie po końcówce (BAY)
    if len(parts) >= 1:
        return instance_name
        
    return 0

# --- CZĘŚĆ 1: ZBIERANIE DANYCH O CZASACH (DO WYKRESÓW) ---
data_time = []

print("Przetwarzanie wyników czasowych...")

for family in FAMILIES:
    family_path = os.path.join(RESULTS_DIR, family)
    if not os.path.exists(family_path):
        print(f"Pominięto rodzinę (brak folderu): {family}")
        continue
    
    # Szukamy plików
    files = os.listdir(family_path)
    
    # Wyciągamy unikalne nazwy instancji
    instances = set()
    for f in files:
        if f.endswith(".res"):
            instance_name = f.split('_')[0]
            instances.add(instance_name)
    
    sorted_instances = sorted(list(instances), key=get_sort_key)

    for instance in sorted_instances:
        parts = instance.split('.')
        param = instance # Domyślnie cała nazwa (dla USA-road)
        
        # Próba wyciągnięcia liczby dla grafów syntetycznych
        if len(parts) >= 2:
            try:
                param = int(parts[-2])
            except ValueError:
                param = parts[-1] 

        for algo in ["dijkstra", "dial", "radix"]:
            # 1. Czas dla min source (s 1)
            file_min = os.path.join(family_path, f"{instance}_{algo}_min.res")
            times_min = parse_time_file(file_min)
            avg_min = times_min[0] if times_min and len(times_min) > 0 else None

            # 2. Czas dla random sources (s losowe)
            file_rand = os.path.join(family_path, f"{instance}_{algo}_rand.res")
            times_rand = parse_time_file(file_rand)
            avg_rand = sum(times_rand)/len(times_rand) if times_rand and len(times_rand) > 0 else None
            
            data_time.append({
                "Family": family,
                "Instance": instance,
                "Param": param,
                "Algorithm": algo,
                "Time_Min": avg_min,        # Czas dla źródła min
                "Time_Avg_Rand": avg_rand   # Średni czas dla 5 losowych
            })

df_time = pd.DataFrame(data_time)
if not df_time.empty:
    df_time.to_csv(os.path.join(OUTPUT_DIR, "times_raw.csv"), index=False)
    print(f"Zapisano surowe dane czasowe do {OUTPUT_DIR}/times_raw.csv")
else:
    print("Brak danych czasowych do zapisania.")

# --- GENEROWANIE WYKRESÓW (ZMODYFIKOWANE) ---
print("Generowanie wykresów...")

# Definicja typów wykresów do wygenerowania
plot_types = [
    {"col": "Time_Min",      "suffix": "min",  "title": "Czas (źródło o min. indeksie)"},
    {"col": "Time_Avg_Rand", "suffix": "rand", "title": "Czas (średnia z 5 losowych źródeł)"}
]

for family in FAMILIES:
    df_fam = df_time[df_time["Family"] == family]
    if df_fam.empty:
        continue
    
    # Sortowanie danych
    if family == "USA-road-d":
         df_fam = df_fam.sort_values(by="Param")
    else:
         df_fam = df_fam.sort_values(by="Param")
    
    # Generujemy DWA wykresy dla każdej rodziny (Min i Rand)
    for p_type in plot_types:
        col_name = p_type["col"]
        suffix = p_type["suffix"]
        title_desc = p_type["title"]

        plt.figure(figsize=(10, 6))
        
        for algo in ["dijkstra", "dial", "radix"]:
            subset = df_fam[df_fam["Algorithm"] == algo]
            # Usuwamy wiersze gdzie brakuje danych dla konkretnej kolumny (np. MLE)
            subset = subset.dropna(subset=[col_name])
            
            if not subset.empty:
                plt.plot(subset["Param"], subset[col_name], marker='o', label=algo)
        
        plt.title(f"{family} - {title_desc}")
        plt.ylabel("Czas [s]")
        
        if family == "USA-road-d":
            plt.xlabel("Region")
            plt.xticks(rotation=45)
        else:
            plt.xlabel("Parametr (n lub log C)")
            plt.yscale("log") # Skala logarytmiczna
            
        plt.legend()
        plt.grid(True)
        plt.tight_layout()
        
        # Zapis do pliku np. plot_Long-C_min.png
        filename = f"plot_{family}_{suffix}.png"
        plt.savefig(os.path.join(OUTPUT_DIR, filename))
        plt.close()

# --- CZĘŚĆ 2: TABELE POPRAWNOŚCI (BEZ ZMIAN) ---
print("Generowanie tabel poprawności...")
table_data = []

for family in FAMILIES:
    family_path = os.path.join(RESULTS_DIR, family)
    if not os.path.exists(family_path):
        continue

    files = [f for f in os.listdir(family_path) if "_p2p_" in f]
    if not files:
        continue
        
    instance_name = files[0].split('_')[0] 
    
    row = {"Rodzina": family, "Instancja": instance_name}
    
    for algo in ["dijkstra", "dial", "radix"]:
        f_mm = os.path.join(family_path, f"{instance_name}_{algo}_p2p_minmax.res")
        res_mm_list = parse_dist_file(f_mm)
        res_mm = res_mm_list[0] if res_mm_list else "BRAK"
        
        f_rnd = os.path.join(family_path, f"{instance_name}_{algo}_p2p_rand.res")
        res_rnd = parse_dist_file(f_rnd)
        
        row[f"{algo} (Min-Max)"] = res_mm
        row[f"{algo} (4 Random)"] = str(res_rnd)

    table_data.append(row)

if table_data:
    df_table = pd.DataFrame(table_data)
    df_table.to_csv(os.path.join(OUTPUT_DIR, "correctness_table.csv"), index=False)
    print(f"Zapisano tabelę poprawności do {OUTPUT_DIR}/correctness_table.csv")
else:
    print("Brak danych do tabeli poprawności.")

print("Zakończono.")