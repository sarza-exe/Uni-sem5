# Sara Żyndul 279686
(@isdefined matrixgen) == false ? include("matrixgen.jl") : nothing
using .matrixgen
(@isdefined blocksys) == false ? include("blocksys.jl") : nothing
using .blocksys
using Plots

# Rozmiary macierzy do przetestowania
sizes = [1000, 5000, 10000, 25000, 50000, 100000, 250000, 500000, 1000000]
l_block = 4      # Rozmiar bloku l
ck = 2.0        # Uwarunkowanie ck
samples_per_size = 5 # Liczba macierzy do wygenerowania i uśrednienia dla każdego rozmiaru

# Tablice na uśrednione wyniki na 4 algorytmy: Gauss, Gauss PP, LU, LU PP
avg_times = zeros(Float64, length(sizes), 4)
avg_rels = zeros(Float64, length(sizes), 4)

println("Rozpoczynanie testów...")

for (idx, n) in enumerate(sizes)
    println("Testowanie dla n = $n ($samples_per_size prób)...")
    
    # Bufory na sumowanie wyników dla danej wielkości n
    sum_times = zeros(Float64, 4)
    sum_rels = zeros(Float64, 4)
    
    for k in 1:samples_per_size
        # Generowanie nazwy pliku tymczasowego
        temp_filename = "temp_A_$(n)_$(k).txt"
        
        # Generowanie macierzy funkcją blockmat
        # (Zakładam, że funkcja blockmat jest już załadowana w pamięci)
        blockmat(n, l_block, ck, temp_filename)
        
        # Uruchomienie benchmarku
        # (Zakładam, że funkcja benchmark zwraca wektor wyników dla 4 metod)
        results = benchmark(temp_filename)
        
        # Sumowanie wyników
        for r in 1:4
            sum_times[r] += results[r].time
            sum_rels[r] += results[r].rel
        end
        
        # Usunięcie pliku tymczasowego
        rm(temp_filename)
    end
    
    # Obliczanie średniej dla danego n
    for r in 1:4
        avg_times[idx, r] = sum_times[r] / samples_per_size
        avg_rels[idx, r] = sum_rels[r] / samples_per_size
    end
end

println("Testy zakończone. Generowanie wykresów...")


labels = ["Eliminacja Gaussa", "Eliminacja Gaussa PP", "Rozkład LU", "Rozkład LU PP"]

# Wykres Czasów
p = plot(xlabel = "n", ylabel = "średni czas [s]", legend = :topleft)

for j in 1:4
    plot!(p, sizes, avg_times[:, j], label = labels[j], marker = :o)
end

title!(p, "Średnie czasy obliczania Ax=b")
savefig(p, "times_avg.png")
display(p)

# Wykres Błędów Względnych
# Używamy skali logarytmicznej dla obu osi, aby lepiej widzieć różnice rzędów wielkości
p2 = plot(xlabel = "n", ylabel = "średni błąd względny", legend = :topright)
plot!(p2, xscale = :log10, yscale = :log10)

for j in 1:4
    plot!(p2, sizes, avg_rels[:, j], label = labels[j], marker = :o)
end

title!(p2, "Średni błąd względny rozwiązania Ax=b")
savefig(p2, "rels_avg.png")
display(p2)

println("Wykresy zapisano jako 'times_avg.png' oraz 'rels_avg.png'.")