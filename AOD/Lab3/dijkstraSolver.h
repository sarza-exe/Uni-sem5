#ifndef DIJKSTRA_SOLVER_H
#define DIJKSTRA_SOLVER_H

#include "solver.h"
#include <queue>
#include <vector>

// Para do kolejki priorytetowej: <dystans, wierzchołek>
using pii = std::pair<long long, int>;

class DijkstraSolver : public ShortestPathSolver {
public:
    DijkstraSolver(const Graph& g) : ShortestPathSolver(g) {}

    void compute(int source, int target = -1) override {
        // 1. Inicjalizacja
        resetDistances();
        dist[source] = 0;

        // Kolejka priorytetowa typu Min-Heap (najmniejszy dystans na wierzchu)
        // std::greater powoduje, że mniejszy element ma wyższy priorytet
        std::priority_queue<pii, std::vector<pii>, std::greater<pii>> pq;

        pq.push({0, source});

        // 2. Główna pętla
        while (!pq.empty()) {
            // Pobierz wierzchołek z najmniejszym dystansem
            long long d = pq.top().first;
            int u = pq.top().second;
            pq.pop();

            // Optymalizacja P2P: Jeśli wyciągnęliśmy cel, mamy gwarancję najkrótszej ścieżki
            if (u == target) return;

            // Lazy deletion: Jeśli w kolejce był "stary" wpis z gorszym dystansem, ignorujemy go
            if (d > dist[u]) continue;

            // Relaksacja sąsiadów
            for (const auto& edge : graph.adj[u]) {
                int v = edge.target;
                long long weight = edge.weight;

                if (dist[u] + weight < dist[v]) {
                    dist[v] = dist[u] + weight;
                    pq.push({dist[v], v});
                }
            }
        }
    }
};

#endif