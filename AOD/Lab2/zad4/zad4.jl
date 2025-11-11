# Sara Żyndul
# julia zad4.jl [graph.csv] [s] [t] [T]
#
# Oczekiwany format pliku CSV (nagłówki):
#   i,j,c,t
# Każdy wiersz to łuk skierowany: z -> do, koszt, czas.

using CSV, DataFrames, JuMP, HiGHS
import MathOptInterface as MOI

arcs_file = length(ARGS) >= 1 ? ARGS[1] : "graphA.csv"
s = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 1
t = length(ARGS) >= 3 ? parse(Int, ARGS[3]) : 10
T_lim = length(ARGS) >= 4 ? parse(Int, ARGS[4]) : 15

println("Wczytywanie: ", arcs_file)
println("Źródło s=", s, "  Cel t=", t, "  Limit czasu T=", T_lim)

df = CSV.read(arcs_file, DataFrame)
cols = Symbol.(names(df))

# Akceptujemy dwie konwencje nagłówków
if all(x->x in cols, [:i, :j, :c, :t])
    iter = ((Int(row.i), Int(row.j), float(row.c), float(row.t)) for row in eachrow(df))
elseif all(x->x in cols, [:from, :to, :cost, :time])
    iter = ((Int(row.from), Int(row.to), float(row.cost), float(row.time)) for row in eachrow(df))
else
    error("CSV musi mieć nagłówki: albo (i,j,c,t) albo (from,to,cost,time). Dostępne kolumny: ", join(string.(cols), ", "))
end

# Zbuduj listę łuków
arcs = Vector{Tuple{Int,Int,Float64,Float64}}()
for (ii, jj, cc, tt) in iter
    push!(arcs, (ii, jj, cc, tt))
end

if isempty(arcs)
    error("Brak łuków w pliku CSV: ", arcs_file)
end

# Zbiór wierzchołków = wszystkie występujące numery
nodes = sort(unique(vcat([a[1] for a in arcs]..., [a[2] for a in arcs]...)))
println("Wierzchołki: ", nodes)

# Sprawdź, czy s i t są w zbiorze
if !(s in nodes && t in nodes)
    error("Podane źródło/cel nie występują w grafie. s=", s, ", t=", t)
end

m = Model(HiGHS.Optimizer)
num_arcs = length(arcs)
ids = 1:num_arcs
from_node = Dict(k => arcs[k][1] for k in ids)
to_node   = Dict(k => arcs[k][2] for k in ids)
cost      = Dict(k => arcs[k][3] for k in ids)
time      = Dict(k => arcs[k][4] for k in ids)

# zmienne binarne wyboru łuku
@variable(m, y[ids], Bin)

# bilans przepływu: dla każdego wierzchołka v
for v in nodes
    out_idxs = [k for k in ids if from_node[k] == v]
    in_idxs  = [k for k in ids if to_node[k] == v]
    b = v == s ? 1 : (v == t ? -1 : 0)
    @constraint(m, sum(y[k] for k in out_idxs) - sum(y[k] for k in in_idxs) == b)
end

# ograniczenie czasu
@constraint(m, sum(time[k] * y[k] for k in ids) <= T_lim)

# cel: minimalizacja kosztu
@objective(m, Min, sum(cost[k] * y[k] for k in ids))

optimize!(m)
status = termination_status(m)
println("Status: ", status)

if status == MOI.OPTIMAL || status == MOI.FEASIBLE_POINT
    chosen = [k for k in ids if value(y[k]) > 0.5]
    total_cost = sum(cost[k] for k in chosen)
    total_time = sum(time[k] for k in chosen)
    println("Wybrane łuki (index, from->to, cost, time):")
    for k in chosen
        println(" ", k, ": ", from_node[k], " -> ", to_node[k], " c=", cost[k], " t=", time[k])
    end
    println("Minimalny koszt = ", total_cost)
    println("Całkowity czas = ", total_time)

    # Rekonstrukcja ścieżki (bez gwarancji unikalności w przypadku cykli)
    path = [s]
    local curr = s
    visited = Set([s])
    local safety = 0
    while curr != t && safety < 100
        next_k = 0
        for k in ids
            if from_node[k] == curr && value(y[k]) > 0.5
                next_k = k
                break
            end
        end
        if next_k == 0
            println("Nie można zrekonstruować ścieżki (brak następnego łuku z węzła ", curr, ")")
            break
        end
        curr = to_node[next_k]
        push!(path, curr)
        safety += 1
        if curr in visited
            println("Uwaga: wykryto cykl podczas rekonstrukcji ścieżki. Przerywam.")
            break
        end
        push!(visited, curr)
    end
        println("Ścieżka: ", join(path, " -> "))
else
    println("Model nie znalazł rozwiązania optymalnego. Status: ", status)
end
