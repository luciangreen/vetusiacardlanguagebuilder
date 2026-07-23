:- module(algorithm_language_command_model, [
    build_command_model/3,
    language_commands/2,
    command_spec_by_id/3,
    build_command_from_id/3,
    command_id/2,
    render_command/2
]).

build_command_model(Analysis, Options, CommandSpecs) :-
    input_command_specs(Analysis, InputSpecs),
    action_command_specs(Analysis, ActionSpecs),
    core_command_specs(CoreSpecs),
    chat_command_specs(Options, ChatSpecs),
    append([InputSpecs, ActionSpecs, CoreSpecs, ChatSpecs], CommandSpecs).

language_commands(Language, Commands) :-
    Specs = Language.commands,
    findall(Syntax, (member(Spec, Specs), Syntax = Spec.syntax), Commands).

command_spec_by_id(Language, Id, Spec) :-
    member(Spec, Language.commands),
    Spec.id = Id.

build_command_from_id(load_input(Name), [Value], set_input(Name, Value)).
build_command_from_id(set_input(Name), [Value], set_input(Name, Value)).
build_command_from_id(run_algorithm, [], run_algorithm).
build_command_from_id(show_result, [], show_result).
build_command_from_id(reset, [], reset).
build_command_from_id(clear, [], clear).
build_command_from_id(help, [], help).
build_command_from_id(commands, [], commands).
build_command_from_id(history, [], history).
build_command_from_id(quit, [], quit).
build_command_from_id(chat_preview, [Text], chat_preview(Text)).
build_command_from_id(chat_explain, [Text], chat_explain(Text)).
build_command_from_id(chat_run, [Text], chat_run(Text)).

command_id(set_input(Name, _), set_input(Name)) :-
    memberchk(Name, [minimum, maximum, min, max, threshold]),
    !.
command_id(set_input(Name, _), load_input(Name)).
command_id(run_algorithm, run_algorithm).
command_id(show_result, show_result).
command_id(reset, reset).
command_id(clear, clear).
command_id(help, help).
command_id(commands, commands).
command_id(history, history).
command_id(quit, quit).
command_id(chat_preview(_), chat_preview).
command_id(chat_explain(_), chat_explain).
command_id(chat_run(_), chat_run).

render_command(set_input(Name, Value), Text) :-
    split_atom_words(Name, Words),
    value_text(Value, ValueText),
    ( memberchk(Name, [minimum, maximum, min, max, threshold]) ->
        Verb = set
    ; Verb = load
    ),
    append([Verb|Words], [ValueText], Tokens),
    atomic_list_concat(Tokens, ' ', Text).
render_command(run_algorithm, "run").
render_command(show_result, "show result").
render_command(reset, "reset").
render_command(clear, "clear").
render_command(help, "help").
render_command(commands, "commands").
render_command(history, "history").
render_command(quit, "quit").
render_command(chat_preview(Text), Rendered) :-
    format(atom(Rendered), 'chat preview "~w"', [Text]).
render_command(chat_explain(Text), Rendered) :-
    format(atom(Rendered), 'chat explain "~w"', [Text]).
render_command(chat_run(Text), Rendered) :-
    format(atom(Rendered), 'chat run "~w"', [Text]).

input_command_specs(Analysis, Specs) :-
    findall(Spec, input_spec_for_arg(Analysis, Spec), Specs).

input_spec_for_arg(Analysis, Spec) :-
    member(ArgName, Analysis.input_args),
    input_words(Analysis, ArgName, Words),
    input_arg_type(ArgName, Type),
    input_verb(ArgName, Verb),
    atomic_list_concat([Verb|Words], ' ', Prefix),
    format(atom(Syntax), '~w <~w>', [Prefix, Type]),
    command_kind(Verb, ArgName, Id),
    Spec = command_spec{
        id: Id,
        syntax: Syntax,
        words: [Verb|Words],
        arg_types: [Type],
        purpose: "Sets required input.",
        effect: "Updates language state.",
        related: [run_algorithm, show_result]
    }.

