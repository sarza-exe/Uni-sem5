%{
#include <stdio.h>    
%}

%%
\"([^\"\\\n]|(\\\\)|(\\\"))*\"          {printf("%s", yytext);}
\'([^\'\\\n]|(\\\\)|(\\\"))*\'          {printf("%s", yytext);}
\"\"\"([^\"\\]|(\\\\)|(\\\"))*\"\"\"    {printf("%s", yytext);}
\'\'\'([^\'\\]|(\\\\)|(\\\'))*\'\'\'    {printf("%s", yytext);}
#.*                                     {}
%%

int yywrap(){}
int main(int argc, char **argv)
{
    ++argv, --argc;
    if(argc > 0)
        yyin = fopen(argv[0], "r");
    else
        yyin = stdin;
    yylex();
}