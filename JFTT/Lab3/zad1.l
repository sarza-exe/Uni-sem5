%option noyywrap
%{
    #include <string.h>
    #include "zad1_y.h"  
%}

%%
[ \t] {}
[ \t]*"#".*(\\\n.*)? {return COMMENT;}
[0-9]+ {yylval.number = atoll(yytext); return num;}
"+" { return '+';}
"-" { return '-';}
"^" { return '^';}
"/" { return '/';}
"*" { return '*';}
"(" { return '(';}
")" { return ')';}
\\\n {}
\n  { return EOL;}
.   { return ERR;}
%%