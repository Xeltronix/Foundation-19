//Ported from NebulaSS13
GLOBAL_LIST_EMPTY(floating_chat_colors)

/proc/remove_images_from_clients(image/I, list/show_to)
	for(var/client/C in show_to)
		C.images -= I
		qdel(I)

/atom/movable
	var/list/stored_chat_text

/atom/movable/proc/animate_chat(message, datum/language/language, small, list/show_to, duration)
	set waitfor = FALSE

	var/style	//additional style params for the message
	var/fontsize = 6
	if(small)
		fontsize = 6
	var/limit = 50
	if(copytext_char(message, length_char(message) - 1) == "!!")
		fontsize = 8
		limit = 30
		style += "font-weight: bold;"

	if(length_char(message) > limit)
		message = "[copytext_char(message, 1, limit)]..."

	if(!GLOB.floating_chat_colors[name])
		GLOB.floating_chat_colors[name] = get_random_colour(0, 160, 230)
	style += "color: [GLOB.floating_chat_colors[name]];"

	// create 2 messages, one that appears if you know the language, and one that appears when you don't know the language
	var/image/understood = generate_floating_text(src, capitalize(message), style, fontsize, duration, show_to)
	var/image/gibberish = language ? generate_floating_text(src, language.scramble(message), style, fontsize, duration, show_to) : understood

	for(var/client/C in show_to)
		if(!C.mob.is_deaf() && C.get_preference_value(/datum/client_preference/floating_messages) == GLOB.PREF_SHOW)
			if(C.mob.say_understands(null, language))
				C.images += understood
			else
				C.images += gibberish

/proc/generate_floating_text(atom/movable/holder, message, style, size, duration, show_to)
	var/image/I = image(null, holder)
	I.layer = FLY_LAYER
	I.alpha = 0
	I.maptext_width = 80
	I.maptext_height = 64
	I.appearance_flags = APPEARANCE_UI_IGNORE_ALPHA
	I.plane = EFFECTS_ABOVE_LIGHTING_PLANE
	I.pixel_x = -round(I.maptext_width / 2) + 16

	style = "font-family: 'Small Fonts'; -dm-text-outline: 1 black; font-size: [size]px; [style]"
	I.maptext = "<center><span style=\"[style]\">[message]</span></center>"
	animate(I, 1, alpha = 255, pixel_y = 16)

	for(var/image/old in holder.stored_chat_text)
		animate(old, 2, pixel_y = old.pixel_y + 8)
	LAZYADD(holder.stored_chat_text, I)

	addtimer(CALLBACK(GLOBAL_PROC, .proc/remove_floating_text, holder, I), duration)
	addtimer(CALLBACK(GLOBAL_PROC, .proc/remove_images_from_clients, I, show_to), duration + 2)

	return I

/proc/remove_floating_text(atom/movable/holder, image/I)
	animate(I, 2, pixel_y = I.pixel_y + 10, alpha = 0)
	LAZYREMOVE(holder.stored_chat_text, I)