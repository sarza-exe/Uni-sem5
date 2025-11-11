# Sara Żyndul
using CSV, DataFrames, JuMP, HiGHS
import MathOptInterface as MOI

# Wczytanie limitów dla komórek
df_min = CSV.read("min_limits.csv", DataFrame)
df_max = CSV.read("max_limits.csv", DataFrame)

# Wczytanie wymagań globalnych
df_global = CSV.read("global_reqs.csv", DataFrame)

# Ekstrakcja danych do macierzy i wektorów
districts = df_min.dzielnica
shifts = names(df_min)[2:end]

N = length(districts) # Liczba dzielnic (3)
M = length(shifts)   # Liczba zmian (3)

# Konwersja DataFrame'ów do macierzy (ignorując pierwszą kolumnę z nazwami)
min_limits = Matrix(df_min[:, 2:end])
max_limits = Matrix(df_max[:, 2:end])

# Ekstrakcja wymagań globalnych
min_shift_reqs = Vector(df_global[df_global.typ .== "zmiana", 2:end][1,:])
min_district_reqs = Vector(df_global[df_global.typ .== "dzielnica", 2:end][1,:])

# Budowa modelu jump

# Inicjalizacja modelu z optymalizatorem highs
model = Model(HiGHS.Optimizer)

# Definicja zmiennych: x[i, j] - liczba radiowozów dla dzielnicy i, zmiany j
@variable(model, x[i=1:N, j=1:M] >= 0, Int)

# Definicja celu: Minimalizacja sumy wszystkich przydziałów
@objective(model, Min, sum(x))

# Ograniczenie 1: Limity dla każdej komórki (dolne i górne)
@constraint(model, cell_lower[i=1:N, j=1:M], x[i, j] >= min_limits[i, j])
@constraint(model, cell_upper[i=1:N, j=1:M], x[i, j] <= max_limits[i, j])

# Ograniczenie 2: Minimalna liczba radiowozów dla każdej ZMIANY (sumy kolumn)
@constraint(model, shift_reqs[j=1:M], sum(x[i, j] for i in 1:N) >= min_shift_reqs[j])

# Ograniczenia 3: Minimalna liczba radiowozów dla każdej DZIELNICY (sumy wierszy)
@constraint(model, district_reqs[i=1:N], sum(x[i, j] for j in 1:M) >= min_district_reqs[i])

println("\nRozwiązywanie problemu optymalizacyjnego...")
optimize!(model)

if termination_status(model) == MOI.OPTIMAL
    println("\nZnaleziono rozwiązanie optymalne!")
    
    # Pobranie wyników
    total_cars = objective_value(model)
    assignments = value.(x)
    
    println("--------------------------------------------------")
    println("Optymalne rozwiązanie:")
    println("--------------------------------------------------")
    
    # Formatowanie wyników w postaci tabeli
    results_df = DataFrame(assignments, Symbol.(shifts))
    insertcols!(results_df, 1, :dzielnica => districts)
    
    println(results_df)
    
    println("\n--------------------------------------------------")
    println("Całkowita liczba wykorzystywanych radiowozów (suma przydziałów): $(Int(total_cars))")
    println("--------------------------------------------------")

else
    println("\nNie znaleziono optymalnego rozwiązania. Status: $(termination_status(model))")
end