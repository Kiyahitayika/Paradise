/obj/machinery/optable
	name = "Operating Table"
	desc = "Used for advanced medical procedures."
	icon = 'icons/obj/surgery.dmi'
	icon_state = "table2-idle"
	density = 1
	anchored = 1.0
	use_power = IDLE_POWER_USE
	idle_power_usage = 1
	active_power_usage = 5
	var/mob/living/carbon/human/patient
	var/obj/machinery/computer/operating/computer
	buckle_lying = -1
	var/no_icon_updates = FALSE //set this to TRUE if you don't want the icons ever changing
	var/list/injected_reagents = list()
	var/reagent_target_amount = 1
	var/inject_amount = 1

/obj/machinery/optable/New()
	..()
	for(dir in list(NORTH,EAST,SOUTH,WEST))
		computer = locate(/obj/machinery/computer/operating, get_step(src, dir))
		if(computer)
			computer.table = src
			break

/obj/machinery/optable/Destroy()
	if(computer)
		computer.table = null
		computer = null
	if(patient)
		patient = null
	return ..()

/obj/machinery/optable/attack_hulk(mob/living/carbon/human/user, does_attack_animation = FALSE)
	if(user.a_intent == INTENT_HARM)
		..(user, TRUE)
		visible_message("<span class='warning'>[user] destroys the operating table!</span>")
		qdel(src)
		return TRUE

/obj/machinery/optable/CanPass(atom/movable/mover, turf/target, height=0)
	if(height==0)
		return TRUE
	if(istype(mover) && mover.checkpass(PASSTABLE))
		return TRUE
	else
		return FALSE


/obj/machinery/optable/MouseDrop_T(atom/movable/O, mob/user)
	if(!ishuman(user) && !isrobot(user)) //Only Humanoids and Cyborgs can put things on this table
		return
	if(!check_table()) //Is the Operating Table empty?
		return
	if(user.restrained() || user.buckled || user.IsWeakened() || user.stunned || user.incapacitated()) //Is the person trying to use the table incapacitated or restrained?
		return
	if(!ishuman(O)) //Only Humanoids can go on this table
		return
	if(isanimal(O) || isrobot(O)) //Animals and Cyborgs do not go on the table
		return
	var/mob/living/L = O
	take_patient(L, user)
	return

/obj/machinery/optable/proc/check_patient()
	if(locate(/mob/living/carbon/human, loc))
		var/mob/living/carbon/human/M = locate(/mob/living/carbon/human, loc)
		if(M.lying)
			patient = M
			if(!no_icon_updates)
				icon_state = M.pulse ? "table2-active" : "table2-idle"
			return TRUE
	patient = null
	if(!no_icon_updates)
		icon_state = "table2-idle"
	return FALSE

/obj/machinery/optable/Crossed(atom/movable/AM, oldloc)
	. = ..()
	if(iscarbon(AM) && LAZYLEN(injected_reagents))
		to_chat(AM, "<span class='danger'>You feel a series of tiny pricks!</span>")

/obj/machinery/optable/process()
	check_patient()
	if(LAZYLEN(injected_reagents))
		for(var/mob/living/carbon/C in get_turf(src))
			var/datum/reagents/R = C.reagents
			for(var/chemical in injected_reagents)
				R.check_and_add(chemical,reagent_target_amount,inject_amount)

/obj/machinery/optable/proc/take_patient(mob/living/carbon/C, mob/living/carbon/user)
	if(C == user)
		user.visible_message("[user] climbs on the operating table.","You climb on the operating table.")
	else
		visible_message("<span class='alert'>[C] has been laid on the operating table by [user].</span>")
	C.resting = TRUE
	C.update_canmove()
	C.forceMove(loc)
	if(user.pulling == C)
		user.stop_pulling()
	if(C.s_active) //Close the container opened
		C.s_active.close(C)
	for(var/obj/O in src)
		O.loc = src.loc
	add_fingerprint(user)
	if(ishuman(C))
		var/mob/living/carbon/human/H = C
		patient = H
		if(!no_icon_updates)
			icon_state = H.pulse ? "table2-active" : "table2-idle"
	else
		if(!no_icon_updates)
			icon_state = "table2-idle"

/obj/machinery/optable/verb/climb_on()
	set name = "Climb On Table"
	set category = "Object"
	set src in oview(1)
	if(usr.stat || !ishuman(usr) || usr.restrained() || !check_table())
		return
	take_patient(usr, usr)

/obj/machinery/optable/attackby(obj/item/I, mob/living/carbon/user, params)
	if(istype(I, /obj/item/grab))
		var/obj/item/grab/G = I
		if(iscarbon(G.affecting))
			take_patient(G.affecting, user)
			qdel(G)
	else
		return ..()

/obj/machinery/optable/wrench_act(mob/user, obj/item/I)
	. = TRUE
	if(!I.tool_start_check(src, user, 0))
		return
	if(I.use_tool(src, user, 20, volume = I.tool_volume))
		to_chat(user, "<span class='notice'>You deconstruct the table.</span>")
		new /obj/item/stack/sheet/plasteel(loc, 5)
		qdel(src)

/obj/machinery/optable/proc/check_table()
	if(check_patient() && patient.lying)
		to_chat(usr, "<span class='notice'>The table is already occupied!</span>")
		return FALSE
	else
		return TRUE
