# Sara Żyndul
# Model liniowy: maksymalizacja zysku
# Dane wejściowe (parametryczne) w plikach CSV:
#  - products.csv: product, price, matcost, demand, t_M1, t_M2, t_M3
#  - machines.csv: machine, cost_per_hour, hours_available
#
# using Pkg; Pkg.add(["CSV","DataFrames","JuMP","HiGHS"]) 

using CSV, DataFrames, JuMP, HiGHS
import MathOptInterface as MOI

# wczytanie danych
function read_data(products_file::String="products.csv", machines_file::String="machines.csv")
    prod_df = CSV.read(products_file, DataFrame)
    mach_df = CSV.read(machines_file, DataFrame)

    products = Vector(prod_df.product)
    machines = Vector(mach_df.machine)

    price = Dict(prod_df.product .=> prod_df.price)
    matcost = Dict(prod_df.product .=> prod_df.matcost)
    demand = Dict(prod_df.product .=> prod_df.demand)

    # times[(product, machine)] in minutes per kg
    times = Dict{Tuple{Any,Any},Float64}()
    for row in eachrow(prod_df)
        times[(row.product, "M1")] = float(row.t_M1)
        times[(row.product, "M2")] = float(row.t_M2)
        times[(row.product, "M3")] = float(row.t_M3)
    end

    cost_per_hour = Dict(mach_df.machine .=> mach_df.cost_per_hour)
    hours_available = Dict(mach_df.machine .=> mach_df.hours_available)

    return products, machines, price, matcost, demand, times, cost_per_hour, hours_available
end

# rozwiązanie problemu
function solve_production(products_file::String="products.csv", machines_file::String="machines.csv", tol::Float64=1e-6)
    products, machines, price, matcost, demand, times, cost_per_hour, hours_available = read_data(products_file, machines_file)

    for p in products
        for m in machines
            if !( (p,m) in keys(times) )
                error("Brak czasu obróbki dla produktu $p na maszynie $m")
            end
        end
    end

    model = Model(HiGHS.Optimizer)

    # zmienne produkcyjne: kg produktu i
    @variable(model, 0 <= q[p in products] <= demand[p])

    # ograniczenia na moce maszyn (czas w minutach)
    @constraint(model, [m in machines], sum(times[(p,m)] * q[p] for p in products) <= hours_available[m] * 60)

    # funkcja celu: maksymalizacja zysku
    # zysk = przychód - koszty materiałowe - koszty pracy maszyn
    revenue = sum(price[p] * q[p] for p in products)
    matcosts = sum(matcost[p] * q[p] for p in products)
    machine_costs = sum(cost_per_hour[m] * (sum(times[(p,m)] * q[p] for p in products) / 60) for m in machines)

    @objective(model, Max, revenue - matcosts - machine_costs)

    optimize!(model)

    status = termination_status(model)
    if status != MOI.OPTIMAL
        println("Uwaga: solver nie zwrócił OPTIMAL (status = ", status, ")")
    end

    obj = objective_value(model)

    # Wypisz plan produkcji (tylko > tol)
    plan = DataFrame(product=String[], qty=Float64[])
    used_machine = Dict(m => 0.0 for m in machines)
    for p in products
        val = value(q[p])
        push!(plan, (string(p), val))
        for m in machines
            used_machine[m] += times[(p,m)] * val
        end
    end

    println("\n=== Wynik optymalizacji ===")
    println("Maksymalny tygodniowy zysk: \$", round(obj, digits=6))
    println("\nPlan produkcji (kg):")
    show(plan, allcols=true)
    println()

    println("\nWykorzystanie maszyn (czas w godzinach):")
    for m in machines
        hours = used_machine[m] / 60
        println(" ", m, ": ", round(hours, digits=6), " z ", hours_available[m], " h (", round(100*hours / hours_available[m], digits=2), "%)")
    end

    println("\nCzy popyt dla produktów jest wyczerpany?")
    for p in products
        exhausted = abs(value(q[p]) - demand[p]) <= tol
        println(" ", p, ": produkcja = ", value(q[p]), ", limit popytu = ", demand[p], " -> ", exhausted ? "WYCZERPANY" : "NIE WYCZERPANY")
    end

    return Dict(:objective => obj, :plan => plan, :used_machine => used_machine, :status => status)
end

if abspath(PROGRAM_FILE) == @__FILE__
    println("Uruchamianie — wczytywanie products.csv i machines.csv z bieżącego katalogu")
    res = solve_production()
end