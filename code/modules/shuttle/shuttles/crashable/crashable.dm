/obj/docking_port/mobile/crashable
	name = "crashable shuttle"

	/// Whether or not this shuttle is crash landing
	var/crash_land = FALSE
	/// Whether fires occur aboard the shuttle when crashing
	var/fires_on_crash = FALSE

/obj/docking_port/mobile/crashable/enterTransit()
	. = ..()

	if(!crash_land)
		return

	for(var/area/shuttle_area in shuttle_areas)
		shuttle_area.flags_alarm_state |= ALARM_WARNING_FIRE
		shuttle_area.updateicon()
		for(var/mob/evac_mob in shuttle_area)
			if(evac_mob.client)
				playsound_client(evac_mob.client, 'sound/effects/bomb_fall.ogg', vol = 50)

	for(var/turf/found_turf as anything in destination.return_turfs())
		if(istype(found_turf, /turf/closed))
			found_turf.ChangeTurf(/turf/open/floor)

	for(var/mob/current_mob as anything in get_mobs_in_z_level_range(destination.return_center_turf(), 18))
		var/relative_dir = get_dir(current_mob, destination.return_center_turf())
		var/final_dir = dir2text(relative_dir)
		to_chat(current_mob, SPAN_HIGHDANGER("You hear something crashing down from above [final_dir ? "to the [final_dir]" : "nearby"]!"))

	if(fires_on_crash)
		handle_fires()

	//cell_explosion(destination.return_center_turf(), length(destination.return_turfs()) * 15, 25, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, create_cause_data("evac pod crash")) - Remove this - Morrow
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cell_explosion), destination.return_center_turf(), length(destination.return_turfs()) * 5, 25, EXPLOSION_FALLOFF_SHAPE_LINEAR, null, create_cause_data("crashing shuttle")), 1.5 SECONDS)

/obj/docking_port/mobile/crashable/on_prearrival()
	. = ..()

	if(!crash_land)
		return

	movement_force = list("KNOCKDOWN" = 0, "THROW" = 5)

	for(var/area/shuttle_area in shuttle_areas)
		for(var/mob/evac_mob in shuttle_area)
			shake_camera(evac_mob, 20, 2)
			if(evac_mob.client)
				playsound_client(evac_mob.client, get_sfx("bigboom"), vol = 50)

/obj/docking_port/mobile/crashable/proc/evac_launch()
	if(!crash_check())
		return

	create_crash_point()

/obj/docking_port/mobile/crashable/proc/crash_check()
	return FALSE

/obj/docking_port/mobile/crashable/proc/create_crash_point()
	for(var/i = 1 to 10)
		var/list/all_ground_levels = SSmapping.levels_by_trait(ZTRAIT_GROUND)
		var/ground_z_level = all_ground_levels[1]

		var/list/area/potential_areas = SSmapping.areas_in_z["[ground_z_level]"]

		var/area/area_picked = pick(potential_areas)

		var/list/potential_turfs = list()

		for(var/turf/turf_in_area in area_picked)
			potential_turfs += turf_in_area

		if(!length(potential_turfs))
			continue

		var/turf/turf_picked = pick(potential_turfs)

		var/obj/docking_port/stationary/crashable/temp_escape_pod_port = new(turf_picked)
		temp_escape_pod_port.width = width
		temp_escape_pod_port.height = height
		temp_escape_pod_port.id = id

		if(!check_crash_point(temp_escape_pod_port))
			qdel(temp_escape_pod_port)
			continue

		destination = temp_escape_pod_port
		break

	if(destination)
		crash_land = TRUE

/// Checks for anything that may get in the way of a crash, returns FALSE if there is something in the way or is out of bounds
/obj/docking_port/mobile/crashable/proc/check_crash_point(obj/docking_port/stationary/crashable/checked_escape_pod_port)
	for(var/turf/found_turf as anything in checked_escape_pod_port.return_turfs())
		var/area/found_area = get_area(found_turf)
		if(found_area.flags_area & AREA_NOTUNNEL)
			return FALSE

		if(!found_area.can_build_special)
			return FALSE

		if(istype(found_turf, /turf/closed/wall))
			var/turf/closed/wall/found_closed_turf = found_turf
			if(found_closed_turf.hull)
				return FALSE

		if(istype(found_turf, /turf/closed/shuttle))
			return FALSE

	return TRUE

/// Forces the shuttle to crash, admin called
/obj/docking_port/mobile/crashable/proc/force_crash()
	create_crash_point()
	set_mode(SHUTTLE_IGNITING)
	on_ignition()
	setTimer(ignitionTime)

/// Sets up and handles fires/explosions on crashing shuttles
/obj/docking_port/mobile/crashable/proc/handle_fires()
	for(var/i = 1 to (length(destination.return_turfs()) / 25))
		var/turf/position = pick(destination.return_turfs())
		new /obj/effect/warning/explosive(position, 3 SECONDS)
		playsound(src, 'sound/effects/pipe_hissing.ogg', vol = 40)
		addtimer(CALLBACK(src, PROC_REF(kablooie), position), 3 SECONDS)

/// Actually blows up the fire/explosion on crashing shuttles, used for effect delay
/obj/docking_port/mobile/crashable/proc/kablooie(turf/position)
	var/new_cause_data = create_cause_data("crashing shuttle fire")
	var/list/exploding_types = list(/obj/item/explosive/grenade/high_explosive/bursting_pipe, /obj/item/explosive/grenade/incendiary/bursting_pipe)
	for(var/path in exploding_types)
		var/obj/item/explosive/grenade/exploder = new path(get_turf(src))
		exploder.cause_data = new_cause_data
		exploder.prime()

/// Handles opening the doors for the specific shuttle type upon arriving at the crash point
/obj/docking_port/mobile/crashable/proc/open_doors()
	return

/obj/docking_port/stationary/crashable
	name = "Crash Escape Pod Dock"

/obj/docking_port/stationary/crashable/on_arrival(obj/docking_port/mobile/arriving_shuttle)
	. = ..()

	if(istype(arriving_shuttle, /obj/docking_port/mobile/crashable))
		var/obj/docking_port/mobile/crashable/crashing_shuttle = arriving_shuttle
		crashing_shuttle.open_doors()

	for(var/area/shuttle_area in arriving_shuttle.shuttle_areas)
		shuttle_area.remove_base_lighting()

		shuttle_area.flags_alarm_state &= ~ALARM_WARNING_FIRE
		shuttle_area.updateicon()

