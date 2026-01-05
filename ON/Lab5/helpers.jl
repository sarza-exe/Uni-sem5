# Sara Żyndul 279686

"""
Struktura do przechowywania macierzy A z równania Ax=b
n        - rozmiar macierzy A nxn
l        - rozmiar bloków w macierzy a
A_blocks - bloki lxl macierzy gęstych A_k
B_blocks - bloki lxl macierzy B_k
C_blocks - bloki lxl macierzy diagonalnych C_k
"""
mutable struct BlockMatrix
    n::Int
    l::Int
    A_blocks::Array{Float64,3}  # (l, l, nb)
    B_blocks::Array{Float64,3}
    C_blocks::Array{Float64,3}
end

"""
Zczytuje wektor b z pliku a jeśli inB == "none" to oblicza b na podstawie b=Ax gdzie x to wektor jedynek
"""
function get_b_vector(inB::String, A::BlockMatrix)
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
    return b, x_is_ones
end

"""
Funkcja czyta plik z zawartości macierzy A i każdy element dopasowuje do odpowiedniego bloku A_k, B_k lub C_k
Return BlockMatrix macierzy z pliku inA
"""
function read_A_Matrix(inA::String)
    open(inA, "r") do file_A
        n, l = parse.(Int, split(readline(file_A)))
        nb = div(n,l)

        A_blocks = zeros(Float64, l, l, nb) 
        B_blocks = zeros(Float64, l, l, nb) # B[k] istnieje dla k=2..nb
        C_blocks = zeros(Float64, l, l, nb) # C[k] istnieje dla k=1..nb-1

        for line in eachline(file_A)
            data = split(line)
            
            i = parse(Int, data[1])
            j = parse(Int, data[2])
            val = parse(Float64, data[3])

            # indeksy blokowe (1..nb)
            block_i = div(i - 1, l) + 1
            block_j = div(j - 1, l) + 1

            # lokalne indeksy wewnątrz bloków lxl (1..l)
            local_i = (i - 1) % l + 1
            local_j = (j - 1) % l + 1

            # Przekątna to A
            if block_j == block_i
                A_blocks[local_i, local_j, block_i] = val
            # Na prawo od przekątnej to C
            elseif block_j == block_i + 1
                C_blocks[local_i, local_j, block_i] = val
            # A na lewo to B
            elseif block_j == block_i - 1
                B_blocks[local_i, local_j, block_i] = val
            end
        end 
        # println(n)
        # println(l)
        # println(A_blocks)
        # println(B_blocks)
        # println(C_blocks)
        return BlockMatrix(n, l, A_blocks, B_blocks, C_blocks)
    end
end


"""
Funkcja czyta plik z zawartości wektora B, waliduje zgodność rozmiaru i zapisuje do wektora
Return wektor rozmiaru n
"""
function read_B_Vector(n::Int, inB::String)
    b = nothing

    open(inB, "r") do file_B
        first = strip(readline(file_B))
        # pierwszy wiersz to n; sprawdzamy czy sie zgadza
        if parse(Int, split(first)[1]) != n
            error("Niewłaściwy wektor b dla macierzy A o rozmiarze $n x $n.")
        end

        b = zeros(Float64, n)
        pos = 0
        for line in eachline(file_B)
            data = split(line)
            val = parse(Float64, data[1])
            pos += 1
            b[pos] = val
        end
    end

    return b
end


"""
Funkcja benchmarkuje algorytmy obliczania wartości x w równaniu Ax=b.
A           - macierz (lub BlockMatrix) wejściowa
b           - wektor prawych stron
algs        - wektor krotek: [( "nazwa1", func1 ), ( "nazwa2", func2 ), ...]
x_is_ones   - jeżeli true, liczy błąd względny względem x = ones(n)
"""
function run_algorithms(A, b, algs, x_is_ones)
    n = length(b)
    results = Vector{NamedTuple{(:n, :name, :ok, :time, :x, :rel, :err),Tuple{Int, String,Bool,Float64,Union{Vector{Float64},Nothing},Union{Float64,Nothing},Union{String,Nothing}}}}()

    for (name, func) in algs
        # Najpierw uruchamiamy algorytm raz, żeby sprawdzić czy działa i obliczyć błąd. Nie mierzymy czasu
        A_work = deepcopy(A)
        b_work = copy(b)
        
        ok = true
        x_res = nothing
        err_msg = nothing
        rel = nothing
        elapsed = 0.0

        try
            x_res = func(A_work, b_work)

            # Walidacja wyniku
            if length(x_res) != n
                ok = false
                err_msg = "Rozmiar wyniku = $(length(x_res)) != n = $n"
            end

            # Obliczenie błędu
            if ok && x_is_ones
                x_true = ones(Float64, n)
                rel = norm(x_res - x_true) / norm(x_true)
            end

        catch e
            ok = false
            err_msg = sprint(showerror, e)
        end

        # Benchmark
        if ok
            #println("Benchmark: $name...")
            
            # setup=(...) wykonuje się przed każdą próbką, ale nie wlicza się do czasu!
            # Używamy $ przy zmiennych lokalnych (A, b, func), żeby makro je widziało.
            elapsed = try
                @belapsed begin
                    A_c = deepcopy($A)
                    b_c = copy($b)
                    $func(A_c, b_c)
                end
            catch e
                @printf("[%s] BENCH ERROR: %s\n", name, sprint(showerror, e))
                0.0
            end
        else
            elapsed = 0.0 
            @printf("[%s] ERROR: %s\n", name, err_msg)
        end

        push!(results, (n=n, name=name, ok=ok, time=elapsed, x=x_res, rel=rel, err=err_msg))
    end

    return results
end

function print_results(results)
    println()
    println("Rozmiar macierzy n = $(results[1].n)")

    @printf("%-30s | %-6s | %-10s | %-12s\n",
            "Algorytm", "Status", "Czas [s]", "Błąd wzgl.")
    println("--------------------------------------------------------------")

    for r in results
        status = r.ok ? "OK" : "ERROR"
        time_str = r.ok ? @sprintf("%.6f", r.time) : "-"
        rel_str  = (r.ok && r.rel !== nothing) ? @sprintf("%.3e", r.rel) : "-"

        @printf("%-30s | %-6s | %-10s | %-12s\n",
                r.name, status, time_str, rel_str)
    end

    println("==============================================================")
end