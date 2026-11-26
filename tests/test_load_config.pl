% Tests that loading a folder keeps its configuration outside the folder.
% Run from the repository root:
%   swipl -q -s tests/test_load_config.pl -g run_tests -t halt
:- use_module(library(plunit)).
:- use_module(library(filesex)).
:- prolog_load_context(directory, Dir),
   (   atom_concat(Dir, '/../load.pl', Load), exists_file(Load)
   ->  true
   ;   atom_concat(Dir, '/load.pl', Load)
   ),
   consult(Load).

tmp_dir(Name, Dir) :-
    tmp_file(Name, Dir),
    make_directory_path(Dir).

use_config_dir(Cfg) :-
    tmp_dir(vclb_cfg, Cfg),
    retractall(vclb_config_dir_override(_)),
    assertz(vclb_config_dir_override(Cfg)).

:- begin_tests(load_config).

test(config_name_from_full_path) :-
    vclb_config_file_name('/Users/a/GitHub/my repo', N),
    N == '_Users_a_GitHub_my_repo.vclb'.

test(config_name_ignores_trailing_slash) :-
    vclb_config_file_name('/x/y/', A),
    vclb_config_file_name('/x/y', B),
    A == B.

test(same_name_different_parent_differs) :-
    vclb_config_file_name('/a/GitHub/r', A),
    vclb_config_file_name('/a/GitHub-private/r', B),
    A \== B.

test(config_path_is_in_config_dir) :-
    use_config_dir(Cfg),
    vclb_config_path('/some/folder', P),
    atom_concat(Cfg, '/_some_folder.vclb', P).

test(default_config_not_written_into_loaded_folder) :-
    use_config_dir(_),
    tmp_dir(vclb_repo, Repo),
    vclb_config_path(Repo, P),
    generate_default_vclb(P),
    exists_file(P),
    atom_concat(Repo, '/config.vclb', Legacy),
    \+ exists_file(Legacy),
    read_config_terms(P, Terms),
    memberchk(vclb_version(1.0), Terms).

test(legacy_config_copied_not_deleted) :-
    use_config_dir(_),
    tmp_dir(vclb_repo2, Repo),
        legacy_vclb_path(Repo, Legacy),
        write_config_terms(Legacy, [vclb_version(1.0),
                                    source_file('/r/a.pl'),
                                    source_predicate(go/2)]),
        vclb_config_path(Repo, P),
        copy_legacy_vclb(Legacy, P),
        read_config_terms(P, Terms),
        Terms == [vclb_version(1.0), source_file('/r/a.pl'), source_predicate(go/2)],
        exists_file(Legacy).

test(remember_selection_updates_config) :-
    use_config_dir(_),
        vclb_config_path('/r3', P),
        generate_default_vclb(P),
        remember_selection(P, '/r3/a.pl', f/2),
        remember_selection(P, '/r3/b.pl', g/1),
        load_remembered_selection(P, F, PI),
        F == '/r3/b.pl', PI == g/1.

% Needs setenv/2 (SWI-Prolog has it); skipped where it is missing.
test(github_paths_from_environment) :-
    (   catch(setenv('VCLB_GITHUB_PATHS', '/p/one/:/p/two/'), _, fail)
    ->  findall(P, get_github_base_path(P), Ps),
        unsetenv('VCLB_GITHUB_PATHS'),
        Ps == ['/p/one/', '/p/two/']
    ;   true
    ).

:- end_tests(load_config).
