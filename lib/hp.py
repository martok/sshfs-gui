"""
Hexpatch
========

Patch a binary file from a simple description, using non-overlapping longest-match context matches.
Useful for instruction-patching executables, if codegen has not changed too much, even different versions will match.

Patch file format
-----------------
- Line-based text file
- comments lines start with # at character 1
- empty lines are ignored

Pairs of lines of what remains form the patch patterns, in hexadecimal. Pattern and replacement don't have
to be the same size, allowing for insertions.

Example:
```
# replace a jump instruction
ab 00 aa bb 75 33 55
ab 00 aa bb ec 33 55
```
"""

import sys


def main(patch, left, right=None):
    if right is None:
        right = right + ".patched"

    with open(left, "rb") as f:
        source = f.read()

    patterns = []
    with open(patch, "rt") as f:
        def dataline(it) -> str:
            while True:
                l = next(it).strip()
                if l and not l.startswith('#'):
                    return l

        liter = iter(f)
        try:
            l = dataline(liter)
            a = bytes.fromhex(l)
            l = dataline(liter)
            b = bytes.fromhex(l)
            patterns.append((a, b))
        except StopIteration:
            pass
    patterns.sort(key=lambda p: len(p[0]), reverse=True)

    modified = bytearray(source)
    wp = 0
    while wp < len(modified):
        found = False
        for pat, rep in patterns:
            try:
                loc = modified.index(pat, wp)
            except ValueError:
                continue
            modified[loc:loc + len(pat)] = rep
            wp += len(rep)
            found = True
            break
        if not found:
            break

    with open(right, "wb") as f:
        f.write(modified)


if __name__ == "__main__":
    main(*sys.argv[1:])
