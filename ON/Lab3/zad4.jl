# Sara Żyndul 279686
(@isdefined Roots) == false ? include("iterationRoots.jl") : nothing
using .Roots

f = x -> sin(x)-(0.5*x)^2
pf = x -> cos(x)-0.5*x

solutions = [
    mbisekcji(f, 1.5, 2.0, 0.5e-5, 0.5e-5),
    mstycznych(f, pf, 1.5, 0.5e-5, 0.5e-5, 32),
    msiecznych(f, 1.0, 2.0, 0.5e-5, 0.5e-5, 32)]

methods = ["bisekcji", "Newtona", "siecznych"]

for i in 1:3
    println('_'^5,"Metoda ", methods[i], '_'^5)
    println("r = ", solutions[i][1])
    println("v = ", solutions[i][2])
    println("it = ", solutions[i][3])
    println("err = ", solutions[i][4])
end