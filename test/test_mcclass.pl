:- module(test_mcclass, [test_mcclass/0]).

:- use_module(library(plunit)).
:- use_module(library(debug)).
:- use_module(library(mcclass)).

test_mcclass :-
    run_tests([omit]).

:- begin_tests(omit).

test(omit_left) :-
    interval(omit_left(11...12 - 20...21), L...U),
    L > 19.9999,
    L < 20.0001,
    U > 20.9999,
    U < 21.0001.

test(omit_right) :-
    interval(omit_right(11...12 - 20...21), L...U),
    L > 10.9999,
    L < 11.0001,
    U > 11.9999,
    U < 12.0001.

:- end_tests(omit).
