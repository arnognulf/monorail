#!/usr/bin/env fish
#TODO: color & cursor setting
#TODO: title
#TODO: missing caching, thus a bit slow

function _PROMPT_LUT
    set -l i 1
    set -g _monorail_prompt_lut[1] ""
    for arg in $argv
        set red $(string split -f1 ';' $arg)
        set green $(string split -f2 ';' $arg)
        set blue $(string split -f3 ';' $arg)
        set _monorail_prompt_lut[$i] $(printf "%.2x%.2x%.2x" "$red" "$green" "$blue")
        set i $(math $i + 1)
    end
end
function _PROMPT_TEXT_LUT
    set -g _monorail_prompt_text_lut $argv
end
function _COLORS
    set -g _monorail_colors $argv
end

set -x _MONORAIL_CONFIG $HOME/.config/monorail
set -x _MONORAIL_DIR $HOME/.local/share/dotfiles/monorail
set -x _MONORAIL_SHORT_HOSTNAME $(string split -f1 . $(hostname))

function _monorail_line
    source $_MONORAIL_CONFIG/colors-kakburken.sh
    set -l i 1
    set -l line ""
    set -l _monorail_prompt_lut_length $(count $_monorail_prompt_lut)
    while test $i -lt $(math $COLUMNS + 1)
        set a $(math $_monorail_prompt_lut_length \* $i)
        set b $(math $COLUMNS + 2)
        set index $(math -s 0 1 + $a / $b)
        set line $line$(set_color $_monorail_prompt_lut[$index])\u2581
        set i $(math $i + 1)
    end
    printf $line
end

function fish_prompt
    printf $(_monorail_line)
    printf \n
    printf $(_monorail_bar)$(set_color normal)" "
end

function _monorail_bar
    set text $(string split "" $(_monorail_prompt_text))
    set -l bar ""
    set -l i 1
    while test $i -le $(count $text)
        set a $(math $(count $_monorail_prompt_lut) \* $i)
        set b $(math $COLUMNS + 2)
        set index $(math -s 0 1 + $a / $b)

        set bar $bar$(set_color --background $_monorail_prompt_lut[$index])$(set_color ffffff)$text[$i]
        set i $(math $i + 1)
    end
    printf $bar
end
function _monorail_prompt_text
    set short_pwd $(basename $PWD)
    if test $PWD = $HOME
        set short_pwd "~"
    end
    if test $PWD = /
        set short_pwd /
    end
    set -l git $(fish_git_prompt)
    set -l text " $short_pwd$git "
    printf $text
end
trap _monorail_update WINCH

function monorail_gradient
    bash $_MONORAIL_DIR/scripts/gradient.sh $argv
end
function monorail_image
    bash $_MONORAIL_DIR/scripts/gradient.sh $argv
end
function monorail_color
    bash $_MONORAIL_DIR/scripts/gradient.sh $argv
end

#function _monorail_preexec --on-event fish_preexec
#end

#function _monorail_postexec --on-event fish_postexec
#end
