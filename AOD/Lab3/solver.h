#ifndef SOLVER_H
#define SOLVER_H

#include "graph.h"
#include <vector>
#include <algorithm>

class ShortestPathSolver {
protected:
    const Graph& graph;             // Referencja do grafu
    std::vector<long long> dist;    // Tablica odległości

public:
    // Konstruktor przyjmuje graf przez referencję
    ShortestPathSolver(const Graph& g) : graph(g) {
        // Rezerwujemy pamięć, ale inicjalizację robimy w compute
        dist.resize(graph.n + 1);
    }

    virtual ~ShortestPathSolver() {}

    // Główna metoda: 
    // source - wierzchołek startowy
    // target - wierzchołek docelowy (jeśli -1, liczymy do wszystkich)
    virtual void compute(int source, int target = -1) = 0;

    // Pobieranie wyniku po obliczeniach
    long long getDistance(int node) const {
        if (node < 0 || static_cast<std::vector<long long int>::size_type>(node) >= dist.size()) return INF;
        return dist[node];
    }
    
    // Metoda pomocnicza do resetowania tablicy dystansów
    void resetDistances() {
        std::fill(dist.begin(), dist.end(), INF);
    }
};

#endif