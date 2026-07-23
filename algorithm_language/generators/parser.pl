:- module(algorithm_language_generator_parser, [
    generate_parser_file/3
]).

generate_parser_file(Language, OutputDir, FilePath) :-
    atomic_list_concat([OutputDir, '/parser.pl'], FilePath),
    setup_call_cleanup(
        open(FilePath, write, Stream),
        (
            format(Stream, '%% Generated parser summary for ~w~n', [Language.name]),
            forall(
                member(Spec, Language.commands),
                format(Stream, '%% ~w -> ~w~n', [Spec.id, Spec.syntax])
            )
        ),
        close(Stream)
    ).
