#!/bin/bash
\cd $HOME
export _MONORAIL_CONFIG=$HOME/.config/monorail
export _MONORAIL_DIR=$HOME/.local/share/dotfiles/monorail
#~/.local/share/dotfiles/monorail/scripts/gradient.sh Sublime_Light
#sleep 1
#vhs ~/.local/share/dotfiles/monorail/monorail.vhs -o ~/.local/share/dotfiles/monorail/images/animation.gif
~/.local/share/dotfiles/monorail/scripts/gradient.sh --dark Sublime_Light
sleep 1
vhs ~/.local/share/dotfiles/monorail/monorail-dark.vhs -o ~/.local/share/dotfiles/monorail/images/animation-dark.gif
exec eog ~/.local/share/dotfiles/monorail/images/animation.gif &
