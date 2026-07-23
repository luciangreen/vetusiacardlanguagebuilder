:- module(algorithm_language_documentation_builder, [
    language_documentation/2,
    explain_language_command/3
]).

language_documentation(Language, Documentation) :-
    Header = "# Generated Language Documentation\n\n",
    findall(Block, command_doc_block(Language, Block), Blocks),
    atomic_list_concat([Header|Blocks], "\n", Documentation).

command_doc_block(Language, Block) :-
    member(Spec, Language.commands),
    command_doc_markdown(Language, Spec, Block).

command_doc_markdown(_Language, Spec, Block) :-
    atomic_list_concat(Spec.related, ", ", RelatedText),
    format(atom(Block),
        "## ~w\n\n**Purpose**: ~w\n\n**Syntax**: `~w`\n\n**Arguments**: ~w\n\n**Effect**: ~w\n\n**Related**: ~w\n",
        [Spec.id, Spec.purpose, Spec.syntax, Spec.arg_types, Spec.effect, RelatedText]).

explain_language_command(Language, CommandText, Explanation) :-
    text_to_atom(CommandText, CommandAtom),
    downcase_atom(CommandAtom, CommandLower),
    member(Spec, Language.commands),
    downcase_atom(Spec.syntax, Syntax),
    sub_atom(Syntax, 0, _, _, CommandLower),
    !,
    format(atom(Explanation), '~w: ~w', [Spec.syntax, Spec.purpose]).
explain_language_command(_, CommandText, Explanation) :-
    format(atom(Explanation), 'No documentation found for "~w".', [CommandText]).

text_to_atom(Text, Atom) :-
    ( atom(Text) ->
        Atom = Text
    ; string(Text) ->
        atom_string(Atom, Text)
    ).
