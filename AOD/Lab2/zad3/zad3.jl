# Sara Żyndul
# Dane wejściowe (CSV):
#  - periods.csv: period,c,o_a,o_cost,demand
#      (dla okresu j: koszt normalnej produkcji cj, maks dodatkowej produkcji aj, koszt jednostkowy oj, popyt dj)
#  - params.csv: normal_capacity, init_inventory, storage_capacity, storage_cost
#
# using Pkg; Pkg.add(["CSV","DataFrames","JuMP","HiGHS"]) 

using CSV, DataFrames, JuMP, HiGHS
import MathOptInterface as MOI

# Wczytanie danych
function read_data(periods_file::String="periods.csv", params_file::String="params.csv")
    per_df = CSV.read(periods_file, DataFrame)
    prm_df = CSV.read(params_file, DataFrame)

    # oczekujemy kolumn: period, c, a, o, d
    periods = Vector(per_df.period)
    c = Dict(per_df.period .=> per_df.c)
    a = Dict(per_df.period .=> per_df.a)
    o_cost = Dict(per_df.period .=> per_df.o)
    d = Dict(per_df.period .=> per_df.demand)

    # params.csv: zakładamy pojedynczy wiersz z nagłówkami
    normal_capacity = prm_df.normal_capacity[1]
    init_inventory = prm_df.init_inventory[1]
    storage_capacity = prm_df.storage_capacity[1]
    storage_cost = prm_df.storage_cost[1]

    return periods, c, a, o_cost, d, normal_capacity, init_inventory, storage_capacity, storage_cost
end

# rozwiązanie
function solve_periods(periods_file::String="periods.csv", params_file::String="params.csv"; tol::Float64=1e-6)
    periods, c, a, o_cost, d, normal_capacity, init_inventory, storage_capacity, storage_cost =
        read_data(periods_file, params_file)

    K = length(periods)
    if any(!(p in keys(c) && p in keys(a) && p in keys(o_cost) && p in keys(d)) for p in periods)
        error("Brakujące dane dla niektórych okresów w pliku periods.csv")
    end

    model = Model(HiGHS.Optimizer)

    # zmienne:
    # p[j] - produkcja normalna w okresie j (<= normal_capacity)
    # o[j] - produkcja ponadwymiarowa (overtime) w okresie j (<= a[j])
    # s[j] - zapas na koniec okresu j (0 <= s[j] <= storage_capacity)
    @variable(model, 0 <= p[p in periods] <= normal_capacity)
    @variable(model, 0 <= o[p in periods] <= a[p])
    @variable(model, 0 <= s[p in periods] <= storage_capacity)

    # bilans towaru: s[j-1] + p[j] + o[j] - d[j] = s[j]
    # dla j = pierwszego okresu s_prev = init_inventory
    for (idx, j) in enumerate(periods)
        if idx == 1
            @constraint(model, init_inventory + p[j] + o[j] - d[j] == s[j])
        else
            jp = periods[idx-1]
            @constraint(model, s[jp] + p[j] + o[j] - d[j] == s[j])
        end
    end

    # funkcja celu: minimalizacja kosztów = suma cj*pj + oj*oj_prod + storage_cost * s[j]
    @objective(model, Min, sum(c[j]*p[j] + o_cost[j]*o[j] + storage_cost*s[j] for j in periods))

    optimize!(model)

    status = termination_status(model)
    if status != MOI.OPTIMAL
        println("Uwaga: solver nie zakończył się statusem OPTIMAL: ", status)
    end

    obj = objective_value(model)

    plan = DataFrame(period=Int[], normal=Float64[], overtime=Float64[], inventory=Float64[])
    for j in periods
        push!(plan, (Int(j), value(p[j]), value(o[j]), value(s[j])))
    end

    println("\n=== Wynik optymalizacji ===")
    println("Minimalny łączny koszt produkcji i magazynowania: \$", round(obj, digits=6))
    println("\nPlan (per okres):")
    show(plan, allcols=true)
    println()

    println("\n(a) Minimalny łączny koszt: \$", round(obj, digits=6))

    # w których okresach produkcja ponadwymiarowa > 0
    println("\n(b) Okresy z produkcją ponadwymiarową (> 0):")
    for j in periods
        if value(o[j]) > tol
            println("  okres ", j, ": overtime = ", value(o[j]))
        end
    end

    # w których okresach magazynowanie jest wyczerpane (s[j] == storage_capacity)
    println("\n(c) Okresy, w których magazynowanie jest wyczerpane:")
    for j in periods
        exhausted = abs(value(s[j]) - storage_capacity) <= tol
        println("  okres ", j, ": zapas = ", value(s[j]), ", pojemność = ", storage_capacity, " -> ", exhausted ? "WYCZERPANE" : "NIE WYCZERPANE")
    end

    return Dict(:objective => obj, :plan => plan, :status => status)
end

if abspath(PROGRAM_FILE) == @__FILE__
    println("Uruchamianie — wczytywanie periods.csv i params.csv z bieżącego katalogu")
    res = solve_periods()
end