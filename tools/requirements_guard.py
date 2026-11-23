#!/usr/bin/env python3
"""Detect accidental removal of approved Bilsan requirements and identity."""
from pathlib import Path
import sys

root=Path(__file__).resolve().parents[1]
spec=(root/"PROJECT_REQUIREMENTS_LOCK.md").read_text(encoding="utf-8")
required={
"ID":4,"KID":11,"PAR":8,"SYS":5,
}
issues=[]
for prefix,count in required.items():
    for number in range(1,count+1):
        key=f"{prefix}-{number:03}"
        if sum(line.startswith(f'- {key} |') for line in spec.splitlines()) != 1:
            issues.append(f"Requirement missing or duplicated: {key}")
apps=[
 ("apps/kids_learn/lib/main.dart","عالم بيلسان"),
 ("apps/parent_control/lib/main.dart","متابعة طفلتي"),
]
for file,name in apps:
    text=(root/file).read_text(encoding="utf-8")
    if f"title: '{name}'" not in text:
        issues.append(f"Identity mismatch in {file}")
    if "assets/kidoza.webp" not in text:
        issues.append(f"Approved Kidoza asset missing in {file}")
for path in ["apps/kids_learn/assets/kidoza.webp","apps/parent_control/assets/kidoza.webp"]:
    if not (root/path).is_file():
        issues.append(f"Missing approved asset: {path}")
for issue in issues:
    print("BLOCK:",issue)
if issues:
    sys.exit(1)
print("Requirements IDs and basic identity/assets preserved.")
print("NOTE: This is a regression guard, NOT proof of full functionality.")
