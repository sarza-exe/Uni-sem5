import ply.lex as lex

tokens = (
   'NUMBER','PLUS','MINUS','TIMES','DIVIDE','POWER',
   'LPAREN','RPAREN','NEWLINE',
)

t_PLUS    = r'\+'
t_MINUS   = r'-'
t_TIMES   = r'\*'
t_DIVIDE  = r'/'
t_POWER   = r'\^'
t_LPAREN  = r'\('
t_RPAREN  = r'\)'
t_ignore  = ' \t'


def t_COMMENT(t):
    r'\#(\\\n|.)*'
    t.lexer.lineno += t.value.count('\n')
    pass

def t_NEWLINE(t):
    r'\n'
    t.lexer.lineno += len(t.value)
    return t

def t_NUMBER(t):
    r'\d+'
    t.value = int(t.value)
    return t

def t_error(t):
    print(f"Nielegalny znak '{t.value[0]}'")
    t.lexer.skip(1)

lexer = lex.lex()