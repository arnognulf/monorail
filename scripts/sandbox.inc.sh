#!/bin/sh
if bwrap --ro-bind / / --proc /proc --dev /dev --tmpfs /tmp \
	--new-session --unshare-all --die-with-parent \
	true 2>/dev/null; then
	_SANDBOX() {
		if [ -z "$1" ]; then
			echo "_SANDBOX_READONLY: full readonly view of filesystem, only r/w /tmp, no net"
			return 1
		fi
		bwrap --ro-bind / / --proc /proc --dev /dev --tmpfs /tmp \
			--new-session --unshare-all --die-with-parent \
			"$@"
	}

	_SANDBOX_RWCWD() {
		if [ -z "$1" ]; then
			echo '_SANDBOX_RWCWD: full readonly view of filesystem, r/w /tmp, r/w current working directory (not home!), no net'
			return 1
		fi
		if [ "$PWD" = "$HOME" ]; then
			echo "_SANDBOX_RWCWD: running in \$HOME not allowed"
			return 1
		fi
		bwrap --ro-bind / / --bind "$PWD" "$PWD" --proc /proc --dev /dev --tmpfs /tmp \
			--new-session --unshare-all --die-with-parent \
			"$@"
	}

else

	_SANDBOX() {
		"$@"
	}

	_SANDBOX_RWCWD() {
		"$@"
	}
fi
