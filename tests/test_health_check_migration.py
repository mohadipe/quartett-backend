import os
import glob
import unittest

MIGRATIONS_DIR = os.path.join(os.path.dirname(__file__), "..", "supabase", "migrations")
DATABASE_TESTS_DIR = os.path.join(os.path.dirname(__file__), "..", "supabase", "tests", "database")
TESTS_DIR = os.path.dirname(__file__)


class TestHealthCheckMigrationAndTests(unittest.TestCase):
    def test_health_check_migration_exists(self):
        """Migration file for backend health check must exist."""
        matches = glob.glob(os.path.join(MIGRATIONS_DIR, "*backend_health_check.sql"))
        self.assertTrue(len(matches) > 0, "Migration *backend_health_check.sql not found.")
        
        with open(matches[0], "r", encoding="utf-8") as f:
            content = f.read()

        self.assertIn("FUNCTION public.health_check()", content)
        self.assertIn("FUNCTION public.health_check_v1()", content)
        self.assertIn("SECURITY DEFINER", content)
        self.assertIn("TO anon, authenticated", content)
        self.assertIn("'healthy'", content)
        self.assertIn("'connected'", content)
        self.assertIn("'1.0.0'", content)

    def test_pgtap_database_test_exists(self):
        """pgTAP test file must exist in supabase/tests/database."""
        test_path = os.path.join(DATABASE_TESTS_DIR, "10_health_check_test.sql")
        self.assertTrue(os.path.isfile(test_path), f"{test_path} does not exist.")

        with open(test_path, "r", encoding="utf-8") as f:
            content = f.read()

        self.assertIn("public.health_check", content)
        self.assertIn("public.health_check_v1", content)
        self.assertIn("anon", content)
        self.assertIn("authenticated", content)
        self.assertIn("healthy", content)
        self.assertIn("connected", content)

    def test_pgtap_tests_dir_copy_exists(self):
        """pgTAP regression test file must exist in tests/ as specified in Issue #26."""
        test_path = os.path.join(TESTS_DIR, "test_health_check.sql")
        self.assertTrue(os.path.isfile(test_path), f"{test_path} does not exist.")


if __name__ == "__main__":
    unittest.main()
