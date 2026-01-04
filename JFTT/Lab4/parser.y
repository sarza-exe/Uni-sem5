%code requires { 
#include <vector> 
#include <string>
#include <map>
#include <stdexcept>

using namespace std;

struct Identifier {
    char *pid;
    long long num;
};

struct VariableInfo {
    std::string name;
    long long memory_address; // Adres w pamięci maszyny
    bool is_array_ref; // Czy to referencja do tablicy przez zmienną np. arr[x]
    long long offset_or_addr; // Adres zmiennej indeksującej (dla arr[x])
    long long arr_start;
};

struct ValueInfo {
    long long value = 0;
    VariableInfo *var_info;
};
}

%code provides {
void declare_array(Identifier *id, long long start, long long end);
void declare_variable(Identifier *id);
}


%{
#include <iostream>
#include <string>
#include <vector>

#include "codeGenerator.hh"
#include "symbolTable.hh"
#include "parser.hh"

int yylex( void );
void yyset_in( FILE * in_str );
extern int yylineno;
void yyerror(const char*);

CodeGenerator codeGen;
SymbolTable symbolTable;

/* Funkcja obsługi błędów */
[[noreturn]] void semantic_error(long long lineno, char const *s) {
    if(lineno == 0) lineno = (long long)yylineno;
    std::cerr << "Syntax error on line " << (int)lineno << ": " << s << std::endl;
    exit(-1);
}

void declare_array(Identifier *id, long long start, long long end)
{
    try {
        symbolTable.declareArray(id->pid, start, end);
    } catch (const std::invalid_argument &e) {
        semantic_error(id->num, e.what());
    }
    free(id->pid);
}

void declare_variable(Identifier *id)
{
    try {
        symbolTable.declareVariable(id->pid);
    } catch (const std::invalid_argument &e) {
        semantic_error(id->num, e.what());
    }
    free(id->pid);
}

//Zapisuje do reg wartość z val_info(5,a,tab[5],tab[a]). h JEST ZAREZEROWOWANY DO OBLICZEŃ. a jest używany do obliczeń
//Jeśli mamy gdzieś > 1 value jednocześnie to tylko ostatnia może zostać zapisana do a.
void save_value_to_reg(ValueInfo *val_info, std::string reg){
    if(reg == "h") yyerror("r_h is reserved for calculations in save_value_to_reg!");
    VariableInfo *info = val_info->var_info;
    if(info == nullptr){
        codeGen.generateConstant(reg, val_info->value);
    }
    else{
        if (info->is_array_ref == false) { // x lub arr[5]
            codeGen.emit("LOAD", info->memory_address);
            if(reg != "a") codeGen.emit("SWP " + reg);
        } else { // arr[x]
            // Adres = AdresBazowy + Wartość(x) - StartIndex
            codeGen.emit("LOAD", info->offset_or_addr); // Załaduj x do ra
            long long net_offset = info->memory_address - info->arr_start;
        
            // rb zawiera net_offset
            if (net_offset > 0) {
                codeGen.generateConstant("h", net_offset); 
                codeGen.emit("ADD h"); // ra = ra + rh = x + arr.memory_address - arr.start_index
            } else if (net_offset < 0) {
                codeGen.generateConstant("h", -net_offset);
                codeGen.emit("SUB h"); // ra = max(ra - rh, 0) 
            }
            
            codeGen.emit("SWP h"); // teraz rb zawiera adres
            codeGen.emit("RLOAD h"); // Wczytaj liczbę do ra. ra = p_rh
            if(reg != "a") codeGen.emit("SWP " + reg);
    }}
    delete info;
    delete val_info;
}

const std::string JPOS_lable = "JPOS";
const std::string JZERO_lable = "JZERO";

%}

//%debug
%define parse.error verbose

/* Definicja typów danych przekazywanych między regułami */
%union {
    long long num;       /* Dla liczb (64-bit)  */
    Identifier *id;
    VariableInfo *var_info;
    ValueInfo *val;
    const std::string *lable;
    /* Tutaj w przyszłości dodasz wskaźniki na węzły AST */
}


%token <num> NUM
%token <id> PIDENTIFIER

%type <var_info> identifier
%type <lable> condition
%type <val> value
%type <id> proc_call

%token ERROR

%token PROCEDURE IS IN END PROGRAM
%token IF THEN ELSE ENDIF
%token WHILE DO ENDWHILE
%token REPEAT UNTIL
%token FOR FROM TO DOWNTO ENDFOR
%token READ WRITE

