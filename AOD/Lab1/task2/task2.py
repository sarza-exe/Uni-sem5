import sys
import argparse
import heapq

def read_graph_from_file(f):
    def get_token_line():
        for line in f:
            line = line.strip()
            if not line:
                continue
            return line
        return None

    first = get_token_line()
    if first is None:
        raise ValueError("Pusty plik/wejście")
    flag = first.strip()
    if flag not in ('D', 'U'):
        raise ValueError("Pierwsza linia powinna być 'D' (skierowany) lub 'U' (nieskierowany)")
    n_line = get_token_line()
    if n_line is None:
        raise ValueError("Brak liczby wierzchołków")
    n = int(n_line)
    m_line = get_token_line()
    if m_line is None:
        raise ValueError("Brak liczby krawędzi")
    m = int(m_line)

    adj = [[] for _ in range(n + 1)]
    for _ in range(m):
        l = get_token_line()
        if l is None:
            raise ValueError("Za mało linii z krawędziami")
        parts = l.split()
        if len(parts) < 2:
            raise ValueError(f"Niepoprawna definicja krawędzi: '{l}'")
        u = int(parts[0]); v = int(parts[1])
        if not (1 <= u <= n and 1 <= v <= n):
            raise ValueError(f"Wierzchołek poza zakresem: {u} {v}")
        adj[u].append(v)
        if flag == 'U':
            adj[v].append(u)
    # sortujemy listy sąsiedztwa dla deterministyczności (opcjonalne, koszt O(m log deg))
    for lst in adj:
        lst.sort()
    directed = (flag == 'D')
    return directed, n, adj

def kahn_toposort(n, adj):
    """Zwraca (has_cycle: bool, topo_order: list lub None)"""
    indeg = [0] * (n + 1)
    for u in range(1, n + 1):
        for v in adj[u]:
            indeg[v] += 1

    # użyjemy min-heap, aby zwracać deterministyczny porządek (najmniejszy wierzchołek najpierw)
    heap = []
    for v in range(1, n + 1):
        if indeg[v] == 0:
            heapq.heappush(heap, v)

    topo = []
    while heap:
        v = heapq.heappop(heap)
        topo.append(v)
        for nei in adj[v]:
            indeg[nei] -= 1
            if indeg[nei] == 0:
                heapq.heappush(heap, nei)

    if len(topo) != n:
        return True, None  # jest cykl (nie udało się przetworzyć wszystkich wierzchołków)
    return False, topo

def main():
    parser = argparse.ArgumentParser(description="Topologiczne sortowanie dla grafów skierowanych (wykrywanie cyklu).")
    parser.add_argument('--input', '-i', help='plik wejściowy (domyślnie stdin)')
    args = parser.parse_args()

    if args.input:
        with open(args.input, 'r', encoding='utf-8') as f:
            directed, n, adj = read_graph_from_file(f)
    else:
        directed, n, adj = read_graph_from_file(sys.stdin)

    if not directed:
        print("Operacja dotyczy tylko grafów skierowanych. (Wejście wskazuje graf nieskierowany).")
        return

    has_cycle, topo = kahn_toposort(n, adj)
    if has_cycle:
        print("CYCLIC") # istnieje cykl
    else:
        print("ACYCLIC") # acykliczny
        if n <= 200:
            print("TOPOLOGICAL ORDER:")
            print(' '.join(str(x) for x in topo))

if __name__ == "__main__":
    main()
