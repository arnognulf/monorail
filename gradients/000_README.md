colors themes for monorail prompt
---------------------------------

Use UP and DOWN arrows and press RETURN to select a predefined color scheme.

Enter text to search for a specific theme

To select a custom foreground and (optionally) background color, call:

monorail_color 444444 00ff00

For custom gradients, call:

monorail_gradient [<INDEX> <HEX_COLOR>] [<INDEX> <HEX_COLOR>]...
INDEX       must be increasing integers and in the range 0...100
HEX_COLOR   is a hexadecimal RRGGBB color 

Eg. design your gradient at https://cssgradient.io/ and transfer these to gradient script.

Examples:
monorail_gradient  b1e874 0  00d4ff 100
monorail_gradient  020024 0  1818a1  35  00d4ff 100

To disable gradients and use the foreground color, select:
monorail_gradient None
