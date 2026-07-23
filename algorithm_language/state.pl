:- module(algorithm_language_state, [
    initial_language_state/1,
    state_get_input/3,
    state_set_input/4,
    state_get_setting/3,
    state_set_setting/4,
    state_set_result/4,
    state_get_result/3,
    state_append_history/3
]).

initial_language_state(language_state([], [], [], [], [])).

state_get_input(language_state(Inputs, _, _, _, _), Key, Value) :-
    memberchk(Key-Value, Inputs).

state_set_input(language_state(Inputs0, Settings, Vars, Results, History), Key, Value, language_state(Inputs, Settings, Vars, Results, History)) :-
    upsert_pair(Inputs0, Key, Value, Inputs).

state_get_setting(language_state(_, Settings, _, _, _), Key, Value) :-
    memberchk(Key-Value, Settings).

state_set_setting(language_state(Inputs, Settings0, Vars, Results, History), Key, Value, language_state(Inputs, Settings, Vars, Results, History)) :-
    upsert_pair(Settings0, Key, Value, Settings).

state_set_result(language_state(Inputs, Settings, Vars, Results0, History), Key, Value, language_state(Inputs, Settings, Vars, Results, History)) :-
    upsert_pair(Results0, Key, Value, Results).

state_get_result(language_state(_, _, _, Results, _), Key, Value) :-
    memberchk(Key-Value, Results).

state_append_history(language_state(Inputs, Settings, Vars, Results, History0), Entry, language_state(Inputs, Settings, Vars, Results, History)) :-
    append(History0, [Entry], History).

upsert_pair([], Key, Value, [Key-Value]).
upsert_pair([Key-_|Rest], Key, Value, [Key-Value|Rest]) :- !.
upsert_pair([Pair|Rest0], Key, Value, [Pair|Rest]) :-
    upsert_pair(Rest0, Key, Value, Rest).
