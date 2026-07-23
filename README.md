# vetusiacardlanguagebuilder

Automatically generates a command-line language and interactive chat interface from a Prolog algorithm. Point it at any Prolog predicate and get a full mini-language with a parser, runtime, validator, Markdown documentation, test scaffolding, and a REPL — all generated for you.

## Features

- **Language generation** — analyses a Prolog predicate and builds a structured command model from its arguments
- **Parser & runtime** — generates `parser.pl` and `runtime.pl` that handle command parsing, validation, and execution
- **Documentation** — produces `docs.md` and `examples.md` describing every generated command
- **Test scaffolding** — generates `tests.pl` with skeletons for each command
- **REPL** — an interactive Read-Eval-Print loop (`language_repl/1`) ready to use immediately
- **Chat interface** — translates natural-language text to generated commands via `preview`, `explain`, and `run` modes
- **Artifact save/load** — persist a generated language to disk and reload it later

## Requirements

- [SWI-Prolog](https://www.swi-prolog.org/) 8.x or later

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
result(ok, input_set(numbers,[8,2,5,1]))

list_tools> set minimum 3
result(ok, input_set(minimum,3))

list_tools> prepare numbers
result(ok,[3,5,8])

list_tools> show result
result(ok,[3,5,8])

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
result(ok,cleared)

list_tools> quit
```

## Chat interface

The chat commands let you drive the algorithm with plain English:

```
list_tools> chat preview "sort 8 2 5 1 minimum 3"
set_input(numbers,[8,2,5,1])
set_input(minimum,3)
run_algorithm
show_result

list_tools> chat explain "sort 8 2 5 1 minimum 3"
Translated commands:
set_input(numbers,[8,2,5,1])
set_input(minimum,3)
run_algorithm
show_result

list_tools> chat run "sort 8 2 5 1 minimum 3"
result(ok,input_set(numbers,[8,2,5,1]))
result(ok,input_set(minimum,3))
result(ok,[5,8])
result(ok,[5,8])
```

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
% result(ok,[3,5,8])

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
| `parser.pl` | Generated command parser |
| `runtime.pl` | Generated command runtime |
| `tests.pl` | Generated test scaffolding |
| `language.pl` | Serialised language descriptor term |

## Options

Pass options as the third argument to `algorithm_language/3`:

| Option | Default | Description |
|--------|---------|-------------|
| `description(Text)` | `"Generated language"` | Human-readable description |
| `chat(Bool)` | `false` | Enable chat translation commands |
| `generate_docs(Bool)` | `true` | Include documentation commands |
| `generate_tests(Bool)` | `true` | Generate test scaffolding |
| `single_file(Bool)` | `false` | Emit a single combined artifact file |
| `command_style(Style)` | `simple` | Command naming style |
| `safe_mode(Bool)` | `true` | Reject unrecognised commands |
| `debug(Bool)` | `false` | Print debug information |

## Running the bundled example

```bash
cd algorithm_language/examples
swipl -g "consult(list_tools_example), run_example, halt" -t halt
```

## License

See [LICENSE](LICENSE).
