using CSV, DataFrames

df = CSV.read("graphB.csv", DataFrame)

dotfile = "mygraph.dot"
pngfile = "mygraph.png"

open(dotfile, "w") do io
    println(io, "digraph G {")
    println(io, "  rankdir=LR;") 
    println(io, "  node [shape=circle,fontsize=12];")
    println(io, "  edge [fontsize=10];")
    for r in eachrow(df)
        i = r.i
        j = r.j
        c = r.c
        t = r.t
        println(io, "  $(i) -> $(j) [label=\"c=$(c), t=$(t)\"];")
    end
    println(io, "}")
end

run(`dot -Tpng $(dotfile) -o $(pngfile)`)
println("Zapisano: $pngfile (w katalogu: $(pwd()))")
