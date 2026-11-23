#!/usr/bin/env python3
"""Fail closed: do not ship an APK while core acceptance criteria are absent."""
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
kids = (root / "apps/kids_learn/lib/main.dart").read_text(encoding="utf-8")
parent = (root / "apps/parent_control/lib/main.dart").read_text(encoding="utf-8")
kids_deps = (root / "apps/kids_learn/pubspec.yaml").read_text(encoding="utf-8")
parent_deps = (root / "apps/parent_control/pubspec.yaml").read_text(encoding="utf-8")

checks = {
    "Identity: child app": "title: 'عالم بيلسان'" in kids,
    "Identity: parent app": "title: 'متابعة طفلتي'" in parent,
    "Identity: approved Kidoza asset": "assets/kidoza.webp" in kids and "assets/kidoza.webp" in parent,
    "Offline child progress persistence": "prefs.setInt('math_correct'" in kids,
    "Offline parent lesson selection": "prefs.setStringList('bilsan_lessons'" in parent,
    "Firebase in both applications": all("firebase_core:" in deps and "cloud_firestore:" in deps and "firebase_auth:" in deps for deps in (kids_deps, parent_deps)),
    "Real child-parent synchronization": False,
    "Secure parent device approval and revocation": False,
    "Recorded Arabic lesson audio": False,
    "Interactive 3D Kidoza, Samsam and Warda": False,
    "Saudi first-grade curriculum and adaptive progression": False,
    "Saved drawings and achievement garden": False,
    "Parent-child integration tests": False,
}
for name, passed in checks.items():
    print(f"{'PASS' if passed else 'BLOCK'} | {name}")
failed = [name for name, passed in checks.items() if not passed]
if failed:
    print(f"RELEASE BLOCKED: {len(failed)} acceptance requirements remain unverified.")
    sys.exit(1)
print("Acceptance criteria satisfied; continue to APK build.")
