/*
 *  class: target_hq
 *
 *  by: ny911
 *  Can NOT be used in network game !
 */


// HERE SHORT FUNCTION LIST OF ALL CLASSES


class target_hq extends target_class
{
	until_level = 0					// set to target level, minimum 1 or 0=use_max_at_time of pakset
         area = { nw=coord3d, se=coord3d }		// to be filled up with area

         constructor(player, weight, until_level, area )
         {
		this.until_level = until_level
                 this.area = { nw={x=0, y=0, z=0}, se={x=0, y=0, z=0} }	// must be setup here to zero !!!
		if ( area.se.x > 0  &&  area.se.y > 0 )
			this.area = area
		base.constructor(player, weight)
	}


	function is_completed()
	{
		local percentage = 0
		local result = this.get_hq_level()
		local level = this.until_level
		if (level < 1)					// catch all lower 1
			level = this.get_max_hq_level_at_time( world.get_time() ) + 1
		percentage = min( (result / level ) * 100, 100)
		return percentage
	}


	function get_result_text()
	{
                 local hq_level = this.get_hq_level()		// get the hq_level
		local text = ""
		if (hq_level == 0)
			text = translate("You did not build a headquarter yet.")
		if (hq_level == 1)
			text = translate("You build a small headquarter.")
		if (hq_level > 1 && hq_level < this.until_level - 1)
			text = translate("You build a medium size headquarter.")
		if (hq_level == this.until_level - 1)
			text = translate("You build the second biggest headquarter.")
		if (hq_level == this.until_level)
			text = translate("You build a luxurious headquarter.")
		return text
	}


	function get_target_text()
	{
                 local text = ""
		local help = ""
                 local area = this.area
		help = ttext("Build a headquarter of level {level}")
		help.level = this.until_level
		text+= help.tostring()
		if ( (area.se.x > 0) && (area.se.y > 0) )	// with HQ area to build
		{
			help = ttext("in the area {area}")
			help.area = this.cube_to_text( area )
			text+= " " + help.tostring()
		}
	 	return text
	}


	function is_work_allowed_here(player, tool_id, pos)
	{
                 local area = this.area
		if ( (tool_id == tool_headquarter)     		// headquarter only inside area if
                      && (area.se.x > 0) && (area.se.y > 0) ) 	// zero x,y area means = don't check area
		{
// ### Abfrage size stimmt nicht, da nicht bekannt welches hq gebaut wird ? oder?
	         	local building_list = building_desc_x.get_building_list( building_desc_x.headquarter )
// ###		local size = {x=3,y=3}				// size of hq (3x3)
// ### welche rotation ?
			local size = building_list[0].get_size(0)	// parameter = rotation
		    	if ( pos.x < area.nw.x || area.se.x < pos.x + size.x - 1 ||
			     pos.y < area.nw.y || area.se.y < pos.y + size.y - 1 ||
			     pos.z < area.nw.z || area.se.z < pos.z )
			{
// ### Koordinate und rotation bei einer Textanzeige
				local result = ttext("Build your headquarter inside the area {area}")
				result.area = this.cube_to_text(area)
				return result
			}
		}
	        return null
	}


	function get_hq_level()
	{
		local level = player_x(this.player).get_headquarter_level()
		local pos = player_x(this.player).get_headquarter_pos()
		if ( !(pos.x >= 0) )
			level = 0
		return level
	}


	function get_max_hq_level_at_time(time)
	{
         	local building_list = building_desc_x.get_building_list( building_desc_x.headquarter )
		local result = 0
		foreach (building in building_list)
			if ( building.is_available(time) && (building.get_headquarter_level() > result) )
				result = building.get_headquarter_level()
		return result
		// by the way : amount of HQs is =  building_desc_x.get_building_list( building_desc_x.headquarter ).len()
	}
}

// END OF FILE