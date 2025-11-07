# Sara Żyndul
using Printf

# deklaracja zmiennych
pprev32 = Float32(0.01)
pprev32_cut = Float32(0.01)
pprev64 = Float64(0.01)
r = Float32(3)
r_64 = Float64(3)

# funkcja zwracająca pn+1 := pn + rpn(1 − pn)
function popFun(p::T, r::T) where T
    return p + r*p*(one(T)-p)
end

# iteracyjne wykonanie eksperymentów
println("| i | Float32 | Float32 z obcięciem | Float64|")
for i in 1:40
    p32 = popFun(pprev32, r)
    global pprev32 = p32
    p32_cut = popFun(pprev32_cut, r)
    if i == 10
        # nie da sie zapisac 0.722 dokladnie w float32 (najblizsza wartosc to 7.220000028610e-01)
        p32_cut = floor(p32_cut * Float32(1000)) / Float32(1000)
    end
    global pprev32_cut = p32_cut
    p64 = popFun(pprev64, r_64)
    global pprev64 = p64
    @printf("| %2d | %-16.12e | %-16.12e | %-16.12e |\n", i, p32, p32_cut, p64)
end