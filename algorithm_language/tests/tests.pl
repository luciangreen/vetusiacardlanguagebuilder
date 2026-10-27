:- begin_tests(algorithm_language).

:- use_module(library(filesex)).
:- use_module('../algorithm_language').
:- use_module('../state').

accept_input(_Input).

prepare_numbers(Input, Minimum, Output) :-
    include(at_least(Minimum), Input, Filtered),
    sort(Filtered, Output).

at_least(Minimum, Value) :-
    Value >= Minimum.

crash_algorithm(_Input, _Output) :-
    throw(error(simulated_runtime_failure, context(crash_algorithm/2, "simulated"))).

fail_algorithm(_Input, _Output) :-
    fail.

setup_language :-
    algorithm_language:algorithm_language(
        list_tools,
        plunit_algorithm_language:prepare_numbers(_, _, _),
        [chat(true), description("List preparation tools")]
    ).

setup_single_arg_language :-
    algorithm_language:algorithm_language(
        lucianpl,
        plunit_algorithm_language:accept_input(_),
        [description("Single argument language")]
    ).

test(language_builds, [nondet]) :-
    setup_language,
    algorithm_language:language_commands(list_tools, Commands),
    assertion(once(member('load numbers <list>', Commands))),
    assertion(once(member('set minimum <number>', Commands))).

test(parser_and_runtime_flow, [nondet]) :-
    setup_language,
    initial_language_state(State0),
    algorithm_language:run_language_command(list_tools, State0, "load numbers [8,2,5,1]", State1, result(ok, _)),
    algorithm_language:run_language_command(list_tools, State1, "set minimum 3", State2, result(ok, _)),
    algorithm_language:run_language_command(list_tools, State2, "prepare numbers", State3, result(ok, [5,8])),
    algorithm_language:run_language_command(list_tools, State3, "show result", _State4, result(ok, [5,8])).

test(chat_preview, [nondet]) :-
    setup_language,
    algorithm_language:chat_to_commands(
        list_tools,
        preview,
        "Sort 8,2,5,1 but remove numbers below 3.",
        Commands
    ),
    assertion(once(member('load numbers [8,2,5,1]', Commands))),
    assertion(once(member('set minimum 3', Commands))).

test(generation_outputs, [nondet]) :-
    setup_language,
    tmp_file(algorithm_language_tests, OutputDir),
    make_directory(OutputDir),
    setup_call_cleanup(
        true,
        (
            algorithm_language:build_language(list_tools, OutputDir),
            directory_file_path(OutputDir, 'docs.md', DocsPath),
            directory_file_path(OutputDir, 'parser.pl', ParserPath),
            directory_file_path(OutputDir, 'runtime.pl', RuntimePath),
            directory_file_path(OutputDir, 'tests.pl', TestsPath),
            directory_file_path(OutputDir, 'commands.pl', CommandsPath),
            directory_file_path(OutputDir, 'examples.md', ExamplesPath),
            directory_file_path(OutputDir, 'language.pl', LanguagePath),
            exists_file(DocsPath),
            exists_file(ParserPath),
            exists_file(RuntimePath),
            exists_file(TestsPath),
            exists_file(CommandsPath),
            exists_file(ExamplesPath),
            exists_file(LanguagePath),
            algorithm_language:load_language(LanguagePath, GeneratedLanguage),
            assertion(GeneratedLanguage.name == list_tools)
        ),
        delete_directory_and_contents(OutputDir)
    ).

test(failed_algorithm_does_not_return_fallback_result, [nondet]) :-
    algorithm_language:algorithm_language(
        failing_tools,
        plunit_algorithm_language:fail_algorithm(_, _),
        []
    ),
    initial_language_state(State0),
    algorithm_language:run_language_command(
        failing_tools, State0, "load input [8,2,5]", State1, result(ok, _)
    ),
    algorithm_language:run_language_command(
        failing_tools, State1, "run", State2,
        result(error, algorithm_failed(fail_algorithm/2))
    ),
    assertion(State2 == State1).

test(documentation_lists_all_available_commands, [nondet]) :-
    setup_language,
    algorithm_language:language_documentation(list_tools, Documentation),
    assertion(sub_atom(Documentation, _, _, _, "load numbers <list>")),
    assertion(sub_atom(Documentation, _, _, _, "chat preview \"<text>\"")),
    assertion(sub_atom(Documentation, _, _, _, "reset")).

test(validation_requires_inputs, [nondet]) :-
    setup_language,
    initial_language_state(State),
    algorithm_language:validate_language_command(
        list_tools, context(State, run_algorithm), invalid(_, _)
    ).

test(chat_explain_and_run, [nondet]) :-
    setup_language,
    algorithm_language:chat_to_commands(
        list_tools, explain,
        "sort 8 2 5 1 but remove numbers below 3", Explanation
    ),
    assertion(sub_atom(Explanation, _, _, _, "set minimum 3")),
    algorithm_language:chat_to_commands(
        list_tools, run,
        "sort 8 2 5 1 but remove numbers below 3", Run
    ),
    get_dict(results, Run, Results),
    last(Results, result(ok, [5,8])),
    get_dict(state, Run, State),
    state_get_result(State, output, [5,8]).

test(language_save_and_load, [nondet]) :-
    setup_language,
    tmp_file(algorithm_language_language, FilePath),
    setup_call_cleanup(
        true,
        (
            algorithm_language:save_language(list_tools, FilePath),
            algorithm_language:load_language(FilePath, Language),
            assertion(Language.name == list_tools),
            algorithm_language:language_commands(Language, Commands),
            assertion(once(member('load numbers <list>', Commands)))
        ),
        ( exists_file(FilePath) -> delete_file(FilePath) ; true )
    ).

test(repl_handles_execution_errors, [nondet]) :-
    algorithm_language:algorithm_language(
        crash_tools,
        plunit_algorithm_language:crash_algorithm(_, _),
        [description("Crash test language")]
    ),
    algorithm_language:stored_language(crash_tools, Language),
    initial_language_state(State0),
    algorithm_language_repl:handle_input(Language, State0, "load input [1]", State1, true),
    algorithm_language_repl:handle_input(Language, State1, "run", State2, true),
    assertion(State2 == State1).

test(single_arg_load_accepts_nested_lists, [nondet]) :-
    setup_single_arg_language,
    initial_language_state(State0),
    algorithm_language:run_language_command(lucianpl, State0, "load arg1 [[[n,a],[1]]]", State1, result(ok, _)),
    state_get_input(State1, arg1, [[[n,a],[1]]]).

test(run_single_arg_language_after_load, [nondet]) :-
    setup_single_arg_language,
    initial_language_state(State0),
    algorithm_language:run_language_command(lucianpl, State0, "load arg1 [[[n,a],[1]]]", State1, result(ok, _)),
    algorithm_language:run_language_command(lucianpl, State1, "run", _State2, result(ok, ok)).

test(repl_rejects_unknown_single_arg_load_without_crashing, [nondet]) :-
    setup_single_arg_language,
    algorithm_language:stored_language(lucianpl, Language),
    initial_language_state(State0),
    algorithm_language_repl:handle_input(Language, State0, "load arg2 [[[n,a],[1]]]", State1, true),
    assertion(State1 == State0).

:- end_tests(algorithm_language).
