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

/// Split a line once for the whole crowd: lowercased words, and those written as a comma vocative ("bob,").
/proc/agent_prepare_words(text)
	var/list/words = list()
	var/list/vocatives = list()
	if(istext(text))
		var/list/raws = splittext(lowertext(text), " ")
		var/count = length(raws)
		var/half = AGENT_NAME_WORDS_MAX / 2
		var/i = 0
		while(i < count)
			i++
			// A long line's middle is skipped. For suppression that fails safe: a missed vocative means answering.
			if(i > half && i <= count - half)
				i = count - half
				continue
			var/raw = raws[i]
			if(!agent_word_worth_reading(raw))
				continue
			var/word = agent_trim_punctuation(raw)
			if(!length(word))
				continue
			words[word] = TRUE
			if(copytext(raw, -1) == ",")
				vocatives[word] = TRUE
	return list("words" = words, "vocatives" = vocatives)

/// Could this word be a name part at all? Too short or too long is skipped before per-letter work.
/proc/agent_word_worth_reading(raw)
	return length(raw) >= 3 && length(raw) <= AGENT_NAME_WORD_MAX

/// Whole-word match. findtext alone is a substring test, which is how a short
/// name swallows an ordinary word.
/proc/agent_text_has_word(text, word)
	if(!istext(text) || !istext(word) || !length(word))
		return FALSE
	var/list/prepared = agent_prepare_words(text)
	var/list/words = prepared["words"]
	return !!words[lowertext(word)]

/// Is this "Unknown Man" and the like? Matching those woke masked NPCs on every "man".
/proc/agent_name_is_placeholder(who)
	return !istext(who) || !length(who) || findtext(who, "Unknown") == 1

/// Name parts worth matching on. Short parts and filler match too much: nobody calls "the goat" "the".
/proc/agent_name_tokens(who)
	var/static/list/filler = list("the", "and", "for", "with", "from")
	var/list/useful = list()
	if(agent_name_is_placeholder(who))
		return useful
	for(var/part in splittext(who, " "))
		if(length_char(part) > 2 && !(lowertext(part) in filler))
			useful += part
	return useful

/// Strong: vocative, first or last word, or the whole name. Weak: mid-sentence. Positive evidence only.
/proc/agent_self_address_strength(who, text)
	if(!istext(text))
		return AGENT_NAMED_NONE
	var/list/parts = agent_name_tokens(who)
	if(!length(parts))
		return AGENT_NAMED_NONE

	// Per name part, once: its folded form, and the letter a word must start with to be worth folding.
	var/list/forms = list()
	var/list/initials = list()
	for(var/part in parts)
		var/form = agent_fold_name(part)
		forms[part] = (length(form) >= AGENT_FOLD_MIN_LENGTH) ? form : null
		initials[copytext(forms[part] || lowertext(part), 1, 2)] = TRUE

	// Positions count blanks too, so "I will go now" keeps "will" in the middle.
	var/list/raws = splittext(text, " ")
	var/last = length(raws)
	var/half = AGENT_NAME_WORDS_MAX / 2
	var/strength = AGENT_NAMED_NONE
	var/list/parts_seen = list()

	var/i = 0
	while(i < last)
		i++
		// Names are said at the edges. A name missed mid-monologue reads as unclear, which still wakes the NPC.
		if(i > half && i <= last - half)
			i = last - half
			continue
		var/raw = raws[i]
		if(!agent_word_worth_reading(raw))
			continue
		var/word = agent_trim_punctuation(raw)
		if(!length(word))
			continue
		// One cheap letter per word decides whether any part could match.
		if(!initials[agent_fold_initial(word)])
			continue
		var/matched
		for(var/part in parts)
			if(agent_word_is_name(word, part, forms[part]))
				matched = part
				break
		if(!matched)
			continue
		parts_seen |= matched
		if(i == 1 || i == last || (copytext(raw, -1) in list(",", "!", ":")))
			return AGENT_NAMED_STRONG
		strength = AGENT_NAMED_WEAK

	if(length(parts) > 1 && length(parts_seen) == length(parts))
		return AGENT_NAMED_STRONG
	return strength

/// Any mention at all. The classifier uses agent_self_address_strength directly.
/proc/agent_name_matches_loosely(who, text)
	return agent_self_address_strength(who, text) != AGENT_NAMED_NONE

