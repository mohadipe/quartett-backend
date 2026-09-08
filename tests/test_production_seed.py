import os
import unittest
import json
import re

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SEED_SQL_PATH = os.path.join(REPO_ROOT, "supabase", "seed_official_decks.sql")
SMOKE_TEST_SCRIPT_PATH = os.path.join(REPO_ROOT, "scripts", "smoke_test_production.py")
SMOKE_TEST_SHELL_PATH = os.path.join(REPO_ROOT, "scripts", "smoke_test_production.sh")
PGTAP_SMOKE_TEST_PATH = os.path.join(REPO_ROOT, "supabase", "tests", "database", "09_production_seed_smoke_test.sql")


class TestProductionSeedSQL(unittest.TestCase):
    """Test suite for supabase/seed_official_decks.sql."""

    def test_seed_official_decks_file_exists(self):
        """seed_official_decks.sql must exist in supabase/."""
        self.assertTrue(
            os.path.isfile(SEED_SQL_PATH),
            f"Expected {SEED_SQL_PATH} to exist."
        )

    def test_seed_sql_cleans_test_artifacts(self):
        """seed_official_decks.sql must clean profiles, matches and user data."""
        if not os.path.isfile(SEED_SQL_PATH):
            self.skipTest("Seed file does not exist yet")
        with open(SEED_SQL_PATH, "r", encoding="utf-8") as f:
            content = f.read()

        # Check for profile and match deletion
        self.assertIn("DELETE FROM public.profiles", content)
        self.assertIn("DELETE FROM public.matches", content)
        self.assertIn("DELETE FROM public.user_inventory_decks", content)
        self.assertIn("DELETE FROM public.user_cosmetics", content)
        self.assertIn("DELETE FROM public.user_achievements", content)
        self.assertIn("DELETE FROM public.daily_quests", content)
        self.assertIn("DELETE FROM public.purchase_receipts", content)

    def test_seed_sql_cleans_obsolete_slugs_and_unofficial_decks(self):
        """seed_official_decks.sql must clean obsolete slugs and non-official decks."""
        if not os.path.isfile(SEED_SQL_PATH):
            self.skipTest("Seed file does not exist yet")
        with open(SEED_SQL_PATH, "r", encoding="utf-8") as f:
            content = f.read()

        self.assertIn("feuerwehr-einsatzfahrzeuge", content)
        self.assertTrue(
            "DELETE FROM public.decks" in content,
            "Must clean up invalid or obsolete decks."
        )

    def test_seed_sql_contains_the_three_official_standard_decks(self):
        """seed_official_decks.sql must seed Supercars, Schmetterlinge and Feuerwehr."""
        if not os.path.isfile(SEED_SQL_PATH):
            self.skipTest("Seed file does not exist yet")
        with open(SEED_SQL_PATH, "r", encoding="utf-8") as f:
            content = f.read()

        expected_decks = [
            ("00000000-0000-0000-0000-000000000001", "supercars-2026", "Supercars 2026", 0),
            ("00000000-0000-0000-0000-000000000002", "butterflies-europe", "Europäische Schmetterlinge", 200),
            ("00000000-0000-0000-0000-000000000003", "feuerwehr-einsatz", "Klassische Feuerwehr", 150),
        ]

        for deck_id, slug, name, price in expected_decks:
            self.assertIn(deck_id, content, f"Missing deck UUID {deck_id}")
            self.assertIn(slug, content, f"Missing deck slug {slug}")
            self.assertIn(name, content, f"Missing deck name {name}")
            self.assertIn(str(price), content, f"Missing deck price {price}")

    def test_seed_sql_attribute_definitions(self):
        """seed_official_decks.sql must have 5 attribute definitions per official deck."""
        if not os.path.isfile(SEED_SQL_PATH):
            self.skipTest("Seed file does not exist yet")
        with open(SEED_SQL_PATH, "r", encoding="utf-8") as f:
            content = f.read()

        # Check required attribute keys for Supercars
        for key in ["power_hp", "vmax", "accel_0_100", "displacement_ccm", "weight_kg"]:
            self.assertIn(key, content)

        # Check required attribute keys for Schmetterlinge
        for key in ["wingspan_mm", "lifespan_days", "altitude_max_m", "caterpillar_duration_weeks", "flight_speed_kmh"]:
            self.assertIn(key, content)

        # Check required attribute keys for Feuerwehr
        for key in ["water_tank_l", "pump_capacity_lpm", "rescue_height_m", "crew_size"]:
            self.assertIn(key, content)