%token ASSIGN       /* := */
%token EQ NEQ       /* =  != */
%token GT LT GE LE  /* >  <  >=  <= */
%token COMMA COLON SEMICOLON
%token LPAREN RPAREN LBRACKET RBRACKET
%token T            /* Oznaczenie tablicy w parametrach [cite: 22] */
%token I_CONST O_VAR /* Modyfikatory I (stała) oraz O (niezainicjowana) [cite: 24, 25] */

/* Operatory arytmetyczne */
%token PLUS MINUS MULT DIV MOD

%%

program_all:
    procedures main {codeGen.emit("HALT");}
    ;

procedure_head: PROCEDURE PIDENTIFIER {
    if(symbolTable.procedureExists($2->pid)) yyerror("Procedure already declared");
    symbolTable.createProcedure($2->pid, codeGen.getCurrentLine());
    symbolTable.enterScope();
    codeGen.emit("SWP g");
}

procedures:
    procedures procedure_head proc_head IS declarations IN commands END {
        symbolTable.leaveScope();
        codeGen.emit("SWP g");
        codeGen.emit("RTRN");
        }
    | procedures procedure_head proc_head IS IN commands END {
        symbolTable.leaveScope();
        codeGen.emit("SWP g");
        codeGen.emit("RTRN");
        }
    | %empty
    ;

proc_head:
    LPAREN args_decl RPAREN {
    };

args_decl:
    args_decl COMMA type PIDENTIFIER
    | type PIDENTIFIER
    ;

type:
    T
    | I_CONST
    | O_VAR
    | %empty
    ;

main_start: PROGRAM IS { 
        symbolTable.enterScope(); //enter main scope
        int L_end = codeGen.popLable();
        codeGen.defineLable(L_end);
    }

main:
    main_start declarations IN commands END
    | main_start IN commands END
    | ERROR { yyerror(""); }
    ;

declarations:
    declarations COMMA PIDENTIFIER{ declare_variable($3);}
    | declarations COMMA PIDENTIFIER LBRACKET NUM COLON NUM RBRACKET { declare_array($3, $5, $7);}
    | PIDENTIFIER { declare_variable($1);}
    | PIDENTIFIER LBRACKET NUM COLON NUM RBRACKET { declare_array($1, $3, $5);}
    ;

commands:
    commands command
    | command
    ;
 
if_start: /* pomocniczy nieterminal, wstawia *$1 label i pushLable(label) */
    condition {
      int L_else = codeGen.newLable();
      codeGen.emitLable(L_else, *$1);
      codeGen.pushLable(L_else);
    };

then_block: THEN commands;

then_tail: /* to jest miejsce po wykonaniu then_block */ 
    { 
        int L_else = codeGen.popLable();
        int L_end  = codeGen.newLable();
        codeGen.emitLable(L_end, "JUMP"); // jump za ELSE
        codeGen.defineLable(L_else);// definuj poczatek ELSE
        codeGen.pushLable(L_end);
    } ELSE commands ENDIF {
        int L_end = codeGen.popLable();
        codeGen.defineLable(L_end);
    }
  | ENDIF {//bez ELSE
        int L_end = codeGen.popLable();
        codeGen.defineLable(L_end);
    };

