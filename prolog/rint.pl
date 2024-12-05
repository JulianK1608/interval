:- module(rint, []).

:- multifile r_hook/1.

:- reexport(interval).
:- reexport(r), r_initialize.

/** <module> Use intervals in R functions.

This module expands the 'interval' module with R functions.
For general information on the use of interval/2, please refer to that module. 
 */

% Binomial distribution
% - Cumulated density lower-tail: interval(pbinom(X, N, P, true), Res)
% - Cumulated density upper-tail: interval(pbinom(X, N, P, false), Res)
% - Quantile: interval(qbinom(Alpha, N, P, true), Res)
% - Density: interval(dbinom(X, N, P), Res)
%
% Normal distribution
% - Cumulated density: interval(pnorm(X, Mu, Sigma), Res)
% - Quantile: interval(qnorm(P, Mu, Sigma), Res)
% - Density: interval(dnorm(X, Mu, Sigma), Res)
%
% T distribution
% - Cumulated density lower-tail: interval(pt(X, Df, true), Res)
% - Cumulated density upper-tail: interval(pt(X, Df, false), Res)
% - Quantile: interval(qt(P, Df), Res)
% - Density: interval(dt(X, Df), Res)
%
% Skip R vectors
%
interval:int_hook(:, colon(_, _), []).
colon(A, A).

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
interval:int_hook(pbinom, pbinom(atomic, atomic, ..., atomic), []).

% lower tail
interval:pbinom(atomic(X), atomic(N), P, atomic(true), Res, Flags) :-
    !,
    interval:interval_(pbinom0(atomic(X), atomic(N), P), Res, Flags).

% upper tail
interval:pbinom(atomic(X), atomic(N), P, atomic(false), Res, Flags) :-
    interval:interval_(pbinom1(atomic(X), atomic(N), P), Res, Flags).

r_hook(pbinom0/3).
interval:mono(pbinom0/3, [+, -, -]).

r_hook(pbinom1/3).
interval:mono(pbinom1/3, [-, +, +]).

%
% Quantile function - hier weiter
%
interval:int_hook(qbinom, qbinom(..., ..., ..., atomic), []).

% lower tail
interval:qbinom(Alpha, N, P, atomic(true), Res, Flags) :-
    !,
    interval:interval_(qbinom0(Alpha, N, P), Res, Flags).

% upper tail
interval:qbinom(Alpha, N, P, atomic(false), Res, Flags) :-
    interval:interval_(qbinom1(Alpha, N, P), Res, Flags).

r_hook(qbinom0/3).
interval:mono(qbinom0/3, [+, +, +]).

r_hook(qbinom1/3).
interval:mono(qbinom1/3, [-, +, +]).

%
% Density
%
interval:int_hook(dbinom, dbinom(..., ..., ...), []).

% left to X / N
interval:dbinom(X1...X2, N1...N2, P1...P2, Res, Flags) :-
    X2 < N1 * P1,
    !,
    interval:interval_(dbinom0(X1...X2, N1...N2, P1...P2), Res, Flags).

% right to X / N
interval:dbinom(X1...X2, N1...N2, P1...P2, Res, Flags) :-
    X1 > N2 * P2,
    !,
    interval:interval_(dbinom1(X1...X2, N1...N2, P1...P2), Res, Flags).

