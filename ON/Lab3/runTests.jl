#Sara Żyndul 279686
using Test

(@isdefined Roots) == false ? include("iterationRoots.jl") : nothing
using .Roots

# funkcje testowe
f1  = x -> x^2 - 2.0
pf1 = x -> 2.0*x

f2 = x -> sin(x^2-x+0.333)+x/2
pf2 = x -> cos(x^2-x+0.333)*(2*x-1)+0.5

f_id = x -> x
f_no_sign = x -> x^2 + 1.0
f_const = x -> 2
pf_const = x -> 0
f_no_root = x -> x^2+2

# tolerancje testowe
delta = 1e-12
epsilon = 1e-12
maxit = 100

@testset "mbisekcji (bisekcji)" begin
    # brak zmiany znaku
    r,v,it,err = mbisekcji(f_no_sign, -1.0, 1.0, delta, epsilon)
    @test err == 1

    # pierwiastek na lewym końcu [a,b]
    r,v,it,err = mbisekcji(f_id, 0.0, 1.0, delta, epsilon)
    @test err == 0
    @test isapprox(r, 0; atol=1e-12)
    @test typeof(r) == Float64
    @test typeof(v) == Float64

    # zbieżność do sqrt(2)
    r,v,it,err = mbisekcji(f1, 0.0, 2.0, 1e-10, 1e-10)
    @test err == 0
    @test isapprox(r, sqrt(2.0); atol=1e-10)
    @test typeof(r) == Float64

    r,v,it,err = mbisekcji(f2, -2.0, 0.0, 1e-5, 1e-5)
    @test err == 0
    @test isapprox(r, -1.0778; atol=1e-5)
    @test typeof(r) == Float64
end

@testset "mstycznych (Newtona)" begin
    # poprawna zbieżność
    r,v,it,err = mstycznych(f1, pf1, 1.0, delta, epsilon, maxit)
    @test err == 0
    @test isapprox(r, sqrt(2.0); atol=1e-12)
    @test typeof(r) == Float64
    @test typeof(v) == Float64

    r,v,it,err = mstycznych(f2, pf2, -2.0, 1e-5, 1e-5, 64)
    @test err == 0
    @test isapprox(r, -1.0778; atol=1e-5)
    @test typeof(r) == Float64

    # pochodna bliska zera
    r,v,it,err = mstycznych(f_const, pf_const, 0.0, delta, epsilon, maxit)
    @test err == 2

    # nieosiągnięcie dokładności w małej liczbie iteracji
    r,v,it,err = mstycznych(f1, pf1, 1.0, 1e-16, 1e-16, 1)
    @test err == 1
end

@testset "msiecznych (siecznych)" begin
    # nie znajduje miejsca zerowego (bo go nie ma)
    r,v,it,err = msiecznych(f_no_root, 0.0, 1.0, delta, epsilon, maxit)
    @test err == 1

    # zbieżność do sqrt(2)
    r,v,it,err = msiecznych(f1, 0.0, 2.0, 1e-12, 1e-12, maxit)
    @test err == 0
    @test isapprox(r, sqrt(2.0); atol=1e-12)
    @test typeof(r) == Float64
    @test typeof(v) == Float64

    r,v,it,err = msiecznych(f2, -2.0, 0.0, 1e-5, 1e-5, 64)
    @test err == 0
    @test isapprox(r, -1.0778; atol=1e-5)
    @test typeof(r) == Float64
end

println("Wszystkie testy wykonane.")
