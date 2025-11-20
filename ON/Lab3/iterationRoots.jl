# Sara Żyndul 279686
module Roots
    export mbisekcji, mstycznych, msiecznych

    """
    Dane:
        f – funkcja f (x) zadana jako anonimowa funkcja,
        a, b – końce przedziału początkowego,
        delta, epsilon – dokładności obliczeń,
    Wyniki:
        (r, v, it, err) – czwórka, gdzie
        r – przybliżenie pierwiastka równania f(x) = 0,
        v – wartość f(r),
        it – liczba wykonanych iteracji,
        err – sygnalizacja błędu
            0 - brak błędu
            1 - funkcja nie zmienia znaku w przedziale [a,b]
    """
    function mbisekcji(f, a::Float64, b::Float64, delta::Float64, epsilon::Float64)
        maxit = 1024
        u = Float64(f(a))
        v = Float64(f(b))
        if(u == 0.0)
            return (a, u, 0, 0)
        elseif(v == 0.0)
            return (b, v, 0, 0)
        end
        if(sign(u) == sign(v)) 
            return (0,0,0,1)
        end
        e = b-a
        for k in 1:maxit
            e = e/2
            c = a + e
            w = Float64(f(c))
            if( abs(e) < delta || abs(w) < epsilon)
                return (c, w, k, 0)
            end
            if(sign(w) != sign(u))
                b = c
                v = w
            else
                a = c
                u = w
            end
        end
        return(c, w, k, 1)
    end


    """
    Dane:
        f, pf – funkcją f(x) oraz pochodną f'(x) zadane jako anonimowe funkcje,
        x0 – przybliżenie początkowe,
        delta,epsilon – dokładności obliczeń,
        maxit – maksymalna dopuszczalna liczba iteracji,
    Wyniki: (r,v,it,err) – czwórka, gdzie
        r – przybliżenie pierwiastka równania f(x) = 0,
        v – wartość f(r),
        it – liczba wykonanych iteracji,
        err – sygnalizacja błędu
            0 - metoda zbieżna
            1 - nie osiągnięto wymaganej dokładności w maxit iteracji,
            2 - pochodna bliska zeru
    """
    function mstycznych(f,pf,x0::Float64, delta::Float64, epsilon::Float64, maxit::Int)
        deriv_err = sqrt(eps(Float64)) # 1.5e-8
        for i in 1:maxit
            f0 = Float64(f(x0))
            if(abs(f0) < epsilon)
                return (x0,f0,i-1,0)
            end
            f1 = Float64(pf(x0))
            if(abs(f1) < deriv_err) # wartość f'(x) za bliska zeru by uniknąć dużych błędów przy dzieleniu
                return (x0,f0,i-1,2)
            end
            x1 = x0
            x0 = x0 - (f0/f1)
            if(abs(x1-x0) < delta)
                return (x0,Float64(f(x0)),i,0)
            end
        end
        return (x0,Float64(f(x0)),maxit,1)
    end

    """
    Dane:
        f – funkcja f(x) zadana jako anonimowa funkcja,
        x0,x1 – przybliżenia początkowe,
        delta,epsilon – dokładności obliczeń,
        maxit – maksymalna dopuszczalna liczba iteracji,
    Wyniki: (r,v,it,err) – czwórka, gdzie
        r – przybliżenie pierwiastka równania f(x) = 0,
        v – wartość f(r),
        it – liczba wykonanych iteracji,
        err – sygnalizacja błędu
            0 - metoda zbieżna
            1 - nie osiągnięto wymaganej dokładności w maxit iteracji
    """
    function msiecznych(f, x0::Float64, x1::Float64, delta::Float64, epsilon::Float64, maxit::Int)
        f0 = Float64(f(x0))
        f1 = Float64(f(x1))
        for i in 1:maxit
            divisor = f0-f1
            if (abs(divisor) < eps(Float64))
                return (x1,Float64(f(x1)),i-1,2)
            end
            xn = (f0*x1 - f1*x0)/(f0 - f1)
            fn = Float64(f(xn))
            if( abs(fn) < epsilon || abs(xn-x1) < delta)
                return(xn, fn, i, 0)
            end
            x0 = x1
            f0 = f1
            x1 = xn
            f1 = fn
        end
        return (xn, fn, maxit, 1)
    end
end