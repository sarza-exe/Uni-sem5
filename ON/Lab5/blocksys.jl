# Sara Żyndul 279686
module blocksys
    using LinearAlgebra
    using Printf
    using BenchmarkTools
    include("helpers.jl")

    export solve

    function solve(inA::String; inB::String = "none")
        A = read_A_Matrix(inA)
        # println(A.n)
        # println(A.l)
        # println(A.A_blocks)
        # println(A.B_blocks)
        # println(A.C_blocks)

        b = nothing
        x_is_ones = false

        # calculate b=Ax where x is a vector of ones
        if inB == "none"
            x_is_ones = true
            n = A.n
            l = A.l
            b = zeros(Float64,n)
            nb = div(n, l)

            for k in 1:nb
                range_k = ((k-1)*l + 1) : (k*l)
                b[range_k] += sum(A.A_blocks[:, :, k], dims=2) # to every b[i] we're adding the correspongind sum of A row
                if k > 1 # B_blocks start at index 2
                    b[range_k] += sum(A.B_blocks[:, :, k], dims=2)
                end
                if k < nb # C_blocks end at index nb-1
                    b[range_k] += sum(A.C_blocks[:, :, k], dims=2)
                end
            end
            
            # println("Obliczono wektor prawych stron b na podstawie macierzy A i wektora x=(1...1)")
            # println(b)
        else
            b = read_B_Vector(A.n, inB)
            # println("zczytano B")
            # println(b)
        end

        algs = [
            ("Gauss (bez pivotu)", gauss_elimination!),
            ("Gauss z częściowym pivotowaniem", gauss_elimination_partial_pivot!),
        ]

        print_results(run_algorithms(A, b, algs, x_is_ones))
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