/**
 * Strict: the name in a vocative position, or the whole name present.
 *
 * Only ever used to decide that SOMEBODY ELSE was addressed, which suppresses a
 * response. High precision and low recall on purpose. "Bob," is being spoken to;
 * "tell Bob" is prose, and a single common-word name in prose proves nothing.
 */
/proc/agent_name_in_vocative(who, text, list/prepared)
	if(!istext(text))
		return FALSE
	var/list/parts = agent_name_tokens(who)
	if(!length(parts))
		return FALSE

	// Callers checking one line against a crowd pass it in, split once.
	if(!prepared)
		prepared = agent_prepare_words(text)
	var/list/words = prepared["words"]
	var/list/vocatives = prepared["vocatives"]

	// "Bob, pass the ale". A trailing comma is the clearest vocative there is.
	for(var/part in parts)
		if(vocatives[lowertext(part)])
			return TRUE

	// Or every part of a multi-part name. Two names rarely co-occur by accident.
	if(length(parts) < 2)
		return FALSE
	for(var/part in parts)
		if(!words[lowertext(part)])
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
	if(!istext(text) || !length(text))
		return AGENT_SCRIPT_NONE

	var/list/cyrillic = agent_cyrillic_map()
	var/latin_letters = 0
	var/cyrillic_letters = 0

	// A sample decides it: copytext_char walks from the start, so reading every letter was quadratic.
	var/sample = copytext_char(text, 1, AGENT_SCRIPT_SAMPLE + 1)
	for(var/i in 1 to length_char(sample))
		var/glyph = copytext_char(sample, i, i + 1)
		if(cyrillic[glyph])
			cyrillic_letters++
		// The empty-string entries are real letters that transliterate to
		// nothing, so they must be counted before this falls through.
		else if(glyph in list("ъ", "ь", "Ъ", "Ь"))
			cyrillic_letters++
		else
			var/lowered = lowertext(glyph)
			if(lowered >= "a" && lowered <= "z")
				latin_letters++
		if(cyrillic_letters && latin_letters)
			return AGENT_SCRIPT_MIXED

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

/// The letter a word folds to, from its first glyph. The gate: folding every word cost 2.3 ms, measured.
/proc/agent_fold_initial(word)
	var/glyph = copytext_char(word, 1, 2)
	var/list/cyrillic = agent_cyrillic_map()
	if(glyph in cyrillic)
		glyph = cyrillic[glyph]
	glyph = lowertext(copytext(glyph, 1, 2))
	return glyph == "c" ? "k" : glyph

/// Is this word the name, spelled or transliterated? Case endings only on Cyrillic, or Mark answers "market".
/proc/agent_word_is_name(word, part, form)
	if(lowertext(word) == lowertext(part))
		return TRUE
	if(!form)
		return FALSE
	var/folded = agent_fold_name(word)
	if(folded == form)
		return TRUE
	if(agent_text_script(word) != AGENT_SCRIPT_CYRILLIC)
		return FALSE
	return findtext(folded, form) == 1 && (length(folded) - length(form)) <= AGENT_FOLD_MAX_SUFFIX

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

/// An emote's words with case kept, possessives cut, same edge window as speech.
/proc/agent_emote_words(text)
	var/list/words = list()
	if(!istext(text))
		return words
	var/list/raws = splittext(text, " ")
	var/count = length(raws)
	var/half = AGENT_NAME_WORDS_MAX / 2
	var/i = 0
	while(i < count)
		i++
		if(i > half && i <= count - half)
			i = count - half
			continue
		var/raw = raws[i]
		if(!agent_word_worth_reading(raw))
			continue
		var/word = agent_trim_punctuation(raw)
		if(copytext(word, -2) == "'s")
			word = copytext(word, 1, -2)
		if(length(word))
			words[word] = TRUE
	return words

/// Strict: an exact capitalised name part, or a Cyrillic word folding to one. "will" never names Will.
/proc/agent_emote_mentions(who, list/words)
	if(!length(words))
		return FALSE
	var/list/parts = agent_name_tokens(who)
	for(var/part in parts)
		// List keys compare case-sensitively, which is the whole point here.
		if(words[part])
			return TRUE
		var/form = agent_fold_name(part)
		if(length(form) < AGENT_FOLD_MIN_LENGTH)
			continue
		var/initial = copytext(form, 1, 2)
		for(var/word in words)
			if(agent_fold_initial(word) != initial)
				continue
			if(agent_text_script(word) == AGENT_SCRIPT_CYRILLIC && agent_word_is_name(word, part, form))
				return TRUE
	return FALSE
