import os
import unittest

try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False

WORKFLOW_PATH = os.path.join(
    os.path.dirname(__file__), "..", ".github", "workflows", "release_backend.yml"
)


@unittest.skipUnless(HAS_YAML, "PyYAML (pip install pyyaml) is required to test GitHub Actions workflows")
class TestReleaseBackendWorkflow(unittest.TestCase):
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
        """Workflow file .github/workflows/release_backend.yml must exist."""
        self.assertTrue(
            self.workflow_exists,
            f"Expected {WORKFLOW_PATH} to exist.",
        )

    def test_workflow_valid_yaml(self):
        """Workflow file must be parseable as valid YAML dictionary."""
        self.assertIsNotNone(self.workflow, "YAML content could not be parsed.")
        self.assertIsInstance(self.workflow, dict)

    def test_workflow_triggers(self):
        """Workflow must define workflow_dispatch with required inputs."""
        triggers = self.workflow.get("on") or self.workflow.get(True, {})
        self.assertIn("workflow_dispatch", triggers, "Missing 'workflow_dispatch' trigger.")

        wf_dispatch = triggers["workflow_dispatch"]
        self.assertIn("inputs", wf_dispatch, "workflow_dispatch missing 'inputs'.")
        inputs = wf_dispatch["inputs"]

        # bump_type input
        self.assertIn("bump_type", inputs, "Missing 'bump_type' input.")
        self.assertEqual(inputs["bump_type"].get("type"), "choice")
        bump_options = inputs["bump_type"].get("options", [])
        self.assertIn("patch", bump_options)
        self.assertIn("minor", bump_options)
        self.assertIn("major", bump_options)

        # custom_version input
        self.assertIn("custom_version", inputs, "Missing 'custom_version' input.")

        # custom_notes input
        self.assertIn("custom_notes", inputs, "Missing 'custom_notes' input.")

        # trigger_deploy input
        self.assertIn("trigger_deploy", inputs, "Missing 'trigger_deploy' input.")
        self.assertEqual(inputs["trigger_deploy"].get("type"), "boolean")

    def test_workflow_permissions(self):
        """Workflow must have contents: write and actions: write permissions."""
        permissions = self.workflow.get("permissions", {})
        self.assertEqual(permissions.get("contents"), "write")
        self.assertEqual(permissions.get("actions"), "write")

    def test_release_job_steps(self):
        """Release job must contain test, versioning, changelog, tag push, gh release, and deploy trigger steps."""
        jobs = self.workflow.get("jobs", {})
        self.assertTrue(len(jobs) > 0, "No jobs defined in release workflow.")
        job_key = list(jobs.keys())[0]
        release_job = jobs[job_key]

        steps = release_job.get("steps", [])
        step_names = [s.get("name", "") for s in steps]
        step_runs = [s.get("run", "") for s in steps]
        step_uses = [s.get("uses", "") for s in steps]
        all_runs_text = "\n".join(step_runs)

        # 1. Checkout with full history
        self.assertTrue(
            any("actions/checkout" in use for use in step_uses),
            "Must use actions/checkout.",
        )
        checkout_step = next(s for s in steps if "actions/checkout" in s.get("uses", ""))
        self.assertEqual(
            checkout_step.get("with", {}).get("fetch-depth"),
            0,
            "Checkout must have fetch-depth: 0 for commit history.",
        )

        # 2. Test execution before release
        self.assertTrue(
            any("supabase test db supabase/tests/contracts" in run for run in step_runs),
            "Must run pgTAP contract regression tests before releasing.",
        )
        self.assertTrue(
            any("supabase test db" in run for run in step_runs),
            "Must run supabase test db before releasing.",
        )

        # 3. Versioning step
        self.assertTrue(
            "generate_release_changelog.py bump" in all_runs_text,
            "Must run generate_release_changelog.py bump.",
        )

        # 4. Changelog step
        self.assertTrue(
            "generate_release_changelog.py changelog" in all_runs_text,
            "Must run generate_release_changelog.py changelog.",
        )

        # 5. Git tag creation & push
        self.assertTrue(
            "git tag" in all_runs_text and "git push origin" in all_runs_text,
            "Must create and push git tag.",
        )

        # 6. GitHub Release
        self.assertTrue(
            any("softprops/action-gh-release" in use for use in step_uses)
            or any("gh release create" in run for run in step_runs),
            "Must create official GitHub Release.",
        )

        # 7. Production deployment trigger
        self.assertTrue(
            "gh workflow run deploy_backend.yml" in all_runs_text,
            "Must trigger deploy_backend.yml using GitHub CLI.",
        )
        self.assertTrue(
            "environment=production" in all_runs_text,
            "Deploy trigger must specify environment=production.",
        )


if __name__ == "__main__":
    unittest.main()
