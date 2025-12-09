# Sara Żyndul 279686
using Test

(@isdefined Interpolacja) == false ? include("module.jl") : nothing
using .Interpolacja

@testset "Testy Modułu Interpolacja" begin

    @testset "1. Ilorazy Różnicowe (ilorazyRoznicowe)" begin
        # Funkcja stała f(x) = 5. Ilorazy rzędu >= 1 powinny wynosić 0.
        x1 = [1.0, 2.0, 3.0]
        f1 = [5.0, 5.0, 5.0]
        fx1 = ilorazyRoznicowe(x1, f1)
        @test fx1[1] == 5.0
        @test fx1[2] == 0.0
        @test fx1[3] == 0.0

        # Funkcja liniowa f(x) = 2x + 1. Ilorazy rzędu 1 powinny być stałe (2.0), rzędu >= 2 powinny wynosić 0.
        x2 = [-1.0, 0.0, 2.0]
        f2 = [ -1.0, 1.0, 5.0]
        fx2 = ilorazyRoznicowe(x2, f2)
        @test fx2[1] == -1.0
        @test fx2[2] ≈ 2.0 # \\approx
        @test abs(fx2[3]) < 1e-10

        # wielomian 2 stopnia
        # x = [0, 1, 2], f(x) = x^2 => [0, 1, 4]
        x3 = [0.0, 1.0, 2.0]
        f3 = [0.0, 1.0, 4.0]
        fx3 = ilorazyRoznicowe(x3, f3)
        @test fx3 ≈ [0.0, 1.0, 1.0]

        # Obsługa błędów (duplikaty węzłów)
        x_err = [1.0, 2.0, 1.0] # duplikat
        f_err = [1.0, 2.0, 3.0]
        @test_throws ErrorException ilorazyRoznicowe(x_err, f_err)
        
        # Różne długości wektorów
        @test_throws AssertionError ilorazyRoznicowe([1.0], [1.0, 2.0])
    end

    @testset "2. Wartość Wielomianu (warNewton)" begin
        x = [0.0, 1.0, 2.0]
        # fx obliczone wcześniej: [0.0, 1.0, 1.0]
        fx = [0.0, 1.0, 1.0]

        # W(xi) == f(xi)
        @test warNewton(x, fx, 0.0) ≈ 0.0
        @test warNewton(x, fx, 1.0) ≈ 1.0
        @test warNewton(x, fx, 2.0) ≈ 4.0

        # Sprawdzenie punktu spoza węzłów
        # Dla f(x)=x^2, W(3) powinno być 9.0
        @test warNewton(x, fx, 3.0) ≈ 9.0
        # Dla f(x)=x^2, W(0.5) powinno być 0.25
        @test warNewton(x, fx, 0.5) ≈ 0.25
        
        # Pusty wektor
        @test warNewton(Float64[], Float64[], 5.0) == 0.0
    end

    @testset "3. Postać Naturalna (naturalna)" begin
        # Pomocnicza funkcja do obliczania wartości wielomianu z postaci naturalnej
        # a = [a0, a1, ..., an] -> a0 + a1*x + ...
        function eval_poly(a, t)
            val = 0.0
            for i in length(a):-1:1
                val = val * t + a[i] # schemat Hornera dla postaci naturalnej (odwrócony względem a)
            end
            res = 0.0
            for (i, coeff) in enumerate(a)
                res += coeff * t^(i-1)
            end
            return res
        end

        # Test dla f(x) = x^2 + 2x + 3
        x = [-1.0, 0.0, 1.0]
        fx = [2.0, 1.0, 1.0]
        
        a = naturalna(x, fx)
        
        # współczynniki dla x^2 + 2x + 3 to [3.0, 2.0, 1.0]
        @test length(a) == 3
        @test a[1] ≈ 3.0
        @test a[2] ≈ 2.0
        @test a[3] ≈ 1.0
        
        # Sprawdzenie czy wielomian w postaci naturalnej daje te same wyniki co Newtona
        t_val = 2.5
        val_newton = warNewton(x, fx, t_val)
        val_natural = eval_poly(a, t_val)
        @test val_natural ≈ val_newton
    end

    @testset "4. Funkcje Rysujące (Smoke Tests)" begin
        # Te testy sprawdzają tylko, czy funkcje uruchamiają się bez błędu.
        fun(x) = x^3
        
        plt = rysujNnfx(fun, -2.0, 2.0, 3; wezly=:rownoodlegle)
        @test plt !== nothing
        
        plt_cheb = rysujNnfx(fun, -2.0, 2.0, 3; wezly=:czebyszew)
        @test plt_cheb !== nothing

        @test_throws ErrorException rysujNnfx(fun, -1.0, 1.0, 2; wezly=:nieznane)
        
        if !isdir("plots")
            mkdir("plots")
        end
        
        try
            draw(fun, -1.0, 1.0, [2, 3], "test_func", :rownoodlegle)
            @test isfile("plots/plottest_func_n2.png")
            @test isfile("plots/plottest_func_n3.png")
            rm("plots/plottest_func_n2.png", force=true)
            rm("plots/plottest_func_n3.png", force=true)
        catch e
            @warn "Test funkcji 'draw' nie powiódł się (możliwy brak backendu graficznego): $e"
        end
    end
end