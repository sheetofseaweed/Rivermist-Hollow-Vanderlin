/datum/unit_test/chat_macros_parenthesise_arguments

/datum/unit_test/chat_macros_parenthesise_arguments/Run()
	var/role = "Bandit"
	var/missing = null
	var/active = TRUE
	var/runtimed = FALSE
	var/literal_ternary
	var/numeric_ternary
	var/tooltip_ternary
	var/trait_ternary
	// An unparenthesised numeric ternary runtimes, which would abort Run() and record a pass.
	try
		literal_ternary = span_notice(TRUE ? "a" : "b")
		numeric_ternary = span_notice(active ? "a" : "b")
		tooltip_ternary = span_tooltip("tip", active ? "a" : "b")
		trait_ternary = SIGNAL_ADDTRAIT(active ? "a" : "b")
	catch
		runtimed = TRUE
	TEST_ASSERT(!runtimed, "A chat macro runtimed on a ternary argument.")
	TEST_ASSERT_EQUAL(literal_ternary, "<span class='notice'>a</span>", "Literal ternary argument was split.")
	TEST_ASSERT_EQUAL(numeric_ternary, "<span class='notice'>a</span>", "Numeric ternary argument was split.")
	TEST_ASSERT_EQUAL(tooltip_ternary, "<span data-component=\"Tooltip\" data-content=\"tip\" class=\"tooltip\">a</span>", "Tooltip ternary argument was split.")
	TEST_ASSERT_EQUAL(trait_ternary, "addtrait a", "Trait signal ternary argument was split.")
	TEST_ASSERT_EQUAL(span_boldred(role == "Bandit" ? "BANDIT!" : "OUTLAW!"), "<span class='bold red'>BANDIT!</span>", "Comparison ternary argument was split.")
	TEST_ASSERT_EQUAL(span_warning(missing || "fallback"), "<span class='warning'>fallback</span>", "Fallback argument was split.")
	TEST_ASSERT_EQUAL(examine_block(missing || "box"), "<div class='chat_box examine_block'>box</div>", "Div block argument was split.")
	TEST_ASSERT_EQUAL(EXAMINE_HINT(missing || "hint"), "<b>hint</b>", "Examine hint argument was split.")
	TEST_ASSERT_EQUAL(html_tag("i", missing || "tag"), "<i>tag</i>", "html_tag argument was split.")
	TEST_ASSERT_EQUAL(conditional_tooltip("plain", "tip", active ? FALSE : TRUE), "plain", "Tooltip condition argument was split.")
