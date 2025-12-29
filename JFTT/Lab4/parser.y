%code requires { 
#include<vector> 
#include <string>

using namespace std;
}

%{
#include <iostream>
#include <string>
#include <vector>

// Deklaracje funkcji zewnętrznych (z Flexa i własnych)
int yylex( void );
void yyset_in( FILE * in_str );
extern int yylineno;
void yyerror(std::vector<std::string> & code, char const *s);

%}

/*%debug*/

%parse-param { std::vector<std::string> & code }


/* Definicja typów danych przekazywanych między regułami */
%union {
    long long num;       /* Dla liczb (64-bit)  */
    char *pid;    /* Dla identyfikatorów (pidentifier) */
    /* Tutaj w przyszłości dodasz wskaźniki na węzły AST */
}


%token <num> NUM
%token <pid> PIDENTIFIER

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
    procedures main
    ;

procedures:
    procedures PROCEDURE proc_head IS declarations IN commands END
    | procedures PROCEDURE proc_head IS IN commands END
    | %empty
    ;

proc_head:
    PIDENTIFIER LPAREN args_decl RPAREN { code.push_back(std::string($1)); free($1); code.push_back("procedure"); };

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
    PROGRAM IS declarations IN commands END { code.push_back("PROGRAM IS declarations IN commands END"); }
    | PROGRAM IS IN commands END { code.push_back("PROGRAM IS IN commands END"); }
    | ERROR         { yyerror( code, "Nierozpoznany symbol" ); }
    ;

declarations:
    declarations COMMA PIDENTIFIER
    | declarations COMMA PIDENTIFIER LBRACKET NUM COLON NUM RBRACKET
    | PIDENTIFIER
    | PIDENTIFIER LBRACKET NUM COLON NUM RBRACKET
    ;

commands:
    commands command
    | command
    ;

command:
    identifier ASSIGN expression SEMICOLON           /* Przypisanie */
    | IF condition THEN commands ELSE commands ENDIF /* Instrukcja warunkowa z ELSE */
    | IF condition THEN commands ENDIF               /* Instrukcja warunkowa bez ELSE */
    | WHILE condition DO commands ENDWHILE           /* Pętla WHILE */
    | REPEAT commands UNTIL condition SEMICOLON      /* Pętla REPEAT [cite: 72] */
    | FOR PIDENTIFIER FROM value TO value DO commands ENDFOR        /* FOR rosnące */
    | FOR PIDENTIFIER FROM value DOWNTO value DO commands ENDFOR    /* FOR malejące */
    | proc_call SEMICOLON                            /* Wywołanie procedury */
    | READ identifier SEMICOLON                      /* Wczytywanie */
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
    PIDENTIFIER
    | PIDENTIFIER LBRACKET PIDENTIFIER RBRACKET  /* Tablica z indeksem zmienną */
    | PIDENTIFIER LBRACKET NUM RBRACKET          /* Tablica z indeksem stałym */
    ;

%%

/* Funkcja obsługi błędów */
void yyerror(std::vector<std::string> & code, char const *s) {
    std::cerr << "Błąd składni w linii " << yylineno << ": " << s << std::endl;
    for (const auto& line : code) {
        cout << line.c_str() << "\n";
    }
    cout << "Yeah\n";
}

void parse_code( std::vector< std::string > & code, FILE * data ) 
{
  cout << "Kompilowanie kodu." << endl;
  yyset_in( data );
  //extern int yydebug;
  //yydebug = 1;
  yyparse( code );
}