% otherwise
interval:dbinom(X1...X2, N1...N2, P1...P2, Res, _Flags) :-
    r(dbinom2(X1, X2, N1, N2, P1, P2), #(L, U)),
    Res = L...U.

r_hook(dbinom0/3).
interval:mono(dbinom0/3, [+, -, -]).

r_hook(dbinom1/3).
interval:mono(dbinom1/3, [-, +, +]).

%
% Normal distribution
%
r_hook(pnorm0/1).
interval:mono(pnorm0/1, [+]).

interval:int_hook(pnorm, pnorm(..., ..., ...), []).
interval:pnorm(X, Mu, Sigma, Res, Flags) :-
     interval:interval_((X - Mu)/Sigma, Z, Flags),
     interval:interval_(pnorm0(Z), Res, Flags).

%
% Quantile function
%
r_hook(qnorm0/1).
interval:mono(qnorm0/1, [+]).

interval:int_hook(qnorm, qnorm(..., ..., ...), []).
interval:qnorm(P, Mu, Sigma, Res, Flags) :-
     interval:interval_(qnorm0(P), Z, Flags),
     interval:interval_(Mu + Z * Sigma, Res, Flags).

%
% Density
%
r_hook(dnorm1/1).
interval:mono(dnorm1/1, [+]).

r_hook(dnorm2/1).
interval:mono(dnorm2/1, [-]).

interval:int_hook(dnorm, dnorm(..., ..., ...), []).
interval:dnorm(X, Mu, Sigma, Res, Flags) :-
    interval:interval_((X - Mu)/Sigma, Z, Flags),
    interval:interval_(atomic(1)/Sigma * dnorm0(Z), Res, Flags).

interval:int_hook(dnorm0, dnorm0(...), []).
interval:dnorm0(A...B, Res, Flags) :-
    B =< 0,
    !,
    interval:interval_(dnorm1(A...B), Res, Flags).

interval:dnorm0(A...B, Res, Flags) :-
    A >= 0,
    !,
    interval:interval_(dnorm2(A...B), Res, Flags).

% mixed
interval:dnorm0(A...B, Res, Flags) :-
    Max is max(abs(A), B),
    interval:interval_(dnorm2(0...Max), Res, Flags).

%
% t distribution
%
interval:int_hook(pt, pt(..., ..., atomic), []).

r_hook(pt0/2).
interval:mono(pt0/2, [+,-]).

r_hook(pt1/2).
interval:mono(pt1/2, [+,+]).

r_hook(pt2/2).
interval:mono(pt2/2, [-,+]).

r_hook(pt3/2).
interval:mono(pt3/2, [-,-]).

% lower tail
interval:pt(L...U, Df, atomic(true), Res, Flags) :-
    U =< 0,
    !,
    interval:interval_(pt0(L...U, Df), Res, Flags).

interval:pt(L...U, Df, atomic(true), Res, Flags) :-
    L >= 0,
    !,
    interval:interval_(pt1(L...U, Df), Res, Flags).

interval:pt(L...U, Df, atomic(true), Res, Flags) :-
    Max is max(abs(L), U), 
    interval:interval_(pt1(0...Max, Df), Res, Flags).

% upper tail
interval:pt(L...U, Df, atomic(false), Res, Flags) :-
    U =< 0,
    !, 
    interval:interval_(pt2(L...U, Df), Res, Flags).

interval:pt(L...U, Df, atomic(false), Res, Flags) :-
    L >= 0,
    !, 
    interval:interval_(pt3(L...U, Df), Res, Flags).

interval:pt(L...U, Df, atomic(false), Res, Flags) :-
    Max is max(abs(L), U), 
    interval:interval_(pt3(0...Max, Df), Res, Flags).

%
% Quantile function
%
r_hook(qt0/2).
interval:mono(qt0/2, [+,-]).

interval:int_hook(qt, qt(..., ...), []).
interval:qt(P, Df, Res, Flags) :-
    interval:interval_(qt0(P, Df), Res, Flags).

%
% Density
%
r_hook(dt0/2).
interval:mono(dt0/2, [+,+]).

r_hook(dt1/2).
interval:mono(dt1/2, [-,+]).

interval:int_hook(dt, dt(..., ...), []).
interval:dt(L...U, Df, Res, Flags) :-
    U =< 0,
    !,
    interval:interval_(dt0(L...U, Df), Res, Flags).

interval:dt(L...U, Df, Res, Flags) :-
    L >= 0,
    !,
    interval:interval_(dt1(L...U, Df), Res, Flags).

% mixed
interval:dt(L...U, Df, Res, Flags) :-
    Max is max(abs(L), U),
    interval:interval_(dt1(0...Max, Df), Res, Flags). 

%
% chisq
%

interval:int_hook(pchisq, pchisq(..., atomic, atomic), []).

r_hook(pchisq0/2).
interval:mono(pchisq0/2, [+,-]).

r_hook(pchisq1/2).
interval:mono(pchisq1/2, [-,+]).

% lower tail
interval:pchisq(L...U, Df, atomic(true), Res, Flags):-
    !,
    interval:interval_(pchisq0(L...U, Df), Res, Flags).

% upper tail
interval:pchisq(L...U, Df, atomic(false), Res, Flags):-
    !,
    interval:interval_(pchisq1(L...U, Df), Res, Flags).

%
% quantile function
%
interval:int_hook(qchisq, qchisq(..., atomic, atomic), []).

r_hook(qchisq0/2).
interval:mono(qchisq0/2, [+,+]).

r_hook(qchisq1/2).
interval:mono(qchisq1/2, [-,+]).

interval:qchisq(L...U, Df, atomic(true), Res, Flags):-
    !,
    interval:interval_(qchisq0(L...U, Df), Res, Flags).

interval:qchisq(L...U, Df, atomic(false), Res, Flags):-
    interval:interval_(qchisq1(L...U, Df), Res, Flags).

%
% density
%
interval:int_hook(dchisq, dchisq(..., atomic), []).

r_hook(dchisq0/2).
interval:mono(dchisq0/2, [-,/]).

r_hook(dchisq1/2).
interval:mono(dchisq1/2, [+,/]).

% for df<=2
interval:dchisq(L...U, atomic(Df), Res, Flags):-
    Df =< 2,
    !,
    interval:interval_(dchisq0(L...U, atomic(Df)), Res, Flags).

% for df>2
interval:dchisq(L...U, atomic(Df), Res, Flags):-
    interval:dchisq_A(L...U, atomic(Df), Res, Flags).

% for x < mode
interval:dchisq_A(L...U, atomic(Df), Res, Flags) :-
    Mode is Df - 2,
    U =< Mode,
    !,
    interval:interval_(dchisq1(L...U, atomic(Df)), Res, Flags).

% for x > mode
interval:dchisq_A(L...U, atomic(Df), Res, Flags) :-
    Mode is Df - 2,
    L >= Mode,
    !,
    interval:interval_(dchisq0(L...U, atomic(Df)), Res, Flags).

% for L < mode, U > mode
interval:dchisq_A(L...U, atomic(Df), Res, Flags) :-
    interval:interval_(dchisq(atomic(L), atomic(Df)), X1..._, Flags),
    interval:interval_(dchisq(atomic(U), atomic(Df)), X3..._, Flags),
    L1 is min(X1, X3),
    Mode is Df - 2,
    interval:interval_(dchisq(atomic(Mode), atomic(Df)), U1..._, Flags),
    Res = L1...U1.