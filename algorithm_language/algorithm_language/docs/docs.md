# Generated Language Documentation


## load_input(input)

**Purpose**: Sets required input.

**Syntax**: `load numbers <list>`

**Arguments**: [list]

**Effect**: Updates language state.

**Related**: run_algorithm, show_result

## set_input(minimum)

**Purpose**: Sets required input.

**Syntax**: `set minimum <number>`

**Arguments**: [number]

**Effect**: Updates language state.

**Related**: run_algorithm, show_result

## run_algorithm

**Purpose**: Runs prepare_numbers.

**Syntax**: `run`

**Arguments**: []

**Effect**: Executes the algorithm.

**Related**: show_result

## run_algorithm

**Purpose**: Runs prepare_numbers.

**Syntax**: `prepare numbers`

**Arguments**: []

**Effect**: Executes the algorithm.

**Related**: show_result

## show_result

**Purpose**: Displays the latest result.

**Syntax**: `show result`

**Arguments**: []

**Effect**: No state change.

**Related**: run_algorithm

## help

**Purpose**: Shows help.

**Syntax**: `help`

**Arguments**: []

**Effect**: No state change.

**Related**: commands

## commands

**Purpose**: Lists available commands.

**Syntax**: `commands`

**Arguments**: []

**Effect**: No state change.

**Related**: help

## history

**Purpose**: Shows command history.

**Syntax**: `history`

**Arguments**: []

**Effect**: No state change.

**Related**: commands

## clear

**Purpose**: Clears runtime values.

**Syntax**: `clear`

**Arguments**: []

**Effect**: Resets inputs/settings/results.

**Related**: reset

## reset

**Purpose**: Resets full language state.

**Syntax**: `reset`

**Arguments**: []

**Effect**: Resets language state.

**Related**: clear

## quit

**Purpose**: Exits the REPL.

**Syntax**: `quit`

**Arguments**: []

**Effect**: Ends session.

**Related**: help

## chat_preview

**Purpose**: Shows translated commands.

**Syntax**: `chat preview "<text>"`

**Arguments**: [string]

**Effect**: No execution.

**Related**: chat_explain, chat_run

## chat_explain

**Purpose**: Explains translated commands.

**Syntax**: `chat explain "<text>"`

**Arguments**: [string]

**Effect**: No execution.

**Related**: chat_preview, chat_run

## chat_run

**Purpose**: Translates and executes text.

**Syntax**: `chat run "<text>"`

**Arguments**: [string]

**Effect**: Runs validated commands.

**Related**: chat_preview, chat_explain

