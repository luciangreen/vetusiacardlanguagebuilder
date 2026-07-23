:- module(algorithm_language_generator_tests, [
    generate_tests_file/3
]).

generate_tests_file(Language, OutputDir, FilePath) :-
    atomic_list_concat([OutputDir, '/tests.pl'], FilePath),
    setup_call_cleanup(
        open(FilePath, write, Stream),
        (
            format(Stream, ':- begin_tests(~w_generated).~n', [Language.name]),
            format(Stream, 'test(language_name) :- assertion(~q = ~q).~n', [Language.name, Language.name]),
            format(Stream, ':- end_tests(~w_generated).~n', [Language.name])
        ),
        close(Stream)
    ).
