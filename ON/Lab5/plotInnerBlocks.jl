# Sara Żyndul 279686
(@isdefined matrixgen) == false ? include("matrixgen.jl") : nothing
using .matrixgen
(@isdefined blocksys) == false ? include("blocksys.jl") : nothing
using .blocksys
using Statistics
using Plots

inner_sizes = [2, 10]  # rozmiary wewnętrznych bloków (l)
n_values = [10^2, 10^3, 10^4, 10^5, 10^6] # rozmiary macierzy n (dostosuj — 1e6 może być niepraktyczne)
per_size = 2  # ile macierzy na parę (n, l)
ck = 2.0  # condition number wewnętrznych bloków Ak
methods = 4  # oczekiwana liczba metod w wynikach benchmarku
labels = ["Eliminacja Gaussa", "Eliminacja Gaussa PP", "Rozkład LU", "Rozkład LU PP"]

Nn = length(n_values)
Nl = length(inner_sizes)

times_avg = fill(NaN, Nn, methods, Nl)
rels_avg  = fill(NaN, Nn, methods, Nl)

for (i_n, n) in enumerate(n_values)
    println("Przetwarzam n = $n ($i_n/$Nn)")
    for (i_l, l) in enumerate(inner_sizes)
        if n % l != 0
            println("  Pomijam l=$l (n % l != 0).")
            continue
        end

        acc_times = zeros(methods)
        acc_rels  = zeros(methods)
        runs_done = 0

        for rep in 1:per_size
            filename = "A$(n)_l$(l)_r$(rep).txt"
            println("    Generuję: n=$n, l=$l, rep=$rep -> $filename")
            blockmat(n, l, ck, filename)

            println("    Benchmark: $filename")
            results = benchmark(filename)  # oczekujemy results[r].time i results[r].rel

            if length(results) != methods
                error("Funkcja benchmark zwróciła długość $(length(results)), oczekiwano $methods.")
            end

            for r in 1:methods
                acc_times[r] += results[r].time
                acc_rels[r]  += results[r].rel
            end

            # usuń plik po wykorzystaniu
            try
                rm(filename; force = true)
                println("    Usunięto: $filename")
            catch e
                @warn "Nie udało się usunąć pliku $filename: $e"
            end

            runs_done += 1
        end

        if runs_done > 0
            times_avg[i_n, :, i_l] = acc_times / runs_done
            rels_avg[i_n, :, i_l]  = acc_rels  / runs_done
            println("  Średnie zapisane dla n=$n, l=$l (runs=$runs_done).")
        else
            println("  Brak uruchomień dla n=$n, l=$l.")
        end
    end
end

p_times = plot(xlabel = "n", ylabel = "czas (s)", title = "Czasy obliczania Ax=b — wszystkie metody i l", legend = :topleft)
for method in 1:methods
    for (i_l, l) in enumerate(inner_sizes)
        y = times_avg[:, method, i_l]
        valid = .!isnan.(y)
        if any(valid)
            label = "$(labels[method]), l=$(l)"
            plot!(p_times, n_values[valid], y[valid], label = label, marker = :auto)
        end
    end
end
savefig(p_times, "times_all_methods.png")
println("Zapisano: times_all_methods.png")

p_rels = plot(xlabel = "n", ylabel = "błąd względny", title = "Błąd względny rozwiązania Ax=b — wszystkie metody i l", legend = :topleft)
plot!(p_rels, xscale = :log10, yscale = :log10)
for method in 1:methods
    for (i_l, l) in enumerate(inner_sizes)
        y = rels_avg[:, method, i_l]
        valid = .!isnan.(y) .&& (y .> 0)
        if any(valid)
            label = "$(labels[method]), l=$(l)"
            plot!(p_rels, n_values[valid], y[valid], label = label, marker = :auto)
        end
    end
end
savefig(p_rels, "rels_all_methods.png")
println("Zapisano: rels_all_methods.png")

println("Gotowe. W katalogu roboczym znajdują się: times_all_methods.png i rels_all_methods.png")
