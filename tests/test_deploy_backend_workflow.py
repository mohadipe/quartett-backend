import os
import unittest
import yaml

WORKFLOW_PATH = os.path.join(
    os.path.dirname(__file__), "..", ".github", "workflows", "deploy_backend.yml"
)


class TestDeployBackendWorkflow(unittest.TestCase):
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
        """Workflow file .github/workflows/deploy_backend.yml must exist."""
        self.assertTrue(
            self.workflow_exists,
            f"Expected {WORKFLOW_PATH} to exist.",
        )

    def test_workflow_valid_yaml(self):
        """Workflow file must be parseable as valid YAML dictionary."""
        self.assertIsNotNone(self.workflow, "YAML content could not be parsed.")
        self.assertIsInstance(self.workflow, dict)

    def test_workflow_triggers(self):
        """Workflow must define triggers for push (main, tags) and workflow_dispatch."""
        triggers = self.workflow.get("on") or self.workflow.get(True, {})
        self.assertIn("push", triggers, "Missing 'push' trigger.")
        self.assertIn("workflow_dispatch", triggers, "Missing 'workflow_dispatch' trigger.")

        push = triggers["push"]
        self.assertIn("branches", push, "Push trigger missing 'branches'.")
        self.assertIn("main", push["branches"], "Push trigger must include 'main' branch.")

        self.assertIn("tags", push, "Push trigger missing 'tags'.")
        self.assertTrue(
            any("backend-v*" in tag for tag in push["tags"]),
            f"Push tags must include 'backend-v*': {push.get('tags')}",
        )

        wf_dispatch = triggers["workflow_dispatch"]
        self.assertIn("inputs", wf_dispatch, "workflow_dispatch missing 'inputs'.")
        self.assertIn("environment", wf_dispatch["inputs"], "workflow_dispatch missing 'environment' input.")
        env_input = wf_dispatch["inputs"]["environment"]
        self.assertEqual(env_input.get("type"), "choice")
        options = env_input.get("options", [])
        self.assertIn("staging", options)
        self.assertIn("production", options)

    def test_staging_job_structure_and_logic(self):
        """Job 1 (Staging): triggers on main push or staging dispatch, runs tests, and deploys to quartett-stage."""
        jobs = self.workflow.get("jobs", {})
        staging_job = jobs.get("staging") or jobs.get("deploy-staging")
        self.assertIsNotNone(staging_job, "Missing staging job in jobs.")

        condition = str(staging_job.get("if", ""))
        self.assertIn("main", condition, "Staging job condition must check for main branch push.")
        self.assertIn("staging", condition, "Staging job condition must check for staging dispatch.")

        steps = staging_job.get("steps", [])
        step_runs = [s.get("run", "") for s in steps]
        step_uses = [s.get("uses", "") for s in steps]

        # 1. Supabase CLI Setup
        self.assertTrue(
            any("supabase/setup-cli" in use for use in step_uses),
            "Staging job must setup Supabase CLI.",
        )

        # 2. Local pgTAP Tests
        self.assertTrue(
            any("supabase start" in run for run in step_runs),
            "Staging job must start local Supabase instance for tests.",
        )
        self.assertTrue(
            any("supabase test db" in run for run in step_runs),
            "Staging job must run pgTAP db tests.",
        )

        # 3. Deploy to Staging with SUPABASE_PROJECT_REF_STAGING
        all_step_text = " ".join(step_runs + [str(s.get("env", {})) for s in steps])
        self.assertIn(
            "SUPABASE_PROJECT_REF_STAGING",
            all_step_text,
            "Staging deploy must reference SUPABASE_PROJECT_REF_STAGING.",
        )
        self.assertTrue(
            any("supabase db push" in run for run in step_runs),
            "Staging deploy must execute supabase db push.",
        )

        # 4. Step Summary
        self.assertTrue(
            any("GITHUB_STEP_SUMMARY" in run for run in step_runs),
            "Staging job must write status to GITHUB_STEP_SUMMARY.",
        )

    def test_production_job_structure_and_logic(self):
        """Job 2 (Production): triggers on backend-v* tag or production dispatch, runs tests, creates backup, and deploys to quartett-prod."""
        jobs = self.workflow.get("jobs", {})
        prod_job = jobs.get("production") or jobs.get("deploy-production")
        self.assertIsNotNone(prod_job, "Missing production job in jobs.")

        condition = str(prod_job.get("if", ""))
        self.assertIn("backend-v", condition, "Production job condition must check for backend-v* tag.")
        self.assertIn("production", condition, "Production job condition must check for production dispatch.")

        steps = prod_job.get("steps", [])
        step_runs = [s.get("run", "") for s in steps]
        step_uses = [s.get("uses", "") for s in steps]

        # 1. Supabase CLI Setup
        self.assertTrue(
            any("supabase/setup-cli" in use for use in step_uses),
            "Production job must setup Supabase CLI.",
        )

        # 2. Local pgTAP Tests
        self.assertTrue(
            any("supabase start" in run for run in step_runs),
            "Production job must start local Supabase instance for tests.",
        )
        self.assertTrue(
            any("supabase test db" in run for run in step_runs),
            "Production job must run pgTAP db tests.",
        )

        # 3. Automated Backup
        self.assertTrue(
            any("supabase db dump" in run for run in step_runs),
            "Production job must run automated backup via supabase db dump.",
        )
        self.assertTrue(
            any("actions/upload-artifact" in use for use in step_uses),
            "Production job must upload database backup as artifact.",
        )

        # 4. Deploy to Production with SUPABASE_PROJECT_REF_PROD
        all_step_text = " ".join(step_runs + [str(s.get("env", {})) for s in steps])
        self.assertIn(
            "SUPABASE_PROJECT_REF_PROD",
            all_step_text,
            "Production deploy must reference SUPABASE_PROJECT_REF_PROD.",
        )
        self.assertTrue(
            any("supabase db push" in run for run in step_runs),
            "Production deploy must execute supabase db push.",
        )

        # 5. Step Summary
        self.assertTrue(
            any("GITHUB_STEP_SUMMARY" in run for run in step_runs),
            "Production job must write status to GITHUB_STEP_SUMMARY.",
        )

    def _eval_condition(self, condition_str: str, context: dict) -> bool:
        """Helper to evaluate GitHub Actions boolean expression against a context dict."""
        # Normalize whitespace and newlines into a single line expression
        expr = " ".join(condition_str.split())
        event_name = context.get("github", {}).get("event_name", "")
        ref = context.get("github", {}).get("ref", "")
        environment = context.get("github", {}).get("event", {}).get("inputs", {}).get("environment", "")

        # Evaluate github.event_name
        expr = expr.replace("github.event_name == 'push'", str(event_name == "push"))
        expr = expr.replace("github.event_name == 'workflow_dispatch'", str(event_name == "workflow_dispatch"))

        # Evaluate github.ref
        expr = expr.replace("github.ref == 'refs/heads/main'", str(ref == "refs/heads/main"))

        # Evaluate startsWith(github.ref, 'refs/tags/backend-v')
        expr = expr.replace(
            "startsWith(github.ref, 'refs/tags/backend-v')",
            str(ref.startswith("refs/tags/backend-v")),
        )

        # Evaluate github.event.inputs.environment
        expr = expr.replace(
            "github.event.inputs.environment == 'staging'",
            str(environment == "staging"),
        )
        expr = expr.replace(
            "github.event.inputs.environment == 'production'",
            str(environment == "production"),
        )

        # Convert logical operators to python
        expr = expr.replace("&&", " and ").replace("||", " or ")
        return bool(eval(expr))

    def test_acceptance_criteria_staging_on_main_push(self):
        """GIVEN push on main, staging runs and production does not."""
        staging_if = str(self.workflow["jobs"]["staging"]["if"])
        prod_if = str(self.workflow["jobs"]["production"]["if"])
        context = {
            "github": {
                "event_name": "push",
                "ref": "refs/heads/main",
                "event": {"inputs": {}},
            }
        }
        self.assertTrue(self._eval_condition(staging_if, context))
        self.assertFalse(self._eval_condition(prod_if, context))

    def test_acceptance_criteria_production_on_tag_push(self):
        """GIVEN push of tag backend-v0.2.0, production runs and staging does not."""
        staging_if = str(self.workflow["jobs"]["staging"]["if"])
        prod_if = str(self.workflow["jobs"]["production"]["if"])
        context = {
            "github": {
                "event_name": "push",
                "ref": "refs/tags/backend-v0.2.0",
                "event": {"inputs": {}},
            }
        }
        self.assertFalse(self._eval_condition(staging_if, context))
        self.assertTrue(self._eval_condition(prod_if, context))

    def test_acceptance_criteria_workflow_dispatch_staging(self):
        """GIVEN workflow_dispatch for staging, staging runs and production does not."""
        staging_if = str(self.workflow["jobs"]["staging"]["if"])
        prod_if = str(self.workflow["jobs"]["production"]["if"])
        context = {
            "github": {
                "event_name": "workflow_dispatch",
                "ref": "refs/heads/main",
                "event": {"inputs": {"environment": "staging"}},
            }
        }
        self.assertTrue(self._eval_condition(staging_if, context))
        self.assertFalse(self._eval_condition(prod_if, context))

    def test_acceptance_criteria_workflow_dispatch_production(self):
        """GIVEN workflow_dispatch for production, production runs and staging does not."""
        staging_if = str(self.workflow["jobs"]["staging"]["if"])
        prod_if = str(self.workflow["jobs"]["production"]["if"])
        context = {
            "github": {
                "event_name": "workflow_dispatch",
                "ref": "refs/heads/main",
                "event": {"inputs": {"environment": "production"}},
            }
        }
        self.assertFalse(self._eval_condition(staging_if, context))
        self.assertTrue(self._eval_condition(prod_if, context))


if __name__ == "__main__":
    unittest.main()
