:- begin_tests(algorithm_language).

:- use_module('../algorithm_language').
:- use_module('../state').

prepare_numbers(Input, Minimum, Output) :-
    include(at_least(Minimum), Input, Filtered),
    sort(Filtered, Output).

at_least(Minimum, Value) :-
    Value >= Minimum.

setup_language :-
    algorithm_language:algorithm_language(
        list_tools,
        plunit_algorithm_language:prepare_numbers(_, _, _),
        [chat(true), description("List preparation tools")]
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
    algorithm_language:build_language(list_tools, 'algorithm_language/docs'),
    exists_file('algorithm_language/docs/docs.md'),
    exists_file('algorithm_language/docs/parser.pl'),
    exists_file('algorithm_language/docs/runtime.pl'),
    exists_file('algorithm_language/docs/tests.pl').

:- end_tests(algorithm_language).
