:- module(algorithm_language_parser_builder, [
    parse_language_command/3
]).

:- use_module(library(dcg/basics)).
:- use_module(command_model).

parse_language_command(Language, Text, Command) :-
    tokenize_command(Text, Tokens),
    ( parse_with_specs(Language.commands, Tokens, Command) ->
        true
    ; throw(error(language_parse_error(Text, "Unknown or malformed command"), _))
    ).

parse_with_specs([Spec|_], Tokens, Command) :-
    spec_tokens_match(Spec.words, Tokens, Remaining),
    parse_args(Spec.arg_types, Remaining, [], ArgValues),
    build_command_from_id(Spec.id, ArgValues, Command),
    !.
parse_with_specs([_|Rest], Tokens, Command) :-
    parse_with_specs(Rest, Tokens, Command).

spec_tokens_match([], Tokens, Tokens).
spec_tokens_match([Word|Words], [Token|Tokens], Remaining) :-
    downcase_atom(Token, TokenLower),
    downcase_atom(Word, WordLower),
    TokenLower = WordLower,
    spec_tokens_match(Words, Tokens, Remaining).

parse_args([], [], Acc, ArgValues) :-
    reverse(Acc, ArgValues).
parse_args([], [_|_], _, _) :-
    fail.
parse_args([Type|Types], [Token|Tokens], Acc, ArgValues) :-
    parse_arg(Type, Token, Value),
    parse_args(Types, Tokens, [Value|Acc], ArgValues).

parse_arg(number, Token, Number) :-
    catch(number_string(Number, Token), _, fail).
parse_arg(list, Token, List) :-
    catch(term_string(Term, Token), _, fail),
    is_list(Term),
    List = Term.
parse_arg(string, Token, Token).
parse_arg(value, Token, Value) :-
    ( catch(number_string(Number, Token), _, fail) ->
        Value = Number
    ; catch(term_string(Term, Token), _, fail) ->
        Value = Term
    ; atom_string(Value, Token)
    ).

tokenize_command(Text, Tokens) :-
    text_to_string(Text, String),
    string_codes(String, Codes),
    phrase(tokens(Tokens), Codes).

tokens([Token|Tokens]) -->
    ws,
    token(Token),
    !,
    tokens(Tokens).
tokens([]) -->
    ws,
    [].

token(Token) -->
    "\"",
    string_without("\"", Codes),
    "\"",
    { string_codes(Token, Codes) }.
token(Token) -->
    "[",
    string_without("]", Inner),
    "]",
    {
        string_codes(InnerText, Inner),
        format(string(Token), "[~w]", [InnerText])
    }.
token(Token) -->
    string_without(" \t\n", Codes),
    { Codes \= [], string_codes(Token, Codes) }.

ws --> [C], { code_type(C, space) }, !, ws.
ws --> [].

text_to_string(Text, String) :-
    ( string(Text) ->
        String = Text
    ; atom(Text) ->
        atom_string(Text, String)
    ; throw(error(type_error(text, Text), _))
    ).
