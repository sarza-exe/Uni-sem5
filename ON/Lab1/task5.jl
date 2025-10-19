# Sara Żyndul
using Printf

# wektory z tresci zadania
x = Array{Float64}([2.718281828, -3.141592654, 1.414213562, 0.5772156649, 0.3010299957])
y = Array{Float64}([1486.2497, 878366.9879, -22.37492, 4773714.647, 0.000185049])

# prawidlowa wartosc iloczynu skalarnego
ref = -1.00657107000000e-11

# wektor z mnozenia odpowiadajacych sobie elementow z x i y w danym typie T
function terms_in_type(x64, y64, T::Type)
    xa = T.(x64)
    ya = T.(y64)
    return xa .* ya
end

# a - suma w przod
function sum_forward(terms::Array{T}) where T
    S = zero(T)
    for t in terms
        S = S + t
    end
    return S
end

# b - suma w tyl
function sum_backward(terms::Array{T}) where T
    S = zero(T)
    for t in reverse(terms)
        S = S + t
    end
    return S
end

# c - od najwiekszego do najmniejszego
function sum_method_c(terms::Array{T}) where T
    pos = [t for t in terms if t > zero(T)]
    neg = [t for t in terms if t < zero(T)]
    sort!(pos, rev=true) # sortowanie malejaco
    sort!(neg)
    Sp = zero(T)
    for v in pos
        Sp += v
    end
    Sn = zero(T)
    for v in neg
        Sn += v
    end
    return Sp + Sn
end

# d - od najmniejszego do najwiekszego
function sum_method_d(terms::Array{T}) where T
    pos = [t for t in terms if t > zero(T)]
    neg = [t for t in terms if t < zero(T)]
    sort!(pos) 
    sort!(neg, rev=true)
    Sp = zero(T)
    for v in pos
        Sp += v
    end
    Sn = zero(T)
    for v in neg
        Sn += v
    end
    return Sp + Sn
end

# wykonanie testow dla okreslonego typu
function test_type(T::Type)
    terms = terms_in_type(x, y, T)
    fwd = sum_forward(terms)
    bwd = sum_backward(terms)
    c   = sum_method_c(terms)
    d   = sum_method_d(terms)

    println("Type: ", T)
    @printf(" terms (T):\n")
    for (i,t) in enumerate(terms)
        @printf("  t[%d] = %.18e\n", i, Float64(t))
    end
    @printf(" Reference = %.17e\n", ref)
    @printf(" forward   = %.18e   abs_err=%.18e\n", Float64(fwd), Float64(fwd) - ref)
    @printf(" backward  = %.18e   abs_err=%.18e\n", Float64(bwd), Float64(bwd) - ref)
    @printf(" method_c  = %.18e   abs_err=%.18e\n", Float64(c),   Float64(c) - ref)
    @printf(" method_d  = %.18e   abs_err=%.18e\n\n", Float64(d), Float64(d) - ref)
end

test_type(Float32)
test_type(Float64)
