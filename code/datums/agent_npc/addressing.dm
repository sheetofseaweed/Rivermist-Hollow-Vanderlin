/**
 * # Name matching for addressing
 *
 * Two matchers, deliberately different strengths, because the two questions
 * they answer have opposite costs.
 *
 * "Were we addressed?" may be answered loosely. A false positive costs one
 * decision. "Was somebody else addressed?" must be answered strictly, because a
 * false positive there is silence, and silence is what makes an NPC look broken.
 *
 * One shared proc for both was the original mistake: a mob named "Will" turned
 * "I will go now" into evidence that the line belonged to someone else.
 */

/// Strip the punctuation players attach to a name. copytext_char, not copytext,
/// because these strings are not always Latin.
/proc/agent_trim_punctuation(token)
	var/static/list/marks = list(",", ".", "!", "?", ";", ":", "\"", "'", "(", ")", "-")
	if(!istext(token))
		return ""
	while(length(token) && (copytext_char(token, 1, 2) in marks))
		token = copytext_char(token, 2)
	while(length(token) && (copytext_char(token, -1) in marks))
		token = copytext_char(token, 1, -1)
	return token

/// Whole-word match. findtext alone is a substring test, which is how a short
/// name swallows an ordinary word.
/proc/agent_text_has_word(text, word)
	if(!istext(text) || !istext(word) || !length(word))
		return FALSE
	var/needle = lowertext(word)
	for(var/token in splittext(lowertext(text), " "))
		if(agent_trim_punctuation(token) == needle)
			return TRUE
	return FALSE

/// Name parts worth matching on. Two characters or fewer match far too much.
/proc/agent_name_tokens(who)
	var/list/useful = list()
	if(!istext(who))
		return useful
	for(var/part in splittext(who, " "))
		if(length(part) > 2)
			useful += part
	return useful

/**
 * Loose: any part of the name, as a whole word.
 *
 * Only ever used to decide that WE were addressed, where being wrong costs a
 * single decision and being right is the difference between answering a player
 * and ignoring them.
 */
/proc/agent_name_matches_loosely(who, text)
	if(!istext(text))
		return FALSE
	for(var/part in agent_name_tokens(who))
		if(agent_text_has_word(text, part))
			return TRUE
	// Only after a plain match fails, because folding is lossy and this is the
	// path that decides we WERE addressed, where being wrong costs a decision.
	return agent_name_matches_folded(who, text)

/**
 * Strict: the name in a vocative position, or the whole name present.
 *
 * Only ever used to decide that SOMEBODY ELSE was addressed, which suppresses a
 * response. High precision and low recall on purpose. "Bob," is being spoken to;
 * "tell Bob" is prose, and a single common-word name in prose proves nothing.
 */
/proc/agent_name_in_vocative(who, text)
	if(!istext(text))
		return FALSE
	var/list/parts = agent_name_tokens(who)
	if(!length(parts))
		return FALSE

	var/list/tokens = splittext(lowertext(text), " ")

	// "Bob, pass the ale". A trailing comma is the clearest vocative there is.
	for(var/token in tokens)
		for(var/part in parts)
			if(token == "[lowertext(part)],")
				return TRUE

	// Or every part of a multi-part name. Two names rarely co-occur by accident.
	if(length(parts) < 2)
		return FALSE
	for(var/part in parts)
		if(!agent_text_has_word(text, part))
			return FALSE
	return TRUE

/**
 * # Matching a Latin name written in Cyrillic
 *
 * Many players here transliterate: an NPC called "Isaac" is addressed as
 * "Исаак", and Russian inflects, so it also arrives as "Исааку" or "Исааком".
 * Plain matching sees none of these, and the cost is not only a missed cue —
 * without a name match the distance rule silences distant speech, so a Russian
 * player shouting across a room was ignored where an English one was heard.
 *
 * The approach is to fold both sides toward a common shape rather than to keep
 * a table of spellings: transliterate, then flatten the differences that
 * transliteration choices produce. Isaac and Исаак both fold to "isak".
 *
 * **Everything here is positive evidence only.** A folded match may decide we
 * were addressed. It may never decide somebody else was: a fuzzy match that
 * silences the NPC is the one outcome the whole design exists to avoid.
 */

/// Cyrillic to Latin. Both cases, so folding never depends on lowertext
/// understanding a script it predates.
/proc/agent_cyrillic_map()
	var/static/list/table
	if(table)
		return table
	table = list(
		"а" = "a", "б" = "b", "в" = "v", "г" = "g", "д" = "d", "е" = "e",
		"ё" = "e", "ж" = "zh", "з" = "z", "и" = "i", "й" = "y", "к" = "k",
		"л" = "l", "м" = "m", "н" = "n", "о" = "o", "п" = "p", "р" = "r",
		"с" = "s", "т" = "t", "у" = "u", "ф" = "f", "х" = "h", "ц" = "ts",
		"ч" = "ch", "ш" = "sh", "щ" = "sch", "ъ" = "", "ы" = "y", "ь" = "",
		"э" = "e", "ю" = "yu", "я" = "ya",
		"А" = "a", "Б" = "b", "В" = "v", "Г" = "g", "Д" = "d", "Е" = "e",
		"Ё" = "e", "Ж" = "zh", "З" = "z", "И" = "i", "Й" = "y", "К" = "k",
		"Л" = "l", "М" = "m", "Н" = "n", "О" = "o", "П" = "p", "Р" = "r",
		"С" = "s", "Т" = "t", "У" = "u", "Ф" = "f", "Х" = "h", "Ц" = "ts",
		"Ч" = "ch", "Ш" = "sh", "Щ" = "sch", "Ъ" = "", "Ы" = "y", "Ь" = "",
		"Э" = "e", "Ю" = "yu", "Я" = "ya",
	)
	return table

