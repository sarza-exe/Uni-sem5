#pragma once
#include <vector>
#include <string>
#include <iostream>

class CodeGenerator {
    std::vector<std::string>* code = nullptr; 

public:

    void setCode(std::vector<std::string> & codeRef)
    {
        code = &codeRef;
    }
    
    void emit(std::string instruction)
    {
        code->push_back(instruction);
    }
    
    void emit(std::string instruction, long long arg)
    {
        code->push_back(instruction + " " + std::to_string(arg));
    }

    void generate_constant(std::string reg, long long n){
        emit("RST " + reg); //0
        if(n == 0) return;
        emit("INC " + reg); // 1
        if(n == 1) return;

        // calculate reversed string binary reprezentation of n
        std::string n_bin = "";
        while(n > 0){
            int bit = n%2;
            n_bin.push_back('0' + bit);
            n /= 2;
        }
        
        // we actually go left to right because the string is reversed
        for(int i = ((int)n_bin.length()-2); i >= 0; i--)
        {
            emit("SHL " + reg); // *=2
            if(n_bin[i] == '1') emit("INC " + reg);
        }
    }

    long long getCurrentLine()
    {
        return (long long)code->size();
    }

    // Wstawia pusty skok i zwraca jego indeks
    long long emitJumpPlaceholder(std::string instruction);

    // Wraca do podanej linii i wpisuje tam poprawny adres skoku
    void backpatch(long long lineToFix, long long destinationLine);

    // Zwraca gotowy kod (do zapisu do pliku)
    std::vector<std::string> getCode();
};