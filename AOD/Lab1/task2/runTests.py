#!/usr/bin/env python3
"""
Uruchamia kolejno dla wszystkich plików .txt w katalogu 'task2' (alfabetycznie):
  <python> task2/task2.py -i <plik>
"""
import sys
import subprocess
from pathlib import Path
import time
import csv
import argparse

def find_txt_files(task2_dir: Path):
    return sorted([p for p in task2_dir.iterdir() if p.is_file() and p.suffix.lower() == ".txt"])

def run_command(cmd):
    """Uruchamia polecenie i zwraca (returncode, stdout, stderr, elapsed_seconds)."""
    start = time.perf_counter()
    try:
        res = subprocess.run(cmd, check=False, text=True, capture_output=True)
        end = time.perf_counter()
        elapsed = end - start
        return res.returncode, res.stdout, res.stderr, elapsed
    except Exception as e:
        # Jeżeli wystąpi wyjątek uruchamiania procesu (np. FileNotFoundError),
        # traktujemy jako błąd i zwracamy ujemny kod
        end = time.perf_counter()
        elapsed = end - start
        return -1, "", f"Exception: {e}", elapsed

def main():
    parser = argparse.ArgumentParser(description="Uruchamia task2.py (bfs, dfs) dla wszystkich plików .txt w ./task2 i mierzy czas.")
    parser.add_argument('--csv', help='(opcjonalnie) zapisz wyniki do pliku CSV (filename,mode,returncode,seconds)')
    args = parser.parse_args()

    script_dir = Path(__file__).resolve().parent
    task2_dir = script_dir

    if not task2_dir.exists() or not task2_dir.is_dir():
        print(f"Nie znaleziono katalogu: {task2_dir}", file=sys.stderr)
        sys.exit(1)

    txt_files = find_txt_files(task2_dir)
    if not txt_files:
        print(f"Brak plików .txt w katalogu: {task2_dir}")
        return

    task2_py = task2_dir / "task2.py"
    if not task2_py.exists():
        print(f"Nie znaleziono pliku {task2_py}", file=sys.stderr)
        sys.exit(1)

    py_exec = sys.executable

    csv_file = None
    csv_writer = None
    if args.csv:
        csv_file = open(args.csv, "w", newline='', encoding='utf-8')
        csv_writer = csv.writer(csv_file)
        # nie dodajemy nagłówka (ułatwia późniejsze scalanie)

    total_all = 0.0

    for txt in txt_files:
        print("="*80)
        print(f"Plik: {txt.name}")
        total_for_file = 0.0

        cmd = [py_exec, str(task2_py), "-i", str(txt)]
        rc, out, err, elapsed = run_command(cmd)
        total_for_file += elapsed
        total_all += elapsed

        # Wypiszemy stdout i stderr (jeżeli istnieje)
        if out:
            print(out, end="")
        if err:
            print("STDERR:", err, file=sys.stderr)

        # Wynik i czas
        print(f"returncode={rc} time={elapsed:.3f}s")

        # zapisz do CSV jeśli aktywne
        if csv_writer:
            csv_writer.writerow([txt.name, rc, f"{elapsed:.6f}"])
    print("="*80)
    print(f"Łączny czas wszystkich testów: {total_all:.3f}s")

    if csv_file:
        csv_file.close()
        print(f"Wyniki zapisane do: {args.csv}")

if __name__ == "__main__":
    main()