/// Which script is this written in? Counted over the letters, because mixed
/// lines like "Исаак, come here" are ordinary here.
/proc/agent_text_script(text)
	if(!istext(text) || !length_char(text))
		return AGENT_SCRIPT_NONE

	var/list/cyrillic = agent_cyrillic_map()
	var/latin_letters = 0
	var/cyrillic_letters = 0

	for(var/i in 1 to length_char(text))
		var/glyph = copytext_char(text, i, i + 1)
		if(cyrillic[glyph])
			cyrillic_letters++
			continue
		// The empty-string entries are real letters that transliterate to
		// nothing, so they must be counted before this falls through.
		if(glyph in list("ъ", "ь", "Ъ", "Ь"))
			cyrillic_letters++
			continue
		var/lowered = lowertext(glyph)
		if(lowered >= "a" && lowered <= "z")
			latin_letters++

	if(cyrillic_letters && latin_letters)
		return AGENT_SCRIPT_MIXED
	if(cyrillic_letters)
		return AGENT_SCRIPT_CYRILLIC
	if(latin_letters)
		return AGENT_SCRIPT_LATIN
	return AGENT_SCRIPT_NONE

/// Can a Latin name be matched against text in this script at all? If not, a
/// failed match says nothing and must never be read as evidence.
/proc/agent_script_is_matchable(script)
	return script == AGENT_SCRIPT_LATIN || script == AGENT_SCRIPT_CYRILLIC || script == AGENT_SCRIPT_MIXED || script == AGENT_SCRIPT_NONE

/**
 * Fold a word toward the shape a name shares across spellings.
 *
 * Transliterate, lowercase, merge c into k, then collapse doubled letters.
 * "Isaac" and "Исаак" both become "isak". This is deliberately lossy: it exists
 * to find a name, never to reconstruct one.
 */
/proc/agent_fold_name(word)
	if(!istext(word) || !length_char(word))
		return ""

	var/list/cyrillic = agent_cyrillic_map()
	var/converted = ""
	for(var/i in 1 to length_char(word))
		var/glyph = copytext_char(word, i, i + 1)
		if(glyph in cyrillic)
			converted += cyrillic[glyph]
		else
			converted += glyph

	converted = lowertext(converted)

	var/folded = ""
	var/previous = ""
	for(var/i in 1 to length(converted))
		var/letter = copytext(converted, i, i + 1)
		if(letter < "a" || letter > "z")
			continue
		// c and k are the commonest transliteration fork in a Latin name.
		if(letter == "c")
			letter = "k"
		if(letter == previous)
			continue
		folded += letter
		previous = letter
	return folded

/**
 * Does a folded form of this name appear in the text?
 *
 * Inflection tolerance is applied only to Cyrillic words. Russian case endings
 * are why it exists, and allowing a trailing suffix on Latin text would wake an
 * NPC named Mark every time somebody mentioned a market.
 */
/proc/agent_name_matches_folded(who, text)
	if(!istext(text))
		return FALSE

	var/list/forms = list()
	for(var/part in agent_name_tokens(who))
		var/folded = agent_fold_name(part)
		if(length(folded) >= AGENT_FOLD_MIN_LENGTH)
			forms += folded
	if(!length(forms))
		return FALSE

	for(var/token in splittext(text, " "))
		var/trimmed = agent_trim_punctuation(token)
		var/folded_token = agent_fold_name(trimmed)
		if(length(folded_token) < AGENT_FOLD_MIN_LENGTH)
			continue
		var/inflectable = agent_text_script(trimmed) == AGENT_SCRIPT_CYRILLIC
		for(var/form in forms)
			if(folded_token == form)
				return TRUE
			if(!inflectable)
				continue
			if(findtext(folded_token, form) == 1 && (length(folded_token) - length(form)) <= AGENT_FOLD_MAX_SUFFIX)
				return TRUE
	return FALSE

/**
 * Was that shouted?
 *
 * say_test reads the trailing punctuation the speaker typed, and send_speech
 * then extends the range by 5 tiles for "!" and 10 for "!!". A shout is a
 * deliberate attempt to be heard at distance, so judging one by ordinary
 * speaking range is exactly how a player yelling across a room gets ignored.
 */
/proc/agent_speech_is_shouted(volume)
	return volume == "2" || volume == "3"
