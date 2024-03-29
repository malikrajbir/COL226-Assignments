

(* BigInteger package for Ocaml... *)
(* Rajbir Malik (Github : jaymalk) *)


(* ======================================== *)
(* Declaring the types *)
type sign = Neg | NonNeg ;;
type bigint = sign * int list;;

(* Product of signs *)
let sp (s1 : sign) (s2 : sign) = match (s1 == s2) with
    true -> NonNeg
  | false -> Neg;;

(* Constructor of bigint *)
let bigintmake (s : sign) (l : int list) : bigint = (s, l);;

(* ---------------------------------------- *)
(* HELPER FUNCTIONS FOR OPERATIONS WITH INT LISTS *)

(* Negate all ints in a list *)
let minus_list (l : int list) = List.map ( fun x -> (-x) ) l;;

(* Get the int list component of big int *)
let dig_list (a : int) =
  let rec make_int_list (a:int) (l:int list) = if a == 0 then l else make_int_list (a/10) ((a mod 10) :: l)
  in make_int_list a [];;

(* Helper function for comparing int lists *)
let larger_list l1 l2 =
  let len1 = List.length l1 and
  len2 = List.length l2
  in match (len1 + (-len2)) with
    0 ->
    let rec compare_values l1 l2 = match (l1, l2) with
        ([], []) -> false
      |(x::xs, y::ys) -> if (x > y) then true else if (x < y) then false else (compare_values xs ys)
      | _ -> false
    in compare_values l1 l2
  | _ -> len1 > len2;;


(* ---------------------------------------- *)
(* EXCEPTIONS *)
exception Division_by_zero;;
exception Illegal_argument;;

(* ======================================== *)
(* ARITHMETIC OPERATIONS *)

(* ---------------------------------------- *)
(* Helper functions for Addition and Subtraction *)

