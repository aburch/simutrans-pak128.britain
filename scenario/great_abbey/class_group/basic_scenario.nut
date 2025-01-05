/*
 *  class: basic_scenario
 *
 *  by: ny911
 *  Can NOT be used in network game !
 */


/* DESCRIPTION OF THE CLASS

citynames can be translated use [language].tab

END OF DESCRIPTION */

// ### STILL TODO

class basic_scenario extends basic_class
{
         // privat values
	scenario_list   = []		// list of target objects for scenario

         constructor(player,cash)
         {
		if (persistent.map_info.len() == 0)
		{
			persistent.map_info.startcash <- cash
			this.set_bank_account(player,cash)
		}
		persistent.map_info.citizen     <- world.get_citizens()[0]
		persistent.map_info.factories   <- world.get_factories()[0]
		persistent.map_info.towns       <- world.get_towns()[0]
		persistent.map_info.attractions <- this.get_amount_of_attractions()
 		persistent.map_info.mapsize     <- integer_to_string(this.get_max_x()) + " x " + integer_to_string(this.get_max_y())
		base.constructor()
         }


	function set_bank_account(player,cash)
	{
                 if (cash != 0)
		{
			local value = (cash * 1000000) - player_x(player).get_cash()[0]
			local max = 10 * 1000000
			while (value > max)    // add maximum 10 million on each turn
			{
				player_x(player).book_cash( max * 100 )
				value = value - max
			}
			player_x(player).book_cash( (value * 100).tointeger() )
		}
	}


	function get_amount_of_attractions()
	{
		local count = 0
		local list  = world.get_attraction_list()
		foreach(att in list) count++
		return count
	}


	function map_info(player,modi)
	{
		local text = ttext("<em>date:</em> {date}<br><em>money:</em> {startcash}<br><em>inhabitants:</em> {citizen}<br><em>cities:</em> {towns}<br><em>factories:</em> {factories}<br><em>attractions:</em> {attractions}<br><em>map size:</em> {mapsize}<br>")
		switch(modi)
		{
			case "start" :
			{
				local info = persistent.map_info
				text.date	 = time_str( settings.get_start_time() )
				text.citizen     = integer_to_string(info.citizen)
				text.startcash   = money_to_string( (info.startcash * 1000000).tointeger() )
				text.factories   = integer_to_string(info.factories)
				text.towns       = integer_to_string(info.towns)
				text.attractions = integer_to_string(info.attractions)
				text.mapsize	 = info.mapsize
				break
			}
			case "now" :
			{
				text.date        = time_str( world.get_time() )
				text.citizen     = integer_to_string(world.get_citizens()[0])
				text.startcash   = money_to_string(player_x(player).get_cash()[0])
				text.factories   = integer_to_string(world.get_factories()[0])
				text.towns       = integer_to_string(world.get_towns()[0])
				text.attractions = integer_to_string(this.get_amount_of_attractions())
				text.mapsize	 = integer_to_string(this.get_max_x()) + " x " + integer_to_string(this.get_max_y())
				break
			}
		}
		return "<br>"+text.tostring()+"<br>"
	}


	function city_list(show,year_or_month)
	{
// ### citzens, growth, buildings, cars, trips, passangers, sent_mail, mail, arrived, goods
		local text = ""
		local citynr = 0
		local cities = [": "]
		foreach (city in city_list_x() )
		{
// ###			citynr = city.get_pos().x * max_x + city.get_pos().y
			local growth = city.get_growth().reduce(sum)
			local cityname = ttext( city.get_name() )
		//	local count = 0
		//	if (citynr in persistent.citylist)
		//  	count = persistent.citylist.rawget(citynr)
// ### translate and rotation
			cities.append( cityname + ":" + " "
				+ "<a href=\"(" + city.get_pos().x + "," + city.get_pos().y + ")\">" + cityname + "</a>"
				+ " (" + (growth > 0? "+"+growth:" <st>"+growth+"</st>") + " ) "
				+ " citylimits ("+city.get_pos_nw().x+","+city.get_pos_nw().y+" - "+city.get_pos_se().x+","+city.get_pos_se().y+")"
				+ "<br>")
		}
		cities.sort()                              			//  sort the list
		foreach (row in cities) text+= row.slice(row.find(":")+1)	//  array to string
		return text
	}


	function add_to_scenario(scenario_object)
	{
                 scenario_list.append(scenario_object)
         }


	function get_result_list(player,show_weight)
	{
                 local text = ""
		local s = " " + this.my_space + " "
		local count = 0
		foreach (target in scenario_list)
			if (target.player == player)
			{
                                 local prz = target.is_completed()
			 	text+= s + "<em>·</em> "
				if (show_weight)
				{
					text+= "<em>"+this.leading_zero(target.weight,3)+"</em>"+s
					count+= target.weight
				}
				text+= target.get_result_text()
				text+= s + s + (prz<100 ? "<st>"+prz+"%</st>":prz+"%") + "<br>"
			}
		if (show_weight)
		{
                         local text2 = ttext( "<br>total of all weights : <em>{total_weight}</em><br>" )
			text2.total_weight = this.leading_zero(count,3).tostring()
			text+= text2.tostring()
		}
		return text
         }


