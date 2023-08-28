alias umamba=micromamba

# search file by name, open in vscode
function sf() {
    rg --color=always --smart-case --files | fzf --preview='bat --color=always --style=numbers --line-range=:500 {}' | xargs -I {} code -r {}
}

# search file by content, open in vscode
function sif() {
    rg --color=always --line-number --no-heading --smart-case "${*:-}" | fzf --ansi \
      --color "hl:-1:underline,hl+:-1:underline:reverse" \
      --delimiter : \
      --preview 'bat --color=always {1} --highlight-line {2}' \
      --preview-window '+{2}+3/3,~3'| cut -d ':' -f1-2 | xargs -I {} code -r -g {}
}

# search single file content, open in vscode
function sib() {
    rg --color=always --line-number --no-heading --smart-case --with-filename '' "${*:-}" | fzf --ansi \
      --color \
      --delimiter : \
      --preview 'bat --color=always {1} --highlight-line {2} --line-range {2}:' | cut -d ':' -f1-2 | xargs -I {} code -r -g {}
}
