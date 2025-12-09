# Sara Żyndul 279686
(@isdefined Interpolacja) == false ? include("module.jl") : nothing
using .Interpolacja

fa = x -> abs(x)
fb = x -> 1.0/(1.0+x^2)
n = [5,10,15]

draw(fa, -1.0, 1.0, n,"6aRowno",:rownoodlegle)
draw(fb,-5.0,5.0,n,"6bRowno",:rownoodlegle)
draw(fa, -1.0, 1.0, n,"6aCzeby",:czebyszew)
draw(fb,-5.0,5.0,n,"6bCzebys",:czebyszew)

