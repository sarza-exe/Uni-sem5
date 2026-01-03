#pragma once
#include <vector>
#include <string>
#include <unordered_map>
#include <iostream>

struct Fixup {
    int instr_index; // indeks instrukcji w code (pozycja do uzupełnienia)
    int lable; // id etykiety, którą ma wskazywać
    std::string op; // "JZERO" lub "JUMP"
    };

class CodeGenerator {
    std::vector<std::string>* code = nullptr; 

    int next_lable_id; // generuje nowe id etykiet
    std::unordered_map<int,int> lable_address; // lable_id -> code index (adres)
    std::vector<Fixup> pending_fixups;
    std::vector<int> lable_stack;

public:

    CodeGenerator(){
        next_lable_id = 0;
        lable_address.clear();
        pending_fixups.clear();
    }

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

    // Utwórz nową etykietę (zwraca jej id)
    int newLable() {
        return next_lable_id++;
    }

    void pushLable(int L) { lable_stack.push_back(L); }

    int popLable() { 
        int v = lable_stack.back(); 
        lable_stack.pop_back(); 
        return v; 
    }

    // Emituj j_lable i dopisz do pending_fixups
    void emitLable(int lable, std::string j_lable) {
        int idx = (int)code->size();
        code->push_back(j_lable);  // placeholder
        pending_fixups.push_back({idx, lable, j_lable});
    }

    // Zdefiniuj etykietę (oznacz miejsce aktualnym indeksem kodu) i backpatchuj
    void defineLable(int lable) {
        int addr = (int)code->size();
        lable_address[lable] = addr;

        // backpatchuj wszystkie pending_fixups, które celują w ten lable
        for (auto it = pending_fixups.begin(); it != pending_fixups.end(); ) {
            if (it->lable == lable) {
                std::string new_instr = it->op + " " + std::to_string(addr);
                code->at(it->instr_index) = new_instr;
                it = pending_fixups.erase(it);
            } else {
                ++it;
            }
        }
    }

    // Na końcu parsowania upewniamy się, że wszystkie etykiety zdefiniowano
    void backpatchAllCheck() {
        if (!pending_fixups.empty()) {
            for (const auto &f : pending_fixups) {
                throw std::domain_error("Unresolved jump to lable " + std::to_string(f.lable) + " at instr " + std::to_string(f.instr_index));
            }
        }
    }

    void generateConstant(std::string reg, long long n){
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

    void generateMult(long long jump_lable ){
        emit("RST a #MULT START"); //ra = 0
        emit("SWP d"); //ra <-> rd
        emit("RST a"); //ra = 0
        emit("ADD b"); //ra += b
        emit("SHR a"); //ra = ra/2
        emit("SHL a"); //ra = ra*2
        emit("SWP b"); //ra <-> rb
        emit("SUB b"); //ra = ra-rb
        emit("JZERO", jump_lable+12); // jeśli rb%2==0 jump
        emit("SWP d");
        emit("ADD c");
        emit("SWP d");
        emit("SWP d");
        emit("SHL c");
        emit("SHR b");
        emit("SWP b");
        emit("JZERO", jump_lable+19); // jeśli rb==0 end
        emit("SWP b");
        emit("JUMP", jump_lable+1); // while(rb)
        emit("SWP b #MULT END");
    }

    void generateIsEqual(){
        emit("RST a");
        emit("ADD b");
        emit("SUB c"); // ra = val1 - val2
        emit("SWP d"); // schowaj wynik w rd
    
        emit("RST a");
        emit("ADD c");
        emit("SUB b"); // ra = val2 - val1
        
        emit("ADD d"); // ra = (val2-val1) + (val1-val2)
    }

};