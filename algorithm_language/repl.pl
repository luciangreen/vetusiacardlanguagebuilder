:- module(algorithm_language_repl, [
    language_repl/1
]).

:- use_module(parser_builder).
:- use_module(runtime_builder).
:- use_module(validator).
:- use_module(state).
:- use_module(chat_builder).

language_repl(Language) :-
    initial_language_state(State0),
    repl_loop(Language, State0).

repl_loop(Language, State0) :-
    format('~w> ', [Language.name]),
    read_line_to_string(user_input, Input),
    ( Input == end_of_file ->
        true
    ; normalize_space(string(Trimmed), Input),
      handle_input(Language, State0, Trimmed, State, Continue),
      ( Continue == true ->
          repl_loop(Language, State)
      ; true
      )
    ).

handle_input(_, State, "", State, true) :- !.
handle_input(_, State, "quit", State, false) :- !.
handle_input(Language, State0, Input, State, true) :-
    ( parse_language_command(Language, Input, Parsed) ->
        execute_parsed(Language, State0, Parsed, State)
    ; format('Parse error: ~w~n', [Input]),
      State = State0
    ).

execute_parsed(Language, State, chat_preview(Text), State) :-
    chat_to_commands(Language, preview, Text, Commands),
    print_lines(Commands).
execute_parsed(Language, State, chat_explain(Text), State) :-
    chat_to_commands(Language, explain, Text, Explanation),
    format('~w~n', [Explanation]).
execute_parsed(Language, _State0, chat_run(Text), State) :-
    chat_to_commands(Language, run, Text, Result),
    print_lines(Result.results),
    State = Result.state.
execute_parsed(Language, State0, Command, State) :-
    validate_language_command(Language, context(State0, Command), Validation),
    ( Validation = valid ->
        execute_language_command(Language, State0, Command, State, Result),
        format('~w~n', [Result])
    ; Validation = invalid(Reason, Suggestion),
      format('Cannot execute: ~w~nSuggestion: ~w~n', [Reason, Suggestion]),
      State = State0
    ).

print_lines([]).
print_lines([Line|Rest]) :-
    format('~w~n', [Line]),
    print_lines(Rest).
