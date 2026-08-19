// RMH Town locks
/obj/effect/mapping_helpers/access/keyset/rmh_town
	color = "#4f9fc4"
	difficulty = 4

/obj/effect/mapping_helpers/access/keyset/rmh_town/bakery
	accesses = list(ACCESS_FARM) //Пока взят доступ фермы, т.к. нету дефайнов под RMH

/obj/effect/mapping_helpers/access/keyset/rmh_town/townmouth
	accesses = list(ACCESS_LOUDMOUTH)

/obj/effect/mapping_helpers/access/keyset/rmh_outsider
	color = "#205ee6"
	difficulty = 5

/obj/effect/mapping_helpers/access/keyset/rmh_outsider/witch
	accesses = list(ACCESS_WITCH)

/obj/effect/mapping_helpers/access/keyset/bandit
	name = "bandit access helper"
	color = "#3b302b"
	difficulty = 4
	accesses = list(ACCESS_BANDIT)



