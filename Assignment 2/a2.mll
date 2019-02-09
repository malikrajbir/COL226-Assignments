{
    type token =
    | INT of int
    | ABS | NOT | DEF
    | ADD | SUB | MULT | DIV | MOD | EXP
    | LEFTBRAC | RIGHTBRAC
    | TRUE | FALSE
    | AND | OR
    | CMP of string
    | IFTE of string
    | ID of string
    | EOC
    | NOT_IN_LANG;;

    exception UNRECOGNISED of char;;
}

(* PREDEFINED REGEX *)

let sp = [' ' '\t']+        (* SPACE *)

let digit = ['0'-'9']               (* INTEGERS *)
let integer = ['1'-'9']digit*

let cond = ("if"|"else"|"then")         (* IF THEN ELSE *)

let eq = ['=']
let gl = ['>' '<']                 (* COMPARISON *)
let cmp = (eq|(gl(eq?)))

let binc = ['+' '-' '*' '^']
let bino = ("div"|"mod")          (* BINARY ARITHMETIC *)
let binops = (binc|bino)

let small = ['a'-'z']
let caps = ['A'-'Z']           (* ID STRING *)
let id = small (small|caps)*


(* READ FUNCTION PARSER *)

rule read = parse
       | sp {read lexbuf}

       | 'T' {TRUE :: (read lexbuf)} | 'F' {FALSE :: (read lexbuf)}     (* TRUE AND FALSE BOOLEAN *)

       | integer as i {INT(int_of_string i) :: (read lexbuf)}           (* INTEGER TYPE *)

       | '(' {LEFTBRAC :: (read lexbuf)} | ')' {RIGHTBRAC :: (read lexbuf)}     (* PARENTHESIS *)

       | binops as b {(read_binops (Lexing.from_string b)) :: (read lexbuf)}    (* BINARY ARITHMETIC OPERATIONS *)

       | "not" {NOT :: (read lexbuf)}
       | "abs" {ABS :: (read lexbuf)}           (* SINGLE WORK KEYWORDS *)
       | "def" {DEF :: (read lexbuf)}

       | "\\/" {OR :: (read lexbuf)} | "/\\" {AND :: (read lexbuf)}     (* AND-OR BINARY BOOLEAN OPERATIONS *)

       | ';' {EOC :: (read lexbuf)}              (* END OF COMMAND *)

       | cond as c {IFTE(c) :: (read lexbuf)}           (* IF THEN ELSE STATEMENTS *)

       | cmp as cp {CMP(cp) :: (read lexbuf)}           (* COMPARISON OPERATIONS *)

       | id as d {ID(d) :: (read lexbuf)}               (* ID STRINGS *)

       | eof {[]}                               (* END OF BUFFER *)

       | _ as w {raise (UNRECOGNISED(w))}          (* CHARACTERS THAT ARE NOT IN THE LANGUAGE *)

and read_binops = parse
                | '+' {ADD}
                | '-' {SUB}             (* SIDE FUNCTION FOR CLASSIFYING BINARY ARITHMETIC OPERATIONS *)
                | '*' {MULT}
                | "div" {DIV}
                | "mod" {MOD}
                | '^' {EXP}


{
    let lex s = read (Lexing.from_string s)         (* LEXER FUNCTION *)
}
