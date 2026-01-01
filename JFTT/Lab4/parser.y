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
    long long memory_address; // Adres w pamięci maszyny
    bool is_array_ref;        // Czy to referencja do tablicy przez zmienną?
    long long offset_or_addr; // Adres zmiennej indeksującej (dla arr[x])
    long long arr_start;
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


%}

//%debug
%define parse.error verbose

/* Definicja typów danych przekazywanych między regułami */
%union {
    long long num;       /* Dla liczb (64-bit)  */
    Identifier *id;
    VariableInfo *var_info;
    /* Tutaj w przyszłości dodasz wskaźniki na węzły AST */
}


%token <num> NUM
%token <id> PIDENTIFIER

%type <var_info> identifier

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

procedures:
    procedures PROCEDURE proc_head IS declarations IN commands END
    | procedures PROCEDURE proc_head IS IN commands END
    | %empty
    ;

proc_head:
    PIDENTIFIER LPAREN args_decl RPAREN;

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

main:
    PROGRAM IS declarations IN commands END
    | PROGRAM IS IN commands END
    | ERROR         { yyerror(""); }
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

command:
    identifier ASSIGN expression SEMICOLON 
    | IF condition THEN commands ELSE commands ENDIF
    | IF condition THEN commands ENDIF 
    | WHILE condition DO commands ENDWHILE 
    | REPEAT commands UNTIL condition SEMICOLON 
    | FOR PIDENTIFIER FROM value TO value DO commands ENDFOR 
    | FOR PIDENTIFIER FROM value DOWNTO value DO commands ENDFOR 
    | proc_call SEMICOLON 
    | READ identifier SEMICOLON
    {
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
                codeGen.generate_constant("b", net_offset); 
                codeGen.emit("ADD b"); // ra = ra + rb 
            } else if (net_offset < 0) {
                codeGen.generate_constant("b", -net_offset);
                codeGen.emit("SUB b"); // ra = max(ra - rb, 0) 
            }
            
            codeGen.emit("SWP b"); // teraz rb zawiera adres
            codeGen.emit("READ"); // Wczytaj liczbę do ra
            codeGen.emit("RSTORE b"); // Zapisz ra do adresu wskazanego przez rb
        }
        
        delete info;
    }
    | WRITE value SEMICOLON                          /* Wypisywanie */
    ;

proc_call:
    PIDENTIFIER LPAREN args RPAREN
    ;

args:
    args COMMA PIDENTIFIER
    | PIDENTIFIER
    ;

expression:
    value PLUS value
    | value MINUS value
    | value MULT value
    | value DIV value
    | value MOD value
    | value
    ;

condition:
    value EQ value
    | value NEQ value
    | value GT value
    | value LT value
    | value GE value
    | value LE value
    ;

value:
    NUM
    | identifier
    ;

identifier:
    PIDENTIFIER //x
    {
        $$ = new VariableInfo();
        $$->memory_address = symbolTable.getAddressVar($1->pid);
        $$->is_array_ref = false;
        symbolTable.markInitialized($1->pid);
    }
    | PIDENTIFIER LBRACKET PIDENTIFIER RBRACKET //arr[x]
    {
        Symbol* arr = symbolTable.getSymbol($1->pid);
        if(arr == nullptr) yyerror(("Array "+ std::string($1->pid) + " not declared").c_str());
        if(arr->is_array == 0) yyerror("Cannot access variable at index");

        Symbol* var = symbolTable.getSymbol($3->pid);
        if(var == nullptr) yyerror(("Variable "+ std::string($3->pid) + " not declared").c_str());
        if(var->is_array == 1) yyerror("Cannot access array with another array");
        if(var->is_initialized == 0) yyerror("Cannot access array with an uninitialized variable");

        $$ = new VariableInfo();
        $$->memory_address = arr->memory_address; // Adres bazowy tablicy
        $$->is_array_ref = true;
        $$->offset_or_addr = var->memory_address; // Adres zmiennej x
        $$->arr_start = arr->array_start;
        symbolTable.markInitialized($1->pid);
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
        $$->memory_address = sym->memory_address + ($3 - start);
        $$->is_array_ref = false;
        symbolTable.markInitialized($1->pid);
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
  symbolTable.leaveScope();
}