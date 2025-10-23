#!/usr/bin/env python3
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
    radj = [[] for _ in range(n + 1)]
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
        radj[v].append(u)
        if flag == 'U':
            # jeśli nieskierowany, dodajemy także odwrotne krawędzie
            adj[v].append(u)
            radj[u].append(v)
    # sortujemy listy sąsiedztwa dla deterministycznych wyników
    for lst in adj:
        lst.sort()
    for lst in radj:
        lst.sort()
    directed = (flag == 'D')
    return directed, n, adj, radj

def iterative_dfs_postorder(n, adj):
    """Zwraca listę wierzchołków w kolejności zakończeń (finish order)."""
    visited = [False] * (n + 1)
    order = []  # postorder (finish order)
    for s in range(1, n + 1):
        if visited[s]:
            continue
        # stack element: (v, next_index)
        stack = [(s, 0)]
        visited[s] = True
        while stack:
            v, idx = stack[-1]
            if idx < len(adj[v]):
                nei = adj[v][idx]
                stack[-1] = (v, idx + 1)
                if not visited[nei]:
                    visited[nei] = True
                    stack.append((nei, 0))
            else:
                # finished v
                stack.pop()
                order.append(v)
    return order

def iterative_collect_component(start, radj, visited):
    """Zwraca listę wierzchołków należących do składowej zaczynając od start (iteracyjne DFS na radj)."""
    comp = []
    stack = [start]
    visited[start] = True
    while stack:
        v = stack.pop()
        comp.append(v)
        for nei in radj[v]:
            if not visited[nei]:
                visited[nei] = True
                stack.append(nei)
    return comp

def kosaraju_scc(n, adj, radj):
    # pierwszy przebieg: uzyskaj finish order (postorder)
    finish_order = iterative_dfs_postorder(n, adj)
    # drugi przebieg: na grafie odwrotnym w kolejności odwrotnej finish_order
    visited = [False] * (n + 1)
    components = []
    for v in reversed(finish_order):
        if not visited[v]:
            comp = iterative_collect_component(v, radj, visited)
            comp.sort()  # uporządkuj wierzchołki w składowej rosnąco
            components.append(comp)
    # ustalamy deterministyczną kolejność składowych: sortujemy według najmniejszego wierzchołka
    components.sort(key=lambda c: c[0] if c else float('inf'))
    return components

def main():
    parser = argparse.ArgumentParser(description="SCC (Kosaraju) — rozkład na silnie spójne składowe.")
    parser.add_argument('--input', '-i', help='plik wejściowy (domyślnie stdin)')
    args = parser.parse_args()

    if args.input:
        with open(args.input, 'r', encoding='utf-8') as f:
            directed, n, adj, radj = read_graph_from_file(f)
    else:
        directed, n, adj, radj = read_graph_from_file(sys.stdin)

    if not directed:
        print("Operacja dotyczy grafów skierowanych (wejście wskazuje graf nieskierowany).")
        return

    components = kosaraju_scc(n, adj, radj)
    k = len(components)
    print("No. SCC: " , k)
    print("No. vertices in each component:", ', '.join(str(len(c)) for c in components))
    if n <= 200:
        idx = 0
        for c in components:
            idx += 1
            print(f"Vertices in C{idx}:", ' '.join(str(v) for v in c))

if __name__ == "__main__":
    main()
