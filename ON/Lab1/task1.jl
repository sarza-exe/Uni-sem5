# Sara Żyndul
using Printf

"""
Funkcja dla podanego typu T zwraca wartosc iteracyjnie wyliczonego 
epsilona maszynowego
"""
function mach_eps(::Type{T}) where T
    eps = T(1)
    # gdy 1 + eps == 1, to eps jest już mniejsze od macheps; dlatego zwracamy poprzednią wartość (eps*2)
    while T(1) + eps != T(1)
        eps = eps / T(2)
    end
    return eps * T(2)
end

"""
Funkcja dla podanego typu T zwraca wartosc iteracyjnie wyliczonej 
liczby maszynowej eta
"""
function eta(::Type{T}) where T
    eta = T(1)
    prev = eta
    while eta != T(0)
        prev = eta
        eta = eta / T(2)
    end
    return prev
end

"""
Funkcja dla podanego typu T zwraca wartosc iteracyjnie wyliczonej 
maksymalnej liczby
"""
function maxV(::Type{T}) where T
    maxNext = T(2)-eps(T)
    max::T = maxNext
    while !isinf(maxNext)
        max = maxNext
        maxNext = maxNext * T(2)    
    end
    step::T = max
    while (step > 0.0 && max + step > max)
        maxNext = max + step
        if !isinf(maxNext)
            max = maxNext
        else
            step /= 2
        end
    end
    return max
end

types = (Float16, Float32, Float64)

println("Maszynowy epsilon (macheps) - iteracyjnie vs eps(Typ)")
println("------------------------------------------------------------------------")
@printf("%-8s  %-20s  %-20s %-12s\n", "Typ", "iteracyjny", "eps(Typ)", "blad wzgledny")
println("------------------------------------------------------------------------")

for T in types
    iter = mach_eps(T)
    builtin = eps(T)
    rel_err = Float64(iter - builtin) / Float64(builtin)
    #%-22.16e means '-' left-align, 22 field width, .16 digits after .
    @printf("%-8s  %-20.12e  %-20.12e (rel err: % .3g)\n",
            string(T), Float64(iter), Float64(builtin), rel_err)
end

println("\nLiczba maszynowa eta - iteracyjnie vs nextFloat(Typ(0.0))")
println("-------------------------------------------------------------------------")
@printf("%-8s  %-20s  %-20s %-12s\n", "Typ", "iteracyjny", "nextFloat(Typ(0.0))", "blad wzgledny")
println("-------------------------------------------------------------------------")

for T in types
    iter = eta(T)
    builtin = nextfloat(T(0.0))
    rel_err = Float64(iter - builtin) / Float64(builtin)

    @printf("%-8s  %-20.12e  %-20.12e (rel err: % .3g)\n",
            string(T), Float64(iter), Float64(builtin), rel_err)
end

println("\nWartosci floatmin")
@printf("floatmin(Float32) = %-22.12e\n", floatmin(Float32))
@printf("floatmin(Float64) = %-22.12e\n", floatmin(Float64))

println("\nWartosci MAX - iteracyjnie vs floatmax(Typ)")
println("-------------------------------------------------------------------------")
@printf("%-8s  %-20s  %-20s %-12s\n", "Typ", "iteracyjny", "floatmax(Typ)", "blad wzgledny")
println("-------------------------------------------------------------------------")

for T in types
    iter = maxV(T)
    builtin = floatmax(T)
    rel_err = Float64(iter - builtin) / Float64(builtin)

    @printf("%-8s  %-20.12e  %-20.12e (rel err: % .3g)\n",
            string(T), Float64(iter), Float64(builtin), rel_err)
end