:- use_module(library(lists)).
:- use_module(library(filesex)). % For directory and file operations
:- use_module('/Users/lg3/Dropbox/GitHub/vetusiacardlanguagebuilder/algorithm_language/algorithm_language').
:- use_module('/Users/lg3/Dropbox/GitHub/vetusiacardlanguagebuilder/algorithm_language/state').

:- dynamic history/2. % Stores query history to track popularity

% =========================================================================
% 1. Main Entry Point
% =========================================================================
language_repl :-
    writeln('--- VCLB Folder Loader REPL ---'),
    writeln('Commands: "load <folder_name>" or "tab <prefix>" (or just "tab")'),
    writeln('Type "exit" to quit.'),
    repl_loop.

% =========================================================================
% 2. REPL Loop & Input Handling
% =========================================================================
repl_loop :-
    write('vclb> '),
    flush_output,
    read_line_to_string(user_input, Input),
    normalize_space(string(CleanInput), Input),
    (   CleanInput == "exit"
    ->  writeln('Exiting REPL.')
    ;   process_command(CleanInput),
        repl_loop
    ).

% =========================================================================
% 3. Command Processing & VCLB Loading
% =========================================================================
% Matches 'load <folder_name>'
process_command(Input) :-
    sub_string(Input, 0, 5, _, "load "), !,
    sub_string(Input, 5, _, 0, FolderName),
    atom_string(FolderAtom, FolderName),
    (   find_github_folder(FolderAtom, FullPath)
    ->  load_vclb(FullPath)
    ;   true
    ).

% Matches 'tab <prefix>' for autocomplete suggestions
process_command(Input) :-
    sub_string(Input, 0, 4, _, "tab "), !,
    sub_string(Input, 4, _, 0, PrefixStr),
    atom_string(PrefixAtom, PrefixStr),
    show_suggestions(PrefixAtom).

% Matches standalone 'tab' (empty prefix, shows all popular choices)
process_command("tab") :- !,
    show_suggestions('').

% Fallback for unknown commands
process_command(_) :-
    writeln('Error: Unknown command.'),
    writeln('Use "load <folder_name>", "tab <prefix>", or "tab" for suggestions.').

% UI helper to fetch and display the sorted suggestions
show_suggestions(Prefix) :-
    get_popular_suggestions(Prefix, Suggestions),
    (   Suggestions == []
    ->  writeln('No matching folders found.')
    ;   writeln('Popular suggestions (most frequent first):'),
        print_list(Suggestions)
    ).

print_list([]).
print_list([H|T]) :-
    format('  - ~w~n', [H]),
    print_list(T).

% 1. Core entry predicate that checks config and runs the targeted scan
load_vclb(FolderPath) :-
    atom_concat(FolderPath, '/config.vclb', VclbPath),
    (   exists_file(VclbPath)
    ->  format('Success: Loaded configuration from ~w~n', [VclbPath])
    ;   format('Warning: ~w missing. Generating default config...~n', [VclbPath]),
        generate_default_vclb(VclbPath)
    ),
    % Trigger the scan inside the verified folder
    scan_and_load(FolderPath).


% Safely creates a fresh config.vclb file with initial contents
generate_default_vclb(VclbPath) :-
    catch(
        (   open(VclbPath, write, Stream),
            writeln(Stream, '% Auto-generated VCLB Configuration'),
            writeln(Stream, 'vclb_version(1.0).'),
            writeln(Stream, 'status(initialized).'),
            close(Stream),
            format('Success: Created default config at ~w~n', [VclbPath])
        ),
        Error,
        format('Error: Could not generate file. Reason: ~w~n', [Error])
    ).

