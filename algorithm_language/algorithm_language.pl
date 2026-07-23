:- module(algorithm_language, [
    algorithm_language/2,
    algorithm_language/3,
    build_language/1,
    build_language/2,
    language_repl/1,
    run_language_command/5,
    parse_language_command/3,
    validate_language_command/3,
    execute_language_command/5,
    language_documentation/2,
    language_commands/2,
    chat_to_commands/4,
    explain_language_command/3,
    save_language/2,
    load_language/2
]).

:- use_module(library(filesex)).
:- use_module(analyse, []).
:- use_module(command_model, []).
:- use_module(parser_builder, []).
:- use_module(runtime_builder, []).
:- use_module(documentation_builder, []).
:- use_module(chat_builder, []).
:- use_module(repl, []).
:- use_module(validator, []).
:- use_module(state, []).
:- use_module(generators/docs, []).
:- use_module(generators/parser, []).
:- use_module(generators/runtime, []).
:- use_module(generators/tests, []).

:- dynamic stored_language/2.
:- meta_predicate algorithm_language(+, :, +).
:- meta_predicate algorithm_language(+, :).

/** <module> Algorithm language builder

Builds command languages from Prolog algorithm interfaces.
*/

%% algorithm_language(+LanguageName, +Algorithm) is det.
%
%  Creates and stores a generated language with default options.
algorithm_language(LanguageName, Algorithm) :-
    algorithm_language(LanguageName, Algorithm, []).

%% algorithm_language(+LanguageName, +Algorithm, +Options) is det.
%
%  Creates and stores a generated language with options.
algorithm_language(LanguageName, Algorithm, Options) :-
    strip_module(Algorithm, Module, PlainAlgorithm),
    normalize_options(Options, NormalizedOptions),
    algorithm_language_analyse:analyse_algorithm(PlainAlgorithm, NormalizedOptions, Analysis),
    algorithm_language_command_model:build_command_model(Analysis, NormalizedOptions, Commands),
    Language = language{
        name: LanguageName,
        algorithm: PlainAlgorithm,
        module: Module,
        options: NormalizedOptions,
        analysis: Analysis,
        commands: Commands
    },
    retractall(stored_language(LanguageName, _)),
    assertz(stored_language(LanguageName, Language)).

%% build_language(+LanguageOrName) is det.
%
%  Generates parser/runtime/docs/tests files to the default docs folder.
build_language(LanguageOrName) :-
    build_language(LanguageOrName, 'algorithm_language/docs').

%% build_language(+LanguageOrName, +OutputDir) is det.
%
%  Generates language artifacts in OutputDir.
build_language(LanguageOrName, OutputDir) :-
    resolve_language(LanguageOrName, Language),
    make_directory_path(OutputDir),
    algorithm_language_generator_docs:generate_docs_file(Language, OutputDir, _),
    algorithm_language_generator_parser:generate_parser_file(Language, OutputDir, _),
    algorithm_language_generator_runtime:generate_runtime_file(Language, OutputDir, _),
    algorithm_language_generator_tests:generate_tests_file(Language, OutputDir, _),
    generate_language_file(Language, OutputDir),
    generate_commands_file(Language, OutputDir),
    generate_examples_file(Language, OutputDir).

%% language_repl(+LanguageOrName) is det.
%
%  Starts an interactive REPL for the generated language.
language_repl(LanguageOrName) :-
    resolve_language(LanguageOrName, Language),
    algorithm_language_repl:language_repl(Language).

%% run_language_command(+LanguageOrName, +StateIn, +Text, -StateOut, -Result) is det.
%
%  Parses, validates and executes a command.
run_language_command(LanguageOrName, StateIn, Text, StateOut, Result) :-
    resolve_language(LanguageOrName, Language),
    parse_language_command(Language, Text, Command),
    validate_language_command(Language, context(StateIn, Command), Validation),
    ( Validation = valid ->
        execute_language_command(Language, StateIn, Command, StateOut, Result)
    ; Validation = invalid(Reason, Suggestion),
      StateOut = StateIn,
      Result = result(error, validation_failed(Reason, Suggestion))
    ).

%% parse_language_command(+LanguageOrName, +Text, -Command) is det.
%
%  Parses text into internal command representation.
parse_language_command(LanguageOrName, Text, Command) :-
    resolve_language(LanguageOrName, Language),
    algorithm_language_parser_builder:parse_language_command(Language, Text, Command).

%% validate_language_command(+LanguageOrName, +ContextOrCommand, -Validation) is det.
%
%  Validates command against command model and runtime state.
validate_language_command(LanguageOrName, ContextOrCommand, Validation) :-
    resolve_language(LanguageOrName, Language),
    algorithm_language_validator:validate_language_command(Language, ContextOrCommand, Validation).

%% execute_language_command(+LanguageOrName, +StateIn, +Command, -StateOut, -Result) is det.
%
%  Executes a parsed command.
execute_language_command(LanguageOrName, StateIn, Command, StateOut, Result) :-
    resolve_language(LanguageOrName, Language),
    algorithm_language_runtime_builder:execute_language_command(Language, StateIn, Command, StateOut, Result).

