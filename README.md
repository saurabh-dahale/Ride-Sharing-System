# Ride Sharing System in C++ and Smalltalk

MSCS-632 Advanced Programming Languages, Assignment 5.
Saurabh Dahale, University of the Cumberlands.

The same ride sharing system implemented twice, under a specification fixing
the classes, the fare rules and the exact output text before either program was
written. `run_both.sh` builds and runs both and diffs the results, so any
difference that remains is the language rather than the design.

## Layout

| Path | Contents |
|---|---|
| `cpp/ridesharing.cpp` | C++17 implementation |
| `smalltalk/ridesharing.st` | GNU Smalltalk implementation |
| `run_both.sh` | Builds, runs and compares both |
| `report/` | The report as .docx and .pdf |

## Running

```
bash run_both.sh
```

C++ builds natively:

```
g++ -std=c++17 -Wall -Wextra -o cpp/ridesharing cpp/ridesharing.cpp && ./cpp/ridesharing
```

GNU Smalltalk runs in a throwaway Debian bullseye container, since the package
is not practical to install on macOS on Apple Silicon:

```
docker run --rm -v "$PWD":/work -w /work debian:bullseye bash -c \
  "sed -i '/security/d' /etc/apt/sources.list && apt-get update -qq && \
   apt-get install -y -qq gnu-smalltalk && gst smalltalk/ridesharing.st"
```

The `sed` is needed because bullseye is oldstable and its security index
advertises an `unzip` build that is no longer in the pool, which otherwise
blocks the install. `unzip` is a hard dependency of gnu-smalltalk.

## The three principles

**Encapsulation.** `Driver::assignedRides` is private in C++ and reachable only
through `addRide` and `getDriverInfo`. The same is true in Smalltalk without
any declaration, because instance variables are private to the object by
construction. C++ rejects a direct access at compile time. Smalltalk accepts it
until the line executes and then raises `MessageNotUnderstood`, which the
Smalltalk program demonstrates in its last section. The C++ program cannot run
that check, so it appears there as a comment carrying the real compiler error.

**Inheritance.** `StandardRide` and `PremiumRide` derive from `Ride`. The base
class holds the shared state and the shared `rideDetails` formatting. C++ makes
`Ride` abstract with a pure virtual `fare()`. Smalltalk uses
`self subclassResponsibility`, which raises only when reached.

**Polymorphism.** Both programs hold the rides in one collection and call
`fare` and `rideDetails` without testing the type. C++ dispatches through the
virtual table over a vector bounded to `Ride`. Smalltalk looks the selector up
in the receiver's class at send time, with no requirement that the elements
share a superclass at all.

## Output

```
=== All rides, priced polymorphically ===
[R-1001] Standard  Union Square -> Mission Bay  3.4 mi  $8.45
[R-1002] Premium   SFO Terminal 2 -> Palo Alto  21.7 mi  $74.44
[R-1003] Standard  Berkeley -> Oakland Airport  14.2 mi  $27.35
[R-1004] Premium   Nob Hill -> Ferry Building  1.3 mi  $15.00
Total of 4 rides: $125.24
```
