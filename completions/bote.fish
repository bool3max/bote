# a fish shell completion file for the bote script

set progname 'bote'
set mainops_long 'create-category' 'remove-category' 'move-category' 'create' 'remove' 'move' 'sanitize' 'list' 'backup' 'restore' 'edit' 'view'
set mainops_short 'C' 'D' 'M' 'c' 'd' 'm' 's' 'l' 'b' 'r' 'e' 'v'
set mainops_all $mainops_long $mainops_short
set opts 'h/help' 'r/root-directory=' 'S/stylesheet=' 'L/logfile=' 'z/gzip' # mirrored from the main script

set -q BOTE_ROOTDIR && set rootdir $BOTE_ROOTDIR || set rootdir "$HOME/notes" # unfortunately we can't support per-operation rootdir(s) here

function cmdline_contains_mainop -d 'Exit with statuscode 0 if the current commandline buffer already contains a main operation as a pos-argument'
    for token in (commandline -o)     
        for mainop in $mainops_all
            test $token = $mainop && return 0
        end
    end
end

function categ_chains -d 'Output a newline-separated list of all possible category chain combinations to stdout'
    # argv[1] - the starting point from which to list all combinations
    for c in $rootdir/$argv[1]/**
        not test -d $c && continue # skip all non-directory nodes   
        test (basename $c) = 'pdf' && continue # skip directories named 'pdf'/'pdfs' (compatibility) as they don't represent categories

        echo (string replace -i "$rootdir/" '' $c)
        categ_chains $c
    end
end

function note_names -d 'Output a newline-separated list of all possible notes names in a given category chain to stdout'
    # argv[1] - the category chain (NOT a full path) from which to pull all note names
    for c in $rootdir/$argv[1]/*.md
        set -l final (string replace -i ".md" '' (basename $c))
        echo $final
    end
end

function is_valid_chain -d 'Exists with status code 0 if the provided category chain exists'
    # argv[1] - the category chain to test for
    test -d "$rootdir/$argv[1]"
end

function note_completion -d 'Provide argument completions for actual category chains/note names depending on the current mainop and current arguments'
    # a mainop is guaranteed to be present on the commandline buffer at the time of this function call

    # make argv contain the full commandline buffer w/o all the options (INCLUDES progname)
    argparse -n $progname $opts -- (commandline -opc) 1>/dev/null 2>&1
    set argv $argv[2..-1] # remove the progname from the list ("bote", the 1st argument)

    set -l mainop $argv[1] # i.e. the first non-option argument
    switch $mainop
        case create-category C 
            test (count $argv) -lt 2 && categ_chains '/'
        case remove-category D
            test (count $argv) -lt 2 && categ_chains '/'
        case move-category M
            test (count $argv) -lt 3 && categ_chains '/'
        case create c
            test (count $argv) -lt 2 && categ_chains '/'
        case remove d
            if test (count $argv) = 1 # i.e. only the mainop has been supplied
                # provide category chains AND notes in the rootdir
                categ_chains '/'
                note_names '/'
            else 
                # there's more than one argument, determine whether it's a notename (rootdir), OR a category chain
                test (count $argv) -lt 3 && is_valid_chain $argv[2] && note_names $argv[2]
            end
        case move m 
        case sanitize s
            # ignored since no args necessary
        case list l
            # ingored since no args necessary
        case backup b
            # args are just files so no meaningful custom completions necessary
        case restore r
            # args are just files so no meaningful custom completions necessary
        case edit e
            if test (count $argv) = 1 # i.e. only the mainop has been supplied
                # provide category chains AND notes in the rootdir
                categ_chains '/'
                note_names '/'
            else 
                # there's more than one argument, determine whether it's a notename (rootdir), OR a category chain
                test (count $argv) -lt 3 && is_valid_chain $argv[2] && note_names $argv[2]
            end
        case view v
            if test (count $argv) = 1 # i.e. only the mainop has been supplied
                # provide category chains AND notes in the rootdir
                categ_chains '/'
                note_names '/'
            else 
                # there's more than one argument, determine whether it's a notename (rootdir), OR a category chain
                test (count $argv) -lt 3 && is_valid_chain $argv[2] && note_names $argv[2]
            end
        case '*'
            return
    end
end

complete -c $progname -f # do not offer any file completions
complete -c $progname -n "not cmdline_contains_mainop" -a (string join ' ' $mainops_all) -kf # main operation
complete -c $progname -n "not cmdline_contains_mainop" -l help -s h -f -d "Show a help string" # don't offer help if a main operation has already been specified
complete -c $progname -n "cmdline_contains_mainop" -a '(note_completion)' -kf # actual note completions
complete -c $progname -l root-directory -s r -r -d "Specify an alternative root directory for the following operation"
complete -c $progname -l stylesheet -s S -r -d "Specify an alternative CSS stylesheet for the following operation"
complete -c $progname -l logfile -s L -r -d "Specify an alternative path for the logfile for the following operation"
complete -c $progname -l gzip -s z -f -d "Specify that the tar archive for the local backup/restore operation is also gzipped"
