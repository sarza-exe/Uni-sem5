# Sara Żyndul
using LinearAlgebra, Printf
include("hilb.jl")
include("matcond.jl")

# funkcje pomocnicze do eksperymentu
function experiment_solve(A)
    n = size(A,1)
    x_true = ones(n)
    b = A * x_true

    # rozwiązania
    x_backslash = A \ b
    x_inv = inv(A) * b

    # błędy względne w normie 2 (norma 2 - pierwiastek z sumy kwadratów elementów matrycy)
    rel2_backslash = norm(x_backslash - x_true) / norm(x_true)
    rel2_inv = norm(x_inv - x_true) / norm(x_true)

    return Dict(
        :cond => cond(A),
        :rank => rank(A),
        :rel2_backslash => rel2_backslash,
        :rel2_inv => rel2_inv,
    )
end

# wykonanie eksperymentów

# macierze Hilberta o rosnącym n
println("=== Hilbert ===")
for n in 2:15
    A = hilb(n)
    res = experiment_solve(A)
    @printf("n=%2d  cond≈%8.3e  rank=%2d  rel2_backslash=%8.3e  rel2_inv=%8.3e\n",
            n, res[:cond], res[:rank], res[:rel2_backslash], res[:rel2_inv])
end

# macierze losowe Rn dla n = 5,10,20 i c rosnące
println("\n=== Losowe macierze matcond ===")
ns = [5,10,20]
cs = [1.0, 1e1, 1e3, 1e7, 1e12, 1e16]
for n in ns
    for c in cs
        A = matcond(n, c)
        res = experiment_solve(A)
        @printf("n=%2d  c_req=%8.1e  cond(A)=%8.3e  rank=%2d  rel2_backslash=%8.3e  rel2_inv=%8.3e\n",
                n, c, res[:cond], res[:rank], res[:rel2_backslash], res[:rel2_inv])
    end
end