% =========================================================================
% 4. GitHub Folder Collection & Popularity Sorting
% =========================================================================
% Resolves folder name inside Dropbox/GitHub/*
find_github_folder(FolderAtom, FullPath) :-
    get_github_base_path(BasePath),
    atom_concat(BasePath, FolderAtom, FullPath),
    exists_directory(FullPath), !,
    log_query(FolderAtom). % Log success to boost popularity

find_github_folder(FolderAtom, _) :-
    format('Error: Folder "~w" not found in active Dropbox/GitHub paths.~n', [FolderAtom]),
    fail.

% Define base paths
get_github_base_path('Dropbox/GitHub/').
get_github_base_path('Dropbox/GitHub-private/').

% Track search counts dynamically
log_query(FolderAtom) :-
    (   retract(history(FolderAtom, Count))
    ->  NewCount is Count + 1
    ;   NewCount is 1
    ),
    asserta(history(FolderAtom, NewCount)).

% =========================================================================
% 5. Autocomplete & Popular Query Sorting
% =========================================================================
% Gathers all matching folders sorted by usage frequency
get_popular_suggestions(Prefix, SortedMatches) :-
    findall(Folders, (
        get_github_base_path(BasePath),
        atom_concat(BasePath, '*', SearchPattern),
        expand_file_name(SearchPattern, AllPaths),
        extract_folder_names(AllPaths, BasePath, Folders)
    ), AllLists),
    append(AllLists, CombinedFolders),
    list_to_set(CombinedFolders, UniqueFolders), % Deduplicate across paths
    include(sub_atom_prefix(Prefix), UniqueFolders, MatchingFolders),
    get_frequencies(MatchingFolders, WeightedPairs),
    keysort(WeightedPairs, DescendingPairs),
    pairs_values(DescendingPairs, SortedMatches).

% Helper to filter prefixes
sub_atom_prefix(Prefix, Atom) :-
    sub_atom(Atom, 0, _, _, Prefix).

% Attach frequencies for sorting (higher counts sort first via negative keys)
get_frequencies([], []).
get_frequencies([H|T], [NegCount-H|Rest]) :-
    (   history(H, Count)
    ->  true
    ;   Count = 0
    ),
    NegCount is -Count,
    get_frequencies(T, Rest).

% Strips parent directory path to return only the folder names
extract_folder_names([], _, []).
extract_folder_names([Path|Paths], BasePath, [Folder|Folders]) :-
    atom_concat(BasePath, Folder, Path), !,
    extract_folder_names(Paths, BasePath, Folders).
extract_folder_names([_|Paths], BasePath, Folders) :-
    extract_folder_names(Paths, BasePath, Folders).




% Main entry point to scan and select a file
scan_and_load(FolderPath) :-
    % Dynamically build a search pattern matching files inside the chosen FolderPath
    % e.g., "FolderPath/*/*README*"
    atomic_list_concat([FolderPath, '/*/*.pl'], Pattern),
    expand_file_name(Pattern, AllFiles),
    include(exists_file, AllFiles, ValidFiles1),

    atomic_list_concat([FolderPath, '/*.pl'], Pattern2),
    expand_file_name(Pattern2, AllFiles2),
    include(exists_file, AllFiles2, ValidFiles2),
    append(ValidFiles1,ValidFiles2,ValidFiles),
    
    (   ValidFiles = []
    ->  format('No *.pl files found inside: ~w~n', [FolderPath])
    ;   print_options(ValidFiles, 1),
        read_selection(ValidFiles, SelectedFile),
        process_pl(SelectedFile)
    ).

% 3. Menu and choice matching UI
print_options([], _).
print_options([File|Tail], Index) :-
    format('~w: ~w~n', [Index, File]),
    NextIndex is Index + 1,
    print_options(Tail, NextIndex).

read_selection(Files, SelectedFile) :-
    write('Enter the number of the file to load: '),
    read_line_to_string(user_input, String),
    number_string(Choice, String),
    (   nth1(Choice, Files, SelectedFile)
    ->  format('Loaded: ~w~n', [SelectedFile])
    ;   writeln('Invalid selection. Try again.'),
        read_selection(Files, SelectedFile)
    ).

prepare_pl_analysis(FilePath, Output) :-
    Output = FilePath.


/*
Usage:

    ?- process_pl('README.pl').

The predicate:

1. Scans File for predicate definitions and dependencies.
2. Ranks the predicates.
3. Recommends the most important predicates.
4. Derives a program name from File.
5. Calls:

       algorithm_language(
           ProgramName,
           predicate(Input, Output),
           [...]
       ).

6. Starts the generated language REPL.
*/

