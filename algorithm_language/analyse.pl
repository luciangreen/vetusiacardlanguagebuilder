:- module(algorithm_language_analyse, [
    analyse_algorithm/3,
    select_algorithm_from_module/3
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

%% select_algorithm_from_module(+Module, +Options, -Algorithm) is det.
%
%  Lists all exported predicates from Module ranked by descending arity
%  then ascending name, prompts the user to choose one, and returns a
%  callable Algorithm term for that predicate.
select_algorithm_from_module(Module, _Options, Algorithm) :-
    module_predicates_ranked(Module, Ranked),
    ( Ranked = [] ->
        throw(error(existence_error(exported_predicates, Module),
                    context(select_algorithm_from_module/3,
                            'No exported predicates found in module.')))
    ;
        length(Ranked, Len),
        format('~nPredicates in ~w (ranked by arity):~n~n', [Module]),
        print_predicate_menu(Ranked, 1),
        format('~nEnter number (1-~w): ', [Len]),
        read_predicate_choice(Ranked, Len, Name/Arity),
        functor(Algorithm, Name, Arity)
    ).

%% module_predicates_ranked(+Module, -Ranked) is det.
%
%  Collects exported predicates from Module (arity > 0, excluding
%  internal helpers) and returns them sorted by descending arity then
%  ascending name.
module_predicates_ranked(Module, Ranked) :-
    module_property(Module, exports(Exports)),
    findall(Name/Arity,
        (
            member(Name/Arity, Exports),
            Arity > 0,
            \+ internal_predicate(Name)
        ),
        Predicates),
    list_to_set(Predicates, Unique),
    predsort(compare_by_arity_then_name, Unique, Ranked).

%% internal_predicate(+Name) is semidet.
%
%  True for predicate names that are internal plumbing and should not
%  be offered as algorithm candidates.
internal_predicate(module_info).
internal_predicate(use_module).

%% compare_by_arity_then_name(+Order, +P1, +P2) is det.
%
%  Ordering relation for predsort/3: sorts Name/Arity pairs by
%  descending arity, breaking ties alphabetically by name.
compare_by_arity_then_name(Order, Name1/Arity1, Name2/Arity2) :-
    ( Arity1 > Arity2 -> Order = (<)
    ; Arity1 < Arity2 -> Order = (>)
    ; compare(Order, Name1, Name2)
    ).

%% print_predicate_menu(+Predicates, +N) is det.
%
%  Prints a numbered list of Name/Arity entries starting at index N.
print_predicate_menu([], _).
print_predicate_menu([Name/Arity|Rest], N) :-
    format('  ~w. ~w/~w~n', [N, Name, Arity]),
    N1 is N + 1,
    print_predicate_menu(Rest, N1).

%% read_predicate_choice(+Ranked, +Max, -Selected) is det.
%
%  Reads a line from user_input and returns the Nth element of Ranked.
%  Re-prompts until a valid integer in 1..Max is entered.
read_predicate_choice(Ranked, Max, Selected) :-
    read_line_to_string(user_input, Input),
    ( catch(number_string(N, Input), _, fail),
      integer(N),
      N >= 1,
      N =< Max ->
        nth1(N, Ranked, Selected)
    ;
        format('Invalid choice. Enter a number between 1 and ~w: ', [Max]),
        read_predicate_choice(Ranked, Max, Selected)
    ).
