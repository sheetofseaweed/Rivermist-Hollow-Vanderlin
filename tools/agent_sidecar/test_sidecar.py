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


def heard(speaker, text):
    return {"event": "heard_speech", "detail": {"speaker": speaker, "text": text, "addressing": "directed"}}


class HistoryCondensation(unittest.TestCase):
    """Memory keeps what happened, not the scene. The scene is resent fresh every turn."""

    def busy_body(self):
        body = envelope(events=[heard("Anna", "Where is the mill?")])
        body["observation"]["entities"] = [
            {"handle": "h%d" % i, "name": "villager %d" % i, "distance": 3, "direction": "north",
             "wearing": ["tunic", "trousers", "boots"], "holding": ["basket"]} for i in range(1, 11)]
        return body

    def test_memory_keeps_what_happened_not_the_scene(self):
        turn = cs.CodexSaleDecider(dry_run=True).build_turn(self.busy_body())
        self.assertIn("Where is the mill?", turn.history_text)
        self.assertNotIn("You can see", turn.history_text)
        # Old handles in memory point at whatever they meant then. Not remembering them avoids that.
        self.assertNotIn("[h1]", turn.history_text)

    def test_a_remembered_turn_costs_far_less_than_the_scene(self):
        # Measured 2026-09-18: 3540 tokens a decision once memory filled, mostly old scenes.
        turn = cs.CodexSaleDecider(dry_run=True).build_turn(self.busy_body())
        self.assertLess(len(turn.history_text) * 5, len(turn.user_text))

    def test_a_quiet_turn_is_remembered_briefly(self):
        self.assertEqual(proto.build_history_text([]), "(Nothing new had happened.)")


class AddressingHints(unittest.TestCase):
    """What the model is told about who a line was for.

    DM decides whether a line buys a decision; the model decides how to answer.
    It can only do that well if the hints DM worked out actually reach it.
    """

    def line(self, **detail):
        detail.setdefault("speaker", "Ivan")
        detail.setdefault("text", "hello")
        return proto.describe_speech("heard_speech", detail)

    def test_explicit_focus_is_stated(self):
        self.assertIn("said directly to you", self.line(spoken_to_you=True, addressing="directed"))

    def test_a_partner_reply_is_stated(self):
        self.assertIn("continuing your conversation", self.line(from_partner=True, addressing="directed"))

    def test_focus_is_not_also_called_a_partner_reply(self):
        # One line, one reason. Both at once reads as the model being unsure.
        rendered = self.line(spoken_to_you=True, from_partner=True, addressing="directed")
        self.assertIn("said directly to you", rendered)
        self.assertNotIn("continuing your conversation", rendered)

    def test_unclear_and_overheard_are_distinguished(self):
        self.assertIn("unclear whether this was meant for you", self.line(addressing="ambiguous"))
        self.assertIn("not apparently to you", proto.describe_speech("overheard_speech", {"speaker": "Ivan", "text": "hello"}))

    def test_a_plain_directed_line_carries_no_hedging(self):
        rendered = self.line(addressing="directed")
        self.assertNotIn("unclear", rendered)
        self.assertNotIn("not apparently", rendered)


