#!/usr/bin/env python3
"""Validate that the phase-one audit tracks every locked requirement and added agreement."""
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
spec = (root / "PROJECT_REQUIREMENTS_LOCK.md").read_text(encoding="utf-8")
audit = (root / "docs/PHASE_01_ACCEPTANCE_AUDIT.md").read_text(encoding="utf-8")
ids = re.findall(r"(?m)^- ((?:ID|KID|PAR|SYS)-\d{3}) \|", spec)
assert len(ids) == 28 and len(set(ids)) == 28, "Expected 28 unique locked requirements"
missing = [key for key in ids if not re.search(r"(?m)^\| " + re.escape(key) + r" \|", audit)]
assert not missing, f"Audit missing requirement rows: {missing}"
extras = re.findall(r"(?m)^\| (EX-\d{3}) \|", audit)
assert len(extras) == 20 and len(set(extras)) == 20, "Expected 20 unique additional agreement rows"
for key in ids:
    row = next(line for line in audit.splitlines() if line.startswith(f"| {key} |"))
    assert row.count("|") >= 5, f"Missing status/evidence/acceptance fields: {key}"
characters = ("كيدوزا", "سمسم", "وردة", "زيزو")
kid_line = next(line for line in spec.splitlines() if line.startswith("- KID-001 |"))
audit_line = next(line for line in audit.splitlines() if line.startswith("| KID-001 |"))
for character in characters:
    assert character in kid_line and character in audit_line, f"Missing approved character: {character}"
assert "11 شخصية تخص مشروع كيدوزا" in audit, "Separate Kidoza project scope must be explicit"
assert "المرحلة الأولى معتمدة من ناحية حصر المتطلبات" in audit, "Audit approval must be explicit and scoped"
print(f"PASS: audited {len(ids)} locked requirements and {len(extras)} additional agreements")
print("NOTE: completeness of documentation is not proof of feature implementation")
