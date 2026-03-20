/obj/item/game_kit
	name = "Gaming Kit"
	icon = 'modular_rmh/icons/obj/items/game_kit.dmi'
	icon_state = "game_kit"
	item_state = "game_kit"
	var/selected = null
	var/board_stat = null
	var/list/viewers_list = list()
	var/static/list/chess_icons = list(
		"board_BI.png" = 'modular_rmh/icons/chess/board_BI.png',
		"board_BK.png" = 'modular_rmh/icons/chess/board_BK.png',
		"board_BN.png" = 'modular_rmh/icons/chess/board_BN.png',
		"board_BP.png" = 'modular_rmh/icons/chess/board_BP.png',
		"board_BQ.png" = 'modular_rmh/icons/chess/board_BQ.png',
		"board_BR.png" = 'modular_rmh/icons/chess/board_BR.png',
		"board_WI.png" = 'modular_rmh/icons/chess/board_WI.png',
		"board_WK.png" = 'modular_rmh/icons/chess/board_WK.png',
		"board_WN.png" = 'modular_rmh/icons/chess/board_WN.png',
		"board_WP.png" = 'modular_rmh/icons/chess/board_WP.png',
		"board_WQ.png" = 'modular_rmh/icons/chess/board_WQ.png',
		"board_WR.png" = 'modular_rmh/icons/chess/board_WR.png',
		"board_none.png" = 'modular_rmh/icons/chess/board_none.png'
	)

/obj/item/game_kit/Initialize()
	. = ..()
	board_stat = "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB"
	selected = null

/obj/item/game_kit/proc/get_icon_url(name)
	var/file = chess_icons[name]
	if(!file)
		return ""
	return SSassets.transport.get_asset_url(name)

/obj/item/game_kit/proc/send_chess_assets(mob/user)
	if(!user?.client)
		return
	for(var/asset_name in chess_icons)
		SSassets.transport.register_asset(asset_name, chess_icons[asset_name])
		SSassets.transport.send_assets(user.client, asset_name)

/obj/item/game_kit/proc/build_html(mob/user)
	var/dat = "<center><b>Game Board</b></center><br>"
	var/table_style = "width:256px;height:256px;border-collapse:collapse;border-spacing:0;table-layout:fixed;font-size:0;line-height:0;"
	var/tile_style = "width:32px;height:32px;padding:0;margin:0;line-height:0;"
	var/board_link_style = "display:block;width:32px;height:32px;padding:0;margin:0;border:0;background:transparent;line-height:0;font-size:0;text-decoration:none;"
	var/board_image_style = "display:block;width:32px;height:32px;padding:0;margin:0;border:0;background:transparent;"
	var/piece_link_style = "display:inline-block;width:32px;height:32px;padding:0;margin:0 6px 0 0;border:0;background:transparent;line-height:0;font-size:0;text-decoration:none;"
	dat += "<a href='?src=\ref[src];mode=hia'>[(selected ? "Selected: [selected]" : "Nothing Selected")]</a> "
	dat += "<a href='?src=\ref[src];mode=remove'>Chess Removal</a><hr>"
	dat += "<table style='[table_style]' cellspacing=0 cellpadding=0>"
	for(var/y = 1 to 8)
		dat += "<tr style='height:32px'>"
		for(var/x = 1 to 8)
			var/color = (y + x) % 2 ? "#ffffff" : "#999999"
			var/index = ((y - 1) * 8 + x)
			var/piece = copytext(board_stat, index * 2 - 1, index * 2 + 1)
			dat += "<td style='background-color:[color];[tile_style]'>"
			dat += "<a href='?src=\ref[src];s_board=[x],[y]' style='[board_link_style]'>"
			if(piece != "BB")
				var/url = get_icon_url("board_[piece].png")
				dat += "<img src='[url]' width='32' height='32' style='[board_image_style]'>"
			dat += "</a></td>"
		dat += "</tr>"
	dat += "</table><hr><b>Chess pieces:</b><br>"
	for(var/piece in list("WP","WK","WQ","WI","WN","WR"))
		var/url = get_icon_url("board_[piece].png")
		dat += "<a href='?src=\ref[src];s_piece=[piece]' style='[piece_link_style]'><img src='[url]' width='32' height='32' style='[board_image_style]'></a>"
	dat += "<br>"
	for(var/piece in list("BP","BK","BQ","BI","BN","BR"))
		var/url = get_icon_url("board_[piece].png")
		dat += "<a href='?src=\ref[src];s_piece=[piece]' style='[piece_link_style]'><img src='[url]' width='32' height='32' style='[board_image_style]'></a>"
	return dat

/obj/item/game_kit/proc/open_ui(mob/user)
	if(!user || !user.client)
		return
	send_chess_assets(user)
	for(var/datum/browser/B in viewers_list)
		if(B.user == user)
			B.set_content(build_html(user))
			B.open()
			return

	var/datum/browser/B = new(user, "game_kit", "Gaming Kit", 600, 748, src)
	B.set_content(build_html(user))
	B.open()
	viewers_list += B

/obj/item/game_kit/proc/close_ui(mob/user)
	for(var/i = 1 to length(viewers_list))
		var/datum/browser/B = viewers_list[i]
		if(B.user == user)
			if(B.open())
				B.close()
			viewers_list[i] = null
	viewers_list -= null

/obj/item/game_kit/proc/update_viewers()
	var/list/to_remove = list()
	for(var/datum/browser/B in viewers_list)
		if(!B || !B.user)
			to_remove += B
			continue
		B.set_content(build_html(B.user))
		B.open()
	viewers_list -= to_remove

/obj/item/game_kit/proc/splice_board(text, pos, insert)
	if(pos <= 1)
		return "[insert][copytext(text, 3)]"
	else if(pos >= length(text) - 1)
		return "[copytext(text, 1, pos)][insert]"
	else
		return "[copytext(text, 1, pos)][insert][copytext(text, pos + 2)]"

/obj/item/game_kit/attack_hand(mob/living/user, unused, flag)
	if(flag)
		return ..()
	return ..()

/obj/item/game_kit/attack_hand_secondary(mob/living/user, list/modifiers)
	if(!user)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	open_ui(user)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/item/game_kit/Topic(href, href_list)
	..()
	if(!usr.contents.Find(src) && !in_range(src, usr))
		return
	if(href_list["s_piece"])
		src.selected = href_list["s_piece"]
	else if(href_list["mode"])
		src.selected = (href_list["mode"] == "remove") ? "remove" : null
	else if(href_list["s_board"])
		var/tx = text2num(copytext(href_list["s_board"], 1, 2))
		var/ty = text2num(copytext(href_list["s_board"], 3, 4))
		var/place = ((ty - 1) * 8 + tx) * 2 - 1
		if(src.selected)
			if(src.selected == "remove")
				src.board_stat = splice_board(src.board_stat, place, "BB")
			else if(length(src.selected) == 2)
				src.board_stat = splice_board(src.board_stat, place, src.selected)
			src.selected = null
		else
			src.selected = copytext(src.board_stat, place, place + 2)
			src.board_stat = splice_board(src.board_stat, place, "BB")
	update_viewers()
