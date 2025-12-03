#include <iostream>
#include <string>
#include <vector>
#include <fstream>
#include <chrono>   // Do mierzenia czasu
#include <cstring>  // Do strcmp
#include <iomanip>  // Do formatowania wyjścia
#include "graph.h"
#include "solver.h"
#include "dijkstraSolver.h"
#include "dialSolver.h"
#include "radixHeapSolver.h"

using namespace std;

// ./main -a dijkstra -d ch9-1.1/inputs/Long-C/Long-C.8.0.gr -ss ch9-1.1/inputs/Long-C/Long-C.8.0.ss -oss results/LongC8.ss.res
// ./main -a dijkstra -d ch9-1.1/inputs/Long-C/Long-C.8.0.gr -p2p ch9-1.1/inputs/Long-C/Long-C.8.0.9.p2p -op2p results/LongC8.p2p.res

// Pomocnicza funkcja do wyświetlania błędów
void error(const string& msg) {
    cerr << "Error: " << msg << endl;
    exit(1);
}

int main(int argc, char* argv[]) {
    // 1. Zmienne konfiguracyjne
    string graphFile;
    string ssFile;
    string ossFile;
    string p2pFile;
    string op2pFile;
    string algorithm = "dijkstra"; // Domyślny algorytm

    // 2. Parsowanie argumentów linii komend
    for (int i = 1; i < argc; ++i) {
        if (strcmp(argv[i], "-d") == 0) {
            if (i + 1 < argc) graphFile = argv[++i];
        } else if (strcmp(argv[i], "-ss") == 0) {
            if (i + 1 < argc) ssFile = argv[++i];
        } else if (strcmp(argv[i], "-oss") == 0) {
            if (i + 1 < argc) ossFile = argv[++i];
        } else if (strcmp(argv[i], "-p2p") == 0) {
            if (i + 1 < argc) p2pFile = argv[++i];
        } else if (strcmp(argv[i], "-op2p") == 0) {
            if (i + 1 < argc) op2pFile = argv[++i];
        } else if (strcmp(argv[i], "-a") == 0) { 
            // Opcjonalna flaga, by zmienić algorytm bez rekompilacji (dla wygody)
            if (i + 1 < argc) algorithm = argv[++i];
        }
    }

    if (graphFile.empty()) {
        error("Nie podano pliku z grafem (-d)");
    }

    // 3. Wczytywanie grafu
    Graph G;
    try {
        cout << "Wczytywanie grafu: " << graphFile << " ..." << endl;
        G.loadFromFile(graphFile);
        cout << "Graf wczytany. N: " << G.n << ", M: " << G.m << ", MaxW: " << G.max_weight << endl;
    } catch (const exception& e) {
        error(e.what());
    }

    // 4. Wybór solvera
    ShortestPathSolver* solver = nullptr;
    if (algorithm == "dijkstra") {
        solver = new DijkstraSolver(G);
    } else if (algorithm == "dial") {
        solver = new DialSolver(G);
    } else if (algorithm == "radix") {
        solver = new RadixHeapSolver(G);
    } else {
        error("Nieznany algorytm: " + algorithm);
    }

    // 5. Obsługa trybu SS (Single Source)
    if (!ssFile.empty() && !ossFile.empty()) {
        ifstream in(ssFile);
        ofstream out(ossFile);

        out << "p res sp ss " << algorithm << "\n";
        out << "f " <<graphFile << " " << ssFile << "\n";
        out << "g " << G.n << " " << G.m << " 0 " << G.max_weight << "\n";
        
        if (!in) error("Nie mozna otworzyc pliku zrodel: " + ssFile);
        if (!out) error("Nie mozna otworzyc pliku wynikowego: " + ossFile);

        cout << "Uruchamianie testow SS..." << endl;

        char type;
        int src;
        // Format pliku .ss często zawiera linie: s <id>
        // Ignorujemy linie nagłówkowe 'p' lub komentarze 'c'
        string linebuf;
        
        while (in >> type) {
            if (type == 's') {
                in >> src;
                
                // Mierzymy czas
                auto start = chrono::high_resolution_clock::now();
                solver->compute(src); // target = -1 (wszystkie)
                auto end = chrono::high_resolution_clock::now();
                
                double time_taken = chrono::duration<double>(end - start).count();
                
                // Zapisujemy czas do pliku wynikowego
                // Format: t <czas_w_sekundach>
                out << "t " << fixed << setprecision(6) << time_taken << endl;
            } else {
                getline(in, linebuf);
            }
        }
        cout << "Zakonczono testy SS." << endl;
    }

    // 6. Obsługa trybu P2P (Point to Point)
    if (!p2pFile.empty() && !op2pFile.empty()) {
        ifstream in(p2pFile);
        ofstream out(op2pFile);

        out << "p res sp ss " << algorithm << "\n";
        out << "f " <<graphFile << " " << p2pFile << "\n";
        out << "g " << G.n << " " << G.m << " 0 " << G.max_weight << "\n";

        if (!in) error("Nie mozna otworzyc pliku par: " + p2pFile);
        if (!out) error("Nie mozna otworzyc pliku wynikowego: " + op2pFile);

        cout << "Uruchamianie testow P2P..." << endl;

        char type;
        int u, v;
        string linebuf;

        // Format pliku .p2p często zawiera linie: q <u> <v>
        while (in >> type) {
            if (type == 'q') {
                in >> u >> v;

                // Mierzymy czas (choć w P2P ważniejsza jest poprawność dystansu)
                solver->compute(u, v);
                long long dist = solver->getDistance(v);

                // Zapisujemy wynik
                // Format: d <zrodlo> <cel> <dystans>
                out << "d " << u << " " << v << " " << dist << endl;
            } else {
                getline(in, linebuf);
            }
        }
        cout << "Zakonczono testy P2P." << endl;
    }

    // Sprzątanie
    delete solver;

    return 0;
}