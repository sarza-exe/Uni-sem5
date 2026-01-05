# Sara Żyndul 279686
module blocksys
    using LinearAlgebra
    using Printf
    using BenchmarkTools
    include("helpers.jl")

    export benchmark, solve_and_save, testt

    function testt(inA::String; inB::String = "none")
        A = read_A_Matrix(inA)
        b, x_is_ones = get_b_vector(inB, A)

        println(solve_lu_decomposition!(A,b))
    end

    """
    Funkcja przyjmuje plik z macierzą A. Ewentualnie przyjmuje też plik z wektorem b, w przeciwnym wypadku
    oblicza b na podstawie równania b = Ax, gdzie x to wektor jedynek.
    Następnie dla podanych w tabeli algs algorytmów wykonuje benchmarkowanie, w którym liczy czasy i błędy względne.
    """
    function benchmark(inA::String; inB::String = "none")
        A = read_A_Matrix(inA)
        b, x_is_ones = get_b_vector(inB, A)

        algs = [
            ("Gauss (bez pivotu)", gauss_elimination!),
            ("Gauss z częściowym pivotowaniem", gauss_elimination_partial_pivot!),
            ("Rozkład LU (bez pivotu)", solve_lu_decomposition!),
            ("Rozkład LU z częściowym pivotowaniem", solve_lu_decomposition_partial_pivot!),            
        ]

        results = run_algorithms(A, b, algs, x_is_ones)
        print_results(results)
        return results
    end

    """
    Funkcja przyjmuje plik z macierzą A. Ewentualnie przyjmuje też plik z wektorem b, w przeciwnym przypadku
    oblicza b na podstawie b = Ax, gdzie x to wektor jedynek.
    Następnie dla podanych w tabeli algs algorytmów wywołuje je, a obliczone wektory x trafiają do plików tekstowych.
    Dla inB = "none" dodatkowo na górze pliku wypisuje błąd względny
    """
    function solve_and_save(inA::String; inB::String = "none")
        A = read_A_Matrix(inA)
        b, x_is_ones = get_b_vector(inB, A)

        algs = [
            ("_gauss", gauss_elimination!),
            ("_gauss_pp", gauss_elimination_partial_pivot!),
            ("_lu", solve_lu_decomposition!),
            ("_lu_pp", solve_lu_decomposition_partial_pivot!),
        ]
 
        for (name, func) in algs
            filename = string(splitext(inA)[1], "_", splitext(inB)[1], name, ".txt")
            open(filename, "w") do f
                A_work = deepcopy(A)
                b_work = copy(b)

                try
                    x_res = func(A_work, b_work)

                    if length(x_res) != A.n
                        error("Rozmiar wyniku = $(length(x_res)) != n = $n")
                    elseif x_is_ones
                        x_true = ones(Float64, A.n)
                        rel = norm(x_res - x_true) / norm(x_true)
                        println(f, rel)
                    end

                    for x in x_res
                        println(f, x)
                    end
                catch e
                    println(f, e)
                end
            end
        end
    end

    function solve_lu_decomposition_partial_pivot!(A::BlockMatrix, b::Vector{Float64})
        p = lu_decomposition!(A; partial_pivoting = true)
        return solve_lu(A, p, b)
    end

    function solve_lu_decomposition!(A::BlockMatrix, b::Vector{Float64})
        p = lu_decomposition!(A; partial_pivoting = false)
        return solve_lu(A, p, b)
    end
    
    # znalezienie rozkładu LU macierzy A
    function lu_decomposition!(A::BlockMatrix; partial_pivoting::Bool = false)
        n = A.n
        l = A.l
        nb = div(n, l)
        
        # Wektor permutacji, na początku (1, 2, ..., n)
        p = collect(1:n)

        # Przetworzenie macierzy na macierz trójkątną górną
        for k in 1:nb
            offset_k = (k-1)*l # Przesunięcie indeksów globalnych dla wektora b w bieżącym bloku

            # Eliminacja wewnątrz bloku A_k
            for i in 1:l 
                
                # Częściowy wybór elementu głównego
                if partial_pivoting
                    # Szukamy największej wartości w kolumnie i dla wierszy od i do l wewnątrz bloku
                    max_val = abs(A.A_blocks[i, i, k])
                    max_row = i
                    
                    for r in (i+1):l
                        val = abs(A.A_blocks[r, i, k])
                        if val > max_val
                            max_val = val
                            max_row = r
                        end
                    end

                    # Jeśli znaleziono lepszy pivot, zamieniamy wiersze
                    if max_row != i
                        # Aktualizacja wektora permutacji, Zamieniamy indeksy globalne
                        p_idx1 = offset_k + i
                        p_idx2 = offset_k + max_row
                        p[p_idx1], p[p_idx2] = p[p_idx2], p[p_idx1]

                        for c in 1:l # Zamiana wierszy w A_k
                            tmp = A.A_blocks[i, c, k]
                            A.A_blocks[i, c, k] = A.A_blocks[max_row, c, k]
                            A.A_blocks[max_row, c, k] = tmp
                        end
                        
                        if k < nb # Zamiana wierszy w C_k
                            for c in 1:l
                                tmp = A.C_blocks[i, c, k]
                                A.C_blocks[i, c, k] = A.C_blocks[max_row, c, k]
                                A.C_blocks[max_row, c, k] = tmp
                            end
                        end

                        # Zamiana wierszy w B_k (jeśli istnieje)
                        if k > 1
                            for c in 1:l
                                tmp = A.B_blocks[i, c, k]
                                A.B_blocks[i, c, k] = A.B_blocks[max_row, c, k]
                                A.B_blocks[max_row, c, k] = tmp
                            end
                        end
                    end
                end
                

                pivot = A.A_blocks[i, i, k]
                
                # Sprawdzenie czy możemy dzielić przez pivot
                if abs(pivot) < 1e-12
                    error("Macierz jest osobliwa (lub bliska zeru) w bloku $k, wiersz lokalny $i. Pivot: $pivot")
                end

                # Eliminacja pod przekątną w A_k
                for j in (i+1):l
                    factor = A.A_blocks[j, i, k] / pivot
                    A.A_blocks[j, i, k] = factor # Zapisujemy do L
                    
                    for c in (i+1):l # Aktualizacja wiersza w A_k
                        A.A_blocks[j, c, k] -= factor * A.A_blocks[i, c, k]
                    end
                    
                    if k < nb # Aktualizacja C_k
                        for c in 1:l
                            A.C_blocks[j, c, k] -= factor * A.C_blocks[i, c, k]
                        end
                    end
                end
            end
            
            # Eliminacja bloku B_{k+1} używając A_k
            if k < nb
                next_k = k + 1

                for j in 1:l # Wiersz w bloku B (i w bloku A_next)
                    for i in 1:l # Kolumna w bloku B (i wiersz w bloku A_curr)
                        elem = A.B_blocks[j, i, next_k]
                        
                        if abs(elem) > 1e-14
                            pivot = A.A_blocks[i, i, k]
                            factor = elem / pivot
                            
                            A.B_blocks[j, i, next_k] = factor # Zapisujemy L
                            
                            for c in (i+1):l # Aktualizacja reszty wiersza w B
                                A.B_blocks[j, c, next_k] -= factor * A.A_blocks[i, c, k]
                            end
                            
                            for c in 1:l # Aktualizacja A_{k+1} (wpływ C_k na A_{k+1})
                                A.A_blocks[j, c, next_k] -= factor * A.C_blocks[i, c, k]
                            end
                        end
                    end
                end
            end
        end
        
        return p
    end

    # Mając daną macierz A w rozkładzie LU znajduje rozwiązanie układu Ax=b
    function solve_lu(A::BlockMatrix, p::Vector{Int}, b::Vector{Float64})
        n = A.n
        l = A.l
        nb = div(n, l)
        
        # Permutacja wektora b Rozwiązujemy układ Ly = pb, więc na wejściu musimy przestawić b
        x = b[p] 

        # Podstawienie w przód (Ly = pb)
        for k in 1:nb
            offset_k = (k-1)*l

            # Wpływ B_k (podprzekątnej macierzy L)
            if k > 1
                offset_prev = (k-2)*l
                for j in 1:l
                    sum_val = 0.0
                    for c in 1:l
                        sum_val += A.B_blocks[j, c, k] * x[offset_prev + c]
                    end
                    x[offset_k + j] -= sum_val
                end
            end

            # Wpływ dolnego trójkąta A_k
            for i in 1:l
                sum_val = 0.0
                for j in 1:(i-1)
                    sum_val += A.A_blocks[i, j, k] * x[offset_k + j]
                end
                x[offset_k + i] -= sum_val
            end
        end

        # Podstawienie wstecz (Ux = y)
        for k in nb:-1:1
            offset_k = (k-1)*l

            # Wpływ C_k (nadprzekątnej macierzy U)
            if k < nb
                offset_next = k*l
                for j in 1:l
                    sum_val = 0.0
                    for c in 1:l
                        sum_val += A.C_blocks[j, c, k] * x[offset_next + c]
                    end
                    x[offset_k + j] -= sum_val
                end
            end

            # Wpływ górnego trójkąta A_k
            for i in l:-1:1
                sum_val = 0.0
                for j in (i+1):l
                    sum_val += A.A_blocks[i, j, k] * x[offset_k + j]
                end
                x[offset_k + i] = (x[offset_k + i] - sum_val) / A.A_blocks[i, i, k]
            end
        end

        return x
    end


    function gauss_elimination!(A::BlockMatrix, b::Vector{Float64}; partial_pivoting::Bool = false)
        n = A.n
        l = A.l
        nb = div(n, l)

        # Przetworzenie macierzy na macierz trójkątną górną
        for k in 1:nb
            offset_k = (k-1)*l # Przesunięcie indeksów globalnych dla wektora b w bieżącym bloku

            # Eliminacja wewnątrz bloku A_k
            for i in 1:l 
                
                # Częściowy wybór elementu głównego
                if partial_pivoting
                    # Szukamy największej wartości w kolumnie i dla wierszy od i do l wewnątrz bloku
                    max_val = abs(A.A_blocks[i, i, k])
                    max_row = i
                    
                    for r in (i+1):l
                        val = abs(A.A_blocks[r, i, k])
                        if val > max_val
                            max_val = val
                            max_row = r
                        end
                    end

                    # Jeśli znaleziono lepszy pivot, zamieniamy wiersze
                    if max_row != i
                        for c in 1:l # Zamiana wierszy w A_k
                            tmp = A.A_blocks[i, c, k]
                            A.A_blocks[i, c, k] = A.A_blocks[max_row, c, k]
                            A.A_blocks[max_row, c, k] = tmp
                        end
                        
                        if k < nb # Zamiana wierszy w C_k
                            for c in 1:l
                                tmp = A.C_blocks[i, c, k]
                                A.C_blocks[i, c, k] = A.C_blocks[max_row, c, k]
                                A.C_blocks[max_row, c, k] = tmp
                            end
                        end

                        # Zamiana w wektorze b
                        tmp_b = b[offset_k + i]
                        b[offset_k + i] = b[offset_k + max_row]
                        b[offset_k + max_row] = tmp_b
                    end
                end


                pivot = A.A_blocks[i, i, k]
                
                # Sprawdzenie czy możemy dzielić przez pivot
                if abs(pivot) < 1e-12
                    error("Macierz jest osobliwa (lub bliska zeru) w bloku $k, wiersz lokalny $i. Pivot: $pivot")
                end

                # Eliminacja pod przekątną w A_k
                for j in (i+1):l
                    factor = A.A_blocks[j, i, k] / pivot
                    A.A_blocks[j, i, k] = 0.0
                    
                    for c in (i+1):l # Aktualizacja wiersza w A_k
                        A.A_blocks[j, c, k] -= factor * A.A_blocks[i, c, k]
                    end
                    
                    if k < nb # Aktualizacja C_k
                        for c in 1:l
                            A.C_blocks[j, c, k] -= factor * A.C_blocks[i, c, k]
                        end
                    end
                    
                    # Aktualizacja b
                    b[offset_k + j] -= factor * b[offset_k + i]
                end
            end
            
            # Eliminacja bloku B_{k+1} używając A_k
            if k < nb
                next_k = k + 1
                offset_next = k*l
                
                for j in 1:l # Wiersz w bloku B (i w bloku A_next)
                    for i in 1:l # Kolumna w bloku B (i wiersz w bloku A_curr)
                        elem = A.B_blocks[j, i, next_k]
                        
                        if abs(elem) > 1e-14
                            pivot = A.A_blocks[i, i, k]
                            factor = elem / pivot
                            
                            A.B_blocks[j, i, next_k] = 0.0 
                            
                            for c in (i+1):l # Aktualizacja reszty wiersza w B
                                A.B_blocks[j, c, next_k] -= factor * A.A_blocks[i, c, k]
                            end
                            
                            for c in 1:l # Aktualizacja A_{k+1} (wpływ C_k na A_{k+1})
                                A.A_blocks[j, c, next_k] -= factor * A.C_blocks[i, c, k]
                            end
                            
                            # Aktualizacja b
                            b[offset_next + j] -= factor * b[offset_k + i]
                        end
                    end
                end
            end
        end

        
        # Obliczanie x na podstawie macierzy górnej trójkątnej
        x = zeros(Float64, n)
        
        for i in n:-1:1
            k = div(i-1, l) + 1      
            loc_i = (i-1)%l + 1      
            
            sum_ax = 0.0
            
            # Część od C_k*x_{k+1}
            if k < nb
                for c in 1:l
                    sum_ax += A.C_blocks[loc_i, c, k] * x[k*l + c]
                end
            end
            
            # Część od A_k*x_k (elementy na prawo od przekątnej)
            for c in (loc_i+1):l
                sum_ax += A.A_blocks[loc_i, c, k] * x[(k-1)*l + c]
            end
            
            x[i] = (b[i] - sum_ax) / A.A_blocks[loc_i, loc_i, k]
        end
        
        return x
    end

    function gauss_elimination_partial_pivot!(A::BlockMatrix, b::Vector{Float64})
        return gauss_elimination!(A, b; partial_pivoting = true)
    end

end