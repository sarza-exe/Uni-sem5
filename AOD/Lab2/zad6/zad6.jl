# Sara Żyndul
using CSV
using DataFrames
using JuMP
using HiGHS
import MathOptInterface as MOI


# Główna funkcja rozwiązująca problem dla danego k.
function solve_camera_problem(k::Int)
    println("\n" * "="^40)
    println("Rozwiązywanie problemu dla k = $k")
    println("="^40)

    # Wczytanie i przygotowanie danych
    if !isfile("grid_layout.csv")
        println("Błąd: Plik grid_layout.csv nie istnieje. Uruchamiam create_csv_data().")
        create_csv_data()
    end
    
    df = CSV.read("grid_layout.csv", DataFrame)
    grid = Matrix(df)
    m, n = size(grid)

    # Identyfikacja kontenerów (C) i pustych miejsc (E)
    containers = Tuple{Int, Int}[]
    empty_squares = Tuple{Int, Int}[]
    
    for i in 1:m, j in 1:n
        if grid[i, j] == 1
            push!(containers, (i, j))
        else
            push!(empty_squares, (i, j))
        end
    end

    if isempty(containers)
        println("Brak kontenerów do monitorowania. Liczba kamer: 0.")
        return
    end

    # Mapowanie pokrycia
    # Tworzymy mapę: Kontener -> Lista kamer, które go widzą
    # coverage_map[ (ci, cj) ] = [ (ei, ej), ... ]
    
    coverage_map = Dict{Tuple{Int, Int}, Vector{Tuple{Int, Int}}}()

    for (ci, cj) in containers
        coverage_map[(ci, cj)] = []
        for (ei, ej) in empty_squares
            
            # Sprawdzenie zasięgu kamery (ei, ej) na kontener (ci, cj)

            # Pokrycie w pionie: ta sama kolumna ORAZ różnica wierszy <= k
            is_vertical_cover = (ej == cj) && (abs(ei - ci) <= k)
            
            # Pokrycie w poziomie: ten sam wiersz ORAZ różnica kolumn <= k
            is_horizontal_cover = (ei == ci) && (abs(ej - cj) <= k)
            
            if is_vertical_cover || is_horizontal_cover
                push!(coverage_map[(ci, cj)], (ei, ej))
            end
        end
    end

    # Sprawdzenie, czy wszystkie kontenery da się pokryć
    for (container, cameras) in coverage_map
        if isempty(cameras)
            println("BŁĄD: Kontener w $container nie może być monitorowany przez żadną kamerę przy k=$k.")
            println("Problem nierozwiązywalny dla tego k.")
            return
        end
    end

    # model jump
    model = Model(HiGHS.Optimizer)
    
    # Zmienne: y[i, j] = 1 jeśli kamera jest w pustym miejscu (i, j)
    # Używamy słownika, bo zmienne definiujemy tylko dla pustych pól
    @variable(model, y[empty_squares], Bin) # Zmienna binarna (0 lub 1)

    # Cel: Minimalizacja liczby kamer
    @objective(model, Min, sum(y))

    # Ograniczenia (Problem Pokrycia Zbioru)
    # Każdy kontener (ci, cj) musi być "widziany" przez co najmniej jedną kamerę
    for (ci, cj) in containers
        # Zbiór kamer (pustych pól), które widzą ten kontener
        possible_cameras = coverage_map[(ci, cj)]
        
        # Suma kamer widzących ten kontener musi być >= 1
        @constraint(model, sum(y[cam_pos] for cam_pos in possible_cameras) >= 1)
    end

    optimize!(model)

    if termination_status(model) == MOI.OPTIMAL
        println("Znaleziono rozwiązanie optymalne.")
        
        num_cameras = Int(objective_value(model))
        println("Minimalna liczba kamer: $num_cameras")
        
        println("\nOptymalne rozmieszczenie kamer (Współrzędne [wiersz, kolumna]):")
        camera_locations = []
        for (ei, ej) in empty_squares
            if value(y[(ei, ej)]) > 0.5 # Bezpieczniej niż == 1
                push!(camera_locations, (ei, ej))
                println("- $([ei, ej])")
            end
        end
        
        # Wizualizacja siatki
        println("\nWizualizacja siatki (K = Kamera, C = Kontener):")
        grid_viz = fill(" . ", m, n) # Puste miejsce
        for (i, j) in containers
            grid_viz[i, j] = " C " # Kontener
        end
        for (i, j) in camera_locations
            grid_viz[i, j] = " K " # Kamera
        end
        
        for i in 1:m
            println(join(grid_viz[i, :]))
        end
        
    else
        println("Nie znaleziono optymalnego rozwiązania. Status: $(termination_status(model))")
    end
end


# Rozwiąż problem dla k=1
solve_camera_problem(1)

# Rozwiąż problem dla k=2
solve_camera_problem(2)