process_pl(File) :-
    must_be(atom, File),

    program_name_from_file(File, ProgramName),

    scan_predicate_dependencies(
        File,
        DependencyGraph,
        RecommendedPredicates
    ),

    print_dependency_report(
        DependencyGraph,
        RecommendedPredicates
    ),

    select_program_predicate(
        RecommendedPredicates,
        PredicateIndicator
    ),

    predicate_language_goal(
        PredicateIndicator,
        Input,
        Output,
        LanguageGoal
    ),

    format(
        'Generating language "~w" from ~q.~n',
        [ProgramName, PredicateIndicator]
    ),

    algorithm_language(
        ProgramName,
        LanguageGoal,
        [
            chat(true),
            description("Processes selected GitHub README file"),
            source_file(File),
            source_predicate(PredicateIndicator),
            dependency_graph(DependencyGraph),
            recommended_predicates(RecommendedPredicates),
            input(Input),
            output(Output)
        ]
    ),

    language_repl(ProgramName).


/* ------------------------------------------------------------------
   Program-name generation
   ------------------------------------------------------------------ */

program_name_from_file(File, ProgramName) :-
    file_base_name(File, BaseName),
    file_name_extension(Name0, _, BaseName),
    normalise_program_name(Name0, ProgramName).

normalise_program_name(Name0, ProgramName) :-
    atom_chars(Name0, Chars0),
    maplist(normalise_name_character, Chars0, Chars1),
    collapse_underscores(Chars1, Chars2),
    remove_edge_underscores(Chars2, Chars3),
    ensure_valid_program_name(Chars3, ValidChars),
    atom_chars(ProgramName, ValidChars).

normalise_name_character(Char, Normalised) :-
    (   char_type(Char, alnum)
    ->  downcase_atom(Char, Normalised)
    ;   Normalised = '_'
    ).

collapse_underscores([], []).
collapse_underscores(['_', '_'|Chars], Result) :-
    !,
    collapse_underscores(['_'|Chars], Result).
collapse_underscores([Char|Chars], [Char|Result]) :-
    collapse_underscores(Chars, Result).

remove_edge_underscores(Chars0, Chars) :-
    drop_leading_underscores(Chars0, Chars1),
    reverse(Chars1, Reversed1),
    drop_leading_underscores(Reversed1, Reversed2),
    reverse(Reversed2, Chars).

drop_leading_underscores(['_'|Chars], Result) :-
    !,
    drop_leading_underscores(Chars, Result).
drop_leading_underscores(Chars, Chars).

ensure_valid_program_name([], [p, r, o, g, r, a, m]).
ensure_valid_program_name([First|Rest], ValidChars) :-
    (   char_type(First, alpha)
    ->  ValidChars = [First|Rest]
    ;   ValidChars = [p, '_' , First|Rest]
    ).


/* ------------------------------------------------------------------
   Dependency scanning
   ------------------------------------------------------------------ */

scan_predicate_dependencies(File, Graph, Recommendations) :-
    read_source_terms(File, Terms),
    collect_predicate_data(Terms, PredicateData),
    build_dependency_graph(PredicateData, Graph),
    rank_predicates(Graph, Recommendations).


read_source_terms(File, Terms) :-
    setup_call_cleanup(
        open(File, read, Stream, [encoding(utf8)]),
        read_terms(Stream, Terms),
        close(Stream)
    ).

read_terms(Stream, Terms) :-
    read_term(
        Stream,
        Term,
        [
            syntax_errors(dec10),
            comments(_Comments)
        ]
    ),
    (   Term == end_of_file
    ->  Terms = []
    ;   Terms = [Term|Rest],
        read_terms(Stream, Rest)
    ).


collect_predicate_data(Terms, PredicateData) :-
    findall(
        predicate_data(HeadPI, Dependencies),
        (
            member(Term, Terms),
            source_clause(Term, Head, Body),
            callable(Head),
            predicate_indicator(Head, HeadPI),
            body_dependencies(Body, Dependencies0),
            sort(Dependencies0, Dependencies)
        ),
        PredicateData
    ).


source_clause((:- _Directive), _, _) :-
    !,
    fail.
source_clause((Head :- Body), Head, Body) :-
    !.
source_clause(Fact, Fact, true) :-
    callable(Fact).


predicate_indicator(Goal, Name/Arity) :-
    strip_module(Goal, _, PlainGoal),
    functor(PlainGoal, Name, Arity).


