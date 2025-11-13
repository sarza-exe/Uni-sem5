%{
#include <stdio.h>
#include <stdbool.h>
bool docs = false;
%}

%%
\"([^\"\\\n]|(\\\")|(\\\n)|(\\))*\" {printf("%s", yytext);}          /*strings with \ line continuation */
"/**"[^\n]*(\n[ ]"*"[^\n]*)*\n?"*/" {if(docs) printf("%s", yytext);} /*block starts with /**, every new line start with " *" and last one is */
"/*!"[^\n]*(\n[ ]"*"[^\n]*)*\n?"*/" {if(docs) printf("%s", yytext);} /*block starts with /*!, every new line start with " *" and last one is */
("///"[^\n]*\n)+"///"[^\n]*\n?      {if(docs) printf("%s", yytext);} /*block of at least two C++ comment lines, where each line starts with /// */
("//!"[^\n]*\n)+"//!"[^\n]*\n?      {if(docs) printf("%s", yytext);} /*block of at least two C++ comment lines, where each line starts with //! */
"//".*                              {}
"/*"([^*]|\*+[^*/])*\*+"/"          {}
%%

int yywrap(){}
int main(int argc, char **argv)
{
    ++argv, --argc;
    if(argc > 0){
        if(argc > 1) docs = true;
        yyin = fopen(argv[0], "r");
    }
    else
        yyin = stdin;
    yylex();
}