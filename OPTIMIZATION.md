Optimization techniques for shell
=================================

File descriptors
----------------
Calling write as well as opening a file descriptor incurs some performance.
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

Booleans
--------
Avoid calling string comparison functions in libc, instead call:

```
if [[ $CONDITION ]];then
...
else
...
fi
```

This avoids memcpy and string comparison functions. 

Functions
---------
Avoid calling functions, with these, we need to dereference a pointer and parse its contents.
Compare with checking if a variable is set or unset but not reading it's contents.

Async code
----------
Is the result not needed immediate? Run the command asynchronous:

```
( exec command >&- 2>&- & )
```

Subshells
---------
Subshells means that bash needs to fork it's entire process. Avoid if possible.

```
$(...)
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
