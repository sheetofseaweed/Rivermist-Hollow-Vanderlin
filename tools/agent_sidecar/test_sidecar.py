#!/usr/bin/env python3
"""Tests for the sidecar side of the agent NPC protocol.

    python tools/agent_sidecar/test_sidecar.py

Stdlib unittest, no network, no provider, no cost. The DM side has its own
suite; this covers everything that lives in Python.

Several of these exist because a reviewer reproduced the bug first. Where that
is so, the test says which defect it pins down.
"""

import json
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import agent_protocol as proto
import codex_sale_sidecar as cs


PERMITTED = ["say", "emote", "wait"]


def envelope(pawn="mob_A", name="Alice", session="s1", epoch=1, events=None):
    return {
        "protocol_version": 1, "session_id": session, "pawn_id": pawn,
        "binding_epoch": epoch, "round_id": 1, "request_id": "r1",
        "binding_generation": 1, "observation_revision": 1,
        "profile": {"persona": "P", "background": "B", "voice": "V", "limits": "L",
                    "permitted_actions": PERMITTED},
        "observation": {"self": {"name": name}, "here": "square", "entities": []},
        "events": events or [],
    }


def verdict(state, **kw):
    return [{"event": "action_result", "detail": {"state": state}}]


class DeadlineBudget(unittest.TestCase):
    """The defect: the sidecar allowed the model 30s against a 15s deadline.

    DM abandoned the request at 15s and drained whatever came later, so a good
    answer produced a 200 in the sidecar log and silence in the game. Two
    actions were lost that way on 2026-09-17 before anyone noticed, because
    neither side logged the abandonment.
    """

    def test_budget_stays_inside_the_deadline(self):
        # 250 deciseconds is a 25 second deadline.
        budget = proto.upstream_timeout({"deadline_ds": 250}, 30)
        self.assertLess(budget, 25.0, "The model budget must end before DM stops listening.")
        self.assertEqual(budget, 25.0 - proto.UPSTREAM_MARGIN_SECONDS)

    def test_a_tight_deadline_still_leaves_the_model_room(self):
        # Squeezing to zero or negative would make every call fail instantly.
        self.assertEqual(proto.upstream_timeout({"deadline_ds": 10}, 30),
                         proto.MIN_UPSTREAM_TIMEOUT)

    def test_a_missing_or_unusable_deadline_falls_back(self):
        for body in ({}, {"deadline_ds": None}, {"deadline_ds": "soon"},
                     {"deadline_ds": 0}, {"deadline_ds": -5}, None):
            self.assertEqual(proto.upstream_timeout(body, 30), 30, repr(body))

    def test_a_boolean_deadline_is_not_treated_as_a_number(self):
        # In Python True is an int, so a naive isinstance check would read
        # deadline_ds=True as a 0.1 second budget.
        self.assertEqual(proto.upstream_timeout({"deadline_ds": True}, 30), 30)


class RequestLocalState(unittest.TestCase):
    """The HTTP server is threaded; per-request values must not live on self."""

    def test_interleaved_builds_do_not_cross_characters(self):
        # Reproduced by review: Alice's stored turn began "You are Bob."
        decider = cs.CodexSaleDecider(dry_run=True, memory_turns=4)
        alice, bob = envelope("mob_A", "Alice"), envelope("mob_B", "Bob")

        turn_a = decider.build_turn(alice)
        decider.build_turn(bob)           # a concurrent request lands in between
        decider.memory.record(alice, turn_a.user_text, {"name": "say", "text": "hello"})
        decider.memory.reconcile(envelope("mob_A", "Alice", events=verdict("succeeded")))

        stored = decider.memory.history(alice)[0]["content"]
        self.assertIn("You are Alice", stored)
        self.assertNotIn("You are Bob", stored)

    def test_turn_carries_its_own_permitted_list(self):
        decider = cs.CodexSaleDecider(dry_run=True)
        wide = envelope()
        narrow = envelope()
        narrow["profile"]["permitted_actions"] = ["wait"]

        turn_wide = decider.build_turn(wide)
        turn_narrow = decider.build_turn(narrow)

        self.assertEqual(turn_wide.permitted, PERMITTED)
        self.assertEqual(turn_narrow.permitted, ["wait"])


