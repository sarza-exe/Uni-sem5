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
    bool is_initialized = false; // czy zmienna zawiera już w sobie jakoś wartość
};

class SymbolTable {
    std::vector<std::map<std::string, Symbol>> scopes;
    long long memory_offset = 0;
    const long long MEMORY_END = LLONG_MAX/2;

public:
    SymbolTable(){
        scopes.emplace_back(); // Scope globalny
    }

    void enterScope(){
        scopes.emplace_back(); // Nowy scope lokalny
    }

    void leaveScope(){
        scopes.pop_back(); // Wychodzimy ze scopu lokalnego
    }

    Symbol* getSymbol(std::string name) {
        // Szuka od ostatniego zakresu (lokalny) do pierwszego (globalny)
        for (auto it = scopes.rbegin(); it != scopes.rend(); ++it) {
            auto search = it->find(name);
            if (search != it->end()) {
                return &search->second;
            }
        }
        return nullptr;
    }

    void markInitialized(std::string name){
        getSymbol(name)->is_initialized = true;
    }

    // Zwraca adres zmiennej lub rzuca błąd, jeśli nie istnieje
    long long getAddressVar(const std::string& name)
    {
        auto it = scopes.back().find(name);
        if (it == scopes.back().end())
            throw std::invalid_argument("Variable \"" + name + "\" not defined");
        if (it->second.is_array) throw std::invalid_argument(name +" is an array not variable");
        return it->second.memory_address;
    }

    // Zwraca adres tablicy lub rzuca błąd, jeśli nie istnieje
    long long getAddressArr(const std::string& name)
    {
        auto it = scopes.back().find(name);
        if (it == scopes.back().end())
            throw std::invalid_argument("Array \"" + name + "\" not defined");
        if (!it->second.is_array) throw std::invalid_argument(name +" is a variable not an array");
        return it->second.memory_address;
    }

    long long getArrayElementAddress(const std::string& name, long long index) const {
        auto it = scopes.back().find(name);
        if (it == scopes.back().end())
            throw std::invalid_argument("Array \"" + name + "\" not defined");
        const Symbol& s = it->second;
        if (!s.is_array)
            throw std::invalid_argument("Trying to access \"" + name + "\" through index but \"" + name + "\" is not an array8");
        if (index < s.array_start || index > s.array_end)
            throw std::out_of_range("Index " + std::to_string(index) + " not in range for array \"" + name + "\"");
        return s.memory_address + (index - s.array_start);
    }

    // Rejestruje nową zmienną w scopie
    void declareVariable(const std::string& name)
    {
        if (exists(name)) throw std::invalid_argument("Double variable declaration: " + name);
        if (memory_offset + 1 > MEMORY_END) throw std::overflow_error("Run out of memory for variable: " + name);
        Symbol s;
        s.memory_address = memory_offset;
        s.is_array = false;
        scopes.back().emplace(name, std::move(s));
        ++memory_offset;
        std::cout << "Inserted " << name << " @" << (memory_offset-1) << "\n";
    }

    // Rejestruje tablicę w scopie
    void declareArray(const std::string& name, unsigned long long start, unsigned long long end)
    {
        if(start > end) throw std::invalid_argument("Start index of array \"" + name + "\" greater then end index: " + std::to_string(start) + " > " + std::to_string(end));
        long long tSize = end-start+1;
        if (memory_offset + tSize > MEMORY_END) throw std::overflow_error("Run out of memory for variable: " + name);
        Symbol sym;
        sym.memory_address = memory_offset;
        memory_offset = memory_offset + tSize;
        sym.is_array = true;
        sym.array_start = start;
        sym.array_end = end;
        const auto [variable, success] = scopes.back().insert({name, sym});
        if(!success) throw std::invalid_argument("Double declaration " + name);
        else std::cout<<"Inserted array "<<variable->first<<" \n";
    }

    // TODO
    // Pomocnicza funkcja do argumentów procedur
    // Argumenty muszą trafić do zakresu procedury, ale mogą być referencjami
    void declareArgument(std::string name) {
         // Tutaj logika podobna do declareVariable, ale w VM argumenty też zajmują komórki pamięci
    }
    
    // Sprawdza czy zmienna istnieje w danym scopie
    bool exists(const std::string& name)
    {
        if (auto search = scopes.back().find(name); search != scopes.back().end())
            return true;
        else
            return false;
    }
};