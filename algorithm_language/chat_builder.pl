:- module(algorithm_language_chat_builder, [
    chat_to_commands/4
]).

:- use_module(library(pcre)).
:- use_module(command_model).
:- use_module(state).
:- use_module(executor).

chat_to_commands(Language, preview, Text, CommandsText) :-
    translate_text(Language, Text, Commands),
    findall(Line,
        (member(Command, Commands), render_translated_command(Language, Command, Line)),
        CommandsText).
chat_to_commands(Language, explain, Text, Explanation) :-
    translate_text(Language, Text, Commands),
    findall(Line,
        (member(Command, Commands), render_translated_command(Language, Command, Line)),
        Lines),
    atomic_list_concat(Lines, '\n', Joined),
    format(atom(Explanation), 'Translated commands:\n~w', [Joined]).
chat_to_commands(Language, run, Text, Result) :-
    translate_text(Language, Text, Commands),
    initial_language_state(State0),
    run_command_sequence(Language, State0, Commands, State, Results),
    Result = chat_run{commands:Commands, state:State, results:Results}.

translate_text(Language, Text, Commands) :-
    find_minimum(Text, Minimum),
    find_numbers(Text, Numbers),
    base_commands(Language, Numbers, Minimum, Commands).

base_commands(Language, Numbers, Minimum, Commands) :-
    InputArgs = Language.analysis.input_args,
    ( Numbers = [] ->
        Load = []
    ; input_argument(InputArgs, InputName) ->
        Load = [set_input(InputName, Numbers)]
    ; Load = []
    ),
    ( var(Minimum) ->
        MinCommands = []
    ; threshold_argument(InputArgs, ThresholdName) ->
        MinCommands = [set_input(ThresholdName, Minimum)]
    ; MinCommands = []
    ),
    append([Load, MinCommands, [run_algorithm, show_result]], Commands).

input_argument(Arguments, numbers) :-
    memberchk(numbers, Arguments),
    !.
input_argument(Arguments, input) :-
    memberchk(input, Arguments),
    !.
input_argument([Name|_], Name).

threshold_argument(Arguments, Name) :-
    member(Name, [minimum, min, threshold, maximum, max]),
    memberchk(Name, Arguments),
    !.

render_translated_command(Language, Command, Line) :-
    Command = set_input(_, Value),
    !,
    command_id(Command, Id),
    command_spec_by_id(Language, Id, Spec),
    term_string(Value, ValueText, [quoted(true)]),
    Words = Spec.words,
    append(Words, [ValueText], Tokens),
    atomic_list_concat(Tokens, ' ', Line).
render_translated_command(_, Command, Line) :-
    render_command(Command, Line).

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
