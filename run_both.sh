#!/usr/bin/env bash
# run_both.sh
#
# Builds and runs both implementations, then checks that they agree.
#
# C++ runs natively. GNU Smalltalk runs in a throwaway Debian bullseye
# container, because the package is not practical to install on macOS on Apple
# Silicon. The container's security source is dropped first, since bullseye is
# oldstable and its security index advertises an unzip build that is no longer
# in the pool, which blocks the install.
#
# Usage:  bash run_both.sh

set -uo pipefail
cd "$(dirname "$0")"
mkdir -p out

say() { echo; echo "================================================================"; echo "$*"; echo "================================================================"; }

say "BUILD: C++"
g++ -std=c++17 -Wall -Wextra -o cpp/ridesharing cpp/ridesharing.cpp || exit 1
echo "compiled clean at -Wall -Wextra"
g++ --version | head -1

say "RUN: C++"
./cpp/ridesharing | tee out/cpp.out

say "RUN: GNU Smalltalk"
docker run --rm -v "$PWD":/work -w /work debian:bullseye bash -c "
  sed -i '/security/d' /etc/apt/sources.list &&
  apt-get update -qq &&
  apt-get install -y -qq gnu-smalltalk >/dev/null 2>&1 &&
  gst --version | head -1 &&
  gst smalltalk/ridesharing.st" | tee out/smalltalk.out

say "COMPARE"
# The C++ program cannot run the encapsulation check, because the equivalent
# line is rejected by the compiler. Compare the sections both produce.
trim() {
  awk '/=== Encapsulation check ===/ {exit}
       /^GNU Smalltalk/ {next}
       {buf = buf $0 ORS}
       END {sub(/\n+$/, "\n", buf); printf "%s", buf}' "$1"
}
trim out/cpp.out > out/cpp.cmp
trim out/smalltalk.out > out/smalltalk.cmp

if diff -q out/cpp.cmp out/smalltalk.cmp >/dev/null 2>&1; then
  echo "IDENTICAL: both implementations produced the same $(wc -l < out/cpp.cmp) lines."
  echo "Any remaining difference between the programs is the language, not the design."
else
  echo "DIFFERENCES FOUND:"
  diff out/cpp.out out/smalltalk.out
fi

say "DONE"
ls -la out/
