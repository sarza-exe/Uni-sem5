#pragma once
#include <map>
#include <stdexcept>
#include <string>
#include <iostream>
#include <climits>

struct Symbol {
    long long memory_address; // Adres w pamięci maszyny wirtualnej
    bool is_array = false; 
    long long array_start; // Początek zakresu tablicy (np. -10)
    long long array_end;
    bool is_param = false; //jeśli true to ładujemy adres
    bool is_I = false;
    bool is_O = false;
    bool is_T = false;
    bool is_initialized = false; // tylko dla zmiennych
};

struct Procedure {
    std::string name;
    long long start_label; // Numer linii w VM, gdzie procedura się zaczyna
    // Lista parametrów w kolejności deklaracji - potrzebne do walidacji wywołania!
    std::vector<Symbol> parameters; //SKOPIOWAĆ BO PRZY LEAVE SCOPE USUNA SIE
}; 

class SymbolTable {
    std::vector<std::map<std::string, Symbol>> scopes;
    std::map<std::string, Procedure*> procedures;
    long long memory_offset = 0;
    const long long MEMORY_END = LLONG_MAX/2;
    std::string currProcedure = "";

public:
    void enterScope(){
        scopes.emplace_back(); // Nowy scope lokalny
    }

    void leaveScope(){
        scopes.pop_back(); // Wychodzimy ze scopu lokalnego
        currProcedure = "";
    }

    bool procedureExists(const std::string& procName){
        if (auto search = procedures.find(procName); search != procedures.end())
            return true;
        else return false;
    }

    std::string currentProcedure(){
        return currProcedure;
    }

    long long getProcedureLable(const std::string& procName){
        if(!procedureExists(procName)) throw std::invalid_argument("Getting lable of unexisting procedure " + procName);
        return procedures[procName]->start_label;
    }

    void createProcedure(const std::string& procName, long long start_label){
        if (auto search = procedures.find(procName); search != procedures.end()){
            throw std::invalid_argument("Procedure already declared");
        }
        else{
            Procedure proc;
            proc.name = procName;
            proc.start_label = start_label;
            procedures[procName] = &proc;
            currProcedure = procName;
        }
    }

    Symbol* getSymbol(std::string name) {
        if (auto search = scopes.back().find(name); search != scopes.back().end())
            return &search->second;
        else return nullptr;
    }

    void markInitialized(std::string name){
        Symbol* sym = getSymbol(name);
        if(sym->is_array) return;
        sym->is_initialized = true;
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
            throw std::invalid_argument("Trying to access \"" + name + "\" through index but \"" + name + "\" is not an array");
        if (index < s.array_start || index > s.array_end)
            throw std::out_of_range("Index " + std::to_string(index) + " not in range for array \"" + name + "\"");
        return s.memory_address + (index - s.array_start);
    }

    std::vector<Symbol> getParameters(const std::string& name){
        if (auto search = procedures.find(name); search != procedures.end()){
            return procedures[name]->parameters;
        }
        else{
            throw std::invalid_argument("Procedure not declared");
        }
    }

    void setArguments(const std::string& name, std::vector<const char*> args){
        std::vector<Symbol> params = procedures[name]->parameters;
        int argsSize = args.size();
        if((int)params.size() != argsSize) throw std::invalid_argument("Wrong number of arguments at call for procedure " + name);

        for (int i = 0; i < argsSize; i++){
            std::string argName = args[i];
            Symbol* arg = getSymbol(argName);
            if(arg == nullptr) throw std::invalid_argument("Trying to call procedure " + name + "with undeclared variable " + name);
            Symbol param = params.at(i);

            std::cout<<"argument " << arg << " at " << param.memory_address<<"\n";
        }
    }

    void declareParameter(const std::string& name, char type)
    {
        if (exists(name)) throw std::invalid_argument("Double variable declaration: " + name);
        if (memory_offset + 1 > MEMORY_END) throw std::overflow_error("Run out of memory for variable: " + name);
        
        Symbol s;
        s.memory_address = memory_offset;
        s.is_param = true;
        s.is_array = (type == 'T');

        if(type == 'I') s.is_I = true;
        else if(type == 'O') s.is_O = true;
        else if(type == 'T'){
             s.is_T = true;
             memory_offset++; //adres dla indeksu startowego
        }

        if (procedures.find(currProcedure) != procedures.end()) {
            procedures[currProcedure]->parameters.push_back(s);
        } else {
            throw std::runtime_error("Internal error: procedure not found");
        }

        scopes.back().emplace(name, std::move(s));
        ++memory_offset;

        std::cout << "Inserted " << type << " " << name << " @" << (memory_offset-1) << "\n";
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
        sym.is_initialized = true;
        const auto [variable, success] = scopes.back().insert({name, sym});
        if(!success) throw std::invalid_argument("Double declaration " + name);
        else std::cout<<"Inserted array "<<variable->first<<" \n";
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