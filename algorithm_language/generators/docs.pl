:- module(algorithm_language_generator_docs, [
    generate_docs_file/3
]).

:- use_module('../documentation_builder').

generate_docs_file(Language, OutputDir, FilePath) :-
    language_documentation(Language, Markdown),
    atomic_list_concat([OutputDir, '/docs.md'], FilePath),
    setup_call_cleanup(
        open(FilePath, write, Stream),
        format(Stream, '~w~n', [Markdown]),
        close(Stream)
    ).