class SceneRendering(unittest.TestCase):
    """What the model is shown of the world. A field DM sends but this never prints is invisible."""

    def turn(self, observation, events=None):
        observation.setdefault("self", {"name": "Isaac"})
        observation.setdefault("here", "tavern")
        return proto.build_user_message(observation, events or [])

    def test_structures_are_listed_with_state_and_count(self):
        # The defect: a barstool the player pointed at did not exist for the model.
        text = self.turn({"structures": [
            {"handle": "h3", "name": "barstool", "distance": 1, "direction": "north", "more": 4},
            {"handle": "h4", "name": "wooden door", "distance": 3, "direction": "east", "state": "closed"},
        ]})
        self.assertIn("[h3] barstool - 1 tile north; 4 more like it further off", text)
        self.assertIn("[h4] wooden door (closed) - 3 tiles east", text)

    def test_other_people_show_both_hands_and_clothing(self):
        line = proto.describe_entity({"handle": "h1", "name": "Anna", "distance": 2, "direction": "west",
                                      "holding": ["mug", "knife"], "wearing": ["bar dress", "boots"],
                                      "posture": "on the barstool"})
        self.assertIn("holding mug and knife", line)
        self.assertIn("wearing bar dress, boots", line)
        self.assertIn("on the barstool", line)

    def test_a_person_showing_no_clothing_is_said_to(self):
        line = proto.describe_entity({"handle": "h1", "name": "Anna", "distance": 2, "direction": "west", "wearing": []})
        self.assertIn("wearing nothing visible", line)

    def test_an_animal_is_not_described_as_naked(self):
        # No wearing key means the thing cannot wear clothes, not that it wears none.
        line = proto.describe_entity({"handle": "h1", "name": "cat", "distance": 2, "direction": "west"})
        self.assertNotIn("wearing", line)

    def test_the_old_single_hand_string_still_renders(self):
        line = proto.describe_entity({"handle": "h1", "name": "Anna", "distance": 2, "direction": "west", "holding": "mug"})
        self.assertIn("holding mug", line)

    def test_own_inventory_is_shown(self):
        # The defect: DM sent what the NPC wore, and this never printed it.
        text = self.turn({"self": {"name": "Isaac", "holding": ["torch", "mug"], "wearing": ["shirt", "trousers"],
                                   "carrying": [{"in": "pouch", "items": ["copper coin x3", "key"]}],
                                   "on": "barstool"}})
        self.assertIn("You are holding torch and mug.", text)
        self.assertIn("You are wearing: shirt, trousers.", text)
        self.assertIn("In your pouch: copper coin x3, key.", text)
        self.assertIn("You are on the barstool.", text)

    def test_empty_hands_are_said(self):
        self.assertIn("Your hands are empty.", self.turn({"self": {"name": "Isaac", "holding": []}}))

    def test_same_tile_reads_as_here(self):
        line = proto.describe_structure({"handle": "h2", "name": "barstool", "distance": 0, "direction": None})
        self.assertIn("right here", line)
        self.assertNotIn("None", line)


class EmoteRendering(unittest.TestCase):
    """Emotes reach the model as things people did, with how aimed they seemed."""

    def test_an_emote_event_is_rendered(self):
        text = proto.build_user_message({"self": {"name": "Isaac"}}, [
            {"event": "saw_emote", "detail": {"speaker": "Anna", "text": "waves at Isaac.", "addressing": "directed"}}])
        self.assertIn("Anna waves at Isaac.", text)

    def test_involuntary_is_marked_and_not_hedged(self):
        line = proto.describe_emote("noticed_emote", {"speaker": "Anna", "text": "coughs.", "involuntary": True,
                                                      "addressing": "overheard"})
        self.assertIn("involuntary", line)
        # One reason is enough. "Not aimed at you" on a cough is noise.
        self.assertNotIn("aimed at you", line)

    def test_unclear_and_overheard_are_distinguished(self):
        self.assertIn("unclear whether this was aimed at you",
                      proto.describe_emote("saw_emote", {"speaker": "Anna", "text": "smiles.", "addressing": "ambiguous"}))
        self.assertIn("not apparently aimed at you",
                      proto.describe_emote("noticed_emote", {"speaker": "Anna", "text": "smiles."}))


class TouchAndStimuli(unittest.TestCase):
    """The touch action on the way out, and hands laid on the NPC on the way in."""

    def test_touch_maps_to_the_dm_shape(self):
        self.assertEqual(proto.to_dm_action({"action": "touch", "handle": "h2", "key": "hug", "text": ""}),
                         {"name": "touch", "handle": "h2", "key": "hug"})

    def test_touch_shorthand_is_recovered(self):
        got = proto.parse_loose_action("touch: h2 hug", ["touch", "wait"])
        self.assertEqual(proto.to_dm_action(got), {"name": "touch", "handle": "h2", "key": "hug"})
        # No way given is a tap; DM fills that in, so an empty key is correct here.
        got = proto.parse_loose_action("touch: h2", ["touch", "wait"])
        self.assertEqual(proto.to_dm_action(got), {"name": "touch", "handle": "h2", "key": ""})

    def test_aliases_are_named_to_the_model(self):
        profile = {"persona": "P", "permitted_actions": ["wait"], "aliases": ["Ike", "Айзек"]}
        self.assertIn("People may also call you: Ike, Айзек.", proto.build_system(profile))
        profile["aliases"] = []
        self.assertNotIn("also call you", proto.build_system(profile))

    def test_touch_is_explained_only_when_permitted(self):
        profile = {"persona": "P", "permitted_actions": ["say", "touch", "wait"]}
        self.assertIn("'touch'", proto.build_system(profile))
        profile["permitted_actions"] = ["say", "wait"]
        self.assertNotIn("'touch'", proto.build_system(profile))

    def test_physical_events_read_plainly(self):
        self.assertEqual(proto.describe_physical({"what": "touched", "by": "Anna"}), "Anna touched you.")
        self.assertEqual(proto.describe_physical({"what": "fed", "by": "Anna", "item": "bread"}), "Anna fed you bread.")
        self.assertEqual(proto.describe_physical({"what": "grabbed", "by": "Bob", "count": 3}), "Bob grabbed you (3 times).")

    def test_counted_attacks_say_how_many(self):
        text = proto.build_user_message({"self": {"name": "Isaac"}}, [
            {"event": "attacked", "detail": {"by": "Bob", "count": 4}}])
        self.assertIn("Bob attacked you (4 times).", text)

    def test_a_physical_event_reaches_the_turn(self):
        text = proto.build_user_message({"self": {"name": "Isaac"}}, [
            {"event": "physical", "detail": {"what": "shoved", "by": "Bob"}}])
        self.assertIn("Bob shoved you.", text)