	function is_scenario_completed(player)
	{
// ### check other players too
		local percentage = 0
		local weight = 0
		foreach (target in scenario_list)
			if (target.player == player)
			{
                                 percentage= percentage + (target.is_completed() * target.weight)
				weight = weight + target.weight
			}
		if (weight == 0) weight = 1
		percentage = (percentage / weight).tointeger()
	        if ( percentage >= 100 )      			// scenario complete
		{
			local text = ttext("Scenario complete.")
			gui.add_message( text.tostring() )
		}
	         return percentage
	}


	function is_work_allowed_here(player, tool_id, pos)
	{
		local result = null       // null = true
		foreach (target in scenario_list)
			if (target.player == player)
			{
				result = target.is_work_allowed_here(player, tool_id, pos)
				if (result != null) return result          // just for fast exit
			}
	        return result
	}


	function is_schedule_allowed(player, schedule)
	{
		local result = null       // null = true
		foreach (target in scenario_list)
			if (target.player == player)
			{
				result = target.is_schedule_allowed(player, schedule)
				if (result != null) return result          // just for fast exit
			}
	        return result
	}


	function get_max_x()
	{
		local i = 8092
		local e = i / 2
		while (e >= 1)
		{
			if ( world.is_coord_valid({x = i, y = 0}) )
			     i = i + e
			else i = i - e
			if (e == 1)
			     e = 0
		  	else e = round_up(e,2)
		}
		if (! world.is_coord_valid( {x = i, y = 0} ) ) i = i -1
		return i+1
	}


	function get_max_y()
	{
		local i = 8092
		local e = i / 2
		while (e >= 1)
		{
			if ( world.is_coord_valid({x = 0, y = i}) )
			     i = i + e
			else i = i - e
			if (e == 1)
			     e = 0
		  	else e = round_up(e,2)
		}
		if (! world.is_coord_valid( {x = 0, y = i} ) ) i = i -1
		return i+1
	}


	function translate_all_city_names()
	{
		foreach ( city in city_list_x() )
		{
			local name = translate( city.get_name() )
			if (name != "") city.set_name( name )
		}
	}


	function translate_all_factory_names()
	{
		foreach ( factory in factory_list_x() )
		{
			local name = translate( factory.get_name() )
			if (name != "") factory.set_name( name )
		}
	}


	function forbid_tools(player, list)
	{
		this.set_tools(player, list, false)
	}


	function allow_tools(player, list)
	{
		this.set_tools(player, list, true)
	}


	function set_tools(player, list, what)
	{
/* example of the list
forbid_tools_array <-{					// array of forbid_tools
	area = {					// protect abbey area
		waytyp= wt_all,
		tool  = [
			{ id = tool_build_station,	error = "no stations in heritage conservation area" },
			{ id = tool_remover, 		error = "no remove in heritage conservation area" },
			{ id = tool_remove_way,		error = "no works in heritage conservation area" }
			],
		list  = [                               // allowed types: coord3d or coord
			{ nw = {x = 213, y = 237, z = 0}, se = {x = 230, y = 257, z = -8} },
			{ nw = {x = 212, y = 244, z = 8}, se = {x = 212, y = 257, z = -8} },
			{ nw = {x = 212, y = 244},        se = {x = 212, y = 257} }
			]
		}
	}
end of example list */
                 if (player == 1) return 			// don't set player "puplic service"
		local pos
		local tool
		local flag = 0
		foreach (j in list)
		{
        			for (local i=0; i < j.tool.len(); i++)
			{
                                 tool = j.tool[i]
				for (local e=0; e < j.list.len(); e++)
				{
                                         pos = j.list[e]
					try { pos.nw.z }	// make difference between rect and cube
					catch(error)
					{
						if (what == false)
							rules.forbid_way_tool_rect(player, tool.id, j.waytyp, "", pos.nw, pos.se, ttext(tool.error) )
						else	rules.allow_way_tool_rect(player, tool.id, j.waytyp, "", pos.nw, pos.se )
						flag = 1
					}
					if (flag == 0)
						if (what == false)
                         				rules.forbid_way_tool_cube(player, tool.id, j.waytyp, "", pos.nw, pos.se, ttext(tool.error) )
                         			else 	rules.allow_way_tool_cube(player, tool.id, j.waytyp, "", pos.nw, pos.se )
					flag = 0
                     		}
               		}
		}
	}	// end of forbid_tools



	function get_target_text()
	{
		local text = ""
		foreach ( point in scenario_list)
			text+= "<em>·</em> "+point.get_target_text()+"<br>"
		return text
	}

}

// END OF FILE
