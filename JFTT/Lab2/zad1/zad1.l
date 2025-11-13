/* lex zad1.l 
gcc lex.yy.c 
./a.out test >> out */

%{
    #include <stdio.h>
    int words = 0;
    int lines = 0;
%}

%%
[^" "\t\n]* {printf( "%s", yytext ); words++;} /*liczy słowa*/
^[ \t\n]+   {} /*usuwa ciągi spacji i tabulatorów na początku lini oraz usuwa puste linie*/
([ \t]+)$   {} /*usuwa ciągi spacji i tabulatorów na końcu lini oraz usuwa puste linie*/
[ \t]+      {printf(" ");} /*zamienia ciągi spacji i tab na jedną spacje*/
\n          {printf("\n"); lines++;}
%%


int yywrap(){}
int main( int argc, char **argv )
{
    ++argv, --argc;
    if ( argc > 0 )
        yyin = fopen( argv[0], "r" );
    else
        yyin = stdin;
     
    yylex();
    printf("words: %d\n", words);
    printf("lines: %d\n", lines);
}
