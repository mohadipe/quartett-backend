import os
import subprocess
import sys
import unittest

# Ensure repo root is on sys.path
REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if REPO_ROOT not in sys.path:
    sys.path.insert(0, REPO_ROOT)

from scripts.generate_release_changelog import (
    parse_version,
    bump_version,
    categorize_commits,
    detect_conventional_bump,
    generate_changelog_markdown,
    get_changed_migrations,
)


class TestGenerateReleaseChangelog(unittest.TestCase):
    def test_parse_version_standard(self):
        self.assertEqual(parse_version("0.9.0"), (0, 9, 0))
        self.assertEqual(parse_version("backend-v0.9.0"), (0, 9, 0))
        self.assertEqual(parse_version("v1.2.3"), (1, 2, 3))
        self.assertEqual(parse_version("backend-v10.20.30"), (10, 20, 30))

    def test_parse_version_invalid(self):
        with self.assertRaises(ValueError):
            parse_version("invalid-version")

    def test_bump_version_patch(self):
        self.assertEqual(bump_version("0.9.0", "patch"), "0.9.1")
        self.assertEqual(bump_version("backend-v0.9.0", "patch"), "0.9.1")

    def test_bump_version_minor(self):
        self.assertEqual(bump_version("0.9.0", "minor"), "0.10.0")

    def test_bump_version_major(self):
        self.assertEqual(bump_version("0.9.0", "major"), "1.0.0")

    def test_bump_version_custom(self):
        self.assertEqual(bump_version("0.9.0", "custom", custom_version="1.5.2"), "1.5.2")
        self.assertEqual(bump_version("0.9.0", "custom", custom_version="backend-v2.0.0"), "2.0.0")

    def test_bump_version_custom_missing(self):
        with self.assertRaises(ValueError):
            bump_version("0.9.0", "custom", custom_version="")

    def test_bump_version_invalid_type(self):
        with self.assertRaises(ValueError):
            bump_version("0.9.0", "unknown_bump")

    def test_detect_conventional_bump_empty(self):
        self.assertEqual(detect_conventional_bump([]), "patch")

    def test_detect_conventional_bump_breaking(self):
        commits = [
            "fix(ci): fix yaml issue (abc1234)",
            "feat!: redesign authentication flow (def5678)",
        ]
        self.assertEqual(detect_conventional_bump(commits), "major")

        commits_footer = [
            "feat(db): rename user table (abc1234)\n\nBREAKING CHANGE: schema changes",
        ]
        self.assertEqual(detect_conventional_bump(commits_footer), "major")

    def test_detect_conventional_bump_feat(self):
        commits = [
            "fix(db): typo in function (abc1234)",
            "feat(db): add player stats view (def5678)",
        ]
        self.assertEqual(detect_conventional_bump(commits), "minor")

    def test_detect_conventional_bump_patch(self):
        commits = [
            "fix(ci): fix secret handling (abc1234)",
            "chore: update dependencies (def5678)",
        ]
        self.assertEqual(detect_conventional_bump(commits), "patch")

    def test_categorize_commits(self):
        commits = [
            "feat(db): add rank tiers view (1111111)",
            "fix(ci): fix sed delimiter in deploy script (2222222)",
            "feat(functions): matchmaking edge function (3333333)",
            "docs: update contract guidelines (4444444)",
            "test(rls): add coverage for guest accounts (5555555)",
            "chore(release): bump version to 0.9.0 [skip ci]",  # should be skipped
            "random other commit message (6666666)",
        ]
        categories = categorize_commits(commits)

        self.assertIn("🗄️ Database & Schema", categories)
        self.assertTrue(any("add rank tiers view" in c for c in categories["🗄️ Database & Schema"]))

        self.assertIn("🐛 Bug Fixes", categories)
        self.assertTrue(any("fix sed delimiter" in c for c in categories["🐛 Bug Fixes"]))

        self.assertIn("⚡ Edge Functions & APIs", categories)
        self.assertTrue(any("matchmaking edge function" in c for c in categories["⚡ Edge Functions & APIs"]))

        self.assertIn("📚 Dokumentation", categories)
        self.assertIn("🧪 Tests & Qualitätssicherung", categories)
        self.assertIn("📌 Sonstiges", categories)

        # Skip ci and chore(release) should NOT appear
        for cat_list in categories.values():
            for item in cat_list:
                self.assertNotIn("[skip ci]", item)
                self.assertNotIn("chore(release):", item)

    def test_generate_changelog_markdown(self):
        commits = [
            "feat(db): add daily quests table (aaa1111)",
            "fix(rls): restrict profile updates (bbb2222)",
        ]
        migrations = [
            "supabase/migrations/20260906160000_contract_facade_layer_v1.sql",
        ]
        md = generate_changelog_markdown(
            version="0.9.1",
            commits=commits,
            custom_notes="Wichtiges Sicherheitsupdate für RPCs",
            changed_migrations=migrations,
            prev_tag="backend-v0.9.0",
        )

        self.assertIn("backend-v0.9.1", md)
        self.assertIn("Wichtiges Sicherheitsupdate für RPCs", md)
        self.assertIn("🗄️ Database & Schema", md)
        self.assertIn("20260906160000_contract_facade_layer_v1.sql", md)
        self.assertIn("backend-v0.9.0", md)

    def test_cli_bump_mode(self):
        script_path = os.path.join(REPO_ROOT, "scripts", "generate_release_changelog.py")
        res = subprocess.run(
            [sys.executable, script_path, "bump", "--current-tag", "backend-v0.9.0", "--bump-type", "patch"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True,
        )
        output = res.stdout
        self.assertIn("new_version=0.9.1", output)
        self.assertIn("new_tag=backend-v0.9.1", output)


if __name__ == "__main__":
    unittest.main()
