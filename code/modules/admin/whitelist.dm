#ifdef TESTSERVER
	#define WHITELISTFILE	"[global.config.directory]/roguetown/wl_test.txt"
#else
	#define WHITELISTFILE	"[global.config.directory]/roguetown/wl_mat.txt"
#endif

GLOBAL_LIST_EMPTY(whitelist)
GLOBAL_PROTECT(whitelist)

/proc/load_whitelist()
	GLOB.whitelist = list()
	for(var/line in world.file2list(WHITELISTFILE))
		if(!line)
			continue
		if(findtextEx(line,"#",1,2))
			continue
		GLOB.whitelist += ckey(line)
/*
/proc/check_whitelist(ckey)
	if(!GLOB.whitelist || !GLOB.whitelist.len)
		load_whitelist()
#ifdef TESTSERVER
	var/plevel = check_patreon_lvl(ckey)
	if(plevel >= 3)
		return TRUE
#endif
	return (ckey in GLOB.whitelist)*/

// HSECTOR EDIT START
/proc/check_whitelist(key)
	if(!SSdbcore.Connect())
		log_world("Failed to connect to database in check_whitelist(). Disabling whitelist for current round.")
		log_game("Failed to connect to database in check_whitelist(). Disabling whitelist for current round.")
		CONFIG_SET(flag/usewhitelist, FALSE)
		return TRUE

	var/datum/DBQuery/query_get_whitelist = SSdbcore.NewQuery({"
		SELECT id FROM [format_table_name("whitelist")]
		WHERE ckey = :ckey
	"}, list("ckey" = key)
	)

	if(!query_get_whitelist.Execute())
		log_sql("Whitelist check for ckey [key] failed to execute. Rejecting")
		message_admins("Whitelist check for ckey [key] failed to execute. Rejecting")
		qdel(query_get_whitelist)
		return FALSE

	var/allow = query_get_whitelist.NextRow()

	qdel(query_get_whitelist)

	return allow

#undef WHITELISTFILE
