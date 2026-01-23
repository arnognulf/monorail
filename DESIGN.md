Goals
=====
Horizontal gradient horizontal line across the screen
-----------------------------------------------------
Line shall be drawn across the screen and be resized when screen is resized.

User configurable LUTs
----------------------
User shall be able to specify their own LUT.

Reverse video in case of no LUT
-------------------------------
If user does not provide LUT; reverse video shall be used for text bar.

Usable on common operating systems
----------------------------------
Monorail shall be usable on a wide range of (UNIX-like) operating systems.

Wide shell and terminal compatibility for `monorail.compat.sh`
--------------------------------------------------------------
Support popular shells such as bash and zsh.
Support common, buggy and vintage terminals.
OpenBSD, NetBSD, and OpenIndiana ships variants of ksh, support these.
On embedded/minimal distributions such as Alpine or OpenWRT, only a posix shell
is shipped. These should be supported.
FreeBSD only ships a posix shell in the default install, support this as well.

Prioritize performance over compatibility for `monorail.sh`
-----------------------------------------------------------
Prompt startup and rendering timem is important for user experience.
Performant shell code requires inlining and minimizing of external executable use, code, variables, and functions.
Put special compatibility cases in `monorail.compat.sh` so `monorail.sh` can be focused on performance.

Misconfigured terminals should be usable
----------------------------------------
Render a usable prompt (not necesarily estetically pleasing) on terminals that do not support truecolor control sequencies and specifies `TERM=xterm`.
In particular FreeBSD console specifies `TERM=xterm` but do not handle truecolor. In `ssh` all other identifying values are filtered.

Non-goals
=========
256 colors
----------
The only commonly used terminal that do not support truecolor terminal control sequencies is  Mac OS Terminal.app (pre-Tahoe/macOS26).
256 colors are quite complex and loks bad.
Also, `tmux` can translate colors to 256-color if needed.


