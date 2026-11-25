import unittest

from screenpilot.geometry import Frame, fit, logical_size


class GeometryTest(unittest.TestCase):
    def test_fractional_scale(self):
        self.assertEqual(logical_size({"width": 2560, "height": 1440, "scale": 1.25, "transform": 0}), (2048, 1152))

    def test_rotated_monitor_swaps_width_and_height(self):
        for t in (1, 3, 5, 7):
            self.assertEqual(logical_size({"width": 2560, "height": 1440, "scale": 1.25, "transform": t}), (1152, 2048))
        for t in (2, 4, 6):
            self.assertEqual(logical_size({"width": 2560, "height": 1440, "scale": 1.25, "transform": t}), (2048, 1152))

    def test_model_pixels_map_to_layout_on_an_offset_monitor(self):
        f = Frame(1920, 0, 2048, 1152, 1568, 882)
        self.assertEqual(f.to_layout(784, 441), (2944, 576))
        self.assertEqual(f.to_layout(0, 0), (1920, 0))

    def test_round_trip(self):
        f = Frame(-1080, 200, 1080, 1920, 882, 1568)
        for p in ((0, 0), (10.5, 1567), (881, 3)):
            x, y = f.from_layout(*f.to_layout(*p))
            self.assertAlmostEqual(x, p[0])
            self.assertAlmostEqual(y, p[1])

    def test_contains_is_the_image(self):
        f = Frame(0, 0, 1920, 1080, 1568, 882)
        self.assertTrue(f.contains(0, 0))
        self.assertTrue(f.contains(1567.9, 881.9))
        self.assertFalse(f.contains(1568, 10))
        self.assertFalse(f.contains(-1, 10))

    def test_fit(self):
        self.assertEqual(fit(1920, 1080, 1568), (1568, 882))
        self.assertEqual(fit(1080, 1920, 1568), (882, 1568))
        self.assertEqual(fit(800, 600, 1568), (800, 600))


if __name__ == "__main__":
    unittest.main()
