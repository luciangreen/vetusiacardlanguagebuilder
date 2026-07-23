:- module(list_tools_example, []).

:- use_module('../algorithm_language').
:- use_module('../state').

prepare_numbers(Input, Minimum, Output) :-
    include(at_least(Minimum), Input, Filtered),
    sort(Filtered, Output).

at_least(Minimum, Value) :-
    Value >= Minimum.

run_example :-
    algorithm_language(
        list_tools,
        prepare_numbers(Input, Minimum, Output),
        [chat(true), description("List tools example")]
    ),
    initial_language_state(State0),
    run_language_command(list_tools, State0, "load numbers [8,2,5,1]", State1, _),
    run_language_command(list_tools, State1, "set minimum 3", State2, _),
    run_language_command(list_tools, State2, "prepare numbers", _State3, Result),
    writeln(Result).
