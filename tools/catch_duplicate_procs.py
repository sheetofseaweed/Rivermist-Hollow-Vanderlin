"""Finds procs defined twice on the same type in one file.

DM compiles these with zero warnings and chains them: the last definition is the
entry point, and its ..() calls the earlier body rather than the parent type. So
both bodies usually run, in an order nobody reading the file would predict. When
the last body omits ..() the earlier one is dead code instead. Definitions in
opposite branches of a #if/#else are legal and are skipped.
"""
import re
import sys
from pathlib import Path

RED = "\033[0;31m"
GREEN = "\033[0;32m"
BLUE = "\033[0;34m"
NC = "\033[0m"

SKIP_DIRS = {".git", "node_modules", "tgui", ".claude", "bootstrap"}

# A proc definition or override starts at column 0 and looks like /type/path/name(
DEFINITION = re.compile(r"^(/[A-Za-z0-9_]+(?:/[A-Za-z0-9_]+)+)\s*\(")

PREPROCESSOR = re.compile(r"^\s*#\s*(\w+)")


def block_comment_depths(src):
    """Returns the /* */ nesting depth at the start of every line, 1-indexed."""
    depths = [0, 0]
    depth = 0
    in_line_comment = False
    in_string = None
    in_multiline = False
    escaped = False

    i = 0
    length = len(src)
    while i < length:
        char = src[i]
        following = src[i + 1] if i + 1 < length else ""

        if char == "\n":
            in_line_comment = False
            escaped = False
            if not in_multiline:
                in_string = None
            depths.append(depth)
            i += 1
            continue

        if in_line_comment:
            i += 1
            continue

        if in_multiline or in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif in_multiline and char == '"' and following == "}":
                in_multiline = False
                i += 2
                continue
            elif in_string and char == in_string:
                in_string = None
            i += 1
            continue

        # Inside a block comment only the comment markers matter, DM allows nesting
        if depth:
            if char == "/" and following == "*":
                depth += 1
                i += 2
                continue
            if char == "*" and following == "/":
                depth -= 1
                i += 2
                continue
            i += 1
            continue

        if char == "/" and following == "/":
            in_line_comment = True
            i += 2
            continue
        if char == "/" and following == "*":
            depth += 1
            i += 2
            continue
        if char == "{" and following == '"':
            in_multiline = True
            i += 2
            continue
        if char in "\"'":
            in_string = char
            i += 1
            continue
        i += 1

    return depths


class BranchTracker:
    """Tracks which #if/#else branch the current line sits in."""

    def __init__(self):
        self.stack = []
        self.conditionals = 0

    def feed(self, line):
        match = PREPROCESSOR.match(line)
        if not match:
            return
        directive = match.group(1)
        if directive in ("if", "ifdef", "ifndef"):
            self.conditionals += 1
            self.stack.append([self.conditionals, 0])
        elif directive in ("else", "elif"):
            if self.stack:
                self.stack[-1][1] += 1
        elif directive == "endif":
            if self.stack:
                self.stack.pop()

    def path(self):
        return tuple((cond, branch) for cond, branch in self.stack)


def mutually_exclusive(left, right):
    """True when the two branch paths can never both be compiled."""
    right_branches = dict(right)
    for conditional, branch in left:
        if conditional in right_branches and right_branches[conditional] != branch:
            return True
    return False


PARENT_CALL = re.compile(r"(?<![A-Za-z0-9_.])\.\.\s*\(")


def body_calls_parent(lines, start):
    """True when the definition starting at this line calls ..() somewhere."""
    for line in lines[start:]:
        if line.strip() and not line[0].isspace():
            break
        if PARENT_CALL.search(line):
            return True
    return False


def find_duplicates(src):
    """Returns [(signature, [line numbers])] for procs defined twice in one file."""
    depths = block_comment_depths(src)
    tracker = BranchTracker()
    seen = {}

    for number, line in enumerate(src.splitlines(), 1):
        tracker.feed(line)

        # Commented-out code is not a definition
        if number < len(depths) and depths[number]:
            continue

        match = DEFINITION.match(line)
        if match:
            seen.setdefault(match.group(1), []).append((number, tracker.path()))

    results = []
    for signature, entries in seen.items():
        if len(entries) < 2:
            continue
        clashing = set()
        for i in range(len(entries)):
            for j in range(i + 1, len(entries)):
                if not mutually_exclusive(entries[i][1], entries[j][1]):
                    clashing.add(entries[i][0])
                    clashing.add(entries[j][0])
        if clashing:
            results.append((signature, sorted(clashing)))

    results.sort(key=lambda item: item[1][0])
    return results


def main():
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.cwd()

    if not root.exists():
        print(f"Path does not exist: {root}")
        sys.exit(2)

    violations = 0

    for dm_file in sorted(root.rglob("*.dm")):
        if SKIP_DIRS.intersection(dm_file.parts):
            continue
        try:
            src = dm_file.read_text(encoding="utf-8", errors="replace")
        except Exception as error:
            print(f"[ERROR] {dm_file}: {error}")
            continue

        relative = dm_file.relative_to(root).as_posix()
        source_lines = src.splitlines()
        for signature, lines in find_duplicates(src):
            listed = ", ".join(str(line) for line in lines)
            earlier = ", ".join(str(line) for line in lines[:-1])
            if body_calls_parent(source_lines, lines[-1]):
                consequence = (
                    f"line {lines[-1]} runs first and its ..() calls line {earlier}, "
                    "not the parent type"
                )
            else:
                consequence = (
                    f"line {lines[-1]} never calls ..(), so line {earlier} is dead code"
                )
            print(
                f"{RED}ERROR{NC}: {relative}:{lines[0]} "
                f"{BLUE}{signature}{NC} is defined {len(lines)} times "
                f"(lines {listed}) - {consequence}."
            )
            violations += 1

    if violations:
        print()
        print(
            f"{RED}ERROR:{NC} Found {violations} duplicate proc definition(s). "
            "Merge the bodies into one, or give the extra one the subtype path it was "
            "meant for. Check what the surviving order actually does before you delete."
        )
        sys.exit(1)

    print(f"{GREEN}OK:{NC} No duplicate proc definitions found.")
    sys.exit(0)


if __name__ == "__main__":
    main()
