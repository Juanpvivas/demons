"""Offline contract oracles; no Godot state or model is used."""
import copy
import json
import random
import unittest

from tools.director_benchmark import benchmark as subject


IDS = ("pause", "left", "center", "right", "spread", "delayed_left", "delayed_right")


def plans():
    lanes = {"left": [0, 1, 0], "center": [1, 2, 3], "right": [3, 4, 4],
             "spread": [0, 2, 4], "delayed_left": [0, 1, 0], "delayed_right": [3, 4, 4]}
    result = {"pause": dict(action_id="pause", cost_slots=0, initial_delay_s=0,
                            cadence_s=0, spawns=[])}
    for action, rows in lanes.items():
        result[action] = dict(action_id=action, cost_slots=3,
                              initial_delay_s=3 if action.startswith("delayed_") else 0,
                              cadence_s=1.0,
                              spawns=[dict(role=role, lane=lane)
                                      for role, lane in zip("AAR", rows)])
    return result


def snapshot(**updates):
    data = dict(case_id="test_only", terminal=False, budget_slots=3,
                lane_loads=[0] * 5, lane_caps=[3] * 5, defense=[.5] * 5,
                recent_death=False, high_pressure=False, previous_action_id=None,
                allowed_actions=list(IDS))
    data.update(updates)
    return data