class TestSmokeTestScripts(unittest.TestCase):
    """Test suite for automated smoke test scripts."""

    def test_smoke_test_python_script_exists_and_executable(self):
        """smoke_test_production.py must exist."""
        self.assertTrue(
            os.path.isfile(SMOKE_TEST_SCRIPT_PATH),
            f"Expected {SMOKE_TEST_SCRIPT_PATH} to exist."
        )

    def test_smoke_test_shell_script_exists_and_executable(self):
        """smoke_test_production.sh must exist."""
        self.assertTrue(
            os.path.isfile(SMOKE_TEST_SHELL_PATH),
            f"Expected {SMOKE_TEST_SHELL_PATH} to exist."
        )

    def test_pgtap_smoke_test_file_exists(self):
        """09_production_seed_smoke_test.sql must exist."""
        self.assertTrue(
            os.path.isfile(PGTAP_SMOKE_TEST_PATH),
            f"Expected {PGTAP_SMOKE_TEST_PATH} to exist."
        )

    def test_smoke_test_python_module_structure(self):
        """smoke_test_production.py must define validation methods."""
        import importlib.util
        spec = importlib.util.spec_from_file_location("smoke_test_production", SMOKE_TEST_SCRIPT_PATH)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)

        self.assertTrue(hasattr(module, "run_smoke_test"))
        self.assertTrue(hasattr(module, "EXPECTED_OFFICIAL_DECKS"))
        self.assertTrue(hasattr(module, "validate_user_and_match_artifacts"))
        self.assertTrue(hasattr(module, "validate_legacy_slugs_and_unofficial_decks"))
        self.assertTrue(hasattr(module, "validate_official_decks_catalog"))
        self.assertTrue(hasattr(module, "validate_cards_catalog"))

    def test_validation_logic_zero_artifacts(self):
        """validate_user_and_match_artifacts returns success when all tables are 0."""
        import importlib.util
        spec = importlib.util.spec_from_file_location("smoke_test_production", SMOKE_TEST_SCRIPT_PATH)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)

        clean_counts = {tbl: 0 for tbl in module.USER_DATA_TABLES}
        res = module.validate_user_and_match_artifacts(clean_counts)
        self.assertEqual(len(res), 1)
        self.assertTrue(res[0].success)

        dirty_counts = {tbl: 0 for tbl in module.USER_DATA_TABLES}
        dirty_counts["profiles"] = 5
        dirty_counts["matches"] = 2
        res_dirty = module.validate_user_and_match_artifacts(dirty_counts)
        self.assertEqual(len(res_dirty), 1)
        self.assertFalse(res_dirty[0].success)
        self.assertIn("7 Test-Artefakte", res_dirty[0].message)

    def test_validation_logic_legacy_and_unofficial_decks(self):
        """validate_legacy_slugs_and_unofficial_decks detects legacy slugs and unofficial decks."""
        import importlib.util
        spec = importlib.util.spec_from_file_location("smoke_test_production", SMOKE_TEST_SCRIPT_PATH)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)

        res_clean = module.validate_legacy_slugs_and_unofficial_decks(0, 0, 0)
        self.assertTrue(all(r.success for r in res_clean))

        res_legacy = module.validate_legacy_slugs_and_unofficial_decks(1, 0, 0)
        self.assertFalse(res_legacy[0].success)

        res_unofficial = module.validate_legacy_slugs_and_unofficial_decks(0, 2, 1)
        self.assertFalse(res_unofficial[1].success)

    def test_validation_logic_official_decks_catalog(self):
        """validate_official_decks_catalog validates slugs, prices and attribute definitions."""
        import importlib.util
        spec = importlib.util.spec_from_file_location("smoke_test_production", SMOKE_TEST_SCRIPT_PATH)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)

        valid_decks = [
            {
                "id": "00000000-0000-0000-0000-000000000001",
                "slug": "supercars-2026",
                "name": "Supercars 2026",
                "category": "Fahrzeuge",
                "price_coins": 0,
                "is_official": True,
                "attribute_definitions": [
                    {"key": "power_hp"}, {"key": "vmax"}, {"key": "accel_0_100"},
                    {"key": "displacement_ccm"}, {"key": "weight_kg"}
                ]
            },
            {
                "id": "00000000-0000-0000-0000-000000000002",
                "slug": "butterflies-europe",
                "name": "Europäische Schmetterlinge",
                "category": "Natur & Tiere",
                "price_coins": 200,
                "is_official": True,
                "attribute_definitions": [
                    {"key": "wingspan_mm"}, {"key": "lifespan_days"}, {"key": "altitude_max_m"},
                    {"key": "caterpillar_duration_weeks"}, {"key": "flight_speed_kmh"}
                ]
            },
            {
                "id": "00000000-0000-0000-0000-000000000003",
                "slug": "feuerwehr-einsatz",
                "name": "Klassische Feuerwehr",
                "category": "Fahrzeuge",
                "price_coins": 150,
                "is_official": True,
                "attribute_definitions": [
                    {"key": "power_hp"}, {"key": "water_tank_l"}, {"key": "pump_capacity_lpm"},
                    {"key": "rescue_height_m"}, {"key": "crew_size"}
                ]
            },
        ]

        res = module.validate_official_decks_catalog(valid_decks)
        self.assertEqual(len(res), 3)
        self.assertTrue(all(r.success for r in res))

        # Test with wrong price
        corrupted_decks = [dict(d) for d in valid_decks]
        corrupted_decks[0]["price_coins"] = 500
        res_corrupt = module.validate_official_decks_catalog(corrupted_decks)
        self.assertFalse(res_corrupt[0].success)

        # Test with missing attribute
        corrupted_attrs = [dict(d) for d in valid_decks]
        corrupted_attrs[1]["attribute_definitions"] = [{"key": "wingspan_mm"}]
        res_attrs = module.validate_official_decks_catalog(corrupted_attrs)
        self.assertFalse(res_attrs[1].success)

    def test_markdown_summary_generation(self):
        """format_markdown_summary outputs expected Markdown table."""
        import importlib.util
        spec = importlib.util.spec_from_file_location("smoke_test_production", SMOKE_TEST_SCRIPT_PATH)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)

        results = [
            module.SmokeTestResult("Test 1", True, "Passed check"),
            module.SmokeTestResult("Test 2", False, "Failed check"),
        ]
        md = module.format_markdown_summary(False, results, "quartett-prod")
        self.assertIn("## 🧪 Production Smoke-Test", md)
        self.assertIn("quartett-prod", md)
        self.assertIn("Test 1", md)
        self.assertIn("Test 2", md)
        self.assertIn("❌", md)
        self.assertIn("✅", md)

    def test_cli_execution_local(self):
        """Executing smoke_test_production.py --local succeeds."""
        import subprocess
        result = subprocess.run(
            ["python3", SMOKE_TEST_SCRIPT_PATH, "--local", "--json"],
            capture_output=True,
            text=True
        )
        self.assertEqual(result.returncode, 0, f"Smoke test failed: {result.stderr}")
        data = json.loads(result.stdout)
        self.assertTrue(data.get("success"))
        self.assertTrue(len(data.get("results", [])) >= 8)


if __name__ == "__main__":
    unittest.main()
