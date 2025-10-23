import sys
import argparse
from collections import deque

def read_graph_as_undirected(f):
    def get_token_line():
        for line in f:
            line = line.strip()
            if not line:
                continue
            # ignore comments that start with '#'
            if line.startswith('#'):
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

    # budujemy listy sąsiedztwa traktując graf jako nieskierowany (dodajemy obie strony)
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
        # dodajemy krawędź obustronnie (także dla grafów U — naturalne)
        adj[u].append(v)
        adj[v].append(u)
    # sortujemy listy sąsiedztwa aby wyniki były deterministyczne (opcjonalne)
    for lst in adj:
        lst.sort()
    return n, adj

def is_bipartite_and_partition(n, adj):
    # color: -1 = unvisited, 0 or 1 = kolor
    color = [-1] * (n + 1)
    V0 = []
    V1 = []

    for s in range(1, n + 1):
        if color[s] != -1:
            continue
        # rozpocznij BFS od nieodwiedzonego wierzchołka s
        q = deque()
        q.append(s)
        color[s] = 0
        while q:
            v = q.popleft()
            for u in adj[v]:
                if color[u] == -1:
                    color[u] = 1 - color[v]
                    q.append(u)
                else:
                    if color[u] == color[v]:
                        # znaleziono krawędź łączącą wierzchołki tego samego koloru -> niebipartytowy
                        return False, None, None
    # jeśli dotąd OK, zbierzemy zbiory
    for v in range(1, n + 1):
        if color[v] == 0:
            V0.append(v)
        elif color[v] == 1:
            V1.append(v)
        else:
            # izolowany wierzchołek, w naszym BFS został oznaczony (kolorowany) — ale traktujmy to bezpiecznie:
            V0.append(v)
    return True, V0, V1

def main():
    parser = argparse.ArgumentParser(description="Sprawdzenie dwudzielności grafu (dla skierowanego lub nieskierowanego).")
    parser.add_argument('--input', '-i', help='plik wejściowy (domyślnie stdin)')
    args = parser.parse_args()

    if args.input:
        with open(args.input, 'r', encoding='utf-8') as f:
            n, adj = read_graph_as_undirected(f)
    else:
        n, adj = read_graph_as_undirected(sys.stdin)

    bip, V0, V1 = is_bipartite_and_partition(n, adj)
    if bip:
        print("TAK")
        if n <= 200:
            print("VO:",' '.join(map(str, V0)) if V0 else "")
            print("V1:", ' '.join(map(str, V1)) if V1 else "")
    else:
        print("NIE")

if __name__ == "__main__":
    main()