%% language_documentation(+LanguageOrName, -Documentation) is det.
%
%  Produces markdown documentation for all generated commands.
language_documentation(LanguageOrName, Documentation) :-
    resolve_language(LanguageOrName, Language),
    algorithm_language_documentation_builder:language_documentation(Language, Documentation).

%% language_commands(+LanguageOrName, -Commands) is det.
%
%  Returns command syntaxes for the generated language.
language_commands(LanguageOrName, Commands) :-
    resolve_language(LanguageOrName, Language),
    algorithm_language_command_model:language_commands(Language, Commands).

%% chat_to_commands(+LanguageOrName, +Mode, +Text, -Result) is det.
%
%  Translates natural language to generated commands.
chat_to_commands(LanguageOrName, Mode, Text, Result) :-
    resolve_language(LanguageOrName, Language),
    algorithm_language_chat_builder:chat_to_commands(Language, Mode, Text, Result).

%% explain_language_command(+LanguageOrName, +CommandText, -Explanation) is det.
%
%  Explains a command using generated docs.
explain_language_command(LanguageOrName, CommandText, Explanation) :-
    resolve_language(LanguageOrName, Language),
    algorithm_language_documentation_builder:explain_language_command(Language, CommandText, Explanation).

%% save_language(+LanguageOrName, +FilePath) is det.
%
%  Saves a generated language term to file.
save_language(LanguageOrName, FilePath) :-
    resolve_language(LanguageOrName, Language),
    setup_call_cleanup(
        open(FilePath, write, Stream),
        write_term(Stream, Language, [fullstop(true), nl(true)]),
        close(Stream)
    ).

%% load_language(+FilePath, -Language) is det.
%
%  Loads and stores a generated language term from file.
load_language(FilePath, Language) :-
    setup_call_cleanup(
        open(FilePath, read, Stream),
        read_term(Stream, Language, []),
        close(Stream)
    ),
    Name = Language.name,
    retractall(stored_language(Name, _)),
    assertz(stored_language(Name, Language)).

resolve_language(Language, Language) :-
    is_dict(Language, language),
    !.
resolve_language(Name, Language) :-
    atom(Name),
    stored_language(Name, Language),
    !.
resolve_language(Name, _) :-
    throw(error(existence_error(language, Name), _)).

normalize_options(Options, Normalized) :-
    defaults(DefaultOptions),
    partition_known_options(Options, Known, Unknown),
    append(Known, DefaultOptions, Combined),
    dedupe_options(Combined, Normalized),
    print_unknown_options(Unknown).

defaults([
    description("Generated language"),
    chat(false),
    generate_docs(true),
    generate_tests(true),
    single_file(false),
    command_style(simple),
    safe_mode(true),
    debug(false)
]).

partition_known_options([], [], []).
partition_known_options([Option|Rest], [Option|Known], Unknown) :-
    known_option(Option),
    !,
    partition_known_options(Rest, Known, Unknown).
partition_known_options([Option|Rest], Known, [Option|Unknown]) :-
    partition_known_options(Rest, Known, Unknown).

known_option(description(_)).
known_option(chat(_)).
known_option(generate_docs(_)).
known_option(generate_tests(_)).
known_option(single_file(_)).
known_option(command_style(_)).
known_option(safe_mode(_)).
known_option(debug(_)).

dedupe_options([], []).
dedupe_options([Option|Rest], [Option|Filtered]) :-
    Option =.. [Name|_],
    exclude(same_option_name(Name), Rest, Remaining),
    dedupe_options(Remaining, Filtered).

same_option_name(Name, Option) :-
    Option =.. [Name|_].

print_unknown_options([]).
print_unknown_options([Option|Rest]) :-
    format(user_error, 'Warning: unknown option ~w~n', [Option]),
    print_unknown_options(Rest).

generate_language_file(Language, OutputDir) :-
    atomic_list_concat([OutputDir, '/language.pl'], FilePath),
    setup_call_cleanup(
        open(FilePath, write, Stream),
        (
            format(Stream, '%% Generated language descriptor~n', []),
            write_term(Stream, Language, [fullstop(true), nl(true)])
        ),
        close(Stream)
    ).

generate_commands_file(Language, OutputDir) :-
    atomic_list_concat([OutputDir, '/commands.pl'], FilePath),
    setup_call_cleanup(
        open(FilePath, write, Stream),
        (
            format(Stream, '%% Generated command syntax list~n', []),
            forall(
                member(Spec, Language.commands),
                format(Stream, 'command(~q, ~q).~n', [Spec.id, Spec.syntax])
            )
        ),
        close(Stream)
    ).

generate_examples_file(Language, OutputDir) :-
    atomic_list_concat([OutputDir, '/examples.md'], FilePath),
    setup_call_cleanup(
        open(FilePath, write, Stream),
        (
            format(Stream, '# Examples for ~w~n~n', [Language.name]),
            forall(
                member(Spec, Language.commands),
                format(Stream, '- `~w`~n', [Spec.syntax])
            )
        ),
        close(Stream)
    ).
