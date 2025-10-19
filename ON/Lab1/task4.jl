# Sara Żyndul

# funkcja zwraca pierwszy x > 1 taki, że x*(1/x) != 1
function notOne()
    x = nextfloat(Float64(1.0))
    while x * (1.0/x) == 1
        x = nextfloat(x)
    end
    println("x = ", x)
    println("x*(1/x) = ", x * (1.0/x))
end
notOne()