action_command_specs(Analysis, Specs) :-
    PredWords = Analysis.predicate_words,
    atomic_list_concat(PredWords, ' ', ActionSyntax),
    format(atom(ActionPurpose), 'Runs ~w.', [Analysis.predicate]),
    Specs = [
        command_spec{
            id: run_algorithm,
            syntax: "run",
            words: [run],
            arg_types: [],
            purpose: ActionPurpose,
            effect: "Executes the algorithm.",
            related: [show_result]
        },
        command_spec{
            id: run_algorithm,
            syntax: ActionSyntax,
            words: PredWords,
            arg_types: [],
            purpose: ActionPurpose,
            effect: "Executes the algorithm.",
            related: [show_result]
        }
    ].

core_command_specs([
    command_spec{id:show_result, syntax:"show result", words:[show,result], arg_types:[], purpose:"Displays the latest result.", effect:"No state change.", related:[run_algorithm]},
    command_spec{id:help, syntax:"help", words:[help], arg_types:[], purpose:"Shows help.", effect:"No state change.", related:[commands]},
    command_spec{id:commands, syntax:"commands", words:[commands], arg_types:[], purpose:"Lists available commands.", effect:"No state change.", related:[help]},
    command_spec{id:history, syntax:"history", words:[history], arg_types:[], purpose:"Shows command history.", effect:"No state change.", related:[commands]},
    command_spec{id:clear, syntax:"clear", words:[clear], arg_types:[], purpose:"Clears runtime values.", effect:"Resets inputs/settings/results.", related:[reset]},
    command_spec{id:reset, syntax:"reset", words:[reset], arg_types:[], purpose:"Resets full language state.", effect:"Resets language state.", related:[clear]},
    command_spec{id:quit, syntax:"quit", words:[quit], arg_types:[], purpose:"Exits the REPL.", effect:"Ends session.", related:[help]}
]).

chat_command_specs(Options, [
    command_spec{id:chat_preview, syntax:"chat preview \"<text>\"", words:[chat,preview], arg_types:[string], purpose:"Shows translated commands.", effect:"No execution.", related:[chat_explain,chat_run]},
    command_spec{id:chat_explain, syntax:"chat explain \"<text>\"", words:[chat,explain], arg_types:[string], purpose:"Explains translated commands.", effect:"No execution.", related:[chat_preview,chat_run]},
    command_spec{id:chat_run, syntax:"chat run \"<text>\"", words:[chat,run], arg_types:[string], purpose:"Translates and executes text.", effect:"Runs validated commands.", related:[chat_preview,chat_explain]}
]) :-
    memberchk(chat(true), Options),
    !.
chat_command_specs(_, []).

input_words(Analysis, input, Words) :-
    memberchk(numbers, Analysis.predicate_words),
    !,
    Words = [numbers].
input_words(_, ArgName, Words) :-
    split_atom_words(ArgName, Words).

input_arg_type(ArgName, number) :-
    memberchk(ArgName, [minimum, maximum, min, max, threshold]),
    !.
input_arg_type(ArgName, list) :-
    memberchk(ArgName, [numbers, input, items, list]),
    !.
input_arg_type(_, value).

input_verb(ArgName, set) :-
    memberchk(ArgName, [minimum, maximum, min, max, threshold]),
    !.
input_verb(_, load).

command_kind(set, ArgName, set_input(ArgName)).
command_kind(load, ArgName, load_input(ArgName)).

split_atom_words(Atom, Words) :-
    atomic_list_concat(Words, '_', Atom).

value_text(Value, Text) :-
    ( is_list(Value) ->
        term_string(Value, Text)
    ; number(Value) ->
        number_string(Value, Text)
    ; atom(Value) ->
        atom_string(Value, Text)
    ; string(Value) ->
        Text = Value
    ; term_string(Value, Text)
    ).