command:
    identifier ASSIGN expression SEMICOLON {
        // a := expr
        // r_b zawiera adres a
        VariableInfo *info = $1;
        if (info->is_array_ref == false) { // x lub arr[5]
            codeGen.generateConstant("b", info->memory_address);
        } else { // arr[x]
            // Adres = AdresBazowy + Wartość(x) - StartIndex
            codeGen.emit("SWP h"); // ra <-> rh (robimy bo ra zawiera wartość expression)
            codeGen.emit("LOAD", info->offset_or_addr); // Załaduj x do ra
            long long net_offset = info->memory_address - info->arr_start;
        
            if (net_offset > 0) { // rb zawiera net_offset
                codeGen.generateConstant("b", net_offset); 
                codeGen.emit("ADD b"); // ra = ra + rh = x + arr.memory_address - arr.start_index
            } else if (net_offset < 0) {
                codeGen.generateConstant("b", -net_offset);
                codeGen.emit("SUB b"); // ra = max(ra - rh, 0) 
            }
            
            codeGen.emit("SWP b"); // teraz rb zawiera adres
            codeGen.emit("SWP h"); // ra <-> rh ra = value(expression)
        }
        symbolTable.markInitialized(info->name);
        delete info;
        // r_a zawiera wartość expression (policzone w expr)
        codeGen.emit("RSTORE b");
    } 
    | IF if_start then_block then_tail //działa
    | WHILE{
            int L_start = codeGen.newLable();
            codeGen.defineLable(L_start); // miejsce początku pętli
            codeGen.pushLable(L_start); // zapamiętaj start (będzie potrzebny do JUMP)
        } condition{
            int L_end = codeGen.newLable();
            codeGen.emitLable(L_end, *$3);
            codeGen.pushLable(L_end);
        } DO commands ENDWHILE {
            int L_end = codeGen.popLable();
            int L_start = codeGen.popLable();
            codeGen.emitLable(L_start, "JUMP"); // skocz z powrotem na początek
            codeGen.defineLable(L_end);
        }
    | REPEAT{
            int L_start = codeGen.newLable();
            codeGen.defineLable(L_start); // miejsce początku pętli
            codeGen.pushLable(L_start);
        } commands UNTIL condition SEMICOLON {
            int L_start = codeGen.popLable();
            codeGen.emitLable(L_start, *$5 );
        }
    | FOR PIDENTIFIER FROM value TO value DO commands ENDFOR 
    | FOR PIDENTIFIER FROM value DOWNTO value DO commands ENDFOR 
    | proc_call SEMICOLON {
        if(!symbolTable.procedureExists($1->pid)) yyerror(("Calling undeclared procedure \"" + std::string($1->pid) + "\"").c_str());
        long long procLable = symbolTable.getProcedureLable($1->pid);
        codeGen.emit("CALL", procLable);
    }
    | READ identifier SEMICOLON {
        VariableInfo *info = $2;
        
        if (info->is_array_ref == false) { // x lub arr[5]
            codeGen.emit("READ");
            codeGen.emit("STORE", info->memory_address);
        } else { // arr[x]
            // Adres = AdresBazowy + Wartość(x) - StartIndex
            codeGen.emit("LOAD", info->offset_or_addr); // Załaduj x
            long long net_offset = info->memory_address - info->arr_start;
        
            // Liczymy w rb wartość adresu
            if (net_offset > 0) {
                codeGen.generateConstant("b", net_offset); 
                codeGen.emit("ADD b"); // ra = ra + rb 
            } else if (net_offset < 0) {
                codeGen.generateConstant("b", -net_offset);
                codeGen.emit("SUB b"); // ra = max(ra - rb, 0) 
            }
            
            codeGen.emit("SWP b"); // teraz rb zawiera adres
            codeGen.emit("READ"); // Wczytaj liczbę do ra
            codeGen.emit("RSTORE b"); // Zapisz ra do adresu wskazanego przez rb
        }
        symbolTable.markInitialized(info->name);
        delete info;
    }
    // Zapisz do r_a wartość value i wywołaj WRITE
    | WRITE value SEMICOLON {
        save_value_to_reg($2, "a");
        codeGen.emit("WRITE");
    }
    ;

proc_call:
    PIDENTIFIER LPAREN args RPAREN {
        $$ = $1;
    }
    ;

args:
    args COMMA PIDENTIFIER
    | PIDENTIFIER
    ;

expression: // zapisuje wartość wyrażenia do r_a
    value PLUS value {
        save_value_to_reg($1, "b");
        save_value_to_reg($3, "a");
        codeGen.emit("ADD b");
    }
    | value MINUS value {
        save_value_to_reg($1, "b");
        save_value_to_reg($3, "a");
        codeGen.emit("SWP b");
        codeGen.emit("SUB b");
    }
    | value MULT value {
        if ($3 -> value == 0 && $3->var_info == nullptr) codeGen.emit("RST a");
        else if ($1 -> value == 0 && $1->var_info == nullptr) codeGen.emit("RST a");
        else if ($3 -> value == 2){
            save_value_to_reg($1, "a");
            codeGen.emit("SHL a");
        }
        else if ($1 -> value == 2){
            save_value_to_reg($3, "a");
            codeGen.emit("SHL a");
        }
        else if ($3 -> value == 1) save_value_to_reg($1, "a");
        else if ($1 -> value == 1) save_value_to_reg($3, "a");
        else{ //r_a = r_b*r_c metodą rosyjskich chłopów
            save_value_to_reg($1, "b");
            save_value_to_reg($3, "c");
            long long jumpLable = codeGen.getCurrentLine();
            codeGen.generateMult(jumpLable);
        }
    }
    | value DIV value {
        if ($3 -> value == 0 && $3->var_info == nullptr){
            codeGen.emit("RST a");
        }
        else if ($3 -> value == 2){
            save_value_to_reg($1, "a");
            codeGen.emit("SHR a");
        }
        else {
            // co z dzieleniem przez 0 jeśli value to nie NUM
            // SWP c    JZERO end_of_div    SWPc    a=b/c
            // generate_division_code w jednym rejestrze wynik w drugim reszta z dzielenia(modulo)
            save_value_to_reg($1, "b");
            save_value_to_reg($3, "c");
        }
    }
    | value MOD value {
        if ($3 -> value == 0 && $3->var_info == nullptr){
            codeGen.emit("RST a");
        }
        else{
            save_value_to_reg($1, "b");
            save_value_to_reg($3, "c");
        }
    }
    | value { save_value_to_reg($1, "a");}
    ;

