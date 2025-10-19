# Sara Żyndul
using Printf

# Delta teoretyczna w [1,2]
delta = 2.0^-52

# Funkcja pomocnicza: wydobywa pola bitowe IEEE754 z Float64 (bitstring)
# bitstring: 1 sign bit, 11 exponent bits, 52 fraction bits
function fields(x::Float64)
    b = bitstring(x)
    sign = b[1]
    exp_bits = b[2:12] # 11 bitów wykładnika
    frac_bits = b[13:end] # 52 bitów mantysy
    exp_field = parse(Int, exp_bits; base=2)
    exp_unbiased = exp_field - 1023 # rzeczywisty wykladnik ([-1022,1023])
    frac_k = parse(Int, frac_bits; base=2)
    return (sign=sign, exp_field=exp_field, exp_unbiased=exp_unbiased, frac_bits=frac_bits, frac_k=frac_k, bitstr=b)
end

# Sprawdzenie: w [1,2] czy każda liczba daje x = 1 + k * 2^-52, gdzie k = frac_field
function check_in_1_2_sample(k_list)
    println("Sprawdzenie postaci x = 1 + k * 2^-52 dla wybranych k w [1,2]:")
    @printf("%18s  %-25s  %-22s  %-6s\n", "k", "x (Float64)", "mantysa", "ok?")
    for k in k_list
        x = 1.0 + ldexp(Float64(k), -52)   # 1 + k*2^-52
        f = fields(x)
        ok = (f.frac_k == k) && (abs(x - (1.0 + ldexp(Float64(k), -52))) == 0.0)
        tail = f.bitstr[end-20+1:end]  # pokaż 20 ostatnich bitów mantysy
        @printf("%18d  %-25.18e  %-22s  %-6s\n", k, x, tail, ok ? "TAK" : "NIE")
    end
    println()
end

# Sprawdzenie kroków nextfloat w obrębie przedziałów [1,2], [1/2,1], [2,4]
function sample_spacing(points::Vector{Float64})
    @printf("%24s  %24s  %24s  %6s\n", "x", "nextfloat(x)-x", "krok teoretyczny (2^(e-52))", "wykładnik")
    for x in points
        num = nextfloat(x) - x
        f = fields(x)
        theory = 2.0^(f.exp_unbiased - 52)   # spacing = 2^(e - 52)
        @printf("%24.17e  %24.18e  %24.18e  %6d\n", x, num, theory, f.exp_unbiased)
    end
    println()
end

# Wybrane przykłady / losowe próbki
k_samples = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 2^20, 2^40, Int(2^52 - 1)]
check_in_1_2_sample(k_samples)

# kilka punktów w [1,2]
pts_1_2 = [1.0, 1.0 + delta, 1.0 + 100*delta, 1.5, 1.9999999999999998]   # ostatni to praktyczny "blisko 2"
println("Próbkowanie w [1,2]:")
sample_spacing(pts_1_2)

# kilka punktów w [1/2,1]
pts_half_1 = [0.5, 0.5 + 2.0^-53, 0.75, 0.9999999999999999]  # 0.5, 0.75, blisko 1
println("Próbkowanie w [1/2,1]:")
sample_spacing(pts_half_1)

# kilka punktów w [2,4]
pts_2_4 = [2.0, 2.0 + 2.0^-51, 3.0, 3.9999999999999996]
println("Próbkowanie w [2,4]:")
sample_spacing(pts_2_4)

println("\nUwagi:")
println("- W przedziale [1,2] wykładnik rzeczywisty = 0, więc krok = 2^{-52} (czyli delta).")
println("- W przedziale [1/2,1] wykładnik rzeczywisty = -1, krok = 2^{-53} (połowa delta).")
println("- W przedziale [2,4] wykładnik rzeczywisty = 1, krok = 2^{-51} (dwa razy delta).")
println("- Ogólnie: na przedziale [2^e, 2^{e+1}) krok = 2^{e-52}.")
