%{
    #include <stdio.h>
    #include <string.h>
    int yylex();
    void yyerror(char*);
    #define P 1234577

    char buffer[4096] = ""; /* Bufor na wyrażenie postfiksowe */

    void append_str(const char *s) {
        strcat(buffer, s);
    }

    void append_num(long long n) {
        char temp[64];
        sprintf(temp, "%lld ", n);
        strcat(buffer, temp);
    }

    void clear_buffer() {
        buffer[0] = '\0';
    }

    long long modulo(long long a) {
        long long res = a % P;
        if (res < 0) res += P;
        return res;
    }

    long long ppower(long long base, long long exp) { //base^exp
        base = modulo(base);
        if(base == 0) return 0;

        long long phi = P-1; // dzialania w wykladniku modulo P-1
        exp = exp % phi;
        if(exp < 0) exp += phi;

        long long out = 1;
        while (exp > 0) {
            if (exp % 2 == 1) out = (out * base) % P;
            base = (base * base) % P;
            exp /= 2;
        }
        return out;
    }
    long long pdiv(long long a, long long b){
        if (b == 0) yyerror("Dividing by 0!");
        return modulo(a*ppower(b,P-2));
    }
%}
%union{
    char op;
    long long number;
}
%type <number> expr;
%start input;
%token <number> num;
%token COMMENT;
%token EOL;
%token ERR; // nieuzywany, lex zwraca gdy dostaje cos niepoprawnego
%left '+' '-';
%left '*' '/';
%nonassoc '^';
%nonassoc UMINUS; //Negacja liczby (np. -5) ma najwyższy priorytet 
%%
input: | input line;
line: expr EOL {
        printf("%s", buffer);
        printf("\nWynik: %lld\n", modulo($1));
        clear_buffer();} |
    com EOL {} |
    error EOL {
        yyerrok;
        clear_buffer();} |
    EOL {
        clear_buffer();
        printf("\n");};
com : COMMENT {};
/*
przechowujemy liczby ujemne jako liczby ujemne aby przy potęgowaniu robić działania na mod P-1
Używamy buffora by w razie wykrycia błędu nie drukować części wyrażenia postfiksowego, a jedynie wypisać error.
%left to łączność lewostronna, '+' i '-' są powyżej '*' i '/' więc mają mniejszy priorytet
%prec UMINUS: '-' przy -1 ma wyższy priorytet niż minus przy 2 - 1
%nonassoc '^' znaczy że nie ma łączności czy możemy zrobić a^b ale nie a^b^c bo parser nie może łączyć w lewo ani w prawo.
a*b+c. mamy stos [a '*' b] i parser widzi '+' ale '*' ma większy priorytet więc mnożymy i mamy [ab '+' c]
*/
expr :
    '-' num {  // wywołuje warning reduce confilicts z '-' expr
        long long val = modulo((-1)*$2);
        append_num(val);
        $$ = (-1)*$2;} |
    num { 
        append_num(modulo($1));
        $$ = $1;} |
    expr '+' expr {
        append_str("+ ");
        $$ = modulo($1+$3);} |
    expr '-' expr {
        append_str("- ");
        $$ = modulo($1-$3);} |
    expr '*' expr {
        append_str("* ");
        $$ = modulo($1*$3);} |
    expr '/' expr {
        append_str("/ ");
        $$ = pdiv(modulo($1), modulo($3));} |
    expr '^' expr {
        append_str("^ ");
        $$ = ppower(modulo($1), $3);}|
    '-' expr %prec UMINUS {
        append_str("-");
        $$ = (-1)*$2;} |
    '(' expr ')' {$$ = $2;}
;
%%

void yyerror(char *s){
    printf("Error. %s\n", s);
}
int main(){
    yyparse();
    return 0;
}