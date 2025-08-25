#!/bin/bash
export _MONORAIL_CONFIG=$HOME/.config/monorail
export _MONORAIL_DIR=$HOME/.local/share/dotfiles/monorail
~/.local/share/dotfiles/monorail/scripts/gradient.sh Sublime_Light.sh
cd $HOME
vhs record >~/.local/share/dotfiles/monorail/monorail.vhs
vhs ~/.local/share/dotfiles/monorail/monorail.vhs -o ~/.local/share/dotfiles/monorail/images/animation.gif
exec eog ~/.local/share/dotfiles/monorail/images/animation.gif &
