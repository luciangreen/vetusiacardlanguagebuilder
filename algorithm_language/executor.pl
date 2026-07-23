:- module(algorithm_language_executor, [
    run_command_sequence/5
]).

:- use_module(validator).
:- use_module(runtime_builder).

run_command_sequence(_, State, [], State, []).
run_command_sequence(Language, State0, [Command|Commands], State, [Result|Results]) :-
    validate_language_command(Language, context(State0, Command), Validation),
    ( Validation = valid ->
        execute_language_command(Language, State0, Command, State1, Result)
    ; Validation = invalid(Reason, Suggestion),
      Result = result(error, validation_failed(Reason, Suggestion)),
      State1 = State0
    ),
    run_command_sequence(Language, State1, Commands, State, Results).
