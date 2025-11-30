# Sara Żyndul 279686
(@isdefined Roots) == false ? include("iterationRoots.jl") : nothing
using .Roots
    
f = x -> 3*x-exp(1)^x

solution = mbisekcji(f, 0.5, 1.0, 1e-4, 1e-4)

println("Pierwsze miejsce zerowe:")
println("x1 = ", solution[1])
println("v = ", solution[2])
println("it = ", solution[3])
println("err = ", solution[4])

solution = mbisekcji(f, 1.0, 2.0, 1e-4, 1e-4)

println("Drugie miejsce zerowe:")
println("x2 = ", solution[1])
println("v = ", solution[2])
println("it = ", solution[3])
println("err = ", solution[4])