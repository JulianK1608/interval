:- module(rint, []).

:- multifile r_hook/1.

:- reexport(interval).
:- reexport(r), r_initialize.

%
% Skip R vectors
%
interval:int_hook_register((:)/2, []).
interval:int_hook(A:B, A:B, _).

%
% Obtain atoms or functions from R
%
interval:eval_hook(Atom, Res) :-
    atomic(Atom),
    r_hook(Atom),
    !,
    r(Atom, Res).

interval:eval_hook(Expr, Res) :-
    compound(Expr),
    compound_name_arity(Expr, Name, Arity),
    r_hook(Name/Arity),
    !,
    r(Expr, Res).

r_hook(true).
r_hook(false).

%
% Binomial distribution
%
interval:int_hook_register(pbinom/4, []).

% lower tail
interval:int_hook(pbinom(X, N, P, true), Res, Opt) :-
    interval(pbinom0(X, N, P), Res, Opt).

r_hook(pbinom0/3).
interval:mono(pbinom0/3, [+, -, -]).

% upper tail
interval:int_hook(pbinom(X, N, P, false), Res, Opt) :-
    interval(pbinom1(X, N, P), Res, Opt).

r_hook(pbinom1/3).
interval:mono(pbinom1/3, [-, +, +]).

%
% Quantile function
%
interval:int_hook_register(qbinom/4, []).

% lower tail
interval:int_hook(qbinom(Alpha, N, P, true), Res, Opt) :-
    interval(qbinom0(Alpha, N, P), Res, Opt).

r_hook(qbinom0/3).
interval:mono(qbinom0/3, [+, +, +]).

% upper tail
interval:int_hook(qbinom(Alpha, N, P, false), Res, Opt) :-
    interval(qbinom1(Alpha, N, P), Res, Opt).

r_hook(qbinom1/3).
interval:mono(qbinom1/3, [-, +, +]).

%
% Density
%
interval:int_hook_register(dbinom/3, []).

% left to X / N
interval:int_hook(dbinom(X1...X2, N1...N2, P1...P2), Res, Opt) :-
    X2 < N1 * P1,
    !,
    interval(dbinom0(X1...X2, N1...N2, P1...P2), Res, Opt).

r_hook(dbinom0/3).
interval:mono(dbinom0/3, [+, -, -]).

% right to X / N
interval:int_hook(dbinom(X1...X2, N1...N2, P1...P2), Res, Opt) :-
    X1 > N2 * P2,
    !,
    interval(dbinom1(X1...X2, N1...N2, P1...P2), Res, Opt).

r_hook(dbinom1/3).
interval:mono(dbinom1/3, [-, +, +]).

% otherwise
interval:int_hook(dbinom(X1...X2, N1...N2, P1...P2), Res, _) :-
    r(dbinom2(X1, X2, N1, N2, P1, P2), #(L, U)),
    Res = L...U.

%
% Normal distribution
%
r_hook(pnorm0/1).
interval:mono(pnorm0/1, [+]).

interval:int_hook_register(pnorm/3, []).
interval:int_hook(pnorm(X, Mu, Sigma), Res, Opt) :-
     interval((X - Mu)/Sigma, Z, Opt),
     interval(pnorm0(Z), Res, Opt).

%
% Quantile function
%
r_hook(qnorm0/1).
interval:mono(qnorm0/1, [+]).

interval:int_hook_register(qnorm/3, []).
interval:int_hook(qnorm(P, Mu, Sigma), Res, Opt) :-
     interval(qnorm0(P), Z, Opt),
     interval(Mu + Z * Sigma, Res, Opt).

%
% Density
%
r_hook(dnorm1/1).
interval:mono(dnorm1/1, [+]).

r_hook(dnorm2/1).
interval:mono(dnorm2/1, [-]).

interval:int_hook_register(dnorm/3, []).
interval:int_hook(dnorm(X, Mu, Sigma), Res, Opt) :-
    interval((X - Mu)/Sigma, Z, Opt),
    interval(1/Sigma * dnorm0(Z), Res, Opt).

interval:int_hook_register(dnorm0/1, []).
interval:int_hook(dnorm0(A...B), Res, Opt) :-
    B =< 0,
    !,
    interval(dnorm1(A...B), Res, Opt).

interval:int_hook(dnorm0(A...B), Res, Opt) :-
    A >= 0,
    !,
    interval(dnorm2(A...B), Res, Opt).

% mixed
interval:int_hook(dnorm0(A...B), Res, Opt) :-
    Max is max(abs(A), B),
    interval(dnorm2(0...Max), Res, Opt).

