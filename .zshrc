alias mm=micromamba

# search file by name, open in vscode
function sf() {
    rg --color=always --smart-case --files | fzf --preview='bat --color=always --style=numbers --line-range=:500 {}' | xargs -I {} code -r {}
}

# search file by content, open in vscode
function sg() {
    # Check if we have at least one argument
    if [[ $# -gt 0 ]]; then
        # The search pattern is the first argument
        local PATTERN="$1"
        shift # Remove the search pattern from the argument list
    else
        # If no arguments were provided, use an empty string as the pattern
        local PATTERN=""
    fi

    # The rest of the arguments are for rg
    local RG_ARGS=("$@")

    # Run rg with the provided arguments, followed by fzf and the preview tool
    rg --color=always --line-number --no-heading --smart-case "${RG_ARGS[@]}" "${PATTERN}" | fzf --ansi \
      --color "hl:-1:underline,hl+:-1:underline:reverse" \
      --delimiter : \
      --preview 'bat --color=always {1} --highlight-line {2}' \
      --preview-window '+{2}+3/3,~3' | cut -d ':' -f1-2 | xargs -I {} code -r -g {}
}

# search single file content, open in vscode
function sb() {
    rg --color=always --line-number --no-heading --smart-case --with-filename '' "${*:-}" | fzf --ansi \
      --color \
      --delimiter : \
      --preview 'bat --color=always {1} --highlight-line {2} --line-range {2}:' | cut -d ':' -f1-2 | xargs -I {} code -r -g {}
}
