# Sara Żyndul 279686
(@isdefined Interpolacja) == false ? include("module.jl") : nothing
using .Interpolacja

fa = x -> exp(1)^x
fb = x -> x^2*sin(x)
draw(fa, 0.0, 1.0, [5,10,15],"5a",:rownoodlegle)
draw(fb,-1.0,1.0,[5,10,15],"5b",:rownoodlegle)