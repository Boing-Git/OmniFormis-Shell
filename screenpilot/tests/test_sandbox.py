import os
import unittest

from screenpilot import config
from screenpilot.sandbox import Sandbox
from helpers import private_runtime


class SandboxEnvTest(unittest.TestCase):
    def setUp(self):
        private_runtime(self)

    def test_apps_get_their_own_home_and_folders(self):
        env = Sandbox().sway_env()
        home = env["HOME"]
        self.assertNotEqual(home, os.path.expanduser("~"))
        self.assertTrue(home.startswith(str(config.state_dir())))
        for var in ("XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_STATE_HOME", "XDG_CACHE_HOME"):
            self.assertTrue(env[var].startswith(home), var)
        self.assertEqual(env["XDG_RUNTIME_DIR"], str(config.runtime_dir()))   # the sockets stay shared
        self.assertEqual(env["WLR_BACKENDS"], "wayland")

    def test_sway_runs_on_its_own_session_bus(self):
        cmd = Sandbox().sway_cmd()
        self.assertEqual(cmd[:2], ["dbus-run-session", "--"])
        self.assertIn("sway", cmd)


if __name__ == "__main__":
    unittest.main()