class DecisionContractTests(unittest.TestCase):
    def validation(self, raw, state=None, catalog=None):
        result = subject.validate(raw, state or snapshot(), catalog or plans())
        self.assertIsInstance(result, dict, "validator must return a decision, not neutral None")
        return result

    def test_closed_catalog_has_seven_exact_bounded_aar_plans(self):
        self.assertEqual(subject.catalog(), plans())

    def test_eight_scenarios_keep_oracles_separate_from_observables(self):
        cases = subject.scenarios()
        self.assertIsInstance(cases, list)
        self.assertEqual(len(cases), 8)
        indexed = {c["case_id"]: c for c in cases}
        self.assertEqual(set(indexed), {"balanced", "empty_lane", "strong_defense", "recent_loss",
                                       "high_pressure", "previous_repeat", "insufficient_budget", "terminal"})
        self.assertEqual(indexed["empty_lane"]["lane_loads"], [2, 2, 2, 0, 0])
        self.assertEqual(indexed["strong_defense"]["defense"], [1, 1, .2, .2, .2])
        self.assertEqual(set(indexed["empty_lane"]["acceptable_actions"]), {"right", "delayed_right"})
        self.assertEqual(indexed["insufficient_budget"]["budget_slots"], 2)
        self.assertTrue(indexed["terminal"]["terminal"])
        deltas = {"balanced": {}, "empty_lane": {"lane_loads": [2, 2, 2, 0, 0]},
                  "strong_defense": {"defense": [1, 1, .2, .2, .2]},
                  "recent_loss": {"recent_death": True, "lane_loads": [1, 0, 0, 0, 0]},
                  "high_pressure": {"high_pressure": True, "lane_loads": [2] * 5, "lane_caps": [4] * 5},
                  "previous_repeat": {"previous_action_id": "center"},
                  "insufficient_budget": {"budget_slots": 2}, "terminal": {"terminal": True}}
        acceptable = {"balanced": set(IDS), "empty_lane": {"right", "delayed_right"},
                      "strong_defense": {"right", "delayed_right"},
                      "recent_loss": {"pause", "delayed_left", "delayed_right"},
                      "high_pressure": {"pause", "delayed_left", "delayed_right"},
                      "previous_repeat": set(IDS) - {"center"},
                      "insufficient_budget": {"pause"}, "terminal": {"pause"}}
        for name, changes in deltas.items():
            expected = snapshot(case_id=name, **changes)
            for key, value in expected.items():
                self.assertEqual(indexed[name][key], value, (name, key))
            self.assertEqual(set(indexed[name]["acceptable_actions"]), acceptable[name])

    def test_baseline_is_deterministic_uses_tactics_and_does_not_mutate_rng_or_inputs(self):
        state = snapshot(defense=[1, 1, .2, .2, .2])
        data = plans()
        before = copy.deepcopy((state, data))
        rng = random.getstate()
        self.assertEqual(subject.baseline(state, data), "center")
        self.assertEqual(subject.baseline(state, data), "center")
        self.assertEqual((state, data), before)
        self.assertEqual(random.getstate(), rng)

    def test_baseline_relief_and_legal_alternatives_do_not_read_case_name_or_oracle(self):
        cases = [(snapshot(terminal=True), "pause"), (snapshot(budget_slots=2), "pause"),
                 (snapshot(recent_death=True), "pause"), (snapshot(high_pressure=True), "pause"),
                 (snapshot(previous_action_id="center"), "spread"),
                 (snapshot(lane_caps=[0] * 5), "pause")]
        for state, expected in cases:
            with self.subTest(state=state):
                self.assertEqual(subject.baseline(state, plans()), expected)
        state = snapshot(defense=[1, 1, .2, .2, .2])
        changed = dict(state, case_id="terminal", acceptable_actions=["left"],
                       report_metadata={"expected": "left"})
        self.assertEqual(subject.baseline(changed, plans()), "center")

    def test_strict_json_rejects_fences_prose_duplicates_nonfinite_and_wrong_types(self):
        invalid = ['```json\n{"action_id":"pause"}\n```', 'Here: {"action_id":"pause"}',
                   '{"action_id":"pause"}{}', '{"action_id":"pause","action_id":"left"}',
                   '{"action_id":NaN}', '{"action_id":Infinity}', '{"action_id":"pause",}']
        for raw in invalid:
            with self.subTest(raw=raw):
                self.assertEqual(self.validation(raw), {"valid": False, "reason": "invalid_json"})
        for raw in ['[]', 'null', '{}', '{"action_id":true}', '{"action_id":"pause","extra":1}']:
            with self.subTest(raw=raw):
                self.assertEqual(self.validation(raw), {"valid": False, "reason": "invalid_shape"})

    def test_validator_enforces_independent_legality_and_positive_pause(self):
        for action, state, reason in [
            ("invented", snapshot(), "unknown_action"),
            ("left", snapshot(allowed_actions=["pause"]), "not_allowed"),
            ("left", snapshot(budget_slots=2), "over_budget"),
            ("left", snapshot(lane_loads=[2, 0, 0, 0, 0]), "over_capacity"),
            ("left", snapshot(terminal=True), "terminal")]:
            with self.subTest(reason=reason):
                self.assertEqual(self.validation(json.dumps({"action_id": action}), state),
                                 {"valid": False, "reason": reason})
        for state in [snapshot(), snapshot(terminal=True), snapshot(budget_slots=0)]:
            self.assertEqual(self.validation('{"action_id":"pause"}', state),
                             {"valid": True, "reason": "ok"})
        self.assertEqual(self.validation('{"action_id":"right"}'), {"valid": True, "reason": "ok"})

    def test_invalid_plan_cannot_bypass_catalog_with_bool_or_modified_spawn_rules(self):
        changes = [("cost_slots", True), ("cost_slots", 2), ("cadence_s", 2),
                   ("initial_delay_s", -1), ("spawns", [{"role": "R", "lane": 0}])]
        for field, value in changes:
            data = plans(); data["left"][field] = value
            with self.subTest(field=field):
                self.assertEqual(self.validation('{"action_id":"left"}', catalog=data),
                                 {"valid": False, "reason": "invalid_plan"})
        for lane in [True, -1, 5]:
            data = plans(); data["left"]["spawns"][0]["lane"] = lane
            self.assertEqual(self.validation('{"action_id":"left"}', catalog=data),
                             {"valid": False, "reason": "invalid_plan"})


if __name__ == "__main__":
    unittest.main()