(* Carry propogator *)
let propogate_carry (l : int list) =
  let rec spread_constant c l' = match (c >= 10) with
      true -> spread_constant (c/10) ((c mod 10)::l')
    | false -> c::l'
  in
  let rec rev_propogate l l' c = match l with
      [] -> if c == 0 then l' else spread_constant c l'
    | hd :: tl -> if hd+c < 0 then rev_propogate tl ((hd+c+10) mod 10::l') (-1)
      else rev_propogate tl (((hd+c) mod 10)::l') ((hd+c)/10)
  in rev_propogate (List.rev l) [] 0;;

(* Removing zeros at the end, if any *)
let rec remove_zeros (l1 : int list) =  match l1 with
    [] -> []
  | x :: xs -> if x != 0 then l1 else (remove_zeros xs);;

(* Simple addition of two int lists *)
(* Gives wrong answer when adding a number with a negative number of bigger magnitude *)
let simple_add l1 l2 = 
    let rec inner_add l1 l2 lsum carry = match (l1, l2) with
        ([], []) -> if carry = 0 then lsum else 1::lsum
        | (x::xs, []) -> if carry = 0 then ((List.rev l1)@lsum) else (let (v, r) = ((x+1)/10, (x+1) mod 10) in inner_add xs [] (r::lsum) v)
        | ([], x::xs) -> inner_add l2 l1 lsum carry
        | (x::xs, y::ys) -> (let (v, r) = ((x+y+carry)/10, (x+y+carry)mod 10) in inner_add xs ys (r::lsum) v)
    in inner_add (List.rev l1) (List.rev l2) [] 0
    ;;

(* Simple subtraction which subtracts and gives a bigint *)
let simple_subtract (l1 : int list) (l2 : int list) : bigint = match (larger_list l1 l2 || l1=l2) with
    true -> (NonNeg, remove_zeros(propogate_carry(simple_add l1 (minus_list l2))))
  | false ->(Neg, remove_zeros(propogate_carry(simple_add l2 (minus_list l1))));;

(* ADDITION *)
let add (a : bigint) (b : bigint) = match (fst a, fst b) with
    (Neg, Neg) -> (Neg, simple_add (snd a) (snd b))
  | (NonNeg, NonNeg) -> (NonNeg, simple_add (snd a) (snd b))
  | (Neg, NonNeg) -> simple_subtract (snd b) (snd a)
  | (NonNeg, Neg) -> simple_subtract (snd a) (snd b);;

(* UNARY NEGATION *)
let minus (a: bigint) = if (snd a) = [] then (NonNeg, []) else if (fst a) = NonNeg then bigintmake (Neg) (snd a)
  else bigintmake (NonNeg) (snd a);;

(* SUBTRACTION *)
let sub (a: bigint) (b: bigint) = add (a) (minus b);;

(* ---------------------------------------- *)
(* Helper functions for multiplication and division *)

(* Scalar multiplication of each member by a constant *)
let scalar_mult_list l1 c = match c with
    |0 -> []
    |1 -> l1
    | _ -> propogate_carry(List.map (fun x -> c * x) l1);;


(* Left shift of an int list by appending a list of zeros, of appropriate size *)
let left_shift (l1 : int list) (shift : int) =
  let rec left_rec_shift (l1 : int list) (z : int list) (shift : int) = match shift>0 with
      false -> l1 @ z
    | _ -> left_rec_shift l1 (0::z) (shift+(-1))
  in left_rec_shift l1 [] shift;;

(* Right shift of an int list by removing the extra elements *)
let right_shift  (l1 : int list) (shift : int) =
  let rec right_rec_shift rev_l1 shift = match shift > 0 with
      false -> rev_l1;
    | _ -> match rev_l1 with
        [] -> []
      | x :: xs -> right_rec_shift xs (shift + (-1))
  in List.rev (right_rec_shift (List.rev l1) shift);;

(* Fast divider that subtracts from higher order to lower order of magnitude.
    Gives a tuple of quotient and remainder.
    Follows the 'sign' same as in ocaml int implementation.
    Throws exception if divisor is zero
*)
let fast_div_rem (l1 : int list) (l2 : int list) =
  if l2 = []  then raise Division_by_zero else
    let rec div_by_shift l1 l2 ld ladd =
    (
        match (ladd, (larger_list l1 l2) || l1=l2) with
        ([], _) -> (ld, l1)
      | (_, true) -> div_by_shift (remove_zeros(propogate_carry(simple_add (l1) (minus_list l2)))) l2 (simple_add ld ladd) ladd
      | (_, false) -> div_by_shift (l1) (right_shift l2 1) (ld) (right_shift ladd 1)
    )
    in
    let len1 = List.length (l1) and
      len2 = List.length (l2) in
    div_by_shift (l1) (left_shift (l2) (len1 - len2)) [] (left_shift [1] (len1 - len2)) ;;

(* MULTIPLICATION *)
let mult (a: bigint) (b: bigint) =
  if (snd a = []) || (snd b = []) then (NonNeg, []) else
    let rec mult_const_add_cache l1 rev_l2 ml cache lev = match rev_l2 with
        [] ->  ml
      | x :: xs -> if (List.mem_assoc x cache) then let xm = (List.assoc x cache) in mult_const_add_cache (l1) (xs) (simple_add ml (left_shift xm lev)) cache (lev+1)
                    else let xm = (scalar_mult_list l1 x) in mult_const_add_cache (l1) (xs) (simple_add ml (left_shift xm lev)) ((x, xm)::cache) (lev+1)
    in if (List.length (snd a)) > (List.length (snd b)) then
    bigintmake (sp (fst a) (fst b)) (mult_const_add_cache (snd a) (List.rev (snd b)) [] [] 0)
    else bigintmake (sp (fst a) (fst b)) (mult_const_add_cache (snd b) (List.rev (snd a)) [] [] 0);;

(* QUOTIENT *)
let div (a : bigint) (b : bigint) =
  if (snd a) = [] then (NonNeg, []) else
    match fst a = fst b with
      true -> bigintmake (NonNeg) (fst (fast_div_rem (snd a) (snd b)))
    | false -> let res = fst (fast_div_rem (snd a) (snd b)) in
      match res with
        [] -> (NonNeg, [])
      | x  -> bigintmake (Neg) (x)
;;

(* REMAINDER *)
let rem (a : bigint) (b : bigint) =
  if (snd a) = [] then (NonNeg, []) else
    match fst a = NonNeg with
      true -> bigintmake (NonNeg) (snd (fast_div_rem (snd a) (snd b)))
    | false -> let res = snd (fast_div_rem (snd a) (snd b)) in
      match res with
        [] -> (NonNeg, [])
      | x  -> bigintmake (Neg) (x)
;;

(* ABSOLUTE VALUE *)
let abs (a: bigint) : bigint = if (fst a) = NonNeg then a
  else bigintmake (NonNeg) (snd a);;


(* ======================================== *)
(* COMPARISON OPERATIONS *)

(* Equal *)
(* Simply used ( = ) implementation for int lists. *)
let eq (a : bigint) (b : bigint) =
  if (snd a = []) then (snd b = []) else
    ((fst a) == (fst b)) && ((snd a) = (snd b));;

(* Greater Than *)
let gt (a : bigint) (b : bigint) = match (fst a, fst b) with
    (NonNeg, Neg) -> true
  |(Neg, NonNeg) -> false
  |(NonNeg, NonNeg)-> larger_list (snd a) (snd b)
  |(Neg, Neg) -> larger_list (snd b) (snd a);;

(* Greater or Equal *)
let geq (a : bigint) (b : bigint) =
  (eq a b) || (gt a b);;

(* Less Than *)
let lt (a : bigint) (b : bigint) =
  (gt b a);;

(* Lesser or Equal *)
let leq (a : bigint) (b : bigint) =
  (geq b a);;

(* ---------------------------------------- *)

(* ======================================== *)
(* CONVERTING TO A STRING *)
let print_num (a : bigint) =
  let rec print_num_list s l = match l with
      [] -> (match s with
          "" -> "0"
        | _ -> s)
    | hd :: tl -> print_num_list (s^string_of_int(hd)) tl
  in if (fst a == Neg) then print_num_list "-" (snd a)
  else print_num_list "" (snd a);;

(* ======================================== *)
(* CONVERTING INT TO BIGINT *)

let mk_big (a : int) :bigint = if a >= 0 then (NonNeg, dig_list a) else (Neg, dig_list (-a)) ;; (* Converting using dig_list *)

(* REVERSE *)
let mk_int (a : bigint) : int =
  let rec mk_from_list a v  = (match a with
        [] -> v
      | x :: xs -> mk_from_list xs (v*10+x))
  in (if fst a = Neg then -(mk_from_list (snd a) 0) else (mk_from_list (snd a) 0))

(* ======================================== *)
(* CONVERTING STRING TO BIGINT *)

let bigint_of_string (a : string) :bigint =
  let rec process_string int_list string ind str_len= match ind < str_len with
      true -> (process_string (((int_of_char (string.[ind])) + (-48))::int_list) string (ind+1) str_len)
    |_ -> int_list
  in
  match a.[0] with
    '-' -> (Neg, remove_zeros (List.rev (process_string [] a 1 (String.length a))))
  | _ -> (NonNeg, remove_zeros (List.rev (process_string [] a 0 (String.length a))))
;;

(* ---------------------------------------- *)
(* ------------------END------------------- *)
(* ---------------------------------------- *)

(* Assignment of operators to values *)
(* Arithmetic Operations *)
let ( +| ) (a : bigint) (b : bigint) = (add a b);;
let ( -| ) (a : bigint) (b : bigint) = (sub a b);;
let ( *| ) (a : bigint) (b : bigint) = (mult a b);;
let ( /| ) (a : bigint) (b : bigint) = (div a b);;
let ( %| ) (a : bigint) (b : bigint) = (rem a b);;
(* Constructor *)
let ( =| ) (a : int) = (mk_big a);;
(* Boolean operations *)
let ( <| ) (a : bigint) (b : bigint) = (lt a b);;
let ( >| ) (a : bigint) (b : bigint) = (gt a b);;
let ( <=| ) (a : bigint) (b : bigint) = (leq a b);;
let ( >=| ) (a : bigint) (b : bigint) = (geq a b);;
let ( ==| ) (a : bigint) (b : bigint) = (eq a b);;