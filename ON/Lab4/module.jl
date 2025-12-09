# Sara Żyndul 279686


module Interpolacja
    using Plots
    export ilorazyRoznicowe, warNewton, naturalna, rysujNnfx, draw

    """
    Dane:
        x – wektor długości n + 1 zawierający węzły x0, . . . , xn
            x[1]=x0,..., x[n+1]=xn
        f – wektor długości n + 1 zawierający wartości interpolowanej funkcji w węzłach f(x0), . . . , f(xn)
    Wyniki:
        fx – wektor długości n + 1 zawierający obliczone ilorazy różnicowe
        fx[1]=f[x0],
        fx[2]=f[x0, x1],..., fx[n]=f[x0, . . . , xn−1], fx[n+1]=f[x0, . . . , xn].
    """
    function ilorazyRoznicowe(x::Vector{Float64}, f::Vector{Float64})
        n = length(x)
        @assert length(f) == n "x i f mają być tej samej długości"
        fx = copy(f)
        # w kroku m liczymy ilorazy rzędu m
        for m in 1:(n-1) 
            # iterujemy od końca tak by nie korzystać z macierzy i
            # przy obliczaniu fx[i] mieć dostęp do fx[i] oraz fx[i-1]
            for i in n:-1:(m+1)
                mian = x[i]- x[i-m]
                if mian == 0.0
                    throw(ErrorException("duplikat węzłów x[$i] == x[$(i-m)]"))
                end
               fx[i] = (fx[i] - fx[i-1]) / (mian)
            end
        end
        return fx
    end

    """
    Dane:
        x – wektor długości n + 1 zawierający węzły x0, . . . , xn
            x[1]=x0,..., x[n+1]=xn
        fx – wektor długości n + 1 zawierający ilorazy różnicowe
            fx[1]=f[x0],
            fx[2]=f[x0, x1],..., fx[n]=f[x0, . . . , xn−1], fx[n+1]=f[x0, . . . , xn]
        t – punkt, w którym należy obliczyć wartość wielomianu
    Wyniki:
        w – wartość wielomianu w punkcie t.
    """
    function warNewton(x::Vector{Float64}, fx::Vector{Float64}, t::Float64)
        n = length(fx)
        @assert length(fx) == n "x i fx mają być tej samej długości"
        if n == 0
            return zero(Float64)
        end
        w = fx[n]
        for k in (n-1):-1:1
            w = w*(t-x[k]) + fx[k]
        end
        return w
    end

    """
    Dane:
        x – wektor długości n + 1 zawierający węzły x0, . . . , xn
            x[1]=x0,..., x[n+1]=xn
        fx – wektor długości n + 1 zawierający ilorazy różnicowe
            fx[1]=f[x0],
            fx[2]=f[x0, x1],..., fx[n]=f[x0, . . . , xn−1], fx[n+1]=f[x0, . . . , xn]
    Wyniki:
        a – wektor długości n + 1 zawierający obliczone współczynniki postaci naturalnej
            a[1]=a0,
            a[2]=a1,..., a[n]=an−1, a[n+1]=an.
    """
    function naturalna(x::Vector{Float64}, fx::Vector{Float64})
        @assert length(x) == length(fx) "x i fx muszą mieć tę samą długość"
        n = length(fx) - 1 
        a = zeros(Float64, n+1)

        a[1] = fx[end] # wielomianu stały c_n
        deg = 0 # bieżący stopień wielomianu

        for k in (n-1):-1:0
            xk = x[k+1]
            a[deg+2] = a[deg+1] # zwiększamy stopień wielomianu. ustawiamy najwyższy współczynnik na poprzedni najwyższy

            for j in (deg+1):-1:2
                a[j] = a[j-1] - xk * a[j]
            end
            a[1] = -xk * a[1]
            a[1] += fx[k+1] # dodajemy c_k do wyrazu wolnego
            deg += 1
        end
        return a
    end

    """
    Dane:
        f – funkcja f(x) zadana jako anonimowa funkcja,
        a,b – przedział interpolacji
        n – stopień wielomianu interpolacyjnego
        wezly – jeśli :rownoodlegle, to węzły równoodległe, jeśli :czebyszew, to węzły n+1 wielomianu
        Czebyszewa Tn+1
    Wyniki:
        funkcja rysuje wielomian interpolacyjny i interpolowaną
        funkcję w przedziale [a, b].
    """
    function rysujNnfx(fun, a::Float64, b::Float64, n::Int; wezly::Symbol = :rownoodlegle)
        @assert n >= 0 "n musi być >= 0"
        @assert a < b "a musi być < b"

        f = Vector{Float64}(undef, n+1)
        x = Vector{Float64}(undef, n+1)

        if wezly == :rownoodlegle
            h::Float64 = (b-a)/n
            for i in 1:(n+1)
                x[i] = a+(i-1)*h
            end
            println(x)
        elseif wezly == :czebyszew
            # węzły Czebyszewa w [-1,1] to cos((2k-1)/(2n+2)*pi), k=1..n+1. skalujemy je do [a,b]: t = (a+b)/2 + (b-a)/2 * t
            mid = (a+b)/2
            half = (b-a)/2
            for k in 1:(n+1)
                t = cos((2k-1)/(2*(n+1))*pi) # [-1,1]
                x[k] = mid + half*t
            end
            println(x)
        else
            throw(ErrorException("brak implementacji dla wezly=$wezly"))
        end

        for i in 1:(n+1)
            f[i] = fun(x[i])
        end

        fx = ilorazyRoznicowe(x, f)

        ts = range(a, stop=b, length=400)
        pvals = similar(ts)

        for (idx, t) in enumerate(ts)
            pvals[idx] = warNewton(x, fx, t)
        end

        fplot = [fun(t) for t in ts]

        plt = plot(ts, fplot, label="f(x)", lw=2, legend=:topright)
        plot!(plt, ts, pvals, label="wielomian N_n(x)", lw=2, linecolor=:red, linestyle=:dash)
        scatter!(plt, x, f, label="węzły", ms=4, markerstrokewidth=0.0)
        xlabel!("x")
        ylabel!("wartość")
        title!("Interpolacja Newtona (n=$(n), wezły=$(wezly))")
        
        return plt
    end

    """
    fun - funkcja anonimowa
    a,b - przedział interpolacji
    nArr - wektor stopni wielomianu interpolacyjnego
    name - nazwa funkcji
    wezly - sposób liczenia wezłów: :rownoodlegle albo :czebyszew
    """
    function draw(fun,a::Float64,b::Float64,nArr::Vector{Int},name::String,wezly::Symbol)
        for n in nArr
            file = "plots/plot"*name*"_n$n"
            plt = rysujNnfx(fun, a, b, n; wezly=wezly)
            savefig(plt, file*".png")
        end
    end
end