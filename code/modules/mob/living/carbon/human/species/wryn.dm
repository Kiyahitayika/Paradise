/datum/species/wryn
	name = "Wryn"
	name_plural = "Wryn"
	icobase = 'icons/mob/human_races/r_wryn.dmi'
	deform = 'icons/mob/human_races/r_wryn.dmi'
	blacklisted = TRUE
	language = "Wryn Hivemind"
	tail = "wryntail"
	punchdamagelow = 0
	punchdamagehigh = 1
	speed_mod = 1
	warning_low_pressure = -300
	hazard_low_pressure = 1
	blurb = "The wryn (r-in, singular r-in) are a humanoid race that possess many bee-like features. Originating from Alveare they \
	have adapted extremely well to cold environments though have lost most of their muscles over generations.\
	In order to communicate and work with multi-species crew Wryn were forced to take on names. Wryn have tended towards using only \
	first names, these names are generally simplistic and easy to pronounce. Wryn have rarely had to communicate using their mouths, \
	so in order to integrate with the multi-species crew they have been taught broken sol?."

	cold_level_1 = 200 //Default 260 - Lower is better
	cold_level_2 = 150 //Default 200
	cold_level_3 = 115 //Default 120

	heat_level_1 = 300 //Default 360 - Higher is better
	heat_level_2 = 310 //Default 400
	heat_level_3 = 317 //Default 1000

	body_temperature = 286

	has_organ = list(
		"heart" =    /obj/item/organ/internal/heart,
		"brain" =    /obj/item/organ/internal/brain,
		"eyes" =     /obj/item/organ/internal/eyes/wryn, //3 darksight.
		"appendix" = /obj/item/organ/internal/appendix,
		"antennae" =    /obj/item/organ/internal/wryn/hivenode
		)

	species_traits = list(LIPS, IS_WHITELISTED, NO_BREATHE, NO_SCAN, HIVEMIND)
	clothing_flags = HAS_UNDERWEAR | HAS_UNDERSHIRT | HAS_SOCKS
	bodyflags = HAS_SKIN_COLOR
	dietflags = DIET_HERB		//bees feed off nectar, so bee people feed off plants too

	dies_at_threshold = TRUE

	reagent_tag = PROCESS_ORG
	base_color = "#704300"
	flesh_color = "#704300"
	blood_color = "#FFFF99"
	//Default styles for created mobs.
	default_hair = "Antennae"

	var/datum/action/innate/wryn_sting/wryn_sting
	sting_check = FALSE

//No flying while using magboots or hardsuit - toggle on/off action

/datum/species/wryn/on_species_gain(mob/living/carbon/human/H)
    ..()
    wryn_sting = new
    wryn_sting.Grant(H)

/datum/species/wryn/on_species_loss(mob/living/carbon/human/H)
    ..()
    if(wryn_sting)
        wryn_sting.Remove(H)

/* Stinger */

//Define the Sting Action
/datum/action/innate/wryn_sting
	name = "Wryn Sting"
	desc = "Readies Wryn Sting for stinging."
	button_icon_state = "wryn_sting_off"


//What happens when you click the Button?
/datum/action/innate/wryn_sting/Trigger()
	if(..())
		UpdateButtonIcon()

//Update the Icon and run some Code
/datum/action/innate/wryn_sting/UpdateButtonIcon()
	var/mob/living/carbon/user = owner
	if(!user.dna.species.sting_check)

		button_icon_state = "wryn_sting_on"
		name = "Wryn Stinger \[READY\]"
		button.name = name
		user.visible_message("<span class='warning'> [user] prepares to use their Wryn stinger!</span>")
		to_chat(user, "<span class='notice'>You prepare your Wryn stinger, use alt+click or middle mouse button to sting your target!</span>")
		user.dna.species.sting_check = TRUE

	else

		button_icon_state = "wryn_sting_off"
		name = "Wryn Stinger"
		button.name = name
		user.visible_message("<span class='warning'[user] retracts their Wryn stinger.</span>")
		to_chat(user, "<span class='warning'>You decide you don't want to sting anyone for now and retract your Wryn stinger.</span>")
		user.dna.species.sting_check = FALSE

	..()


//What does the Action do?
/datum/species/wryn/wryn_sting(mob/living/U, mob/living/T)
	if((U.restrained() && U.pulledby) || U.buckled)
		to_chat(U, "<span class='warning'>You need freedom of movement to sting someone!</span>")
		return
	if(U.getStaminaLoss() >= 50)
		to_chat(U, "<span class='warning'>Rest before stinging again!</span>")
		return
	if(T in orange(1))
		var/obj/item/organ/external/O = T.get_organ(pick("l_leg", "r_leg", "l_foot", "r_foot", "groin"))
		U.visible_message("<span class='danger'>[U] stings [T] in [O] with their Wryn stinger! </span>", "<span class='danger'> You sting [T] in [O] with your Wryn stinger!</span>")
		U.adjustStaminaLoss(25)
		var/dam = rand(3,12)
		T.apply_damage(dam, BURN, O)
		playsound(U.loc, 'sound/weapons/sear.ogg', 50, 0)
		add_attack_logs(U, T, "Stung by Wryn Stinger - [dam] Burn damage to [O].")
		if(U.restrained())
			if(prob(50))
			U.apply_damage(2, TOX, T) //apply tiny Tox damage to Target, rather than Stun
			U.visible_message("<span class='danger'>[U] is looking a little green!</span>", "<span class='danger'>You feel a little ill!</span>")
			return
		if(U.getStaminaLoss() >= 60)
			to_chat(U, "<span class='warning'>You feel too tired to use your Wryn Stinger at the moment.</span>")

/datum/species/wryn/handle_death(gibbed, mob/living/carbon/human/H)
	for(var/mob/living/carbon/C in GLOB.alive_mob_list)
		if(C.get_int_organ(/obj/item/organ/internal/wryn/hivenode))
			to_chat(C, "<span class='danger'><B>Your antennae tingle as you are overcome with pain...</B></span>")
			to_chat(C, "<span class='danger'>It feels like part of you has died.</span>") // This is bullshit

/datum/species/wryn/harm(mob/living/carbon/human/user, mob/living/carbon/human/target, datum/martial_art/attacker_style)
	if(target.handcuffed && target.get_int_organ(/obj/item/organ/internal/wryn/hivenode))

		user.visible_message("<span class='notice'>[user] begins to violently pull off [target]'s antennae.</span>")
		to_chat(target, "<span class='danger'><B>[user] grips your antennae and starts violently pulling!<B></span>")
		if(do_mob(user, target, 250))
			var/obj/item/organ/internal/wryn/hivenode/node = new /obj/item/organ/internal/wryn/hivenode
			target.remove_language("Wryn Hivemind")
			node.remove(target)
			node.forceMove(user.loc)
			to_chat(user, "<span class='notice'>You hear a loud crunch as you mercilessly pull off [target]'s antennae.</span>")
			to_chat(target, "<span class='danger'>You hear a loud crunch as your antennae is ripped off your head by [user].</span>")
			to_chat(target, "<span class='danger'><B>It's so quiet...</B></span>")
			var/obj/item/organ/external/head/head_organ = target.get_organ("head")
			head_organ.h_style = "Bald"
			target.update_hair()

			add_attack_logs(user, target, "Antennae removed")
		return 0
	else
		..()
