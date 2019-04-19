open Bigint
exception Not_implemented

(* Self defined exceptions *)
exception Bad_State (* To be raised when an undesired state has been reached *)
exception Not_Found of string (* To be raised when a literal is not present in the table *)
exception TupleSizeMismatch (* To be raised when the size of projection and tuple doesnt match *)
exception Read_Definition (* To be raised when definition is to be parsed instead of expression *)
exception BadStack (* To be raised when the stack contents are not as desired *)

(* abstract syntax *)
type  exptree =
  V of string (* variables starting with a Capital letter, represented as alphanumeric strings with underscores (_) and apostrophes (') *)
  | Integer of int      (* Integer constant *)
  | Bool of bool     (* Boolean constant *)
  (* unary operators on integers *)
  | Abs of exptree                   (* abs *)
  | Negative of exptree              (* unary minus ~ *)
  (* unary operators on booleans *)
  | Not of exptree
  (* binary operators on integers *)
  | Plus of exptree * exptree        (* Addition + *)
  | Minus of exptree * exptree       (* Subtraction - *)
  | Mult of exptree * exptree        (* Multiplication * *)
  | Div of exptree * exptree         (* Division *)
  | Rem of exptree * exptree         (* Modulo *)
  (* binary operators on booleans *)
  | And of exptree * exptree         (* conjunction /\ *)
  | Or of exptree * exptree          (* binary operators on booleans \/ *)
  (* comparison operations on integers *)
  | Cmp of exptree
  | Equals of exptree * exptree      (* = *)
  | GreaterTE of exptree * exptree   (* >= *)
  | LessTE of exptree * exptree      (* <= *)
  | GreaterT of exptree * exptree    (* > *)
  | LessT of exptree * exptree       (* < *)
  (* expressions using parenthesis *)
  | InParen of exptree               (* ( ) *)
  (* a conditional expression *)
  | If_Then_Else of exptree * exptree * exptree (* if then else fi  *)
  (* creating n-tuples (n >= 0) *)
  | Tuple of int * (exptree list)
  (* projecting the i-th component of an expression (which evaluates to an n-tuple, and 1 <= i <= n) *)
  | Project of (int*int) * exptree   (* Proj((i,n), e)  0 < i <= n *)
  | Let of definition * exptree
  (* | FunctionAbstraction of string * exptree *)
  | App of exptree * exptree
  (* Recursive Function Abstraction *)
  | RecFuncAbs of string * string * exptree
  (* New Function Abstraction (A4 extension) *)
  | Lambda of string * exptree
  (* For additional handeling in interpreter *)
  | Watch
  | Null
  | Exit
(* definition *)
and definition =
    (* Simple of string * exptree *)
  | SimpleType of string * exptree
  | Sequence of (definition list)
  | Parallel of (definition list)
  | Local of definition * definition
  (* While Loop *)
  | While of exptree * definition
  ;;


(* ================================================ *)
(* SIMPLE EVALUATOR (DEFINITIONAL) *)
(* ================================================ *)

(* The type of value returned by the definitional interpreter. *)
type value = NumVal of int | BoolVal of bool | TupVal of int * (value list)
           | Func of (((string* value) list) * string * exptree) | RecFunc of (((string* value) list) * string * string * exptree)
           | NullVal | WatchVal | ExitVal

(* Functions related to tables *)
let rec find_in_table (table : (string * value) list) (s : string) = match table with
[] -> raise (Not_Found s)
| d :: ds -> if (fst d) = s then (d) else (find_in_table ds s)
;;

let rec find_mapping (table : (string * value) list) (s : string) =
  snd (find_in_table table s);;


(* DEFINITIONAL INTERPRETER *)
let rec eval (ex : exptree) (rho : (string * value) list) =
  let rec calc e = match e with
    (* Basics *)
    | V(st) -> ((find_mapping rho) st)
    | Integer(x) -> NumVal(x)
    | Bool(b) -> BoolVal(b)
    (* Unary operations : Integers *)
    | Abs(e) ->      (match (calc e) with | NumVal(bn) -> NumVal(if bn < 0 then -bn else bn)   | _ -> raise Bad_State)
    | Negative(e) -> (match (calc e) with | NumVal(bn) -> NumVal(- bn) | _ -> raise Bad_State)
    (* Unary operations : Bool *)
    | Not(e) -> (match (calc e) with | BoolVal(b) -> BoolVal(not b) | _ -> raise Bad_State)
    (* Binary operations : Integers *)
    | Plus(e1, e2)  ->  (match ((calc e1), (calc e2)) with | (NumVal(x1), NumVal(x2)) -> NumVal(x1 + x2)  | _ -> raise Bad_State)
    | Minus(e1, e2)  -> (match ((calc e1), (calc e2)) with | (NumVal(x1), NumVal(x2)) -> NumVal(x1 - x2)  | _ -> raise Bad_State)
    | Mult(e1, e2) ->   (match ((calc e1), (calc e2)) with | (NumVal(x1), NumVal(x2)) -> NumVal(x1 * x2) | _ -> raise Bad_State)
    | Div(e1, e2)  ->   (match ((calc e1), (calc e2)) with | (NumVal(x1), NumVal(x2)) -> NumVal(x1 / x2)  | _ -> raise Bad_State)
    | Rem(e1, e2)  ->   (match ((calc e1), (calc e2)) with | (NumVal(x1), NumVal(x2)) -> NumVal(x1 mod x2)  | _ -> raise Bad_State)
    (* Binary operations : Bool *)
    | And(e1, e2) -> (match ((calc e1), (calc e2)) with | (BoolVal(b1), BoolVal(b2)) -> BoolVal(b1 && b2) | _ -> raise Bad_State)
    | Or(e1, e2) ->  (match ((calc e1), (calc e2)) with | (BoolVal(b1), BoolVal(b2)) -> BoolVal(b1 || b2) | _ -> raise Bad_State)
    (* Comparison operations *)
    | Cmp(e) -> (match (calc e) with | NumVal(x) -> BoolVal(x>0) | _ -> raise Bad_State)
    | Equals(e1, e2) ->    (match ((calc e1), (calc e2)) with | (NumVal(x1), NumVal(x2)) -> BoolVal(x1 = x2)  | _ -> raise Bad_State)
    | GreaterTE(e1, e2) -> (match ((calc e1), (calc e2)) with | (NumVal(x1), NumVal(x2)) -> BoolVal(x1 >= x2) | _ -> raise Bad_State)
    | LessTE(e1, e2) ->    (match ((calc e1), (calc e2)) with | (NumVal(x1), NumVal(x2)) -> BoolVal(x1 <= x2) | _ -> raise Bad_State)
    | GreaterT(e1, e2) ->  (match ((calc e1), (calc e2)) with | (NumVal(x1), NumVal(x2)) -> BoolVal(x1 > x2)  | _ -> raise Bad_State)
    | LessT(e1, e2) ->     (match ((calc e1), (calc e2)) with | (NumVal(x1), NumVal(x2)) -> BoolVal(x1 < x2)  | _ -> raise Bad_State)
    (* Parenthesis *)
    | InParen(e) -> (calc e)
    (* Conditional *)
    | If_Then_Else(e1, e2, e3) -> (match (calc e1) with |BoolVal(b) -> (if b then (calc e2) else (calc e3)) | _ -> raise Bad_State)
    (* Creating N-Tuple *)
    | Tuple(n, el) -> TupVal(n, List.map calc el)
    (* Projecting a component of the tuple *)
    | Project((i, n), e) -> (match (calc e) with | TupVal(m, al) -> if not (m == n) then (raise TupleSizeMismatch) else ((List.nth al (i-1))) | _ -> raise Bad_State)
    (* Let statements in expressions *)
    | Let(d, e) -> (eval e ( (extension rho d) @ (rho)))
    (* Function Abstraction *)
    | Lambda(st, e1) -> Func(rho, st, e1)
    (* Recursive Function Abstraction *)
    | RecFuncAbs(nm, st, e1) -> RecFunc(rho, nm, st, e1)
    (* Function Call *)
    | App(e1, e2) -> (match (calc e1) with
          Func(tab, s, fex) -> (eval fex ((s, calc e2)::tab))
        | RecFunc(tab, nm, s, fex) -> (eval fex (List.sort_uniq compare ((nm, RecFunc(tab, nm, s, fex))::(s, calc e2)::tab)))
        | _ -> raise Bad_State)
    (* Handle commands *)
    | Null -> NullVal
    | Watch -> WatchVal
    | Exit -> ExitVal
    (* All possible steps covered above, stage below should not be reached *)
    (* | _ -> (raise Bad_State) *)
  in calc ex
(* Extension from definitions to rho *)
and extension (table : (string * value) list) (d : definition) = match d with
    | SimpleType(st, ex) -> [(st, eval ex table)]
    | Sequence(dl) -> (let rec seq_ex (tab_o) (dl) (tab_n) = match dl with
                [] -> tab_n
                | d :: ds -> seq_ex (tab_o) (ds) ((extension (tab_n@tab_o) d)@tab_n)
                in seq_ex table dl [])
    | Parallel(dl) -> (List.flatten (List.map (extension table) dl))
    | Local(d1, d2) -> extension ((extension table d1)@table) d2
    (* While Loop *)
    | While(e, d) -> (match (eval e table) with BoolVal true -> (extension ((extension table d)@table) d)| BoolVal false -> table| _ -> raise Bad_State)
;;

(* KRIVINE MACHINE SETUP *)
(* Krivine Operational Codes *)
type precode = INT of int | VR of string | BOOL of bool | NULL | EXT
| ABSO of precode list | NEGA of precode list
| ADD of (precode list) * (precode list) | SUB of (precode list) * (precode list) | DVD of (precode list) * (precode list) | MUL of (precode list) * (precode list) | MOD of (precode list) * (precode list)
| NT of precode list | AND of (precode list) * (precode list) | OR of (precode list) * (precode list) 
| CMPE of (precode list) | EQ | GTNE | LTNE | GTN | LTN
| CONDI of (precode list) * (precode list) | LETK of precode * (precode list) | RETK
| LAM of string * (precode list) | RLAM of string * string * (precode list) | APP of (precode list)
| DF of string * (precode list)


(* ================================================ *)
(* SECD MACHINE *)
(* ================================================ *)

(* Opcodes for compilation *)
type opcode = VAR of string | N of int | B of bool | ABS | UNARYMINUS | NOT
  | PLUS | MINUS | MULT | DIV | REM | CONJ | DISJ | CMP | EQS | GTE | LTE | GT | LT
  | PAREN | COND of (opcode list * opcode list) | TUPLE of int | PROJ of int*int 
  | LET of (opcode list) * (opcode list) 
  | CLOS of string * (opcode list) | RCLOS of string * string * (opcode list) | APP | RET | SET | DEFRET
  | DEF of string | SEQCOMPOSE of (opcode list) | PARCOMPOSE of (opcode list) | LOCALDEF of (opcode)*(opcode) | WHILE of (opcode list)*(opcode list)
  | EXIT | WATCH | NULL

(* OPCODE CONVERTER FOR SECD *)
let rec compile (ex : exptree) : opcode list = match ex with
    | Integer(x) -> [N(x)]
    | V(x) -> [VAR(x)]
    | Bool(b) -> [B(b)]
    (* Unary operations : Integers *)
    | Abs(x) ->      (compile x) @ [ABS]
    | Negative(x) -> (compile x) @ [UNARYMINUS]
    (* Unary operations : Bool *)
    | Not(e1) ->      (compile e1) @ [NOT]
    (* Binary operations : Integers *)
    | Plus(e1, e2)  ->   (compile e1) @ (compile e2) @ [PLUS]
    | Minus(e1, e2) ->   (compile e1) @ (compile e2) @ [MINUS]
    | Mult(e1, e2)  ->   (compile e1) @ (compile e2) @ [MULT]
    | Div(e1, e2)   ->   (compile e1) @ (compile e2) @ [DIV]
    | Rem(e1, e2)   ->   (compile e1) @ (compile e2) @ [REM]
    (* Binary operations : Bool *)
    | And(e1, e2) -> (compile e1) @ (compile e2) @ [CONJ]
    | Or(e1, e2) ->  (compile e1) @ (compile e2) @ [DISJ]
    (* Comparison operations *)
    | Cmp(e1) -> (compile e1) @ [CMP]
    | Equals(e1, e2) ->    (compile e1) @ (compile e2) @ [EQS]
    | GreaterTE(e1, e2) -> (compile e1) @ (compile e2) @ [GTE]
    | LessTE(e1, e2) ->    (compile e1) @ (compile e2) @ [LTE]
    | GreaterT(e1, e2) ->  (compile e1) @ (compile e2) @ [GT]
    | LessT(e1, e2) ->     (compile e1) @ (compile e2) @ [LT]
    (* Parenthesis *)
    | InParen(e) -> (compile e) @ [PAREN]
    (* Conditional *)
    | If_Then_Else(e1, e2, e3) -> (compile e1) @ [COND((compile e2) , (compile e3))]
    (* Handling N-Tuple *)
    | Tuple(n, el) -> (let rec opcode_list_from_tuple eli l m = match eli with
          [] -> l@[TUPLE(m)]
        | x :: xs -> opcode_list_from_tuple xs (l@(compile x)) m
       in opcode_list_from_tuple el [] n)
    (* Projecting a component of the tuple *)
    | Project((i, n), e) -> (compile e) @ [PROJ(i, n)]
    (* Let statements in expressions *)
    | Let(d, e) -> [LET(def_compile d, compile(e)@[RET])]
    (* Function Abstraction *)
    | Lambda(st, e1) -> [CLOS( st, compile(e1)@[RET])]
    (* Recursive Function Abstraction *)
    | RecFuncAbs(nm, st, e1) -> [RCLOS(nm, st, compile(e1)@[RET])]
    (* Function Call *)
    | App(e1, e2) -> (compile e1) @ (compile e2) @ [APP]
    (* Handle commands *)
    | Null -> [NULL]
    | Watch -> [WATCH]
    | Exit -> [EXIT]
(* OPCODE CONVERTER IN DEFINITIONS *)
and def_compile (df : definition) : opcode list = match df with
    | SimpleType(st, ex) -> ((compile ex) @ [DEF(st)])
    | Sequence(dl) -> (match dl with [] -> [] | d :: ds -> (def_compile d)@(def_compile (Sequence(ds))))
    | While(e, d) -> [WHILE(compile e, def_compile d)]
    | _ -> print_string("Definition not implemented"); raise Not_implemented    
    (* | Parallel(dl) -> PARCOMPOSE(List.map def_compile dl) *)
    (* | Local(d1, d2) -> LOCALDEF(def_compile d1, def_compile d2) *)  

(* ------------------------------------------------------------------------ *)
(* ANSWER, GAMMA and CLOSURE TYPES | FOR SECD MACHINE and KRIVINE MACHINE *)
type answer = Num of int | Bool of bool | Tup of int * (answer list)
and gamma = (string * closure) list
and closure = VCL of (answer * gamma) | CL of (precode list * gamma) | FCL of (string * precode list * gamma) | RFCL of (string * string * precode list * gamma)
            |FunCL of (string * (opcode list) * gamma) | RFunCL of (string * string * (opcode list) * gamma)
(* ------------------------------------------------------------------------ *)


let rec get ((st, gm) : (string * gamma)) = match gm with
[] -> raise (Not_Found(st));
| x :: xs -> if (fst x)=st then (snd x) else get(st, xs)
;; 

(* SECD Operation *)
let rec secd (stack : closure list) (env : gamma) (code : opcode list) (dump : ((closure list)*(gamma)*(opcode list)) list) = match (stack, code) with
(* Evaluation Complete *)
| (stack, []) -> (stack, env)
(* User level opcodes, for interpreter *)
| (stack , EXIT::code') -> exit 0
| (stack , NULL::code') -> (secd stack env code' dump)
(* Basic Value closures *)
| (_, N(x)::code') ->    secd (VCL(Num(x), [])::stack) env code' dump
| (_, VAR(st)::code') -> secd (get(st, env)::stack) env code' dump
| (_, B(b)::code') ->    secd (VCL(Bool(b), [])::stack) env code' dump
(*---------- EXPRESSIONS ----------*)
(* Unary operations : Integers *)
| (VCL(Num(x), e')::stack', ABS::code') ->  secd (VCL(Num(if x<0 then - x else x), e')::stack') env code' dump
| (VCL(Num(x), e')::stack', UNARYMINUS::code') ->  secd (VCL(Num(-x), e')::stack') env code' dump
(* Unary operations : Bool *)
| (VCL(Bool(b), e')::stack', NOT::code') ->  secd (VCL(Bool(not b), e')::stack') env code' dump
(* Binary operations : Integers *)
| (VCL(Num(x1), e')::VCL(Num(x2), e'')::stack', PLUS::code') ->  secd (VCL(Num(x1+x2), e')::stack') env code' dump
| (VCL(Num(x1), e')::VCL(Num(x2), e'')::stack', MINUS::code') ->  secd (VCL(Num(x2-x1), e')::stack') env code' dump
| (VCL(Num(x1), e')::VCL(Num(x2), e'')::stack', MULT::code') ->  secd (VCL(Num(x1*x2), e')::stack') env code' dump
| (VCL(Num(x1), e')::VCL(Num(x2), e'')::stack', DIV::code') ->  secd (VCL(Num(x2/x1), e')::stack') env code' dump
| (VCL(Num(x1), e')::VCL(Num(x2), e'')::stack', REM::code') ->  secd (VCL(Num(x2 mod x1), e')::stack') env code' dump
(* Binary operations : Bool *)
| (VCL(Bool(b1), e')::VCL(Bool(b2), e'')::stack', CONJ::code') ->  secd (VCL(Bool(b1 && b2), e')::stack') env code' dump
| (VCL(Bool(b1), e')::VCL(Bool(b2), e'')::stack', DISJ::code') ->  secd (VCL(Bool(b1 || b2), e')::stack') env code' dump
(* Comparison operations *)
| (VCL(Num(x), e')::stack', CMP::code') ->  secd (VCL(Bool(x>0), e')::stack') env code' dump
| (VCL(Num(x1), e')::VCL(Num(x2), e'')::stack', EQS::code') ->  secd (VCL(Bool(x1=x2), e')::stack') env code' dump
| (VCL(Num(x1), e')::VCL(Num(x2), e'')::stack', GTE::code') ->  secd (VCL(Bool(x2>=x1), e')::stack') env code' dump
| (VCL(Num(x1), e')::VCL(Num(x2), e'')::stack', LTE::code') ->  secd (VCL(Bool(x2<=x1), e')::stack') env code' dump
| (VCL(Num(x1), e')::VCL(Num(x2), e'')::stack', GT::code') ->  secd (VCL(Bool(x2>x1), e')::stack') env code' dump
| (VCL(Num(x1), e')::VCL(Num(x2), e'')::stack', LT::code') ->  secd (VCL(Bool(x1>x2), e')::stack') env code' dump
(* Parenthesis *)
| (st, PAREN::code') -> secd st env code' dump
(* Conditional *)
| (VCL(Bool(b), e')::stack', COND(c1, c2)::code') ->  if b then 
            secd stack' env (c1@code') dump else secd stack' env (c2@code') dump
(* N-tuples *)
| (stack, TUPLE(m)::code') -> (let rec take_out_and_put_back l1 l2 n_org nn = match nn with
  0 -> (VCL(Tup(n_org, l1), [])::l2)
| nn -> (match l2 with
      VCL(x, _) :: xs -> (take_out_and_put_back (x::l1) xs n_org (nn-1))
    | _ -> print_string("Tuple not possible\n");raise Bad_State)
in secd (take_out_and_put_back [] stack m m) env code' dump)
(* Projection *)
| (VCL(Tup(n, al), e')::stack', PROJ(i, m)::code') -> if m=n then secd ((VCL(List.nth al (i-1), e'))::stack') env code' dump else raise TupleSizeMismatch
(* Let statements *)
| (stack, LET(c1, c2)::code') -> secd [] env (c1@c2) ((stack, env, code') :: dump)
(* Function Abstraction *)
| (stack', CLOS(st, c')::code') -> secd (FunCL(st, c', env)::stack') env code' dump
(* Recursive Function Abstraction *)
| (stack', RCLOS(nm, st, c')::code') -> secd (RFunCL(nm, st, c', env)::stack') env code' dump
(* Function Call *)
| (VCL(a1, e')::FunCL(st, c1, e'')::stack', APP::code') -> secd [] ((st, VCL(a1, e'))::e'') c1 ((stack', env, code') :: dump)
(* Recursive Function Call *)
| (VCL(a1, e')::RFunCL(nm, st, c1, e'')::stack', APP::code') -> secd [] ((st, VCL(a1, e'))::(nm, RFunCL(nm, st, c1, e''))::e'') c1 ((stack', env, code') :: dump)
(* RETURN CODE *)
| (vcl :: stack'', RET::code'') -> (match dump with [] -> raise Bad_State | (s, ev, cd)::xs -> secd (vcl::s) ev cd xs)
(*------------ DEFINITIONS ------------*)
(* Simple *)
| (vcl::stack', DEF(st)::code') -> secd stack' ((st, vcl)::env) code' (dump)
(* Sequential and Parallel (NOT SET) *)
(* Local (NOT SET) *)
(* While loop *)
| (stack', WHILE(ce, cd)::code') -> secd stack' env (ce@[COND(cd@[WHILE(ce, cd)], [NULL])]@code') (dump)
| _ -> print_string("Problem : Not Implemented\n"); raise Not_implemented


(* ================================================ *)
(* KRIVINE MACHINE *)
(* ================================================ *)

(* Krivine Compiler *)
let rec krivine_compile (ex : exptree) = match ex with
  (* Handle commands *)
    | Exit -> [EXT]
    | Null -> [NULL]
  (* Basic types *)
    | Integer(x) -> [INT x]
    | V st -> [VR st]
    | Bool b -> [BOOL b]
  (* Unary operations : Integers *)
    | Abs(x) -> [ABSO(krivine_compile x)]
    | Negative(x) -> [NEGA(krivine_compile x)]
  (* Binary operations : Integers *)
    | Plus(x1, x2) -> [ADD(krivine_compile x1, krivine_compile x2)]
    | Minus(x1, x2) -> [SUB(krivine_compile x1, krivine_compile x2)]
    | Mult(x1, x2) -> [MUL(krivine_compile x1, krivine_compile x2)]
    | Div(x1, x2) -> [DVD(krivine_compile x1, krivine_compile x2)]
    | Rem(x1, x2) -> [MOD(krivine_compile x1, krivine_compile x2)]
  (* Unary operations : Bool *)
    | Not(b) -> [NT(krivine_compile b)]
  (* Binary operations : Bool *)
    | Or(b1, b2) -> [OR(krivine_compile b1, krivine_compile b2)]
    | And(b1, b2) -> [AND(krivine_compile b1, krivine_compile b2)]
  (* Comparison operations *)
    | Cmp(x) -> [CMPE(krivine_compile x)]
    | Equals(e1, e2) ->    (krivine_compile e1) @ (krivine_compile e2) @ [EQ]
    | GreaterTE(e1, e2) -> (krivine_compile e1) @ (krivine_compile e2) @ [GTNE]
    | LessTE(e1, e2) ->    (krivine_compile e1) @ (krivine_compile e2) @ [LTNE]
    | GreaterT(e1, e2) ->  (krivine_compile e1) @ (krivine_compile e2) @ [GTN]
    | LessT(e1, e2) ->     (krivine_compile e1) @ (krivine_compile e2) @ [LTN]
  (* Conditional *)
    | If_Then_Else(e1, e2, e3) -> krivine_compile e1 @ [CONDI(krivine_compile e2, krivine_compile e3)]
  (* Parenthesis *)
    | InParen(e) -> (krivine_compile e)
  (* Let statements in expressions *)
    | Let(d, e) -> [LETK(krivine_def_compile d, (krivine_compile e)@[RETK])]
  (* Function Abstraction *)
    | Lambda(st, e1) -> [LAM(st, krivine_compile e1)]
  (* Recursive Function Abstraction *)
    | RecFuncAbs(nm, st, e1) -> [RLAM(nm, st, krivine_compile e1)]
  (* Function Call *)
    | App(e1, e2) -> (krivine_compile e1) @ [APP(krivine_compile e2)]
  (* Categories not implemented *)
    | _ -> raise Not_implemented
(* Definitions compiler *)
and krivine_def_compile (d : definition) = match d with
    | SimpleType(st, e) -> DF(st, krivine_compile e)
    | _ -> raise Not_implemented
;;

(* Krivine Solver *)
let rec krivine (stack : closure list) (env : gamma) (pc : precode list) = match pc with
  (* Higher order precodes, for 4th wall interaction *)
    | EXT :: pc' -> exit 0
    | NULL :: pc' -> (krivine stack env pc')
  (* Process Complete *)
    | [] -> (List.hd stack, env)
    | RETK::pc'  -> (List.hd stack, env)
  (* Basic types *)
    | INT(x) :: pc' -> krivine ((VCL(Num x, env))::stack) env pc'
    | VR(x) :: pc' -> (match get(x, env) with CL(pc, env') -> (let x' = fst (krivine [] env' pc) in krivine (x'::stack) env pc')| _ as x -> krivine (x::stack) env pc')
    | BOOL(b) :: pc' -> krivine (VCL(Bool b, env)::stack) env pc'
  (* Unary operations : Integers *)
    (* Absolute value *)
    | ABSO(e) :: pc' -> (match e with
            | [NULL] -> (match stack with
                            | VCL(Num x, e')::stack' -> krivine (VCL(Num (if x > 0 then x else -x), e')::stack') env pc' 
                            | _ -> raise BadStack)
            | _ -> krivine stack env (e @ [ABSO([NULL])] @ pc') )
    (* Negation *)
    | NEGA(e) :: pc' -> (match e with
            | [NULL] -> (match stack with
                            | VCL(Num x, e')::stack' -> krivine (VCL(Num (-x), e')::stack') env pc' 
                            | _ -> raise BadStack)
            | _ -> krivine stack env (e @ [NEGA([NULL])] @ pc') )
  (* Binary operations : Integers *)
    (* Addition *)
    | ADD(e1, e2) :: pc' ->   (match (e1, e2) with 
            | ([NULL], [NULL]) -> (match stack with 
                            | VCL(Num x2, e')::VCL(Num x1, e'')::stack' -> krivine (VCL(Num (x2+x1), e'')::stack') env pc' 
                            | _ -> raise BadStack)
            | ([NULL], _) -> krivine stack env (e2 @ [ADD([NULL], [NULL])] @ pc') 
            | (_, _) -> krivine stack env (e1 @ [ADD([NULL], e2)] @ pc'))
    (* Subtraction *)
    | SUB(e1, e2) :: pc' ->   (match (e1, e2) with 
            | ([NULL], [NULL]) -> (match stack with 
                            | VCL(Num x2, e')::VCL(Num x1, e'')::stack' -> krivine (VCL(Num (x1 - x2), e'')::stack') env pc' 
                            | _ -> raise BadStack)
            | ([NULL], _) -> krivine stack env (e2 @ [SUB([NULL], [NULL])] @ pc') 
            | (_, _) -> krivine stack env (e1 @ [SUB([NULL], e2)] @ pc'))
    (* Division *)
    | DVD(e1, e2) :: pc' ->   (match (e1, e2) with 
            | ([NULL], [NULL]) -> (match stack with 
                            | VCL(Num x2, e')::VCL(Num x1, e'')::stack' -> krivine (VCL(Num (x1 / x2), e'')::stack') env pc' 
                            | _ -> raise BadStack)
            | ([NULL], _) -> krivine stack env (e2 @ [DVD([NULL], [NULL])] @ pc') 
            | (_, _) -> krivine stack env (e1 @ [DVD([NULL], e2)] @ pc'))
    (* Multiplication *)
    | MUL(e1, e2) :: pc' ->   (match (e1, e2) with 
            | ([NULL], [NULL]) -> (match stack with 
                            | VCL(Num x2, e')::VCL(Num x1, e'')::stack' -> krivine (VCL(Num (x2*x1), e'')::stack') env pc' 
                            | _ -> raise BadStack)
            | ([NULL], _) -> krivine stack env (e2 @ [MUL([NULL], [NULL])] @ pc') 
            | (_, _) -> krivine stack env (e1 @ [MUL([NULL], e2)] @ pc'))
    (* Modulus *)
    | MOD(e1, e2) :: pc' ->   (match (e1, e2) with 
            | ([NULL], [NULL]) -> (match stack with 
                            | VCL(Num x2, e')::VCL(Num x1, e'')::stack' -> krivine (VCL(Num (x1 mod x2), e'')::stack') env pc' 
                            | _ -> raise BadStack)
            | ([NULL], _) -> krivine stack env (e2 @ [MOD([NULL], [NULL])] @ pc') 
            | (_, _) -> krivine stack env (e1 @ [MOD([NULL], e2)] @ pc'))
  (* Unary operations : Bool *)
    | NT(e) :: pc' -> (match e with
            | [NULL] -> (match stack with
                            | VCL(Bool b, e')::stack' -> krivine (VCL(Bool(not b), e')::stack') env pc' 
                            | _ -> raise BadStack)
            | _ -> krivine stack env (e @ [NT([NULL])] @ pc') )
  (* Binary operations : Bool *)
    (* Conjunction *)
    | AND(e1, e2) :: pc'  ->  (match (e1, e2) with 
            | ([NULL], [NULL]) -> (match stack with 
                            | VCL(Bool x2, e')::VCL(Bool x1, e'')::stack' -> krivine (VCL(Bool (x2 && x1), e'')::stack') env pc' 
                            | _ -> raise BadStack)
            | ([NULL], _) -> krivine stack env (e2 @ [AND([NULL], [NULL])] @ pc') 
            | (_, _) -> krivine stack env (e1 @ [AND([NULL], e2)] @ pc'))
    (* Disjunction *)
    | OR(e1, e2) :: pc'  ->  (match (e1, e2) with 
            | ([NULL], [NULL]) -> (match stack with 
                            | VCL(Bool x2, e')::VCL(Bool x1, e'')::stack' -> krivine (VCL(Bool (x2 || x1), e'')::stack') env pc' 
                            | _ -> raise BadStack)
            | ([NULL], _) -> krivine stack env (e2 @ [OR([NULL], [NULL])] @ pc') 
            | (_, _) -> krivine stack env (e1 @ [OR([NULL], e2)] @ pc'))
  (* Comparison Operations *)
    (* Basic CMP *)
    | CMPE(e) :: pc' -> (match e with
            | [NULL] -> (match stack with
                            | VCL(Num x, e')::stack' -> krivine (VCL(Bool (x > 0), e')::stack') env pc' 
                            | _ -> raise BadStack)
            | _ -> krivine stack env (e @ [CMPE([NULL])] @ pc') )
    (* Equal *)
    | EQ :: pc' -> (match stack with 
            | VCL(Num x2, e')::VCL(Num x1, e'')::stack' -> krivine (VCL(Bool (x1 = x2), e')::stack') env pc' 
            | _ -> raise BadStack)
    (* Greater Than *)
    | GTN :: pc' -> (match stack with 
            | VCL(Num x2, e')::VCL(Num x1, e'')::stack' -> krivine (VCL(Bool (x1 > x2), e')::stack') env pc' 
            | _ -> raise BadStack)
    (* Less Than *)
    | LTN :: pc' -> (match stack with 
            | VCL(Num x2, e')::VCL(Num x1, e'')::stack' -> krivine (VCL(Bool (x1 < x2), e')::stack') env pc' 
            | _ -> raise BadStack)
    (* Greater Than Equal *)
    | GTNE :: pc' -> (match stack with 
            | VCL(Num x2, e')::VCL(Num x1, e'')::stack' -> krivine (VCL(Bool (x1 >= x2), e')::stack') env pc' 
            | _ -> raise BadStack)
    (* Less Than Equal *)
    | LTNE :: pc' -> (match stack with 
            | VCL(Num x2, e')::VCL(Num x1, e'')::stack' -> krivine (VCL(Bool (x1 <= x2), e')::stack') env pc' 
            | _ -> raise BadStack)
  (* Conditional *)
    | CONDI(e2, e3) :: pc' -> (match stack with
            | VCL(Bool true, e')::stack' -> krivine stack' env (e2@pc')
            | VCL(Bool false, e'):: stack' -> krivine stack' env (e3@pc')
            | _ -> raise BadStack)
  (* Let condition *)
    | LETK(d, c) :: pc' -> (let x = fst (krivine stack env ([d]@c)) in krivine (x::stack) env pc')
  (* Function Abstraction *)
    | LAM(st, e1) :: pc' -> (krivine (FCL(st, e1, env)::stack) env  pc')
  (* Recursive Function Abstraction *)
    | RLAM(nm, st, e1) :: pc' -> (krivine (RFCL(nm, st, e1, env)::stack) ((nm, RFCL(nm, st, e1, env))::env) pc')
  (* Function Call *)
    | APP(e) :: pc' -> (match stack with 
                        | FCL(st, ex, env')::stack' -> let x = krivine stack' ((st, CL(e, env))::env') (ex) in krivine (fst(x)::stack') env pc'
                        | RFCL(nm, st, ex, env')::stack' -> let x = krivine stack' ((nm, RFCL(nm, st, ex, env'))::(st, CL(e, env))::env') ex in krivine (fst(x)::stack') env pc'
                        | _ -> raise BadStack)
  (* DEFINTIONS *)
    | DF(st, c) :: pc' -> (krivine stack ((st, CL(c, env))::env) pc')
  (* Not Implemented *)
    (* | _ -> raise Not_implemented *)