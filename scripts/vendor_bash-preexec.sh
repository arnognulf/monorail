#!/bin/bash
rm -rf bash-preexec
git clone https://github.com/rcaloras/bash-preexec
REVISION=$(cd bash-preexec; git rev-parse HEAD;)
rm -rf bash-preexec/.git
#git add bash-preexec
#git commit -m "feat: vendor bash-preexec at $REVISION"
echo "git commit -m \"feat: vendor bash-preexec at $REVISION\""
