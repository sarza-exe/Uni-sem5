#Sara Żyndul
using Printf

# funkcja f z zadania
function funF(x::Float64)
    return sqrt(x^2+1)-1
end

# bardziej dokladna funkcja g
function funG(x::Float64)
    return x^2/(sqrt(x^2+1)+1)
end

@printf("|  i|%-28s | %-28s|\n", "Funkcja f", "Funkcja g")
println("|  -|:----------------------------|:----------------------------|")
i = 1
while true
    f = funF(Float64(8)^(-i))
    g = funG(Float64(8)^(-i))
    @printf("|%3d |%-28.18e | %-28.18e|\n", i, f, g)
    global i += 1
    if g == 0
        break
    end
end