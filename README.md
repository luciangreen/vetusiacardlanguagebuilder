# vetusiacardlanguagebuilder

Automatically generates a command-line language and interactive chat interface from a Prolog algorithm. Point it at any Prolog predicate and get a full mini-language with a parser, runtime, validator, Markdown documentation, test scaffolding, and a REPL — all generated for you.

## Features

- **Language generation** — analyses a Prolog predicate and builds a structured command model from its arguments
- **Parser & runtime** — parses, validates, and executes commands in the running Prolog process; generated `parser.pl` and `runtime.pl` files are currently summaries, not standalone implementations
- **Documentation** — produces `docs.md` and `examples.md` describing every generated command
- **Test scaffolding** — generates a minimal PlUnit smoke-test file; the maintained behavioral suite is `algorithm_language/tests/tests.pl`
- **REPL** — an interactive Read-Eval-Print loop (`language_repl/1`) ready to use immediately
- **Chat interface** — translates natural-language text to generated commands via `preview`, `explain`, and `run` modes
- **Artifact save/load** — persist a generated language to disk and reload it later

## Requirements

- [SWI-Prolog](https://www.swi-prolog.org/) 8.x or later

## Run the test suite

From the repository root, run the PlUnit suite with:

```bash
swipl -q -s algorithm_language/tests/tests.pl -g run_tests -t halt
```

Run the bundled example with:

```bash
swipl -q -s algorithm_language/examples/list_tools_example.pl \
  -g list_tools_example:run_example -t halt
```

The generation test writes into a temporary directory and removes it afterward.
The test suite does not overwrite the checked-in generated examples.

## Quick start

Define your algorithm, generate a language, and start the REPL — all in three steps:

```prolog
:- use_module('algorithm_language/algorithm_language').
:- use_module('algorithm_language/state').

% 1. Define your Prolog algorithm
prepare_numbers(Input, Minimum, Output) :-
    include(at_least(Minimum), Input, Filtered),
    sort(Filtered, Output).

at_least(Minimum, Value) :-
    Value >= Minimum.

% 2. Generate the language
?- algorithm_language(
       list_tools,
       prepare_numbers(Input, Minimum, Output),
       [chat(true), description("Filters and sorts a number list")]).

% 3. Start the interactive REPL
?- language_repl(list_tools).
```

## REPL session example

Once the REPL is running, you interact with the generated command language:

```
list_tools> load numbers [8,2,5,1]
result(ok,"Input loaded.")

list_tools> set minimum 3
result(ok,"Minimum set.")

list_tools> prepare numbers
result(ok,[5,8])

list_tools> show result
result(ok,[5,8])

list_tools> commands
load numbers <list>
set minimum <number>
run
prepare numbers
show result
help
commands
history
clear
reset
quit
chat preview "<text>"
chat explain "<text>"
chat run "<text>"

list_tools> help
...

list_tools> history
...

list_tools> clear
result(ok,"Runtime cleared.")

list_tools> quit
```

## Chat interface

The chat commands let you drive the algorithm with plain English:

```
list_tools> chat preview "sort 8 2 5 1 but remove numbers below 3"
load numbers [8,2,5,1]
set minimum 3
run_algorithm
show_result

list_tools> chat explain "sort 8 2 5 1 but remove numbers below 3"
Translated commands:
load numbers [8,2,5,1]
set minimum 3
run_algorithm
show_result

list_tools> chat run "sort 8 2 5 1 but remove numbers below 3"
result(ok,"Input loaded.")
result(ok,"Minimum set.")
result(ok,[5,8])
result(ok,[5,8])
```

Chat translation is a deterministic pattern matcher, not a general language
model: it currently recognizes numbers and a `below N` or `minimum N` threshold.
`chat run` starts with a fresh state for each request.

## Programmatic API

```prolog
:- use_module('algorithm_language/algorithm_language').
:- use_module('algorithm_language/state').

% Build the language
?- algorithm_language(list_tools,
       prepare_numbers(Input, Minimum, Output),
       [chat(true)]).

% Run commands from code
?- initial_language_state(S0),
   run_language_command(list_tools, S0,   "load numbers [8,2,5,1]", S1, _),
   run_language_command(list_tools, S1,   "set minimum 3",          S2, _),
   run_language_command(list_tools, S2,   "prepare numbers",        _,  R),
   writeln(R).
% result(ok,[5,8])

% Get the list of generated commands
?- language_commands(list_tools, Commands),
   maplist(writeln, Commands).

% Get Markdown documentation as an atom
?- language_documentation(list_tools, Doc),
   writeln(Doc).

% Explain a single command
?- explain_language_command(list_tools, "load numbers [1,2,3]", Explanation),
   writeln(Explanation).

% Translate natural language (preview mode — no execution)
?- chat_to_commands(list_tools, preview, "sort 5 3 1 but below 4", Commands),
   maplist(writeln, Commands).

% Save and reload a generated language
?- save_language(list_tools, '/tmp/list_tools.pl').
?- load_language('/tmp/list_tools.pl', _).
```

## Generating artifact files

`build_language/1` writes all generated files to `algorithm_language/docs/` (or a directory of your choice with `build_language/2`):

```prolog
% Write artifacts to the default output directory
?- build_language(list_tools).

% Write artifacts to a custom directory
?- build_language(list_tools, '/tmp/my_lang').
```

Generated files:

| File | Description |
|------|-------------|
| `docs.md` | Markdown reference for every command |
| `examples.md` | One-liner examples for every command |
| `commands.pl` | Machine-readable command syntax list |
| `parser.pl` | Command syntax summary (not an executable parser yet) |
| `runtime.pl` | Algorithm/interface summary (not an executable runtime yet) |
| `tests.pl` | Minimal PlUnit smoke-test scaffold |
| `language.pl` | Serialised language descriptor term |

## Options

Pass options as the third argument to `algorithm_language/3`:

| Option | Default | Current behavior |
|--------|---------|------------------|
| `description(Text)` | `"Generated language"` | Stored in the language analysis; not currently included in generated Markdown |
| `chat(Bool)` | `false` | Enables/disables generated chat commands |
| `generate_docs(Bool)` | `true` | Accepted, but does not yet control documentation generation |
| `generate_tests(Bool)` | `true` | Accepted, but does not yet control test scaffolding generation |
| `single_file(Bool)` | `false` | Accepted, but combined-file output is not implemented |
| `command_style(Style)` | `simple` | Accepted, but alternate command styles are not implemented |
| `safe_mode(Bool)` | `true` | Accepted, but does not currently change validation behavior |
| `debug(Bool)` | `false` | Accepted, but debug logging is not implemented |

## Current implementation status

The in-process command model, parser, validator, runtime, Markdown command
reference, chat preview/explain/run flow, REPL, and language save/load APIs are
implemented. If the selected algorithm fails, execution now returns an explicit
`algorithm_failed(Name/Arity)` error and preserves the prior state; it does not
substitute an unrelated built-in operation.

Remaining implementation work:

- Generate executable standalone parser/runtime artifacts rather than summaries.
- Make `generate_docs/1`, `generate_tests/1`, `single_file/1`,
  `command_style/1`, `safe_mode/1`, and `debug/1` options effective.
- Expand the generated test scaffold into tests of command parsing and execution.
- Broaden algorithm analysis beyond argument-count heuristics (for example,
  source comments, modes, types, called predicates, and determinism).
- Extend chat translation beyond the current number-list/minimum patterns.

## License

See [LICENSE](LICENSE).
