#!/bin/bash

# install for macos
if [[ $(uname) == "Darwin" ]]; then
    echo "This is macOS"
else
    echo "This is not macOS"
    exit 1
fi

# install homebrew
if [[ $(command -v brew) == "" ]]; then
    echo "Installing homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Homebrew already installed"
fi

# install dependencies bat, rg, fzf
if [[ $(command -v bat) == "" ]]; then
    echo "Installing bat, rg, fzf..."
    brew update
    brew install ripgrep
    brew install fzf
    brew install bat
else
    echo "bat already installed"
fi

# append .zshrc into ~/.zshrc file if not exists
if [[ $(grep -c "sf()" ~/.zshrc) == 0 ]]; then
    echo "Appending .zshrc..."
    cat .zshrc >>~/.zshrc
else
    echo ".zshrc already appended"
fi

exit 0