class SitGiveTakeMe(unittest.TestCase):
    """The four actions added 2026-09-24, and the notes that keep sneakers hidden."""

    ALL = ["say", "me", "sit", "stand", "give", "take", "wait"]

    def test_new_actions_map_to_the_dm_shape(self):
        cases = [
            ({"action": "me", "text": "wipes the bar."}, {"name": "me", "text": "wipes the bar."}),
            ({"action": "sit", "handle": "h4"}, {"name": "sit", "handle": "h4"}),
            ({"action": "stand"}, {"name": "stand"}),
            ({"action": "give", "handle": "h2", "key": "h7"}, {"name": "give", "handle": "h2", "key": "h7"}),
            ({"action": "take", "handle": "h2"}, {"name": "take", "handle": "h2"}),
        ]
        for parsed, expected in cases:
            self.assertEqual(proto.to_dm_action(parsed), expected, parsed)

    def test_new_shorthand_is_recovered(self):
        self.assertEqual(proto.to_dm_action(proto.parse_loose_action("me: wipes the bar.", self.ALL)),
                         {"name": "me", "text": "wipes the bar."})
        self.assertEqual(proto.to_dm_action(proto.parse_loose_action("give: h2 h7", self.ALL)),
                         {"name": "give", "handle": "h2", "key": "h7"})
        self.assertEqual(proto.to_dm_action(proto.parse_loose_action("sit: h4", self.ALL)),
                         {"name": "sit", "handle": "h4"})
        self.assertEqual(proto.to_dm_action(proto.parse_loose_action("stand", self.ALL)), {"name": "stand"})

    def test_each_action_is_explained_only_when_permitted(self):
        wide = proto.build_system({"persona": "P", "permitted_actions": self.ALL})
        narrow = proto.build_system({"persona": "P", "permitted_actions": ["say", "wait"]})
        for phrase in ("'me'", "'sit'", "'give'"):
            self.assertIn(phrase, wide)
            self.assertNotIn(phrase, narrow)

    def test_held_items_show_their_handles(self):
        text = proto.build_user_message({"self": {"name": "Isaac", "holding": ["mug"],
                                                  "held": [{"handle": "h9", "name": "mug"}]}}, [])
        self.assertIn("You are holding [h9] mug.", text)

    def test_an_offer_and_its_taking_read_plainly(self):
        self.assertEqual(proto.describe_physical({"what": "offered", "by": "Anna", "item": "bread"}),
                         "Anna is offering you bread.")
        text = proto.build_user_message({"self": {"name": "Isaac"}}, [
            {"event": "offer_taken", "detail": {"by": "Anna", "item": "mug"}}])
        self.assertIn("Anna took the mug you held out.", text)

    def test_unseen_is_said_everywhere(self):
        # A sneaker the NPC has not spotted is heard and felt, never seen.
        self.assertIn("you cannot see them", proto.describe_speech("heard_speech", {"speaker": "Bob", "text": "hi",
                                                                                    "unseen": True}))
        self.assertIn("you cannot see them", proto.describe_emote("saw_emote", {"speaker": "Bob", "text": "waves.",
                                                                                 "unseen": True}))
        self.assertIn("you cannot see them", proto.describe_physical({"what": "touched", "by": "Bob", "unseen": True}))
        self.assertNotIn("cannot see", proto.describe_speech("heard_speech", {"speaker": "Bob", "text": "hi"}))


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
        alice = envelope("mob_A", "Alice", events=[heard("Ivan", "for Alice")])
        bob = envelope("mob_B", "Bob", events=[heard("Ivan", "for Bob")])

        turn_a = decider.build_turn(alice)
        decider.build_turn(bob)           # a concurrent request lands in between
        decider.memory.record(alice, turn_a.history_text, {"name": "say", "text": "hello"})
        decider.memory.reconcile(envelope("mob_A", "Alice", events=verdict("succeeded")))

        stored = decider.memory.history(alice)[0]["content"]
        self.assertIn("for Alice", stored)
        self.assertNotIn("for Bob", stored)

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


