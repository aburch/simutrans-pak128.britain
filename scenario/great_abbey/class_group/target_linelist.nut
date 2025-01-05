/*
 *  class: target_linelist
 *
 *  by: ny911
 *  Can NOT be used in network game !
 */


/* DESCRIPTION OF THE CLASS

	extends scenario_target

END OF DESCRIPTION */


// ### STILL TODO


class target_linelist extends target_class
{
/*
	erweitern: statt unhappy class of halt mit allen optionen
*/

/*
 array [
 	{ pos = { x=221, y=249, z=0},
	type="count_lines_over_all",
	good=0,
	way=wt_rail,
	target=3,
	minimum_halts=6,
	unhappy_time=6,
	unhappy_max=50}
       ]
 type = count_unique_halt, count_unique_halt_over_all,
	count_unique_happy_halt, count_unique_max_unhappy

		// for goods:  0=Passengers, 1=Mail, 2=None, >=3 anything else
		// type:count_over_all,count_this_line, only_unhappy

the line must be from the player of the class
unhappy_time = 0 don't care about unhappy 1-12 amount of month to make sum() of
unhappy_max in time to be allowed
target = minimum number of lines for this halt
minimum_halts = each line will need minimum this amount
good = number of good (0=passanger, 1=mail, 2=None, >=3 anything else
way = waytype
*/
	list = []				// for the target list of factory goods
	count_points = 0
	good_list = []
	result_text = ""
	result_time = -1

         constructor(player, weight, list )
         {
		this.list = list
		this.count_points = 0
		this.good_list = []
        		local listx= good_desc_list_x()
		foreach ( good in listx )
			this.good_list.append( good.name )
		this.result_text = ""
		this.result_time = -1
		base.constructor(player, weight)
	}


	function is_completed()
	{
		get_value()
		return min( (100 * this.count_points / this.list.len() ), 100)
	}


	function get_result_text()
	{
		get_value()
		return this.result_text
	}


	function make_result()
	{
		if (this.list.len() == 0) return
		local text   = ""
		local text3  = ""
		local result = []
		local linelist = null
// ### make it better, faster, ...
// ### rewerite en.tab for this class, lines are incorrect or missing
// ### missing information for : type:count_over_all,count_this_line, only_unhappy(no amount)
		local newlist = []
		local source_list = []
		local i = 0
		local myhalt = null
		local unhappy = 0
		local unhappy_text = translate("are unhappy")
		local space = this.my_space + " " + this.my_space + " " + this.my_space + " "
		local help  = ""
		local pos   = ""
		local text2 = ""
		local count = 0
		local count2= 0
		local amount= 0
		this.count_points = 0
		if ( this.is_label_set( result_view_pos, "short" ) )
			return translate("line service")
		text = translate("line service - list of lines for each target station") + "<br>"
		foreach ( myline in this.list)
		{
                         count2 = 0
			linelist = this.get_linelist(myline.pos, myline.good, myline.way)
         	        myhalt = tile_x(myline.pos.x, myline.pos.y, myline.pos.z).get_halt()
			if ( linelist.len() > 0)
			{
				text3 = ""
				for (local e = 0; e < linelist.len(); e++)
				{
		                        newlist = []
					i = 0
					foreach (line in linelist)
					{
						if (i != e) newlist.append(line)
						else source_list = line
						i++
					}
				 	newlist = this.get_unique_halts_of_all( source_list, newlist )
					text2 = ""
					amount = 0
					foreach (halt in newlist)
					{
						text2+= space + space + halt.get_name()
						unhappy = get_sum_of_first_x(halt.get_unhappy(),myline.unhappy_time)
						if (unhappy > 0)
							text2+= " (<st>" + unhappy + "</st> " + unhappy_text + ")"
						else amount++
						text2+= "<br>"
					}
					help = ttext("<em>{listname}</em> ({halt_amount} Halts, {counted} counted, {needed} needed)<br>")
					help.listname = source_list.get_name()
					help.halt_amount = newlist.len()
					help.counted     = (amount < myline.minimum_halts ? "<st>"+amount+"</st>":amount)
					help.needed      = myline.minimum_halts
					text3+= space + this.my_space + " " + help.tostring() + text2 + "<br>"
					if ( amount >= myline.minimum_halts )
						count2++
				}
			}
			else
				text3 = space + this.my_space + " " + translate("no line at this station") + "<br>"
	                help = ttext("{space}{name} with {lines} lines, {counted} counted, {needed} needed<br>{space}type={type}, target={target} lines, max_unhappy={unhappy},<br>{space}good={good}, way={way}, time={time} month, halt={halt}<br>")
			pos = this.pos_to_text( myline.pos )
			if ( linelist.len() > 0)
				help.name    = "<a href=\"" + pos + ">" + myhalt.get_name() + " " + pos + "</a>"
			else	help.name    = "<a href=\"" + pos + ">" + pos + "</a>"
			help.lines   = linelist.len()
			help.counted = ( count2 < myline.target ? "<st>"+count2+"</st>":count2 )
			help.needed  = myline.target
			help.type    = myline.type
			help.target  = myline.target
			help.unhappy = myline.unhappy_max
			help.good    = translate( this.good_list[ myline.good ] )
			help.way     = translate( get_waytype( myline.way ) )
			help.time    = myline.unhappy_time
			help.halt    = myline.minimum_halts
			help.space   = space
			text+= help.tostring() + text3
			if (count2 >= myline.target) this.count_points++
		}
		text+= space + translate("result of all line services:")
		return text
	}


