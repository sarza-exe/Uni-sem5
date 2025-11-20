# Sara Żyndul 279686
(@isdefined Roots) == false ? include("iterationRoots.jl") : nothing
using .Roots

f = x -> exp(1)^(1-x)-1
pf = x -> -exp(1)^(1-x)

solutions = [
    mbisekcji(f, 0.5, 1.5, 1e-5, 1e-5),
    mstycznych(f, pf, 1.5, 1e-5, 1e-5, 64),
    msiecznych(f, 0.5, 1.5, 1e-5, 1e-5, 64)]

methods = ["bisekcji", "Newtona", "siecznych"]

for i in 1:3
    println('_'^5,"Metoda ", methods[i], '_'^5)
    println("r = ", solutions[i][1])
    println("v = ", solutions[i][2])
    println("it = ", solutions[i][3])
    println("err = ", solutions[i][4])
end