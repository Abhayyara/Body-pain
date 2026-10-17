#!/usr/bin/env python3
"""Structural sanity checks that run WITHOUT the Flutter SDK.

This is NOT a substitute for `flutter analyze` / `flutter test`. It catches:
  * unbalanced brackets/braces/parens in .dart files
  * unresolved relative and package:bodywise3d imports
  * region geometry problems (bounds, unexpected overlaps, left/right mirroring)
  * safety-rule IDs that exist in code but not in docs/SAFETY_RULES.md (or vice versa)
"""
import itertools
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
errors = []


def strip(src: str) -> str:
    """Remove comments and string literals so bracket counting is reliable."""
    out, i, n = [], 0, len(src)
    while i < n:
        c = src[i]
        if src.startswith("//", i):
            while i < n and src[i] != "\n":
                i += 1
        elif src.startswith("/*", i):
            j = src.find("*/", i + 2)
            i = n if j < 0 else j + 2
        elif c in "'\"":
            q = c
            triple = src.startswith(q * 3, i)
            end = q * 3 if triple else q
            i += len(end)
            while i < n and not src.startswith(end, i):
                i += 2 if src[i] == "\\" else 1
            i += len(end)
            out.append('""')
        else:
            out.append(c)
            i += 1
    return "".join(out)


# 1. brackets -------------------------------------------------------------
dart_files = sorted(list((ROOT / "lib").rglob("*.dart")) + list((ROOT / "test").rglob("*.dart")))
pairs = {")": "(", "]": "[", "}": "{"}
for f in dart_files:
    stack = []
    for ch in strip(f.read_text(encoding="utf-8")):
        if ch in "([{":
            stack.append(ch)
        elif ch in pairs:
            if not stack or stack.pop() != pairs[ch]:
                errors.append(f"{f.relative_to(ROOT)}: mismatched '{ch}'")
                break
    else:
        if stack:
            errors.append(f"{f.relative_to(ROOT)}: unclosed {''.join(stack)}")

# 2. imports --------------------------------------------------------------
imp = re.compile(r"""^\s*import\s+['"]([^'"]+)['"]""", re.M)
for f in dart_files:
    for target in imp.findall(f.read_text(encoding="utf-8")):
        if target.startswith("package:bodywise3d/"):
            p = ROOT / "lib" / target[len("package:bodywise3d/"):]
        elif target.startswith(("dart:", "package:")):
            continue
        else:
            p = (f.parent / target).resolve()
        if not p.exists():
            errors.append(f"{f.relative_to(ROOT)}: unresolved import {target}")

# 3. region geometry ------------------------------------------------------
src = (ROOT / "lib/data/body_regions.dart").read_text(encoding="utf-8")
num = r"(-?\d*\.?\d+)"
rect_re = rf"_r\(\s*{num}\s*,\s*{num}\s*,\s*{num}\s*,\s*{num}\s*\)"


def rects(text):
    return [tuple(float(x) for x in m) for m in re.findall(rect_re, text)]


def mirror(r):
    return (1 - r[2], r[1], 1 - r[0], r[3])


regions = {}  # id -> {"front": rect|None, "back": rect|None}
for m in re.finditer(r"_midline\(\s*id:(.*?)\n\s*\),", src, re.S):
    body = m.group(1)
    rid = re.search(r"\s*'([^']+)'", body).group(1)
    fr = re.search(rf"front:\s*({rect_re})", body)
    bk = re.search(rf"back:\s*({rect_re})", body)
    regions[rid] = {
        "front": rects(fr.group(1))[0] if fr else None,
        "back": rects(bk.group(1))[0] if bk else None,
    }
for m in re.finditer(r"\.\.\._pair\((.*?)\n\s*\),", src, re.S):
    body = m.group(1)
    fam = re.search(r"family:\s*'([^']+)'", body).group(1)
    rf_ = rects(re.search(rf"rightFront:\s*({rect_re})", body).group(1))[0]
    in_front = "inFront: false" not in body
    in_back = "inBack: false" not in body
    regions[f"right_{fam}"] = {
        "front": rf_ if in_front else None,
        "back": mirror(rf_) if in_back else None,
    }
    regions[f"left_{fam}"] = {
        "front": mirror(rf_) if in_front else None,
        "back": rf_ if in_back else None,
    }

required = re.search(r"kRequiredRegionIds = <String>\[(.*?)\];", src, re.S).group(1)
required = set(re.findall(r"'([^']+)'", required))
if set(regions) != required:
    errors.append(f"region ids differ from required list: "
                  f"missing={sorted(required - set(regions))} extra={sorted(set(regions) - required)}")
if len(required) != 36:
    errors.append(f"expected 36 required ids, found {len(required)}")

for rid, views in regions.items():
    if not (views["front"] or views["back"]):
        errors.append(f"{rid}: not visible in any view")
    for view, r in views.items():
        if r is None:
            continue
        l, t, rr, b = r
        if not (0 <= l < rr <= 1 and 0 <= t < b <= 1):
            errors.append(f"{rid}/{view}: rect out of bounds {r}")
        side = rid.split("_")[0]
        if side in ("left", "right"):
            cx = (l + rr) / 2
            want_screen_right = (side == "left") == (view == "front")
            if (cx > 0.5) != want_screen_right:
                errors.append(f"{rid}/{view}: on the wrong side of the screen")

allowed_overlap = {frozenset(("head", "jaw"))}
for view in ("front", "back"):
    vis = [(rid, v[view]) for rid, v in regions.items() if v[view]]
    for (a, ra), (b, rb) in itertools.combinations(vis, 2):
        w = min(ra[2], rb[2]) - max(ra[0], rb[0])
        h = min(ra[3], rb[3]) - max(ra[1], rb[1])
        if w > 1e-9 and h > 1e-9 and frozenset((a, b)) not in allowed_overlap:
            errors.append(f"{view}: unexpected overlap {a} / {b} ({w:.3f} x {h:.3f})")

# 4. safety rule ids vs docs ----------------------------------------------
code = (ROOT / "lib/features/safety/safety_engine.dart").read_text(encoding="utf-8")
code_ids = set(re.findall(r"'([ECI]\d+)'", code))
doc = (ROOT / "docs/SAFETY_RULES.md").read_text(encoding="utf-8")
doc_ids = set(re.findall(r"^\|\s*([ECI]\d+)\s*\|", doc, re.M))
if code_ids != doc_ids:
    errors.append(f"safety ids differ: code-only={sorted(code_ids - doc_ids)} doc-only={sorted(doc_ids - code_ids)}")
tests = (ROOT / "test/safety_engine_test.dart").read_text(encoding="utf-8")
for rid in sorted(code_ids):
    if rid.startswith("E"):
        continue  # E1-E7 covered by iterating RedFlag.values; E8/E9 asserted by id
    if f"'{rid}'" not in tests:
        errors.append(f"safety rule {rid} has no test mentioning it")

print(f"dart files checked: {len(dart_files)}")
print(f"regions parsed: {len(regions)}  safety rules: {len(code_ids)}")
if errors:
    print("\nFAILED:")
    for e in errors:
        print(" -", e)
    sys.exit(1)
print("OK: all structural checks passed (this is not a compile).")
