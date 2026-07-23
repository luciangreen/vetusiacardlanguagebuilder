:- module(algorithm_language_validator, [
    validate_language_command/3
]).

:- use_module(command_model).
:- use_module(state).

validate_language_command(Language, context(State, Command), Validation) :-
    !,
    command_id(Command, Id),
    ( command_spec_by_id(Language, Id, _) ->
        validate_for_state(Language, State, Command, Validation)
    ; Validation = invalid("Unavailable command.", "Run `commands` to inspect available commands.")
    ).
validate_language_command(Language, Command, Validation) :-
    initial_language_state(State),
    validate_language_command(Language, context(State, Command), Validation).

validate_for_state(Language, State, run_algorithm, Validation) :-
    missing_required_inputs(Language.analysis.input_args, State, Missing),
    ( Missing = [] ->
        Validation = valid
    ; atomic_list_concat(Missing, ', ', MissingText),
      format(atom(Reason), 'Cannot execute run. Missing inputs: ~w.', [MissingText]),
      Validation = invalid(Reason, "Load required inputs before running.")
    ).
validate_for_state(_, _, set_input(minimum, Value), Validation) :-
    ( number(Value) ->
        Validation = valid
    ; Validation = invalid("Minimum must be numeric.", "Use: set minimum 5")
    ).
validate_for_state(_, _, _, valid).

missing_required_inputs([], _, []).
missing_required_inputs([Name|Rest], State, Missing) :-
    ( state_get_input(State, Name, _) ->
        missing_required_inputs(Rest, State, Missing)
    ; state_get_setting(State, Name, _) ->
        missing_required_inputs(Rest, State, Missing)
    ; missing_required_inputs(Rest, State, Tail),
      Missing = [Name|Tail]
    ).