	function get_target_text()
	{
                 local text = translate("offer the following service")
		local my   = "<br>" + this.my_space + " " + this.my_space + " "
		local help = ""
		local pos  = ""
		foreach ( myline in this.list)
		{
	                help = ttext("at station {station} minimum {target} {way} lines for {good}")
			pos = this.pos_to_text( myline.pos )
			help.station = "<a href=\"" + pos + ">" + pos + "</a>"
			help.way     = translate( get_waytype( myline.way ) )
			help.good    = translate( this.good_list[ myline.good ] )
			help.target  = myline.target
			text+= my + help.tostring()

			help = ttext("with {halt} different station halts and a maximum of {unhappy} unhappy passengers")
			help.halt    = myline.minimum_halts
			help.unhappy = myline.unhappy_max
			text+= my + help.tostring()

			help = ttext("at each station of the line within the last {time} month, type={type}")
			help.type = myline.type
			help.time = ( myline.unhappy_time > 0 ? myline.unhappy_time:translate("(no time limit)") )
			text+= my + help.tostring() + "<br>"
		}
	 	return text
	}


	function is_work_allowed_here(player, tool_id, pos)
	{
		return null
	}


	function get_value()
	{
		local now    = world.get_time()
		local ticks  = now.ticks_per_month / 4			// calc ticks to wait
		if ( (this.result_time < 0) || (this.result_time < now.ticks - ticks) )
		{							// make search for all targets in list only X ticks
			this.result_text = this.make_result()
			this.result_time = now.ticks
		}
	}


         function is_halt_in_list(halt,list)
	{
		if ( !(list.len() > 0) ) return false  			// be sure list is not empty
		foreach (listhalt in list)
			if ( (halt <=> listhalt) == 0 )	    		// use metamethod "_cmp"
				return true		    		// if halt is in list, return true
		return false				    		// not in list, return false
	}


	function get_unique_halts_of_line(line)
	{
                 local halt = null
		local result = []
		local schedule = line.get_schedule()
		foreach (stop in schedule.entries )
		{
			 halt = stop.get_halt( player_x(this.player) )
			 if ( !is_halt_in_list(halt,result) )
			 	result.append(halt)
		}
	 	return result
	}


	function get_unique_halts_of_all(line, linelist)
	{
		// get only unique halts of line where no other Line of List has a halt
                 local result = []
		local cmp_list = []
		foreach (cmp_line in linelist)                          // make a single list of halts
                         cmp_list.extend( this.get_unique_halts_of_line(cmp_line) )
		line = this.get_unique_halts_of_line(line)		// must be unique halts
		foreach (halt in line)
			if ( ! this.is_halt_in_list(halt,cmp_list) )    // compare complete list
				result.append(halt)
		return result
	}


	function get_linelist(coord3d, good, way)
	{
		local halt = tile_x(coord3d.x, coord3d.y, coord3d.z).get_halt()
		local player_name = player_x(this.player).get_name()
		local lines = []
		if (halt != null)
			foreach (linex in halt.get_line_list() )
				if ( (linex.get_owner().get_name() == player_name ) &&  // must be checked, e.g. on puplic stations
				     does_line_transport(linex,good) &&
				     is_line_of_waytype(linex,way) )
				lines.append( linex )
		return lines
	}


         function does_line_transport(line, good)
	{
		if (line.get_goods_catg_index().find(good) != null) return true
		return false
	}


	function is_line_of_waytype(line, way)
	{
		if (way == wt_all) return true
		if (line.get_schedule().waytype == way) return true
		return false
	}


	function get_sum_of_first_x(array, month)		// get the wanted sum() of X month
	{
		local value = 0
                 if (month == 0) return 0
                 for (local i = 0; i < month - 1; i++)
			value = array[i]
		return value
         }


	function get_waytype( way )
	{
		local waytype_list = ["all","road","rail","water","monorail","maglev","trams","narrow gauge","aircrafts","powerlines"]
		return waytype_list[ (way < 0 ? 0:way) ]
	}

}

// END OF FILE