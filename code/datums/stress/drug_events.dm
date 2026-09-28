/datum/stress_event/smoked
	desc = "<span class='nicegreen'>I have had a smoke recently.</span>\n"
	stress_change = 2
	timer = 6 MINUTES

/datum/stress_event/overdose
	desc = span_red("I took too much.")
	stress_change = 3
	timer = 5 MINUTES

// Each addiction tick refreshes the current stage, so a stage lapses soon after withdrawal moves on or ends.
/datum/stress_event/withdrawal_light
	desc = span_red("I could use a fix.")
	stress_change = 1
	timer = 30 SECONDS

/datum/stress_event/withdrawal_medium
	desc = span_red("I need a fix.")
	stress_change = 2
	timer = 30 SECONDS

/datum/stress_event/withdrawal_severe
	desc = span_red("I crave a fix so badly it hurts.")
	stress_change = 3
	timer = 30 SECONDS

/datum/stress_event/withdrawal_critical
	desc = span_boldred("I NEED A FIX!")
	stress_change = 4
	timer = 30 SECONDS

/datum/stress_event/happiness_drug
	desc = "<span class='nicegreen'>I can't feel anything and I never want this to end.</span>\n"
	stress_change = 50

/datum/stress_event/happiness_drug_good_od
	desc = "<span class='nicegreen'>YES! YES!! YES!!!</span>\n"
	stress_change = 100
	timer = 30 SECONDS

/datum/stress_event/happiness_drug_bad_od
	desc = "<span class='boldwarning'>NO! NO!! NO!!!</span>\n"
	stress_change = -100
	timer = 30 SECONDS

/datum/stress_event/narcotic_medium
	desc = "<span class='nicegreen'>I feel comfortably numb.</span>\n"
	stress_change = 4
	timer = 3 MINUTES

/datum/stress_event/narcotic_heavy
	desc = "<span class='nicegreen'>I feel like I'm wrapped in cotton!</span>\n"
	stress_change = -3
	timer = 3 MINUTES

/datum/stress_event/stimulant_medium
	desc = "<span class='nicegreen'>I have so much energy and I feel like I could do anything.</span>\n"
	stress_change = 4
	timer = 3 MINUTES

/datum/stress_event/stimulant_heavy
	desc = "<span class='nicegreen'>Eh ah AAAAH! HA HA HA HA HAA! Uuuh.</span>\n"
	stress_change = 6
	timer = 3 MINUTES