class ProposalsVersusHistory(unittest.TestCase):
    """The model proposes; DM disposes. History records only what DM allowed."""

    def test_answer_is_not_history_until_dm_rules(self):
        decider = cs.CodexSaleDecider(dry_run=True, memory_turns=4)
        body = envelope()
        turn = decider.build_turn(body)
        decider.memory.record(body, turn.user_text, {"name": "say", "text": "x"})
        self.assertEqual(decider.memory.depth(body), 0)

    def test_rejected_action_never_enters_history(self):
        decider = cs.CodexSaleDecider(dry_run=True, memory_turns=4)
        body = envelope()
        turn = decider.build_turn(body)
        decider.memory.record(body, turn.user_text, {"name": "say", "text": "never happened"})

        decider.memory.reconcile(envelope(events=verdict("rejected")))

        self.assertEqual(decider.memory.depth(body), 0,
                         "a transcript claiming the character did something it never did "
                         "is worse than a shorter transcript")

    def test_accepted_action_enters_history(self):
        decider = cs.CodexSaleDecider(dry_run=True, memory_turns=4)
        body = envelope()
        turn = decider.build_turn(body)
        decider.memory.record(body, turn.user_text, {"name": "say", "text": "happened"})

        decider.memory.reconcile(envelope(events=verdict("succeeded")))

        self.assertEqual(decider.memory.depth(body), 1)

    def test_failed_action_is_kept_because_it_did_happen(self):
        decider = cs.CodexSaleDecider(dry_run=True, memory_turns=4)
        body = envelope()
        turn = decider.build_turn(body)
        decider.memory.record(body, turn.user_text, {"name": "approach", "handle": "h1"})

        decider.memory.reconcile(envelope(events=verdict("failed")))

        self.assertEqual(decider.memory.depth(body), 1,
                         "failing to reach something still happened; only 'rejected' "
                         "means DM refused to run it at all")


