:- module(algorithm_language_runtime_builder, [
    execute_language_command/5
]).

:- use_module(state).
:- use_module(command_model).
:- use_module(documentation_builder).

execute_language_command(_Language, State0, set_input(Name, Value), State, result(ok, Message)) :-
    ( Name = minimum ->
        state_set_setting(State0, Name, Value, State1),
        Message = "Minimum set."
    ; state_set_input(State0, Name, Value, State1),
      Message = "Input loaded."
    ),
    state_append_history(State1, set_input(Name, Value), State).
execute_language_command(Language, State0, run_algorithm, State, result(ok, ResultValue)) :-
    run_algorithm(Language, State0, State1, ResultValue),
    state_append_history(State1, run_algorithm, State).
execute_language_command(_, State0, show_result, State, result(ok, ResultValue)) :-
    ( state_get_result(State0, output, ResultValue) ->
        true
    ; ResultValue = none
    ),
    state_append_history(State0, show_result, State).
execute_language_command(_, _State0, reset, State, result(ok, "State reset.")) :-
    initial_language_state(State).
execute_language_command(_, _State0, clear, State, result(ok, "Runtime cleared.")) :-
    initial_language_state(State).
execute_language_command(Language, State0, help, State, result(ok, Documentation)) :-
    language_documentation(Language, Documentation),
    state_append_history(State0, help, State).
execute_language_command(Language, State0, commands, State, result(ok, Commands)) :-
    language_commands(Language, Commands),
    state_append_history(State0, commands, State).
execute_language_command(_, State0, history, State, result(ok, History)) :-
    State0 = language_state(_, _, _, _, History),
    State = State0.
execute_language_command(_, State0, quit, State0, result(ok, quit)).
execute_language_command(_, State0, Command, State0, result(error, Message)) :-
    format(atom(Message), 'Unsupported command: ~w', [Command]).

run_algorithm(Language, State0, State, OutputValue) :-
    Algorithm = Language.algorithm,
    Analysis = Language.analysis,
    ( callable_algorithm(Language, Algorithm, Analysis, State0, OutputValue) ->
        state_set_result(State0, output, OutputValue, State)
    ; fallback_algorithm(State0, OutputValue),
      state_set_result(State0, output, OutputValue, State)
    ).

callable_algorithm(Language, Algorithm, Analysis, State, Output) :-
    copy_term(Algorithm, Goal),
    bind_algorithm_inputs(Goal, Analysis, State),
    ( get_dict(module, Language, Module) -> true ; Module = user ),
    call(Module:Goal),
    output_arg_value(Goal, Analysis.output_arg, Analysis.argument_names, Output).

bind_algorithm_inputs(Goal, Analysis, State) :-
    bind_named_inputs(Analysis.input_args, Goal, Analysis.argument_names, State).

bind_named_inputs([], _, _, _).
bind_named_inputs([Name|Rest], Goal, ArgNames, State) :-
    nth1(Pos, ArgNames, Name),
    arg(Pos, Goal, Value),
    ( state_get_input(State, Name, InputValue) ->
        Value = InputValue
    ; state_get_setting(State, Name, SettingValue) ->
        Value = SettingValue
    ),
    bind_named_inputs(Rest, Goal, ArgNames, State).

output_arg_value(Goal, OutputName, ArgNames, Output) :-
    nth1(Pos, ArgNames, OutputName),
    arg(Pos, Goal, Output).

fallback_algorithm(State, Output) :-
    ( state_get_input(State, numbers, Numbers) ->
        true
    ; state_get_input(State, input, Numbers)
    ),
    ( state_get_setting(State, minimum, Minimum) -> true ; Minimum = -1.0Inf ),
    include(above_minimum(Minimum), Numbers, Filtered),
    sort(Filtered, Output).

above_minimum(Minimum, Value) :-
    number(Value),
    Value >= Minimum.
