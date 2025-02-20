colors themes for monorail prompt
---------------------------------

Use UP and DOWN arrows and press RETURN to select a predefined color scheme.

Enter text to search for a specific theme


To select dark mode, call:

gradient --dark

To select a custom fore- and background color, call:

gradient --bgcolor=<HEX_COLOR> --fgcolor=<HEX_COLOR>

For custom gradients, call:

gradient [<INDEX> <HEX_COLOR>] [<INDEX> <HEX_COLOR>]...
INDEX       must be increasing integers and in the range 0...100
HEX_COLOR   is a hexadecimal RRGGBB color 

Eg. design your gradient at https://cssgradient.io/ and transfer these to gradient script, https://uigradients.com/ is also a great resource.

Note: this script is slow due to using OKLab colorspace with bc(1),

Examples:
gradient  0 b1e874  100 00d4ff
gradient  0 020024  35 1818a1  100 00d4ff
gradient  0 b1e874  100 ff00d3
gradient --dark
gradient --bgcolor=020024 --fgcolor=00d4ff