class MemoryKeying(unittest.TestCase):

    def test_rebuilt_npc_does_not_inherit_a_dead_one(self):
        # pawn_id is a BYOND ref and refs are reused after deletion.
        decider = cs.CodexSaleDecider(dry_run=True, memory_turns=4)
        old = envelope(epoch=1)
        turn = decider.build_turn(old)
        decider.memory.record(old, turn.user_text, {"name": "wait"})
        decider.memory.reconcile(envelope(epoch=1, events=verdict("succeeded")))

        self.assertEqual(decider.memory.depth(old), 1)
        self.assertEqual(decider.memory.depth(envelope(epoch=2)), 0)

    def test_new_round_drops_older_sessions(self):
        decider = cs.CodexSaleDecider(dry_run=True, memory_turns=4)
        old = envelope(session="s1")
        turn = decider.build_turn(old)
        decider.memory.record(old, turn.user_text, {"name": "wait"})
        decider.memory.reconcile(envelope(session="s1", events=verdict("succeeded")))
        self.assertEqual(decider.memory.depth(old), 1)

        fresh = envelope(session="s2", pawn="mob_Z")
        turn = decider.build_turn(fresh)
        decider.memory.record(fresh, turn.user_text, {"name": "wait"})
        decider.memory.reconcile(envelope(session="s2", pawn="mob_Z", events=verdict("succeeded")))

        self.assertEqual(decider.memory.depth(old), 0)

    def test_history_is_bounded_and_starts_on_a_user_turn(self):
        decider = cs.CodexSaleDecider(dry_run=True, memory_turns=2)
        for i in range(5):
            body = envelope()
            turn = decider.build_turn(body)
            decider.memory.record(body, turn.user_text, {"name": "say", "text": "t%d" % i})
            decider.memory.reconcile(envelope(events=verdict("succeeded")))

        history = decider.memory.history(envelope())
        self.assertEqual(len(history) // 2, 2)
        self.assertEqual(history[0]["role"], "user")

    def test_memory_can_be_disabled(self):
        decider = cs.CodexSaleDecider(dry_run=True, memory_turns=0)
        body = envelope()
        turn = decider.build_turn(body)
        decider.memory.record(body, turn.user_text, {"name": "wait"})
        decider.memory.reconcile(envelope(events=verdict("succeeded")))
        self.assertEqual(decider.memory.depth(body), 0)


class OutputShape(unittest.TestCase):
    """codex.sale accepts json_schema without enforcing it."""

    def test_every_mode_states_the_shape_in_the_prompt(self):
        decider = cs.CodexSaleDecider(dry_run=True)
        for mode in cs.OUTPUT_MODES:
            system = decider.build_turn(envelope(), mode=mode).request["messages"][0]["content"]
            self.assertIn("Reply with a single JSON object", system, mode)
            self.assertIn('"wait"', system, mode)

    def test_text_mode_sends_no_response_format(self):
        decider = cs.CodexSaleDecider(dry_run=True)
        self.assertNotIn("response_format",
                         decider.build_turn(envelope(), mode="text").request)

    def test_schema_enum_comes_from_the_profile(self):
        decider = cs.CodexSaleDecider(dry_run=True)
        narrow = envelope()
        narrow["profile"]["permitted_actions"] = ["wait"]
        request = decider.build_turn(narrow, mode="json_schema").request
        enum = request["response_format"]["json_schema"]["schema"]["properties"]["action"]["enum"]
        self.assertEqual(enum, ["wait"])


class ReplyParsing(unittest.TestCase):

    def test_shorthand_replies_are_recovered(self):
        # The reply that made a live NPC stand silent: valid, just not JSON.
        got = proto.parse_loose_action("say: Morning to you.", PERMITTED)
        self.assertEqual(proto.to_dm_action(got), {"name": "say", "text": "Morning to you."})

    def test_prose_is_not_mistaken_for_a_command(self):
        for prose in ("I stand quietly and watch the river.",
                      "saying nothing feels right",
                      ""):
            self.assertIsNone(proto.parse_loose_action(prose, PERMITTED), prose)

    def test_unpermitted_shorthand_is_not_recovered(self):
        self.assertIsNone(proto.parse_loose_action("approach: h1", PERMITTED))

    def test_json_survives_fences_and_preamble(self):
        for raw in ('{"action":"wait","text":"","key":"","handle":""}',
                    '```json\n{"action":"wait","text":"","key":"","handle":""}\n```',
                    'Sure!\n{"action":"wait","text":"","key":"","handle":""}'):
            self.assertEqual(proto.to_dm_action(proto.extract_json(raw)), {"name": "wait"})

    def test_empty_object_is_not_a_valid_action(self):
        # The probe once treated any extractable JSON as proof of enforcement.
        self.assertIsNotNone(proto.extract_json("{}"))
        self.assertIsNone(proto.to_dm_action({}))


class Interpretation(unittest.TestCase):

    def setUp(self):
        self.decider = cs.CodexSaleDecider(dry_run=True)
        self.turn = self.decider.build_turn(envelope())

    def reply(self, content, finish="stop", extra=None):
        message = {"content": content}
        if extra:
            message.update(extra)
        return {"usage": {"total_tokens": 7},
                "choices": [{"message": message, "finish_reason": finish}]}

    def test_good_json_becomes_an_action(self):
        action, refusal, _ = self.decider.interpret(
            200, self.reply('{"action":"say","text":"hi","key":"","handle":""}'), self.turn)
        self.assertIsNone(refusal)
        self.assertEqual(action, {"name": "say", "text": "hi"})

    def test_answer_in_a_sibling_field_is_found(self):
        action, _, _ = self.decider.interpret(
            200, self.reply("", extra={"reasoning_content":
                                       '{"action":"wait","text":"","key":"","handle":""}'}),
            self.turn)
        self.assertEqual(action, {"name": "wait"})

    def test_empty_content_refuses_rather_than_crashing(self):
        action, refusal, _ = self.decider.interpret(200, self.reply(""), self.turn)
        self.assertIsNone(action)
        self.assertIn("empty", refusal)

    def test_transport_failures_refuse_with_a_reason(self):
        for status, expect in ((401, "api key"), (429, "rate limited"), (500, "provider error")):
            action, refusal, _ = self.decider.interpret(status, {"error": "x"}, self.turn)
            self.assertIsNone(action)
            self.assertIn(expect, refusal)


if __name__ == "__main__":
    unittest.main(verbosity=2)