//skaczemy jeśli fałsz (sprawdzamy warunek przeciwny)
condition:
    value EQ value { // (a-b)+(b-a)>0
        save_value_to_reg($1, "b");
        save_value_to_reg($3, "c");
        codeGen.generateIsEqual();
        $$ = &JPOS_lable;
    }
    | value NEQ value { // (a-b)+(b-a)=0
        save_value_to_reg($1, "b");
        save_value_to_reg($3, "c");
        codeGen.generateIsEqual();
        $$ = &JZERO_lable;
    }
    | value GT value { // a <= b -> a-b <= 0
        save_value_to_reg($3, "b");
        save_value_to_reg($1, "a");
        codeGen.emit("SUB b");
        $$ = &JZERO_lable;
    }
    | value LT value { // b >= a -> 0 >= a-b
        save_value_to_reg($1, "b");
        save_value_to_reg($3, "a");
        codeGen.emit("SUB b");
        $$ = &JZERO_lable;
    }
    | value GE value { // b < a -> a-b > 0
        save_value_to_reg($1, "b");
        save_value_to_reg($3, "a");
        codeGen.emit("SUB b");
        $$ = &JPOS_lable;
    }
    | value LE value { // a > b -> a-b > 0
        save_value_to_reg($3, "b");
        save_value_to_reg($1, "a");
        codeGen.emit("SUB b");
        $$ = &JPOS_lable;
    }
    ;

value: // zapisuje do ValueInfo wartość NUM albo wskaźnik do VariableInfo
    NUM {
        $$ = new ValueInfo();
        $$->value = $1;
        $$->var_info = nullptr;
    }
    | identifier{
        VariableInfo *info = $1;
        Symbol* sym = symbolTable.getSymbol(info->name);
        if(!sym->is_initialized) yyerror("Cannot access uninitialized variable");
        $$ = new ValueInfo();
        $$->var_info = info;
    }
    ;

identifier: // saves in VariableInfo if it's x, tab[2] or tab[x] with corresponding addresses and name
    PIDENTIFIER //x
    {
        if(symbolTable.getSymbol($1->pid) == nullptr) yyerror(("Variable \"" + std::string($1->pid) + "\" not declared").c_str());
        $$ = new VariableInfo();
        $$->name = $1->pid;
        $$->memory_address = symbolTable.getAddressVar($1->pid);
        $$->is_array_ref = false;
    }
    | PIDENTIFIER LBRACKET PIDENTIFIER RBRACKET //arr[x]
    {
        Symbol* arr = symbolTable.getSymbol($1->pid);
        if(arr == nullptr) yyerror(("Array \""+ std::string($1->pid) + "\" not declared").c_str());
        if(arr->is_array == 0) yyerror("Cannot access variable at index");

        Symbol* var = symbolTable.getSymbol($3->pid);
        if(var == nullptr) yyerror(("Variable \""+ std::string($3->pid) + "\" not declared").c_str());
        if(var->is_array == 1) yyerror("Cannot access array with another array");
        if(var->is_initialized == 0) yyerror("Cannot access array with an uninitialized variable");

        $$ = new VariableInfo();
        $$->name = $1->pid;
        $$->memory_address = arr->memory_address; // Adres bazowy tablicy
        $$->is_array_ref = true;
        $$->offset_or_addr = var->memory_address; // Adres zmiennej x
        $$->arr_start = arr->array_start;
    }
    | PIDENTIFIER LBRACKET NUM RBRACKET //arr[5]
    {
        Symbol* sym = symbolTable.getSymbol($1->pid);
        if(sym == nullptr) yyerror("Array not declared");
        if(sym->is_array == 0) yyerror("Cannot access variable at index");
        long long start = sym->array_start;
        long long end = sym->array_end;
        
        if ($3 < start || $3 > end) yyerror("Array index out of bounds");
        
        $$ = new VariableInfo();
        $$->name = $1->pid;
        $$->memory_address = sym->memory_address + ($3 - start);
        $$->is_array_ref = false;
    }
    ;

%%

/* Funkcja obsługi błędów */
void yyerror(char const *s) {
    std::cerr << "Error on line " << yylineno << ": " << s << std::endl;
    exit(-1);
}

void parse_code( std::vector< std::string > & code, FILE * data ) 
{
    cout << "Compiling..." << endl;
    codeGen.setCode(code);
    yyset_in( data );
    //extern int yydebug;
    //yydebug = 1; 
    yyparse();
    codeGen.backpatchAllCheck();
    symbolTable.leaveScope();
}