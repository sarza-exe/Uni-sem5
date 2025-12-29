#pragma once
#include <map>
#include <stdexcept>
#include <string>
#include <iostream>
#include <climits>

struct Symbol {
    long long memory_address; // Adres w pamięci maszyny wirtualnej
    bool is_array;           // Czy to tablica?
    long long array_start;   // Początek zakresu tablicy (np. -10)
    long long array_end;     // Koniec zakresu tablicy (np. 10)
    bool is_I = false;
    bool is_O = false;
    bool is_T = false;
};

class SymbolTable {
    std::map<std::string, Symbol> symbols;
    long long memory_offset = 0;
    const long long MEMORY_END = LLONG_MAX/2;

public:
    // Zwraca adres zmiennej lub rzuca błąd, jeśli nie istnieje
    long long getAddress(const std::string& name)
    {
        auto it = symbols.find(name);
        if (it == symbols.end())
            throw std::invalid_argument("Zmienna \"" + name + "\" niezadeklarowana");
        return it->second.memory_address;
    }

    long long getArrayElementAddress(const std::string& name, long long index) const {
        auto it = symbols.find(name);
        if (it == symbols.end())
            throw std::invalid_argument("Tablica \"" + name + "\" niezadeklarowana");
        const Symbol& s = it->second;
        if (!s.is_array)
            throw std::invalid_argument("Próba odwołania się do \"" + name + "\" poprzez indeks, ale \"" + name + "\" nie jest tablicą");
        if (index < s.array_start || index > s.array_end)
            throw std::out_of_range("Index " + std::to_string(index) + " spoza zakresu tablicy \"" + name + "\"");
        return s.memory_address + (index - s.array_start);
    }

    // Rejestruje nową zmienną
    void declareVariable(const std::string& name)
    {
        if (exists(name)) throw std::invalid_argument("Podwójna deklaracja: " + name);
        if (memory_offset + 1 > MEMORY_END) throw std::overflow_error("Brak pamięci na zmienną: " + name);
        Symbol s;
        s.memory_address = memory_offset;
        s.is_array = false;
        symbols.emplace(name, std::move(s));
        ++memory_offset;
        std::cout << "Wstawiono " << name << " @" << (memory_offset-1) << "\n";
    }

    // Rejestruje tablicę
    void declareArray(const std::string& name, long long start, long long end)
    {
        if(start > end) throw std::invalid_argument("startowy indeks tablicy \"" + name + "\" większy od końcowego: " + std::to_string(start) + " > " + std::to_string(end));
        long long tSize = end-start+1;
        if (memory_offset + tSize > MEMORY_END) throw std::overflow_error("Brak pamięci na tablicę: " + name);
        Symbol sym;
        sym.memory_address = memory_offset;
        memory_offset = memory_offset + tSize;
        sym.is_array = true;
        sym.array_start = start;
        sym.array_end = end;
        const auto [variable, success] = symbols.insert({name, sym});
        if(!success) throw std::invalid_argument("Podwójna inicjalizacja zmiennej: " + name);
        else std::cout<<"Wstawiono tablice "<<variable->first<<" \n";
    }
    
    // Sprawdza czy zmienna istnieje
    bool exists(const std::string& name)
    {
        if (auto search = symbols.find(name); search != symbols.end())
            return true;
        else
            return false;
    }
};