class PerProfileMemory(unittest.TestCase):
    """A profile may set its own memory length, so a social NPC can remember more than a guard."""

    def body(self, memory=None, events=None):
        body = envelope(events=events)
        if memory is not None:
            body["profile"]["memory_turns"] = memory
        return body

    def fill(self, store, memory, count):
        for i in range(count):
            store.record(self.body(memory), "turn %d" % i, {"name": "say", "text": "t%d" % i})
            store.reconcile(self.body(memory, events=verdict("succeeded")))

    def test_a_profile_can_remember_more_than_the_default(self):
        store = proto.ConversationStore(max_turns=2)
        self.fill(store, 5, 8)
        self.assertEqual(store.depth(self.body(5)), 5)

    def test_a_profile_can_remember_less(self):
        store = proto.ConversationStore(max_turns=6)
        self.fill(store, 1, 4)
        self.assertEqual(store.depth(self.body(1)), 1)
        self.assertEqual(store.history(self.body(1))[0]["role"], "user")

    def test_no_value_means_the_default(self):
        store = proto.ConversationStore(max_turns=3)
        self.fill(store, None, 6)
        self.assertEqual(store.depth(self.body()), 3)

    def test_the_ceiling_holds_whatever_the_profile_asks(self):
        store = proto.ConversationStore(max_turns=6)
        self.assertEqual(store.limit(self.body(10000)), proto.MAX_MEMORY_TURNS)
        self.assertEqual(store.limit(self.body(-4)), 0)
        # In Python True is an int; a boolean is not a length.
        self.assertEqual(store.limit(self.body(True)), 6)
        self.assertEqual(store.limit(self.body("12")), 6)

    def test_zero_on_the_command_line_still_turns_memory_off(self):
        # The operator's switch outranks any profile.
        store = proto.ConversationStore(max_turns=0)
        self.assertEqual(store.limit(self.body(10)), 0)
        self.fill(store, 10, 3)
        self.assertEqual(store.depth(self.body(10)), 0)

    def test_lowering_memory_mid_round_applies_at_once(self):
        store = proto.ConversationStore(max_turns=6)
        self.fill(store, 6, 6)
        self.assertEqual(store.depth(self.body(2)), 2)
        self.assertEqual(store.history(self.body(2))[0]["role"], "user")

    def test_switching_memory_off_forgets(self):
        store = proto.ConversationStore(max_turns=6)
        self.fill(store, 6, 3)
        store.reconcile(self.body(0, events=verdict("succeeded")))
        self.assertEqual(store.depth(self.body(6)), 0, "turning it back on must not bring old turns back")


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


class CapabilityProbe(unittest.TestCase):
    """The probe once treated any extractable JSON as proof the schema was enforced."""

    GOOD = '{"action":"say","text":"Well met.","key":"","handle":""}'

    def test_only_the_full_shape_proves_json_schema(self):
        self.assertTrue(cs.probe_honoured("json_schema", self.GOOD, ["say", "wait"]))
        for bad in ('{}',
                    '{"greeting": "hello"}',
                    '{"action":"say","text":"hi"}',
                    '{"action":"say","text":"hi","key":"","handle":"","mood":"warm"}',
                    '{"action":"say","text":7,"key":"","handle":""}',
                    '{"action":"dance","text":"","key":"","handle":""}',
                    'Well met, traveller.'):
            self.assertFalse(cs.probe_honoured("json_schema", bad, ["say", "wait"]), bad)

    def test_json_object_needs_an_object_not_a_shape(self):
        self.assertTrue(cs.probe_honoured("json_object", '{"greeting": "hello"}', ["say", "wait"]))
        self.assertFalse(cs.probe_honoured("json_object", '[1, 2]', ["say", "wait"]))
        self.assertFalse(cs.probe_honoured("json_object", "Well met.", ["say", "wait"]))

    def test_text_mode_proves_nothing(self):
        self.assertFalse(cs.probe_honoured("text", self.GOOD, ["say", "wait"]))


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