body_dependencies(Body, Dependencies) :-
    findall(
        PredicateIndicator,
        (
            body_goal(Body, Goal),
            dependency_goal(Goal),
            predicate_indicator(Goal, PredicateIndicator)
        ),
        Dependencies
    ).


body_goal(Var, _) :-
    var(Var),
    !,
    fail.
body_goal(true, _) :-
    !,
    fail.
body_goal((A, B), Goal) :-
    !,
    (
        body_goal(A, Goal)
    ;
        body_goal(B, Goal)
    ).
body_goal((A ; B), Goal) :-
    !,
    (
        body_goal(A, Goal)
    ;
        body_goal(B, Goal)
    ).
body_goal((If -> Then), Goal) :-
    !,
    (
        body_goal(If, Goal)
    ;
        body_goal(Then, Goal)
    ).
body_goal((If *-> Then), Goal) :-
    !,
    (
        body_goal(If, Goal)
    ;
        body_goal(Then, Goal)
    ).
body_goal(\+ Goal0, Goal) :-
    !,
    body_goal(Goal0, Goal).
body_goal(once(Goal0), Goal) :-
    !,
    body_goal(Goal0, Goal).
body_goal(call(Goal0), Goal) :-
    callable(Goal0),
    !,
    body_goal(Goal0, Goal).
body_goal(Module:Goal0, Module:Goal) :-
    atom(Module),
    !,
    body_goal(Goal0, Goal).
body_goal(Goal, Goal) :-
    callable(Goal).


dependency_goal(Goal) :-
    callable(Goal),
    predicate_indicator(Goal, PredicateIndicator),
    \+ ignored_dependency(PredicateIndicator).


ignored_dependency(true/0).
ignored_dependency(fail/0).
ignored_dependency(!/0).
ignored_dependency('=' / 2).
ignored_dependency('\\=' / 2).
ignored_dependency('==' / 2).
ignored_dependency('\\==' / 2).
ignored_dependency('@<' / 2).
ignored_dependency('@=<' / 2).
ignored_dependency('@>' / 2).
ignored_dependency('@>=' / 2).
ignored_dependency(is/2).
ignored_dependency('=:='/2).
ignored_dependency('=\\='/2).
ignored_dependency('<'/2).
ignored_dependency('=<'/2).
ignored_dependency('>'/2).
ignored_dependency('>='/2).
ignored_dependency(var/1).
ignored_dependency(nonvar/1).
ignored_dependency(atom/1).
ignored_dependency(integer/1).
ignored_dependency(number/1).
ignored_dependency(compound/1).
ignored_dependency(callable/1).


/* ------------------------------------------------------------------
   Graph construction
   ------------------------------------------------------------------ */

build_dependency_graph(PredicateData, Graph) :-
    defined_predicates(PredicateData, DefinedPredicates),
    findall(
        predicate(
            PredicateIndicator,
            Calls,
            CalledBy,
            ClauseCount,
            Score
        ),
        (
            member(PredicateIndicator, DefinedPredicates),

            predicate_calls(
                PredicateIndicator,
                PredicateData,
                Calls
            ),

            predicate_callers(
                PredicateIndicator,
                PredicateData,
                CalledBy
            ),

            predicate_clause_count(
                PredicateIndicator,
                PredicateData,
                ClauseCount
            ),

            predicate_score(
                Calls,
                CalledBy,
                ClauseCount,
                Score
            )
        ),
        Graph
    ).


defined_predicates(PredicateData, DefinedPredicates) :-
    findall(
        PredicateIndicator,
        member(
            predicate_data(PredicateIndicator, _),
            PredicateData
        ),
        PredicateIndicators
    ),
    sort(PredicateIndicators, DefinedPredicates).


predicate_calls(PredicateIndicator, PredicateData, Calls) :-
    findall(
        CalledPredicate,
        (
            member(
                predicate_data(PredicateIndicator, Dependencies),
                PredicateData
            ),
            member(CalledPredicate, Dependencies)
        ),
        Calls0
    ),
    sort(Calls0, Calls).


predicate_callers(PredicateIndicator, PredicateData, CalledBy) :-
    findall(
        Caller,
        (
            member(
                predicate_data(Caller, Dependencies),
                PredicateData
            ),
            memberchk(PredicateIndicator, Dependencies)
        ),
        CalledBy0
    ),
    sort(CalledBy0, CalledBy).


