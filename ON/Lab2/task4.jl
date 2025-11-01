# Sara Żyndul

# using Pkg
# Pkg.add("Polynomials")
using Polynomials
using Printf
using LinearAlgebra

# współczynniki z pliku wielomian.txt
p_desc = [1, -210.0, 20615.0,-1256850.0,
      53327946.0,-1672280820.0, 40171771630.0, -756111184500.0,          
      11310276995381.0, -135585182899530.0,
      1307535010540395.0,     -10142299865511450.0,
      63030812099294896.0,     -311333643161390640.0,
      1206647803780373360.0,     -3599979517947607200.0,
      8037811822645051776.0,      -12870931245150988800.0,
      13803759753640704000.0,      -8752948036761600000.0,
      2432902008176640000.0]

# Polynomials oczekuje wektora w porządku rosnących potęg (const -> najwyższa)
P = Polynomial(reverse(p_desc))  # wielomian w postaci obiektu Polynomial

# Wielomian w postaci iloczynowej (dokładna postać z pierwiastkami 1..20)
function p_factored(x)
    prod = one(x)
    for k in 1:20
        prod *= (x - k)
    end
    return prod
end

# obliczenie zer z funkcji roots
z = roots(P)

# Obliczenia: |P(zk)|, |p_factored(zk)|, |zk - k|
println("| k |     zk (real)      |  |P(zk)|  |  |p(zk)|  |  |zk - k| |")
for (k, zk) in enumerate(z)
    val_P = abs(P(zk))
    val_p = abs(p_factored(zk))
    diff = abs(zk - k)
    @printf("| %2d | % .12f | %9.3e | %9.3e | %9.3e |\n", k, zk, val_P, val_p, diff)
end

# drobna modyfikacja współczynnika -210 -> -210 - 2^-23
p_desc2 = copy(p_desc)
p_desc2[2] = p_desc2[2] - 2.0^-23   # indeks 2 to drugi współczynnik
P2 = Polynomial(reverse(p_desc2))

z2 = roots(P2)

println("\nPo perturbacji (-210 -> -210 - 2^-23):")
println("| k |     zk' (real)     |  |P2(zk')|  |  |p(zk')|  |  |zk' - k| |")
for (k, zk) in enumerate(z2)
    val_P2 = abs(P2(zk))
    val_p2 = abs(p_factored(zk))
    diff2 = abs(zk - k)
    @printf("| %2d | % .12f+%.8fim | %9.3e | %9.3e | %9.3e |\n", k, real(zk), imag(zk), val_P2, val_p2, diff2)
end

