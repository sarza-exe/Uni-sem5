# Sara Żyndul
using Printf

# Funkcja do obliczania przyblizonej wartosci pochodnej funkcji fun w punkcie x
function approximateDer(fun::Function, x::Float64, h::Float64)
    return (fun(x+h)-fun(x))/h
end

# Funkcja f z zadania
f(x::Float64) = sin(x) + cos(3*x)
# Pochodna f
derF(x::Float64) = cos(x) - 3sin(3*x)

exVal = derF(1.0)
println(exVal)

@printf("| n|%-28s | %-28s| %-28s|\n", "Przybliżenie pochodnej f", "Błąd bezwzględny", "Wartość (h+1)")
println("| -|:----------------------------|:----------------------------|:----------------------------|")
for n in 0:54
    h = 2.0^(-n)
    appF = approximateDer(f, 1.0, h)
    absErr = abs(exVal - appF)
    @printf("|%2d|%-28.16e | %-28.16e| %-28.16e|\n", n, appF, absErr, 1.0+h)
end
