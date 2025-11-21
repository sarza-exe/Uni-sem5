# Sara Żyndul 279686
(@isdefined Roots) == false ? include("iterationRoots.jl") : nothing
using .Roots

function runTasks(f, pf)
    solutions = [
        mbisekcji(f, 0.5, 1.5, 1e-5, 1e-5),
        mbisekcji(f, 0.0, 3.0, 1e-5, 1e-5),
        mbisekcji(f, -1e5, 1e5, 1e-5, 1e-5),
        mstycznych(f, pf, 1.0, 1e-5, 1e-5, 255),
        mstycznych(f, pf, 1.5, 1e-5, 1e-5, 255),
        mstycznych(f, pf, 4.0, 1e-5, 1e-5, 255),
        mstycznych(f, pf, 8.0, 1e-5, 1e-5, 255),
        mstycznych(f, pf, 1e3, 1e-5, 1e-5, 255),
        msiecznych(f, 0.0, 0.5, 1e-5, 1e-5, 255),
        msiecznych(f, 0.5, 10000.0, 1e-5, 1e-5, 255),
        msiecznych(f, -100.0, -90.0, 1e-5, 1e-5, 255),
        msiecznych(f, 100.0, 1000.0, 1e-5, 1e-5, 255),
        msiecznych(f, 1000.0, 1005.0, 1e-5, 1e-5, 255)
        ]

    methods = ["bisekcji na [0.5, 1.5]", "bisekcji na [0.0, 3.0]", "bisekcji na [-1e5, 1e5]", 
               "Newtona dla x0=1", "Newtona dla x0=1.5", "Newtona dla x0=4", "Newtona dla x0=8", "Newtona dla x0=1000",
               "siecznych na [0.0, 0.5]", "siecznych na [0.5, 10000]", "siecznych na [-100, -90]", "siecznych na [100, 1000]", "siecznych na [1000, 1005]"]

    for i in 1:length(methods)
        println('_'^5,"Metoda ", methods[i], '_'^5)
        println("r = ", solutions[i][1])
        println("v = ", solutions[i][2])
        println("it = ", solutions[i][3])
        println("err = ", solutions[i][4])
    end
end

f = x -> exp(1)^(1-x)-1
pf = x -> -exp(1)^(1-x)

println("Iteracyjne znajdowanie pierwiastków dla f(x)=e^(1-x)-1\n")
runTasks(f,pf)

f2 = x -> x*exp(1)^(-x)
pf2 = x -> -exp(1)^(-x)*(x-1)

println("\n\nIteracyjne znajdowanie pierwiastków dla f(x)=xe^(-x)\n")
runTasks(f2,pf2)