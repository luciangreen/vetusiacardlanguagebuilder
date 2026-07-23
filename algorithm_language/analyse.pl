:- module(algorithm_language_analyse, [
    analyse_algorithm/3
]).

analyse_algorithm(Algorithm, Options, Analysis) :-
    must_be(callable, Algorithm),
    Algorithm =.. [Predicate|Args],
    length(Args, Arity),
    argument_names(Arity, ArgNames),
    split_input_output(ArgNames, InputArgs, OutputArg),
    option_description(Options, Description),
    atomic_list_concat(PredicateWords, '_', Predicate),
    Analysis = analysis{
        predicate: Predicate,
        predicate_words: PredicateWords,
        arity: Arity,
        argument_names: ArgNames,
        input_args: InputArgs,
        output_arg: OutputArg,
        comments: "",
        called_predicates: [],
        determinism: det,
        semideterminism: semidet,
        description: Description
    }.

argument_names(2, [input, output]) :- !.
argument_names(3, [input, minimum, output]) :- !.
argument_names(Arity, Names) :-
    findall(Name,
        (
            between(1, Arity, Index),
            ( Index =:= Arity ->
                Name = output
            ; atom_concat(arg, Index, Name)
            )
        ),
        Names
    ).

split_input_output([Only], [], Only) :- !.
split_input_output(ArgNames, InputArgs, OutputArg) :-
    append(InputArgs, [OutputArg], ArgNames).

option_description(Options, Description) :-
    ( memberchk(description(Description), Options) ->
        true
    ; Description = "Generated language"
    ).
