:- module(algorithm_language_analyse, [
    analyse_algorithm/3,
    select_algorithm_from_module/3
]).

analyse_algorithm(Algorithm, Options, Analysis) :-
    must_be(callable, Algorithm),
    Algorithm =.. [Predicate|Args],
    length(Args, Arity),
    algorithm_argument_names(Algorithm, Options, ArgNames),
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

%% algorithm_argument_names(+Algorithm, +Options, -Names) is det.
%
%  The arguments' names, from (in order): an arg_names(Names) option; the
%  variable names in the head of the predicate's first clause in its source
%  file (prepare_numbers(Input, Minimum, Output) gives input, minimum and
%  output), for three or more arguments; otherwise names from the number of
%  arguments.  (Before, any
%  three-argument predicate was given input, minimum and output.)
algorithm_argument_names(Algorithm, Options, Names) :-
    functor(Algorithm, _, Arity),
    (   memberchk(arg_names(Names0), Options), length(Names0, Arity)
    ->  Names = Names0
    ;   Arity >= 3,          % one and two arguments keep arg1, and input and output
        memberchk(source_module(M), Options),
        catch(source_argument_names(M, Algorithm, Names1), _, fail)
    ->  Names = Names1
    ;   argument_names(Arity, Names)
    ).

source_argument_names(M, Algorithm, Names) :-
    functor(Algorithm, F, A),
    functor(Head0, F, A),
    once(clause(M:Head0, _, Ref)),
    clause_property(Ref, file(File)),
    clause_property(Ref, line_count(Line)),
    head_names_at(File, Line, F, A, Names).

%% head_names_at(+File, +Line, +Name, +Arity, -Names) is semidet.
%  Reads the clause starting at Line of File and names each head argument
%  from its variable: Input becomes input, _Input becomes input. Fails if an
%  argument is not a variable or two names are the same.
head_names_at(File, Line, F, A, Names) :-
    setup_call_cleanup(
        open(File, read, S),
        ( skip_lines(S, Line), read_term(S, T, [variable_names(VN)]) ),
        close(S)),
    ( T = (Head :- _) -> true ; Head = T ),
    functor(Head, F, A),
    Head =.. [_|Args],
    maplist(variable_label(VN), Args, Names),
    sort(Names, Unique), length(Unique, A).

skip_lines(_, 1) :- !.
skip_lines(S, N) :- read_line_to_string(S, _), N1 is N - 1, skip_lines(S, N1).

variable_label(VN, Arg, Label) :-
    var(Arg),
    member(Name = V, VN), V == Arg, !,
    atom_codes(Name, Codes0),
    ( Codes0 = [0'_|Codes] -> true ; Codes = Codes0 ),
    Codes \== [],
    atom_codes(Atom, Codes),
    camel_to_snake(Atom, Label).

camel_to_snake(Atom, Snake) :-
    atom_chars(Atom, [C0|Cs]),
    downcase_atom(C0, L0),
    foldl([C, A0, A1]>>( char_type(C, upper(Lower)) -> append(A0, ['_', Lower], A1) ; append(A0, [C], A1) ), Cs, [L0], Chars),
    atom_chars(Snake, Chars).

argument_names(1, [arg1]) :- !.
argument_names(2, [input, output]) :- !.
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

split_input_output([arg1], [arg1], none) :- !.
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
