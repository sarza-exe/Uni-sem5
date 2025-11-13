%{
#include <stdio.h>
#include <math.h>
#include <stdbool.h>
#define MAX 512
int stack[MAX];
int sp = 0;

int pop(){
    if(sp == 0){
        printf("Nothing on stack!\n");
        return 0;
    }
    return stack[--sp];
}

bool push(int n){
    if(sp > MAX-1){
        printf("Stack overflow!");
        return false;
    }
    stack[sp++] = n;
    return true;
}

int clearStack(){
    sp = 0;
}

int power(int a, int b){
    if(b == 0) return 1;
    int out = a;
    for (int i = 1; i < b; i++)
        out*=a;
    return out;
}

bool operation(char op){
     /* 5 2 - == 5-2 */
    int b = pop();
    int a = pop();
    switch(op){
        case '+':
            return push(a+b);
        case '-':
            return push(a-b);
        case '/':
            if(b == 0){
                printf("Cannot divide by 0!");
                return false;
            }
            return push(a/b);
        case '*':
            return push(a*b);
        case '%':
            if(b == 0){
                printf("Cannot modulo 0!");
                return false;
            }
            return push(a%b);
        case '^':
            if(b < 0){
                printf("Negative power %d in integer calculator!", b);
                return false;
            }
            return push(power(a,b));
        default:
            printf("Fail on \"%c\"!", op);
            return false;
    }
    return true;
}
%}

%x SKIP

%%
-?[0-9]+    { 
                bool status = push(atoi(yytext));
                if(!status) BEGIN(SKIP);
            }
[ \t]+      {}
"\n"        {
                if (sp == 1)  printf("= %d\n", pop()); 
                else if (sp > 1)printf("Too few operators!\n");
                clearStack();
            }
[\^%\*/\+-] {
                if(sp < 2){
                    printf("Too few arguments!");
                    BEGIN(SKIP);
                } else{
                    bool status = operation(yytext[0]);
                    if(!status) BEGIN(SKIP);
                }
            }
.           {
                printf("Wrong symbol \"%s\"", yytext);
                BEGIN(SKIP);
            }
<SKIP>[^\n]+ { /* consume characters other than newline */ }
<SKIP>\n     { /* newline ends skip. go back to INITIAL */
                  BEGIN(INITIAL);
                  printf("\n");
                  sp = 0;
             }
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