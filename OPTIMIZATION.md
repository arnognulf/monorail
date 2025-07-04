Optimization techniques for shell
=================================

File descriptors
----------------
Calling write on a file descriptor incurs some performance.
Consider:
* no ouptut is printed
* no output is wanted

then the command can be called as
```
# encapsule in a large block
{
   ...
   command
   ...
} 1>&- 2>&-
```

note, that some commands fail with EBADFD if ran with closed file descriptor, eg: `type -P cmd`
These must have stdout connected to /dev/null.

String comparisons
------------------
Avoid calling string comparison functions in libc, instead call:

```
boolean ()
{
if CONDITION
then
boolean ()
{
:
}
else
boolean ()
{
false
}
fi
}
```

This replaces the string comparisons with simple jumps

The `false` function can also be unset, this will also provide the non-zero return code

Async code
----------
Is the result not needed immediate? Run the command asynchronous:

```
( exec command >&- 2>&- & )
```

Locale
------
Is the command locale not needed?
Call the command with
```
LC_MESSAGES=C LC_ALL=C command
```

to avoid dynamically loading locale libraries

Minify
------
Less code == less needed to interpret

Consider running
```
shfmt -mn -w script.sh
```
