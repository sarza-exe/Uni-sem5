#pragma once
#include <vector>
#include <string>
#include <iostream>

class CodeGenerator {
    std::vector<std::string>* code = nullptr; 

public:

    CodeGenerator() { std::cout << "GEN @" << this << "\n"; }

    void setCode(std::vector<std::string> & codeRef)
    {
        code = &codeRef;
    }
    // Dodaje prostą instrukcję
    void emit(std::string instruction)
    {
        code->push_back(instruction);
    }
    
    // Dodaje instrukcję z argumentem (np. "STORE 5")
    void emit(std::string instruction, long long arg)
    {
        code->push_back(instruction + std::to_string(arg));
    }

    // Zwraca aktualny numer linii (potrzebne do skoków)
    long long getCurrentLine()
    {
        return (long long)code->size();
    }

    // Wstawia pusty skok i zwraca jego indeks (do uzupełnienia później)
    long long emitJumpPlaceholder(std::string instruction);

    // Wraca do podanej linii i wpisuje tam poprawny adres skoku
    void backpatch(long long lineToFix, long long destinationLine);

    // Zwraca gotowy kod (do zapisu do pliku)
    std::vector<std::string> getCode();
};