# Sara Żyndul
# using Pkg
# Pkg.add("Plots")
using Plots, Printf, DelimitedFiles
gr()   # backend GR

# iteracja funkcji f(x)=x^2 + c
function iterate_map(c, x0; N=40)
    f(x) = x^2 + c
    xs = Vector{Float64}(undef, N+1)
    xs[1] = x0
    for n in 1:N
        xs[n+1] = xs[n]^2 + c
    end
    return xs, f
end

# cobweb diagram: rysuje y=f(x), y=x i "schodki" iteracji
function cobweb_plot(f, xs; xlims = (-2, 2), ylims = (-2, 2))
    p = plot(f, xlims..., label="f(x)=x^2+c", legend=:topleft)
    plot!(x->x, xlims..., linestyle=:dash, label="y=x")
    for i in 1:length(xs)-1
        x0 = xs[i]; x1 = xs[i+1]
        plot!([x0, x0], [x0, x1], lw=1, color=:black, label=false)
        plot!([x0, x1], [x1, x1], lw=1, color=:black, label=false)
    end
    xlims!(xlims); ylims!(ylims)
    return p
end

# zapis i rysowanie jednego przypadku
function run_case(c, x0; N=40, name="case")
    xs, f = iterate_map(c, x0, N=N)

    # cobweb
    p_cob = cobweb_plot(f, xs; xlims = (-2.5, 2.5), ylims = (-2.5, 2.5))
    title!(p_cob, "c=$(c), x0=$(x0)")
    savefig(p_cob, "plots/$(name)_cobweb.png")

    return xs
end

isdir("plots") || mkdir("plots")

# lista przypadków do uruchomienia (7 przypadków)
cases = [
    (-2.0, 1.0, "c-2_x0_1"),
    (-2.0, 2.0, "c-2_x0_2"),
    (-2.0, 1.99999999999999, "c-2_x0_1.99999999999999"),
    (-1.0, 1.0, "c-1_x0_1"),
    (-1.0, -1.0, "c-1_x0_-1"),
    (-1.0, 0.75, "c-1_x0_0.75"),
    (-1.0, 0.25, "c-1_x0_0.25"),
]

num_cases = length(cases)
N = 40

# macierz wyników: wiersze = iteracje 1..40, kolumny = przypadki 1..7
results_mat = zeros(Float64, N, num_cases)

for (idx, (c,x0,name)) in enumerate(cases)
    println("Running ", name)
    xs = run_case(c, x0; N=N, name=name)
    # zapisz do macierzy wartości x1..x40 jako wiersze 1..40, kolumna idx
    results_mat[:, idx] .= xs[2:end]
end

println("Gotowe. Pliki .png zapisane w katalogu plots/ w bieżącym katalogu.")

# ładne wypisanie macierzy (wierszami = iteracje)
println("\nResults matrix (rows = iterations 1..40; cols = cases 1..7):")
for i in 1:size(results_mat,1)
    @printf("%2d: ", i)
    for j in 1:size(results_mat,2)
        @printf("% .12e", results_mat[i,j])
        if j < size(results_mat,2)
            print(", ")
        end
    end
    println()
end
