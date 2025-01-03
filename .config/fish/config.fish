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

# moritz functions
alias mm='micromamba'
alias ipy='ipython'
alias ipyi='ipython -i'
alias lg='lazygit'
alias tvt='tv text'

function tvtc
    set file_location (tv text)
    if test -n "$file_location"
        code --goto $file_location
    end
end

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

pixi completion --shell fish | source
fish_add_path -m /home/moritz/.pixi/bin

# expose code ipc socket in tmux
# see https://www.vinnie.work/blog/2024-06-29-controlling-vscode-from-tmux
function reload_vscode_ipc
    set user_ipc_path /run/user/(id -u)/vscode-ipc-*
    # Check if the glob matches at least one file
    if count $user_ipc_path > /dev/null
        set -x VSCODE_IPC_HOOK_CLI (ls -tr $user_ipc_path | tail -n 1)
    else
        # If no match, clear the variable
        set -e VSCODE_IPC_HOOK_CLI
    end
end
reload_vscode_ipc

