:- use_module(library(rologp)).
:- use_module(library(interval)).

interval:int(Expr, Res),
    compound(Expr),
    compound_name_arity(Expr, Name, Arity),
    rmono(Name/Arity, Signs)
 => compound_name_arguments(Expr, Name, Args),
    findall(R,
        (   maplist(lower, Signs, Args, Lower),
            compound_name_arguments(LowerExpr, Name, Lower),
            r_eval(LowerExpr, R)
        ), Ls),
    min_list(Ls, L),
    findall(R,
        (   maplist(upper, Signs, Args, Upper),
            compound_name_arguments(UpperExpr, Name, Upper),
            r_eval(UpperExpr, R)
        ), Us),
    max_list(Us, U),
    Res = L...U.

rmono(pbinom/3, [/, /, +]).
