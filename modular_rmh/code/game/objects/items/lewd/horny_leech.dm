// описание идеи.
// Хорни пиявка
// В игре она рандомно присасывается к персонажам с трейтом красивый и flaw, монстр сиикер?
//  При присасывании:
// -  К груди, впрыскивает хорни препараты(пока что просто увеличивает показатели), затем включает лактацию и делает
// парням 1 размер, а девушкам на 2 размера больше.
// - К паху, впрыскивает много препарата(постоянно поддерживает показатели, для оргазма), начиная работать как дилдо
// или мастурбатор


/obj/item/natural/worms/horny_leech
	name = "Strange leech"
	desc = "A disgusting, blood-sucking parasite. But something is strange. Maybe its color or smell..."
	//icon = 'modular_rmh/icons/obj/lewd/horny_leech.dmi'
	//icon_state = "h_leech"
	icon = 'icons/roguetown/items/surgery.dmi'
	icon_state = "leech"
	baitpenalty = 0
	isbait = TRUE//потом вписать вероятность поимки той или иной рыбы
	bundletype = null

	var/fluid_sucking = 5
	var/fluid_storage = 0
	var/max_storage = 100
	var/completely_silent = FALSE
	embedding = list(
		"embed_chance" = 100,
		"embedded_unsafe_removal_time" = 0,
		"embedded_pain_chance" = 0,
		"embedded_fall_chance" = 0,
		"embedded_bloodloss"= 0,
		"embedded_ignore_throwspeed_threshold" = TRUE,
	)
	var/target_organ = null

//инициализация
//описание
//Атака на грудь, пах
/obj/item/natural/worms/horny_leech/attack(mob/living/M, mob/user)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		var/obj/item/bodypart/selected_organ = H.get_bodypart(check_zone(user.zone_selected))
		if(!selected_organ)
			return
		if(!get_location_accessible(H, check_zone(user.zone_selected)))
			to_chat(user, "<span class='warning'>Something in the way.</span>") //ooooooooooooooo
			return
		var/used_time
		if(completely_silent)
			used_time = 0
		else
			used_time = (7 SECONDS - (H.get_skill_level(/datum/skill/misc/medicine) * 1 SECONDS))/2
		if(!do_after(user, used_time, H))
			return
		if(!H)
			return
		if(!(user.zone_selected in list(BODY_ZONE_CHEST, BODY_ZONE_PRECISE_GROIN)))
			to_chat(user, "The leech crawls over the body and then falls off. Apparently, it's looking for more intimate parts of the body.")
			return

		switch(user.zone_selected)
			if(BODY_ZONE_CHEST)
				target_organ = "breasts"
				to_chat(user, "The leech begins to crawl towards the area of ​​interest and opens its soft mouth...")
			if(BODY_ZONE_PRECISE_GROIN)
				var/organ_choice = browser_input_list(user, "Select the organ to which you will attach the leech.", list("Vagina", "Penis"))
				if(organ_choice == "Vagina")
					target_organ = "vagina"
					to_chat(user, "The leech begins to crawl towards the vagina and opens its soft mouth...")
				if(organ_choice == "Penis")
					target_organ = "penis"
					to_chat(user, "The leech opens its mouth wide and swallows the penis, starting to squeeze it...")

		user.dropItemToGround(src)
		src.forceMove(H)
		selected_organ.add_embedded_object(src, silent = TRUE, crit_message = FALSE)
		//selected_organ.add_embedded_object(src, silent = TRUE, crit_message = FALSE)
		if(M == user)
			user.visible_message("<span class='notice'>[user] places [src] on [user.p_their()] [selected_organ].</span>", "<span class='notice'>I place a leech on my [selected_organ].</span>")
		else
			user.visible_message("<span class='notice'>[user] places [src] on [M]'s [selected_organ].</span>", "<span class='notice'>I place a leech on [M]'s [selected_organ].</span>")
		return
	return ..()

/obj/item/natural/worms/horny_leech/on_embed_life(mob/living/user, obj/item/bodypart/bodypart)
	if(!user)
		return

	var/mob/living/carbon/human/H = user

	//var/milk_to_take = min(max_storage - fluid_storage, breasts.reagents.total_volume, fluid_sucking)
	switch(target_organ)
		if("breasts")

			var/obj/item/organ/genitals/filling_organ/breasts/breasts = H.getorganslot(ORGAN_SLOT_BREASTS)
			//есть нет груди, добавляем и пишем об этом
			if(!breasts)
				breasts.Insert(H)
				to_chat(user, "You feel your breasts getting bigger and becoming more sensitive.")
			if(!H.breast_milk)//проверяем наличие молока в груди
				H.set_milk(initial(H.breast_milk))
				H.breasts.add_reagent(/datum/reagent/consumable/milk, 20)
				to_chat(user, "Your nipples start to itch and you feel wetness on your clothes.")
			//сам процесс доения и переливания молока
			var/milk_to_take = min(max_storage - fluid_storage, breasts.reagents.total_volume, fluid_sucking)
			breasts.reagents.trans_to(src, milk_to_take)
			fluid_storage += milk_to_take

			if(fluid_storage >= max_storage)
				bodypart.remove_embedded_object(src)
				return TRUE
			if(prob(25))
				to_chat(H, span_warning("You feel the leech squeezing your nipple, injecting a stream of milk into itself."))
			return FALSE
		if("penis")
			var/obj/item/organ/genitals/penis/penis = H.getorganslot(ORGAN_SLOT_PENIS)
			var/obj/item/organ/genitals/filling_organ/testicles/testicles = H.getorganslot(ORGAN_SLOT_TESTICLES)

			if(!penis)
				bodypart.remove_embedded_object(src)
				return TRUE
			var/chosen_verb = pick(list("A leech is sucking my penis!", "ver2", "ver3", "ver 4"))// варианты того как пиявка сжимается и сосет
			if(testicles)
				var/milk_to_take = min(max_storage - fluid_storage, testicles.reagents.total_volume, fluid_sucking)
				testicles.reagents.trans_to(src, milk_to_take)
				fluid_storage += milk_to_take
			if(fluid_storage >= max_storage)
				bodypart.remove_embedded_object(src)
				return TRUE
			return FALSE
		if("vagina")
				//переделываем. Выводится с каждым циклом сообщение как от ерп итеракта. А с рандомным шансом прокает оргазм.
				// надо понять как выводить в чат еро комент
				// Как работает тут оргазм
			var/obj/item/organ/genitals/filling_organ/vagina/vagina = H.getorganslot(ORGAN_SLOT_VAGINA)
			if(!vagina)
				bodypart.remove_embedded_object(src)
				return TRUE
			var/chosen_verb = pick(list("A leech is sucking my vagina!", "ver2", "ver3", "ver 4"))//варианты как извивается в киске и тд
			var/milk_to_take = min(max_storage - fluid_storage, vagina.reagents.total_volume, fluid_sucking)
			vagina.reagents.trans_to(src, milk_to_take)
			fluid_storage += milk_to_take
			if(fluid_storage >= max_storage)
				bodypart.remove_embedded_object(src)
				return TRUE
			return FALSE
