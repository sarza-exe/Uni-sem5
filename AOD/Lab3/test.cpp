#include "graph.h"
#include "solver.h"
#include "dijkstraSolver.h"
#include "dialSolver.h"
#include "radixHeapSolver.h"
#include <iostream>
#include <string.h>

int main(int argc, char* argv[]) {
    // Parsowanie argumentów (np. -d plik.gr)
    std::string graphFile = "ch9-1.1/inputs/Square-C/Square-C.15.0.gr"; 
    // ... logika pobierania nazwy pliku z argv ...
    

    Graph G;
    try {
        std::cout << "Wczytywanie grafu..." << std::endl;
        G.loadFromFile(graphFile);
        std::cout << "Wczytano graf: " << G.n << " wierzcholkow, " << G.m << " lukow. " << G.max_weight << " max_weight" << std::endl;
    } catch (const std::exception& e) {
        std::cerr << "Blad: " << e.what() << std::endl;
        return 1;
    }

    // Wybór solvera na podstawie argumentów programu lub testu
    ShortestPathSolver* solverDial = new DialSolver(G); 

    // Tryb P2P (Point to Point)
    solverDial->compute(1); // Podajemy cel -> szybsze wyjście
    //long long wynik1 = solverDij->getDistance(152740);
    //std::cout << "Dijkstra\nNajkrotszy dystans do 152740 to " << wynik1 << "\n";


    // ShortestPathSolver* solverDial = new DialSolver(G); 
    // solverDial->compute(873150, 152740); // Podajemy cel -> szybsze wyjście
    //         long long wynik2 = solverDial->getDistance(152740);
    //         std::cout << "Dial\nNajkrotszy dystans do 152740 to " << wynik2 << "\n";

    ShortestPathSolver* solverRad = new RadixHeapSolver(G); 
    solverRad->compute(873150, 152740); // Podajemy cel -> szybsze wyjście
    long long wynik3 = solverRad->getDistance(152740);
    std::cout << "Radix Heap\nNajkrotszy dystans do 152740 to " << wynik3 << "\n";
}