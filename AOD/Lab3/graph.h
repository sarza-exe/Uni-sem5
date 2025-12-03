#ifndef GRAPH_H
#define GRAPH_H

#include <vector>
#include <string>
#include <fstream>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <algorithm>

// Używamy dużej wartości dla nieskończoności (brak ścieżki)
const long long INF = std::numeric_limits<long long>::max();

// Struktura reprezentująca krawędź (łuk)
struct Edge {
    int target; // Wierzchołek docelowy
    int weight; // Koszt krawędzi (wagi są nieujemne [cite: 8])
};

class Graph {
public:
    int n; // Liczba wierzchołków
    long long m; // Liczba łuków
    int max_weight; // Maksymalny koszt krawędzi (potrzebne do algorytmu DIALA )
    
    // Lista sąsiedztwa: adj[u] zawiera listę krawędzi wychodzących z wierzchołka u
    // Używamy n+1, aby zachować indeksowanie od 1 do n zgodnie z formatem pliku 
    std::vector<std::vector<Edge>> adj;

    Graph() : n(0), m(0), max_weight(0) {}

    // Funkcja wczytująca graf z formatu DIMACS (.gr)
    void loadFromFile(const std::string& filename) {
        std::ifstream file(filename);
        if (!file.is_open()) {
            throw std::runtime_error("Nie można otworzyć pliku: " + filename);
        }

        char type;
        std::string line_buffer;

        // Optymalizacja I/O dla C++
        std::ios_base::sync_with_stdio(false);
        std::cin.tie(NULL);

        while (file >> type) {
            if (type == 'c') {
                // Linia komentarza - ignorujemy całą linię 
                std::getline(file, line_buffer); 
            } else if (type == 'p') {
                // Linia problemu: p sp <n> <m> 
                std::string problem_type;
                file >> problem_type >> n >> m;
                
                // Rezerwujemy pamięć. Indeksujemy od 1, więc rozmiar n + 1
                adj.assign(n + 1, std::vector<Edge>());
            } else if (type == 'a') {
                // Definicja łuku: a <u> <v> <w> 
                int u, v, w;
                file >> u >> v >> w;
                
                // Dodajemy krawędź do listy sąsiedztwa
                adj[u].push_back({v, w});
                
                // Aktualizujemy max_weight (kluczowe dla Diala i Radix Heap)
                if (w > max_weight) {
                    max_weight = w;
                }
            } else {
                // Inne, nieistotne linie
                std::getline(file, line_buffer);
            }
        }
        file.close();
    }
    
    // Metoda pomocnicza do czyszczenia grafu przed kolejnym testem (jeśli potrzebne)
    void clear() {
        adj.clear();
        n = 0;
        m = 0;
        max_weight = 0;
    }
};

#endif