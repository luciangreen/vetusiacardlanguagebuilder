# vetusiacardlanguagebuilder

Creates a programming language and chat interface for a Prolog algorithm.

## Quick start

```prolog
:- use_module('algorithm_language/algorithm_language').
:- use_module('algorithm_language/state').

prepare_numbers(Input, Minimum, Output) :-
    include(at_least(Minimum), Input, Filtered),
    sort(Filtered, Output).

at_least(Minimum, Value) :-
    Value >= Minimum.

?- algorithm_language(
       list_tools,
       prepare_numbers(Input, Minimum, Output),
       [chat(true)]).

?- language_repl(list_tools).
```

## Generated command capabilities

The generated language supports command parsing, validation, runtime execution,
Markdown documentation generation, chat translation (`preview`, `explain`,
`run`), REPL interaction, and artifact generation (`docs.md`, `parser.pl`,
`runtime.pl`, `tests.pl`, `language.pl`, `commands.pl`, `examples.md`).