predicate_clause_count(PredicateIndicator, PredicateData, Count) :-
    aggregate_all(
        count,
        member(
            predicate_data(PredicateIndicator, _),
            PredicateData
        ),
        Count
    ).


/*
Ranking gives more weight to incoming dependencies because predicates
called by many other predicates are usually central implementation
predicates.

Outgoing dependencies and multiple clauses also contribute.
*/

predicate_score(Calls, CalledBy, ClauseCount, Score) :-
    length(Calls, OutgoingCount),
    length(CalledBy, IncomingCount),
    Score is
        IncomingCount * 5 +
        OutgoingCount * 2 +
        ClauseCount.


/* ------------------------------------------------------------------
   Recommendations
   ------------------------------------------------------------------ */

rank_predicates(Graph, Recommendations) :-
    findall(
        Score-PredicateIndicator,
        member(
            predicate(
                PredicateIndicator,
                _Calls,
                _CalledBy,
                _ClauseCount,
                Score
            ),
            Graph
        ),
        ScoredPredicates0
    ),
    keysort(ScoredPredicates0, Ascending),
    reverse(Ascending, Descending),
    take_first(10, Descending, TopPairs),
    pairs_values(TopPairs, Recommendations).


take_first(0, _, []) :-
    !.
take_first(_, [], []) :-
    !.
take_first(N, [Item|Items], [Item|Selected]) :-
    N > 0,
    N1 is N - 1,
    take_first(N1, Items, Selected).


select_program_predicate([PredicateIndicator|_], PredicateIndicator) :-
    !.
select_program_predicate([], _) :-
    throw(
        error(
            existence_error(predicate, source_file),
            context(
                process_pl/1,
                'No Prolog predicates were found in the selected file'
            )
        )
    ).


/* ------------------------------------------------------------------
   Construct predicate(Input, Output)
   ------------------------------------------------------------------ */

/*
For a selected predicate such as process/2, this constructs:

    process(Input, Output)

For process/1:

    process(Input)

For process/3 or greater:

    process(Input, Output, Extra1, ...)

Input and Output are returned separately so they can also be supplied
to algorithm_language/3 as metadata.
*/

predicate_language_goal(Name/Arity, Input, Output, Goal) :-
    Arity >= 0,
    functor(Goal, Name, Arity),
    Goal =.. [Name|Arguments],
    assign_language_arguments(
        Arguments,
        Input,
        Output
    ).

assign_language_arguments([], none, none).
assign_language_arguments([Input], Input, none).
assign_language_arguments([Input, Output|Rest], Input, Output) :-
    initialise_extra_arguments(Rest).

initialise_extra_arguments([]).
initialise_extra_arguments([_|Rest]) :-
    initialise_extra_arguments(Rest).


/* ------------------------------------------------------------------
   Report
   ------------------------------------------------------------------ */

print_dependency_report(Graph, Recommendations) :-
    format('~nPredicate dependency scan~n', []),
    format('=========================~n', []),

    forall(
        member(
            predicate(
                PredicateIndicator,
                Calls,
                CalledBy,
                ClauseCount,
                Score
            ),
            Graph
        ),
        (
            format('~n~q~n', [PredicateIndicator]),
            format('  clauses: ~d~n', [ClauseCount]),
            format('  calls: ~q~n', [Calls]),
            format('  called by: ~q~n', [CalledBy]),
            format('  score: ~d~n', [Score])
        )
    ),

    format('~nRecommended top predicates:~n', []),
    print_recommendations(Recommendations, 1),
    nl.


print_recommendations([], _).
print_recommendations(
    [PredicateIndicator|Predicates],
    Index
) :-
    format('  ~d. ~q~n', [Index, PredicateIndicator]),
    NextIndex is Index + 1,
    print_recommendations(Predicates, NextIndex).
    
make_predicate_call(PredicateName, 2, I, O, PredicateCall) :-
    PredicateCall =.. [PredicateName, I, O].

make_predicate_call(PredicateName, 1, I, _, PredicateCall) :-
    PredicateCall =.. [PredicateName, I].

make_predicate_call(PredicateName, Arity, I, O, PredicateCall) :-
    Arity > 2,
    length(Arguments, Arity),
    Arguments = [I, O|_],
    PredicateCall =.. [PredicateName|Arguments].    