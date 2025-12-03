#ifndef DIAL_SOLVER_H
#define DIAL_SOLVER_H

#include "solver.h"
#include <vector>

class DialSolver : public ShortestPathSolver {
private:
    // Kubełki: wektor wektorów przechowujący identyfikatory wierzchołków
    // buckets[k] przechowuje wierzchołki o tymczasowym dystansie d, takim że d % (C+1) == k
    std::vector<std::vector<int>> buckets;
    
    // Maksymalny koszt krawędzi (C)
    int C;
    // Rozmiar tablicy kubełków (C + 1)
    int bucket_size;

public:
    DialSolver(const Graph& g) : ShortestPathSolver(g) {
        // Pobieramy max_weight z grafu (zdefiniowane w Graph.h)
        // Jeśli graf nie ma krawędzi lub wagi 0, ustawiamy min 1, by uniknąć modulo 0
        C = (g.max_weight > 0) ? g.max_weight : 1;
        bucket_size = C + 1;
        
        // Rezerwujemy pamięć na kubełki
        buckets.resize(bucket_size);
    }

    void compute(int source, int target = -1) override {
        // 1. Inicjalizacja
        resetDistances();
        dist[source] = 0;

        // Czyszczenie kubełków po poprzednim uruchomieniu
        // Zamiast clear() na wektorze zewnętrznym (co zwalnia pamięć),
        // czyścimy tylko wewnętrzne wektory, aby uniknąć reallokacji.
        for(auto& b : buckets) {
            b.clear();
        }

        // Wstawiamy źródło do kubełka 0
        buckets[0].push_back(source);

        // Kursor wskazuje na aktualny dystans, który przetwarzamy
        long long current_dist = 0;
        
        // Licznik elementów w kolejce (aby wiedzieć, kiedy skończyć)
        int num_elements = 1;

        long long nC = (long long)graph.n * C;

        // 2. Główna pętla
        while (num_elements > 0) {
            // Przesuwamy kursor do najbliższego niepustego kubełka
            // Uwaga: w pesymistycznym przypadku (duże C) ta pętla generuje narzut czasowy
            while (buckets[current_dist % bucket_size].empty()) {
                current_dist++;
                // Zabezpieczenie na wypadek błędu logicznego (choć num_elements chroni pętlę while)
                if (current_dist > dist[source] + nC) break; 
            }

            int bucket_idx = current_dist % bucket_size;
            
            // Przetwarzamy wszystkie wierzchołki w bieżącym kubełku
            while (!buckets[bucket_idx].empty()) {
                int u = buckets[bucket_idx].back();
                buckets[bucket_idx].pop_back();
                num_elements--;

                // Jeśli szukamy konkretnego celu i go znaleźliśmy
                if (u == target) return;

                // Lazy deletion: Jeśli wyciągnięty wierzchołek ma już lepszy dystans
                // niż ten, który wskazuje current_dist, ignorujemy go.
                if (dist[u] < current_dist) continue;

                // Relaksacja sąsiadów
                for (const auto& edge : graph.adj[u]) {
                    int v = edge.target;
                    int weight = edge.weight;

                    if (dist[u] + weight < dist[v]) {
                        dist[v] = dist[u] + weight;
                        
                        // Dodajemy do odpowiedniego kubełka (cyklicznie)
                        buckets[dist[v] % bucket_size].push_back(v);
                        num_elements++;
                    }
                }
            }
            // Po opróżnieniu kubełka przechodzimy do następnego możliwego dystansu
            current_dist++;
        }
    }
};

#endif