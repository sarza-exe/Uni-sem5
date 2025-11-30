# Sara Żyndul 279686
module Roots
    export mbisekcji, mstycznych, msiecznych

    """
    Dane:
        f – funkcja f (x) zadana jako anonimowa funkcja,
        a, b – końce przedziału początkowego,
        delta, epsilon – dokładności obliczeń,
    Wyniki:
        (c, w, it, err) – czwórka, gdzie
        c – przybliżenie pierwiastka równania f(x) = 0,
        w – wartość f(r),
        it – liczba wykonanych iteracji,
        err – sygnalizacja błędu
            0 - brak błędu
            1 - funkcja nie zmienia znaku w przedziale [a,b]
    """
    function mbisekcji(f, a::Float64, b::Float64, delta::Float64, epsilon::Float64)
        u = Float64(f(a))
        v = Float64(f(b))
        if(sign(u) == sign(v)) 
            return (0,0,0,1)
        end
        e = b-a
        it = 1
        while true
            e = e/2
            c = a + e
            w = Float64(f(c))
            if( abs(e) < delta || abs(w) < epsilon)
                return (c, w, it, 0)
            end
            if(sign(w) != sign(u))
                b = c
                v = w
            else
                a = c
                u = w
            end
            it += 1
        end
    end


    """
    Dane:
        f, pf – funkcją f(x) oraz pochodną f'(x) zadane jako anonimowe funkcje,
        x0 – przybliżenie początkowe,
        delta,epsilon – dokładności obliczeń,
        maxit – maksymalna dopuszczalna liczba iteracji,
    Wyniki: (x,v,it,err) – czwórka, gdzie
        x – przybliżenie pierwiastka równania f(x) = 0,
        v – wartość f(x),
        it – liczba wykonanych iteracji,
        err – sygnalizacja błędu
            0 - metoda zbieżna
            1 - nie osiągnięto wymaganej dokładności w maxit iteracji,
            2 - pochodna bliska zeru
    """
    function mstycznych(f,pf,x0::Float64, delta::Float64, epsilon::Float64, maxit::Int)
        deriv_err = sqrt(eps(Float64)) # 1.5e-8
        v = Float64(f(x0))
        if(abs(v) < epsilon)
            return (x0,v,0,0)
        end
        for it in 1:maxit
            dv = Float64(pf(x0))
            if(abs(dv) < deriv_err) # wartość f'(x) za bliska zeru by uniknąć dużych błędów przy dzieleniu
                return (x0,v,it-1,2)
            end
            x1 = x0 - (v/dv)
            v = Float64(f(x1))
            if(abs(x1-x0) < delta || abs(v) < epsilon)
                return (x1,v,it,0)
            end
            x0 = x1
        end
        return (x0,Float64(f(x0)),maxit,1)
    end

    """
    Dane:
        f – funkcja f(x) zadana jako anonimowa funkcja,
        x0,x1 – przybliżenia początkowe,
        delta,epsilon – dokładności obliczeń,
        maxit – maksymalna dopuszczalna liczba iteracji,
    Wyniki: (x0,f0,it,err) – czwórka, gdzie
        x0 – przybliżenie pierwiastka równania f(x) = 0,
        f0 – wartość f(r),
        it – liczba wykonanych iteracji,
        err – sygnalizacja błędu
            0 - metoda zbieżna
            1 - nie osiągnięto wymaganej dokładności w maxit iteracji
    """
    function msiecznych(f, x0::Float64, x1::Float64, delta::Float64, epsilon::Float64, maxit::Int)
        f0 = Float64(f(x0))
        f1 = Float64(f(x1))
        for it in 1:maxit
            if(abs(f0) > abs(f1))
                x0, x1 = x1, x0
                f0, f1 = f1, f0
            end
            s = (x1-x0)/(f1-f0)
            x1 = x0
            f1 = f0
            x0 = x0 - f0*s
            f0 = Float64(f(x0))
            if( abs(f0) < epsilon || abs(x1-x0) < delta)
               return(x0, f0, it, 0)
            end
        end
        return (x0, f0, maxit, 1)
    end
end