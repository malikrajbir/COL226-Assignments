open Structure_a0.A0
open Signature_a1
module A1 : CalculatorLanguage = struct

type  exptree =  N of bigint
              | Plus of exptree * exptree
              | Minus of exptree * exptree
              | Mult of exptree * exptree
              | Div of exptree * exptree
              | Rem of exptree * exptree
              | Nega of exptree
              | Abs of exptree

(* opcodes of the stack machine *)
type opcode = CONST of bigint | PLUS | TIMES | MINUS | DIV | REM | ABS | UNARYMINUS

(* Exceptions *)
exception IllformedStack;;

let eval (e:exptree) =
  let rec calc e = match e with
      N (x) -> x
    | Plus(e1, e2) -> add (calc e1) (calc e2)
    | Minus (e1, e2) -> sub (calc e1) (calc e2)
    | Mult (e1, e2) -> mult (calc e1) (calc e2)
    | Div (e1, e2) -> div (calc e1) (calc e2)
    | Rem (e1, e2) -> rem (calc e1) (calc e2)
    | Nega (e) -> minus (calc e)
    | Abs (e) -> abs (calc e)
  in calc e
;;

let compile (e : exptree) =
  let rec mk_list  e = match e with
      N (x) -> [CONST(x)]
    | Plus(e1, e2) -> (mk_list e1) @ (mk_list e2) @ [PLUS]
    | Minus (e1, e2) -> (mk_list e1) @ (mk_list e2) @ [MINUS]
    | Mult (e1, e2) -> (mk_list e1) @ (mk_list e2) @ [TIMES]
    | Div (e1, e2) -> (mk_list e1) @ (mk_list e2) @ [DIV]
    | Rem (e1, e2) -> (mk_list e1) @ (mk_list e2) @ [REM]
    | Nega (e) -> [UNARYMINUS]
    | Abs (e) -> [ABS]
  in (mk_list e)
;;


  let stackmc (li : bigint list) (lo : opcode list) =
    let perform_action li oc = match oc with
        CONST (x)  -> x :: li
      | PLUS  -> (match li with
          x1 :: x2 :: xs -> (add x1 x2) :: xs
          | _ -> raise IllformedStack)
      | TIMES  -> (match li with
          x1 :: x2 :: xs -> (mult x1 x2) :: xs
          | _ -> raise IllformedStack)
      | MINUS  -> (match li with
          x1 :: x2 :: xs -> (sub x2 x1) :: xs
          | _ -> raise IllformedStack)
      | DIV  -> (match li with
          x1 :: x2 :: xs -> (div x2 x1) :: xs
          | _ -> raise IllformedStack)
      | REM  -> (match li with
          x1 :: x2 :: xs -> (rem x2 x1) :: xs
          | _ -> raise IllformedStack)
      | ABS  -> (match li with
            x :: xs -> (abs x) :: xs
          | _ -> raise IllformedStack)
      | UNARYMINUS  -> (match li with
            x :: xs -> (minus x) :: xs
          | _ -> raise IllformedStack)
  in
    let rec result li lo = match lo with
        [] -> List.hd li
      |x :: xs -> result (perform_action li x) xs
  in result li lo
  ;;

end