/*
 *  class: target_class
 *
 *  by: ny911
 *  Can NOT be used in network game !
 */


/* DESCRIPTION OF THE CLASS

         constructor(player, weight)
	function is_completed()					[return: integer]	// percentage 0 to 100
	function get_result_text()                              [return: string]
	function get_target_text()                              [return: string]
	function is_work_allowed_here(player, tool_id, pos)     [return: null or error_string]
	function is_schedule_allowed(player, schedule)          [return: null or error_string]
	function is_label_set( pos, value )			[return: bool]

END OF DESCRIPTION */


// master object for scenario_goals
// if needed, use : "base.[functionname]([parameters])" in child class


class target_class extends basic_class
{
         weight = 1				// weight of this scenario target must be minimum 1
	player = 0				// save player


         constructor(player, weight)		// extend later also for rules
         {
		base.constructor()
		this.player = player
		this.weight = weight
	}


	function is_completed()
	{
		local percentage = 0		// result allowed from 0 to 100
		return percentage
	}


	function get_result_text()
	{
                 return translate("Your result text")
	}


	function get_target_text()
	{
                 return translate("Target text of class")
	}


	function is_work_allowed_here(player, tool_id, pos)
	{
	        return null     // null = true
	}


	function is_schedule_allowed(player, schedule)
	{
		return null     // null = true
	}


	function is_label_set( pos, value )		// did a label/ding object have this value
	{
		local obj = square_x( pos.x, pos.y ).get_ground_tile().find_object( mo_label )
		if ( obj == null ) return false
// ### no ding value check possible in API 112.3  -> so return true
		return true
//		obj.get_name()  or  obj.get_value()
//		if ( obj.get_value() != value ) return false
	}

}

// END OF FILE