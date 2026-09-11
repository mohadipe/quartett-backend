import os
import glob
import unittest

MIGRATIONS_DIR = os.path.join(os.path.dirname(__file__), "..", "supabase", "migrations")
DATABASE_TESTS_DIR = os.path.join(os.path.dirname(__file__), "..", "supabase", "tests", "database")


class TestDeckLanguageMigrationAndTests(unittest.TestCase):
    def test_deck_language_migration_exists(self):
        """Migration file for deck language must exist."""
        matches = glob.glob(os.path.join(MIGRATIONS_DIR, "*add_language_to_decks.sql"))
        self.assertTrue(len(matches) > 0, "Migration *add_language_to_decks.sql not found.")

        with open(matches[0], "r", encoding="utf-8") as f:
            content = f.read()

        self.assertIn("ALTER TABLE public.decks", content)
        self.assertIn("language VARCHAR(5) DEFAULT 'de'", content)
        self.assertIn("v1_catalog_decks", content)
        self.assertIn("community_decks", content)
        self.assertIn("TO anon, authenticated", content)

    def test_pgtap_database_test_exists(self):
        """pgTAP test file must exist in supabase/tests/database."""
        test_path = os.path.join(DATABASE_TESTS_DIR, "11_deck_language_test.sql")
        self.assertTrue(os.path.isfile(test_path), f"{test_path} does not exist.")

        with open(test_path, "r", encoding="utf-8") as f:
            content = f.read()

        self.assertIn("has_column('public', 'decks', 'language'", content)
        self.assertIn("col_type_is('public', 'decks', 'language', 'character varying(5)'", content)
        self.assertIn("col_default_is('public', 'decks', 'language', 'de'", content)
        self.assertIn("has_view('public', 'community_decks'", content)
        self.assertIn("has_column('public', 'v1_catalog_decks', 'language'", content)


if __name__ == "__main__":
    unittest.main()
