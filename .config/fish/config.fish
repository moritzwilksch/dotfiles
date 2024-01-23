if status is-interactive
    # Commands to run in interactive sessions can go here
end

# function fish_prompt
#      set_color brcyan
#      printf %s $(prompt_pwd)
#      set_color brmagenta
#      printf (fish_git_prompt)
#      set_color normal
#      printf ' $ '
# end

# vim bindings!
fish_vi_key_bindings

# moritz functions
alias mm='micromamba'
alias ipy='ipython'
alias ipyi='ipython -i'

# search files
function sf
    rg --smart-case --files | fzf --ansi --preview='bat --color=always --style=numbers --line-range=:500 {}' | xargs -I {} code -r {}
end

# search ripgrep
function sg
    # Check if we have at least one argument
    if test (count $argv) -gt 0
        # The search pattern is the first argument
        set PATTERN $argv[1]
        set -e argv[1] # Remove the search pattern from the argument list
    else
        # If no arguments were provided, use an empty string as the pattern
        set PATTERN ""
    end

    # The rest of the arguments are for rg
    set RG_ARGS $argv

    # Run rg with the provided arguments, followed by fzf and the preview tool
    rg --color=always --line-number --no-heading --smart-case $RG_ARGS $PATTERN | fzf --ansi \
      --color "hl:-1:underline,hl+:-1:underline:reverse" \
      --delimiter : \
      --preview 'bat --color=always {1} --highlight-line {2}' \
      --preview-window '+{2}+3/3,~3' | cut -d ':' -f1-2 | xargs -I {} code -r -g {}
end

# search buffer
function sb
    rg --color=always --line-number --no-heading --smart-case --with-filename '' $argv | fzf --ansi \
      --color \
      --delimiter : \
      --preview 'bat --color=always {1} --highlight-line {2} --line-range {2}:' | cut -d ':' -f1-2 | xargs -I {} code -r -g {}
end