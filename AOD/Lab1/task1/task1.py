import sys
import argparse
from collections import deque

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
        if 1 <= u <= n and 1 <= v <= n:
            adj[u].append(v)
            if flag == 'U':
                adj[v].append(u)
        else:
            raise ValueError(f"Wierzchołek poza zakresem: {u} {v}")
    # Dla deterministycznych wyników sortujemy listy sąsiedztwa
    for lst in adj:
        lst.sort()
    directed = (flag == 'D')
    return directed, n, adj

def bfs_full(n, adj, start=None):
    visited = [False] * (n + 1)
    discovered = [False] * (n + 1)
    parent = [0] * (n + 1)
    order = []

    def bfs_from(s):
        q = deque()
        q.append(s)
        discovered[s] = True
        parent[s] = 0
        while q:
            v = q.popleft()
            if visited[v]:
                continue
            visited[v] = True
            order.append(v)
            for u in adj[v]:
                if not discovered[u]:
                    discovered[u] = True
                    parent[u] = v
                    q.append(u)

    if start is not None:
        if 1 <= start <= n:
            if not discovered[start]:
                bfs_from(start)
        else:
            raise ValueError("Start poza zakresem")
    # zapewniamy, że wszystkie składowe zostaną odwiedzone
    for v in range(1, n + 1):
        if not discovered[v]:
            bfs_from(v)

    return order, parent

def dfs_full(n, adj, start=None):
    visited = [False] * (n + 1)
    discovered = [False] * (n + 1)
    parent = [0] * (n + 1)
    order = []

    def dfs_from(s):
        stack = []
        stack.append(s)
        discovered[s] = True
        parent[s] = 0
        while stack:
            v = stack.pop()
            if visited[v]:
                continue
            visited[v] = True
            order.append(v)
            # Aby odwiedzać mniejszych sąsiadów wcześniej, wrzucamy na stos w odwrotnej kolejności
            neigh = adj[v]
            for u in reversed(neigh):
                if not discovered[u]:
                    discovered[u] = True
                    parent[u] = v
                    stack.append(u)

    if start is not None:
        if 1 <= start <= n:
            if not discovered[start]:
                dfs_from(start)
        else:
            raise ValueError("Start poza zakresem")
    for v in range(1, n + 1):
        if not discovered[v]:
            dfs_from(v)

    return order, parent

def main():
    parser = argparse.ArgumentParser(description="BFS/DFS dla grafu (wejście: D/U, n, m, m x 'u v').")
    parser.add_argument('mode', choices=['bfs','dfs'], help='tryb: bfs lub dfs')
    parser.add_argument('--input', '-i', help='plik wejściowy (domyślnie stdin)')
    parser.add_argument('--tree', action='store_true', help='wypisz drzewo przeszukiwania (parent child)')
    parser.add_argument('--start', type=int, default=None, help='opcjonalny wierzchołek startowy')
    args = parser.parse_args()

    if args.input:
        with open(args.input, 'r', encoding='utf-8') as f:
            directed, n, adj = read_graph_from_file(f)
    else:
        directed, n, adj = read_graph_from_file(sys.stdin)

    if args.mode == 'bfs':
        order, parent = bfs_full(n, adj, start=args.start)
    else:
        order, parent = dfs_full(n, adj, start=args.start)

    # Wypisujemy kolejność odwiedzin
    print("ORDER OF VISITS:")
    print(' '.join(str(x) for x in order))

    if args.tree:
        print("TREE:")
        # wypisujemy krawędzie drzewa dla wszystkich wierzchołków z parent != 0
        # sortujemy według parent, lub według dziecka — tutaj wypiszemy w kolejności odwiedzin (order)
        for v in order:
            p = parent[v]
            if p and p != 0:
                print(f"{p} {v}")

if __name__ == "__main__":
    main()
