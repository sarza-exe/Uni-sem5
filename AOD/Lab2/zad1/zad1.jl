# Sara Żyndul
# import Pkg
# Pkg.add(["CSV","DataFrames","JuMP","HiGHS", "MathOptInterface"])

using JuMP, HiGHS, CSV, DataFrames
import MathOptInterface as MOI

# Funkcja wczytujaca dane
function read_data(sup_file::String, dem_file::String, cost_file::String)
    sup_df = CSV.read(sup_file, DataFrame)
    dem_df = CSV.read(dem_file, DataFrame)
    cost_df = CSV.read(cost_file, DataFrame)

    # kolumny: supplier, capacity ; airport, demand ; supplier, airport, cost
    suppliers = Vector(sup_df.supplier)
    airports = Vector(dem_df.airport)

    supply = Dict(sup_df.supplier .=> sup_df.capacity)
    demand = Dict(dem_df.airport .=> dem_df.demand)

    # costs jako dictionary (supplier,airport) => cost
    costs = Dict{Tuple{Any,Any},Float64}()
    for row in eachrow(cost_df)
        costs[(row.supplier, row.airport)] = float(row.cost)
    end

    return suppliers, airports, supply, demand, costs
end


# Model JuMP
function solve_transport(sup_file::String="supplies.csv", dem_file::String="demands.csv", cost_file::String="costs.csv"; tol::Float64 = 1e-6)

    suppliers, airports, supply, demand, costs = read_data(sup_file, dem_file, cost_file)

    # sprawdzenie spojnosci danych
    total_supply = sum(values(supply))
    total_demand = sum(values(demand))
    if total_supply < total_demand
        error("Niewystarczające łączne zdolności dostaw (supply < demand). supply=$total_supply, demand=$total_demand")
    end

    model = Model(HiGHS.Optimizer)

    # zmienne: macierz ilosci paliwa od dostawcy s do lotniska a
    @variable(model, x[suppliers, airports] >= 0)

    # pokrycie popytu na kazdym lotnisku ([a in airports] generuje ograniczenie dla każdego lotniska z osobna)
    @constraint(model, [a in airports], sum(x[s,a] for s in suppliers) == demand[a])

    # ograniczenia pojemnosci dostawcow
    @constraint(model, [s in suppliers], sum(x[s,a] for a in airports) <= supply[s])

    # funkcja celu: minimalizacja kosztu
    @objective(model, Min, sum(costs[(s,a)] * x[s,a] for s in suppliers for a in airports))

    optimize!(model) #uruchomienie solvera

    status = termination_status(model)
    if status != MOI.OPTIMAL
        println("Uwaga: solver nie zakończył się statusem OPTIMAL: ", status)
    end

    obj = objective_value(model) # minimalny koszt

    # budujemy tabele dostaw
    shipments = DataFrame(supplier=String[], airport=String[], qty=Float64[])
    used_amount = Dict(s => 0.0 for s in suppliers)
    for s in suppliers, a in airports
        q = value(x[s,a])
        if q > tol
            push!(shipments, (string(s), string(a), q))
        end
        used_amount[s] += q
    end

    # minimalny koszt
    println("\n--- Wynik optymalizacji ---")
    println("Minimalny łączny koszt: \$", round(obj, digits=6))

    # wypisz plan dostaw
    println("\nPlan dostaw (tylko > $(tol)):")
    show(shipments, allcols=true)
    println()

    # Czy wszystkie firmy dostarczają?
    all_deliver = all(used_amount[s] > tol for s in suppliers)
    println("\nCzy wszystkie firmy dostarczają paliwo? ", all_deliver ? "Tak" : "Nie")

    # (c) Czy mozliwosci dostaw sa wyczerpane?
    println("\nCzy możliwości dostaw firm są wyczerpane (pojedynczo):")
    for s in suppliers
        exhausted = abs(used_amount[s] - supply[s]) <= tol
        println(" ", s, ": dostarczono = ", used_amount[s], ", pojemność = ", supply[s], " -> ", exhausted ? "WYCZERPANA" : "NIE WYCZERPANA")
    end

    return Dict(
        :objective => obj,
        :shipments => shipments,
        :used_amount => used_amount,
        :supply => supply,
        :demand => demand,
        :status => status
    )
end


if abspath(PROGRAM_FILE) == @__FILE__
    println("Uruchamianie modelu — wczytywanie supplies.csv, demands.csv, costs.csv z bieżącego katalogu")
    res = solve_transport()
end

