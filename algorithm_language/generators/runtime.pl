:- module(algorithm_language_generator_runtime, [
    generate_runtime_file/3
]).

generate_runtime_file(Language, OutputDir, FilePath) :-
    atomic_list_concat([OutputDir, '/runtime.pl'], FilePath),
    setup_call_cleanup(
        open(FilePath, write, Stream),
        (
            format(Stream, '%% Generated runtime summary for ~w~n', [Language.name]),
            format(Stream, '%% Predicate: ~w/~w~n', [Language.analysis.predicate, Language.analysis.arity]),
            format(Stream, '%% Input args: ~w~n', [Language.analysis.input_args]),
            format(Stream, '%% Output arg: ~w~n', [Language.analysis.output_arg])
        ),
        close(Stream)
    ).
