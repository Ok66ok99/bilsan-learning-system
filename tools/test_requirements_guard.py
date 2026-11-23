#!/usr/bin/env python3
"""Non-destructive mutation tests for requirements_guard.py.

All deliberate damage happens only in a temporary directory.
"""
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

source = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix="bilsan-guard-test-") as temp:
    root = Path(temp)
    for item in ("PROJECT_REQUIREMENTS_LOCK.md",):
        shutil.copy2(source / item, root / item)
    for app in ("kids_learn", "parent_control"):
        for suffix in ("lib/main.dart", "assets/kidoza.webp"):
            origin = source / "apps" / app / suffix
            target = root / "apps" / app / suffix
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(origin, target)
    target = root / "tools/requirements_guard.py"
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source / "tools/requirements_guard.py", target)

    def run_guard():
        return subprocess.run([sys.executable, str(target)], cwd=root,
                              capture_output=True, text=True)

    assert run_guard().returncode == 0, "Unchanged baseline must pass"
    print("PASS baseline: untouched project accepted")

    ledger = root / "PROJECT_REQUIREMENTS_LOCK.md"
    original = ledger.read_text(encoding="utf-8")
    ledger.write_text(original.replace("- KID-007 |", "- DELETED-007 |", 1), encoding="utf-8")
    assert run_guard().returncode != 0, "Missing requirement must be rejected"
    ledger.write_text(original, encoding="utf-8")
    print("PASS mutation: missing approved requirement rejected")

    child = root / "apps/kids_learn/lib/main.dart"
    original = child.read_text(encoding="utf-8")
    child.write_text(original.replace("عالم بيلسان", "تطبيق تجريبي"), encoding="utf-8")
    assert run_guard().returncode != 0, "Changed child identity must be rejected"
    child.write_text(original, encoding="utf-8")
    print("PASS mutation: changed child identity rejected")

    mascot = root / "apps/kids_learn/assets/kidoza.webp"
    mascot.unlink()
    assert run_guard().returncode != 0, "Missing mascot asset must be rejected"
    print("PASS mutation: missing Kidoza asset rejected")

print("ALL 4 GUARD TESTS PASSED; original project was never changed.")
