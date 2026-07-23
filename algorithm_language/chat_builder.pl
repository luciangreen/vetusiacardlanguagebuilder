:- module(algorithm_language_chat_builder, [
    chat_to_commands/4
]).

:- use_module(library(pcre)).
:- use_module(command_model).
:- use_module(state).
:- use_module(executor).

chat_to_commands(Language, preview, Text, CommandsText) :-
    translate_text(Language, Text, Commands),
    findall(Line, (member(Command, Commands), render_command(Command, Line)), CommandsText).
chat_to_commands(Language, explain, Text, Explanation) :-
    translate_text(Language, Text, Commands),
    findall(Line, (member(Command, Commands), render_command(Command, Line)), Lines),
    atomic_list_concat(Lines, '\n', Joined),
    format(atom(Explanation), 'Translated commands:\n~w', [Joined]).
chat_to_commands(Language, run, Text, Result) :-
    translate_text(Language, Text, Commands),
    initial_language_state(State0),
    run_command_sequence(Language, State0, Commands, State, Results),
    Result = chat_run{commands:Commands, state:State, results:Results}.

translate_text(_, Text, Commands) :-
    find_minimum(Text, Minimum),
    find_numbers(Text, Numbers),
    base_commands(Numbers, Minimum, Commands).

base_commands(Numbers, Minimum, Commands) :-
    ( Numbers = [] ->
        Load = []
    ; Load = [set_input(numbers, Numbers)]
    ),
    ( var(Minimum) ->
        MinCommands = []
    ; MinCommands = [set_input(minimum, Minimum)]
    ),
    append([Load, MinCommands, [run_algorithm, show_result]], Commands).

find_numbers(Text, Numbers) :-
    number_source_text(Text, Source),
    split_string(Source, " \n\t,.;:!?()[]{}", " \n\t,.;:!?()[]{}", Parts),
    findall(Number,
        (
            member(Part, Parts),
            catch(number_string(Number, Part), _, fail)
        ),
        Numbers).

number_source_text(Text, Source) :-
    re_matchsub("(?i)sort\\s+(.+?)(?:\\s+but|\\.|$)", Text, Dict, []),
    !,
    Source = Dict.1.
number_source_text(Text, Text).

find_minimum(Text, Minimum) :-
    re_matchsub("(?i)below\\s+([0-9]+(?:\\.[0-9]+)?)", Text, Dict, []),
    number_string(Minimum, Dict.1),
    !.
find_minimum(Text, Minimum) :-
    re_matchsub("(?i)minimum\\s+([0-9]+(?:\\.[0-9]+)?)", Text, Dict, []),
    number_string(Minimum, Dict.1).
