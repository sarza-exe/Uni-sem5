# source venv/bin/activate
# python3 yacc.py

import ply.yacc as yacc
from lexer import tokens

P = 1234577

class NodeValue:
    def __init__(self, val, is_atom=False):
        self.val = val 
        self.is_atom = is_atom # surowa liczba (true), wynik działania (false)

    def __str__(self):
        return str(self.val)

def gf_mod(n):
    return n % P

def gf_pow(base, exp):
    base = gf_mod(base)
    if base == 0: return 0
    
    phi = P - 1
    exp = exp % phi
    
    return pow(base, exp, P)

def gf_div(a, b):
    b = gf_mod(b)
    if b == 0:
        raise ZeroDivisionError("Dzielenie przez zero w GF")
    inv = pow(b, -1, P)
    return gf_mod(a * inv)

rpn_buffer = []

def append_rpn(text):
    rpn_buffer.append(str(text))

def clear_rpn():
    rpn_buffer.clear()

def fix_exponent_display(raw_exp):
    val_p = gf_mod(raw_exp)
    val_phi = raw_exp % (P-1)
    if val_p == val_phi:
        return
    wrong_str = str(val_p)
    if rpn_buffer and rpn_buffer[-1] == wrong_str:
            rpn_buffer.pop()
            append_rpn(val_phi)

# Definicja priorytetów (od najniższego) 
precedence = (
    ('left', 'PLUS', 'MINUS'),
    ('left', 'TIMES', 'DIVIDE'),
    ('nonassoc', 'POWER'),
    ('right', 'UMINUS'), 
)


def p_input(p):
    '''input : 
             | input line'''
    pass

def p_line(p):
    '''line : NEWLINE
            | expression NEWLINE'''
    if len(p) == 3:
        # wypisz RPN i wynik
        print(f"{' '.join(rpn_buffer)}")
        print(f"Wynik: {gf_mod(p[1].val)}")
    clear_rpn()

def p_line_error(p):
    '''line : error NEWLINE'''
    clear_rpn()
    parser.errok()

def p_expression_binop(p):
    '''expression : expression PLUS expression
                  | expression MINUS expression
                  | expression TIMES expression
                  | expression DIVIDE expression
                  | expression POWER expression'''
    
    val1 = p[1].val
    op = p[2]
    val2 = p[3].val
    
    res = 0
    if op == '+':
        append_rpn("+")
        res = gf_mod(val1 + val2)
    elif op == '-':
        append_rpn("-")
        res = gf_mod(val1 - val2)
    elif op == '*':
        append_rpn("*")
        res = gf_mod(val1 * val2)
    elif op == '/':
        append_rpn("/")
        try:
            res = gf_div(val1, val2)
        except ZeroDivisionError:
            print("Błąd: Dzielenie przez zero!")
    elif op == '^':
        fix_exponent_display(val2)
        append_rpn("^")
        res = gf_pow(val1, val2) 

    p[0] = NodeValue(res, is_atom=False)

def p_expression_uminus(p):
    '''expression : MINUS expression %prec UMINUS'''
    
    child_node = p[2]
    
    if child_node.is_atom:
        # Jeśli trafiliśmy na surową liczbę, to znaczy, że reguła NUMBER właśnie wrzuciła ją do bufora RPN.
        rpn_buffer.pop() # Usuwamy ją z bufora
        visual_val = gf_mod(-child_node.val)
        append_rpn(visual_val)
        p[0] = NodeValue(-child_node.val, is_atom=False)
        
    else:
        append_rpn("NEG")
        p[0] = NodeValue(-child_node.val, is_atom=False)

def p_expression_group(p):
    '''expression : LPAREN expression RPAREN'''
    p[0] = NodeValue(p[2].val, is_atom=False)

def p_expression_number(p):
    '''expression : NUMBER'''
    visual_val = gf_mod(p[1])
    append_rpn(visual_val)
    
    p[0] = NodeValue(p[1], is_atom=True)

def p_error(p):
    print("Błąd składni")



# Budowanie parsera
parser = yacc.yacc()

if __name__ == "__main__":
    print(f"Kalkulator GF({P}) [Python/PLY]. Wpisz wyrażenie.")
    buffer = ""
    while True:
        try:
            line = input()
        except EOFError and KeyboardInterrupt:
            print()
            break
        if not line: continue
        if line.rstrip().endswith('\\'):
            buffer += line.rstrip()[:-1] # zajmujemy sie tutaj line continuation \
            continue
        else:
            buffer += line + '\n'
            parser.parse(buffer)
            buffer = ""
        