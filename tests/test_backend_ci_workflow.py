import os
import unittest

try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False

WORKFLOW_PATH = os.path.join(
    os.path.dirname(__file__), "..", ".github", "workflows", "backend_ci.yml"
)
CONTRACTS_DIR = os.path.join(
    os.path.dirname(__file__), "..", "supabase", "tests", "contracts"
)


@unittest.skipUnless(HAS_YAML, "PyYAML is required to test GitHub Actions workflows")
class TestBackendCIWorkflow(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.workflow_exists = os.path.isfile(WORKFLOW_PATH)
        if cls.workflow_exists:
            with open(WORKFLOW_PATH, "r", encoding="utf-8") as f:
                cls.workflow_content = f.read()
                cls.workflow = yaml.safe_load(cls.workflow_content)
        else:
            cls.workflow_content = ""
            cls.workflow = None

    def test_workflow_file_exists(self):
        """Workflow file .github/workflows/backend_ci.yml must exist."""
        self.assertTrue(self.workflow_exists, f"Expected {WORKFLOW_PATH} to exist.")

    def test_workflow_triggers(self):
        """Workflow must trigger on push to main and pull_request to main."""
        triggers = self.workflow.get("on") or self.workflow.get(True, {})
        self.assertIn("push", triggers, "Missing push trigger.")
        self.assertIn("pull_request", triggers, "Missing pull_request trigger.")
        self.assertIn("main", triggers["push"].get("branches", []))
        self.assertIn("main", triggers["pull_request"].get("branches", []))

    def test_contract_regression_tests_step(self):
        """Backend CI must explicitly run pgTAP contract regression tests."""
        jobs = self.workflow.get("jobs", {})
        job = jobs.get("test-database")
        self.assertIsNotNone(job, "Missing test-database job.")

        steps = job.get("steps", [])
        step_runs = [s.get("run", "") for s in steps]
        step_names = [s.get("name", "") for s in steps]

        # Supabase start
        self.assertTrue(
            any("supabase start" in run for run in step_runs),
            "Must start local supabase containers.",
        )

        # Contract regression test step
        self.assertTrue(
            any("supabase test db supabase/tests/contracts" in run for run in step_runs),
            "Must run pgTAP contract regression tests on supabase/tests/contracts.",
        )

        # General db test step
        self.assertTrue(
            any(run.strip() == "supabase test db" for run in step_runs),
            "Must run full pgTAP test suite.",
        )

    def test_contract_test_files_exist(self):
        """Dedicated contract regression test files must exist in supabase/tests/contracts."""
        v1_test = os.path.join(CONTRACTS_DIR, "test_contract_v1.sql")
        v2_test = os.path.join(CONTRACTS_DIR, "test_contract_v2.sql")
        self.assertTrue(os.path.isfile(v1_test), f"Expected {v1_test} to exist.")
        self.assertTrue(os.path.isfile(v2_test), f"Expected {v2_test} to exist.")


if __name__ == "__main__":
    unittest.main()
