#!/usr/bin/env python3
"""Keep documented Swift examples on the same safety rules as the product.

`VOX-DOC-011` requires that "examples shall not bypass canonical validation or safety
semantics for convenience". `check_swift_safety.py` enforces those semantics over `.swift`
files, and a fenced example in a Markdown specification is not a `.swift` file -- so nothing
scanned the 224 Swift blocks in `docs/`. `ADR-0310` measured them and found none bypassing,
which is why this gate is clean rather than a ratchet.

The reserved forms are the ones a writer reaches for to keep an example short:

  * `try!` and `as!`, which turn a typed refusal into a crash;
  * `fatalError`, which is the same move spelled differently;
  * the bare word `unsafe`, which the Swift safety policy reserves.

An identifier that merely *contains* "unsafe" is deliberately not matched.
`UnsafeMutableRawBufferPointer` appears in a destination protocol in the core data model
specification and is legitimate: `ADR-0287` corrected an earlier over-strict reading that
would have banned it.
"""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DOCS = ROOT / "docs"

BLOCK = re.compile(r"```swift\n(.*?)```", re.DOTALL)
RESERVED = (
    (re.compile(r"\btry!"), "try!"),
    (re.compile(r"\bas!"), "as!"),
    (re.compile(r"\bfatalError\b"), "fatalError"),
    (re.compile(r"\bunsafe\b"), "the bare word `unsafe`"),
)


def main() -> int:
    findings: list[str] = []
    blocks = 0
    for path in sorted(DOCS.rglob("*.md")):
        source = path.read_text()
        for block in BLOCK.finditer(source):
            blocks += 1
            body = block.group(1)
            first = source[: block.start()].count("\n") + 1
            for pattern, name in RESERVED:
                for hit in pattern.finditer(body):
                    line = first + body[: hit.start()].count("\n") + 1
                    findings.append(
                        f"{path.relative_to(ROOT).as_posix()}:{line}: example uses {name},"
                        " which bypasses the safety semantics `VOX-DOC-011` requires it to keep"
                    )

    if findings:
        print("Example safety check failed:")
        for finding in findings:
            print(f"- {finding}")
        return 1
    print(f"Example safety check passed: {blocks} documented Swift examples.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
