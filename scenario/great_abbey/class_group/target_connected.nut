 /*
 *  class: target_connected
 *
 *  by: ny911
 *  Can NOT be used in network game !
 */


/* DESCRIPTION OF THE CLASS

	extends scenario_target

END OF DESCRIPTION */


class target_connected extends target_class
{
/*
 array [
 	{
	pos_from	= { x=221, y=249, z=0},
	pos_to		= { x=221, y=249, z=0},
	waytype		= [wt_all, wt_rail, wt_road, wt_air, wt_tram, wt_water],
	good		= 0,
	min_transfer	= 0,
	max_transfer	= 3,
	max_unhappy	= 0
	}
       ]
good = number of good (0=passanger, 1=mail, 2=None, >=3 anything else
way = array of allowed waytypes
pos can be any coord3d, it did NOT must be the place of a station
*/
	list = []				// for the target list of factory goods
	max_recursive = 10			// maximum of transfers, using to find way
         halt_list   = []
	good_list   = []
	pl_public   = null
         halt_target = null
         recursive   = 0
	result_list = []
	result_time = -1
	result_min  = -1
	result_max  = -1
	radius      = 2

         constructor( player, weight, list, radius )
         {
		this.list        = list
		this.halt_list   = []
		this.result_list = []
		this.result_time = -1
		this.pl_public   = player_x(1)
		this.radius      = radius
		local list = good_desc_list_x()
		foreach ( good in list )
			this.good_list.append( good.name )
		base.constructor(player, weight)
	}


	function is_completed()
	{
		local percentage = 0
		this.get_value()
		if (this.result_list.len() == 0)
			return 100
		foreach (result in this.result_list)
			percentage+= ( result == true ? 1:0 )
		return min( (100 * percentage / this.result_list.len() ), 100)
	}


	function get_result_text()
	{
		local text = ""
		local i = 0
		if (this.list.len() == 0) return text
		this.get_value()
		text = ttext("Connected places ({amount} targets)")
		text.amount = this.result_list.len()
		text = text.tostring()
		if ( !this.is_label_set( result_view_pos, "short" ) )
			foreach (target in this.list)
			{
				text+= "<br>" + this.my_space + " " + this.my_space + " " + this.my_space
				text+= get_ttext_connection( target ) + " = "
				text+= translate( (this.result_list[i] == true ? "true":"false") )
				i++
			}
                 return text
	}


	function get_target_text()
	{
                 local text = ""
		local help = ""
		if (this.list.len() == 0) return text
		text = translate("List of connections to support (coord inside of a station coverage):")
		foreach (target in this.list)
		{
			text+= "<br><br>" + this.my_space + this.my_space + get_ttext_connection( target )
			help = ttext("Minimum transfers {min_transfer}, maximum transfers {max_transfer}, maximum unhappy at each station {max_unhappy}")
			help.min_transfer = target.min_transfer
			help.max_transfer = target.max_transfer
			help.max_unhappy  = target.max_unhappy
			text+= "<br>" + this.my_space + this.my_space + help.tostring()
		}
	 	return text
	}


         function get_ttext_connection(target)
	{
		local way  = ""
                 local help = ttext( "From {from} to {to} with waytype {waytype} for {good}, max unhappy = {unhappy}" )
		local waytype_list = ["all","road","rail","water","monorail","maglev","trams","narrow gauge","aircrafts","powerlines"]
		foreach ( wtype in target.waytype )
		{
                         if (wtype < 0) wtype = 0
			way+= translate( waytype_list[wtype] ) + " "
		}
		help.waytype      = way
		help.from	  = this.pos_to_text( target.pos_from )
		help.to		  = this.pos_to_text( target.pos_to )
		help.good	  = translate( this.good_list[ target.good ] )
		help.unhappy	  = target.max_unhappy
		return help.tostring()
	}


	function get_value()
	{
                 local result = []
		local now    = world.get_time()
		local ticks  = now.ticks_per_month / 4			// calc ticks to wait
		if ( (this.result_time < 0) || (this.result_time < now.ticks - ticks) )
		{							// make search for all targets in list only X ticks
			this.result_time = now.ticks
			if (this.list.len() == 0) return
			foreach (target in this.list)
				result.append( this.get_result_of( target ) )
                         this.result_list = result
		}
	}


         function is_halt_in_list( halt, list )
	{
		if ( !(list.len() > 0) )				// be sure list is not empty
			return false
		foreach (listhalt in list)
			if ( (halt <=> listhalt) == 0 )	    		// use metamethod "_cmp"
				return true		    		// if halt is in list, return true
		return false				    		// not in list, return false
	}


	function get_result_of( connect )				// connect is element of this.list
	{
		local halt_a = null
		local halt_b = null
		local pl_x   = player_x( this.player )
		// find all halts for positions
		local from = this.find_all_accessible_halts( this.player, connect.pos_from, connect.good, connect.max_unhappy )
		local to   = this.find_all_accessible_halts( this.player, connect.pos_to, connect.good, connect.max_unhappy )
		// don't check owner of halt here !!! It's inside the get_all_direct_halts() function
                 foreach (halt_a in from)
		{
			this.halt_list = []
			if ( halt_a != null)
				this.halt_list.append( halt_a )
                 	foreach (halt_b in to)
			{
				this.result_min = -1
				this.result_max = -1
				this.recursive  =  0
                                 this.halt_target = halt_b
				search_way( halt_a, connect )
				if ( (this.result_min >= connect.min_transfer) &&
				     (this.result_max <= connect.max_transfer) &&
				     (this.result_min > -1) )
					return true
			}
		}
		return false
	}


	function search_way( halt_start, connect )
	{
		local new_halts = get_all_direct_halts( halt_start, connect.waytype, connect.good, connect.max_unhappy )
                 local help = -1
		this.recursive++
		this.halt_list.extend( new_halts )
		foreach ( halt in new_halts )
			if ( (halt <=> this.halt_target) == 0 )		// cmp; is target in list, then true
			{
                                 help = this.recursive - 1
				if (help > this.result_min )
					this.result_min = help
				if ( (help < this.result_max ) || (this.result_max < 0) )
					this.result_max = help
				return
			}
		if ( ( this.recursive < this.max_recursive ) && ( this.recursive < connect.max_transfer + 2) )
			foreach ( halt in new_halts )
				search_way( halt, connect )
		this.recursive--
	}


	function get_all_direct_halts( halt, waytype, good, max_unhappy )
	{
		local result    = []
		local pl_x      = player_x( this.player )
		local good_desc = good_desc_x( this.good_list[good] )
		try { local h = waytype[0] }				// waytype is an array if not, make it
		catch (error) { waytype = [ waytype ] }
		if (                                   			// first check the halt
		     ( ( ! ( halt.get_owner() <=> pl_x ) ) && ( x.get_owner() != this.pl_public ) ) ||		// check owner
		     ( halt.get_unhappy()[0] > max_unhappy ) ||         // check max_unhappy
		     ( ! halt.accepts_good( good_desc ) )	    	// check goods (pax, mail, freight)
		   )
			return result
		// now check lines and convoys to get list of halts
		foreach ( line in halt.get_line_list() )
			result.extend( this.get_halts( pl_x, line, waytype, good, result ) )
		foreach ( convoy in halt.get_convoy_list() )
			result.extend( this.get_halts( pl_x, convoy, waytype, good, result ) )
                 return result
	}


         function get_halts( pl_x, x, waytype, good, result_list )
	{
		local result = []
		local halt = null
		if ( ( (! ( x.get_owner() <=> pl_x ) ) && ( x.get_owner() != this.pl_public ) ) ||
		     ( ! is_schedule_of_waytype( x.get_schedule().waytype, waytype ) ) ||
		     ( x.get_goods_catg_index().find( good ) == null )
		   )
			return result
		foreach ( waystop in x.get_schedule().entries )
		{
			halt = waystop.get_halt( pl_x )
			if ( (halt != null) && ( !is_halt_in_list( halt, result_list ) )
			     && ( !is_halt_in_list( halt, result ) )
			     && ( !is_halt_in_list( halt, this.halt_list ) ) )
				result.append(halt)			// get only halts, no waystops
		}
		return result
	}


	function is_schedule_of_waytype( waytype , waytype_array )
	{
		foreach ( way in waytype_array )
			if ( (waytype == way) || (waytype == wt_all) )
				return true
		return false
	}


	function find_all_accessible_halts( player, position, good, unhappy )
	{
                 // remember here: player might not be equal to this.player
		local result= []
		local halt  = null
		local max_x = position.x + this.radius
		local max_y = position.y + this.radius
		local min_x = position.x - this.radius
		local min_y = position.y - this.radius
		good   = good_desc_x( this.good_list[good] )
		player = player_x( player )
		for ( local x = min_x; x < max_x; x++ )
			for ( local y = min_y; y < max_y; y++ )
			{
				// don't need to check x,y out off map borders
				// don't use height here
				halt = square_x( x, y ).get_player_halt( player )
				if ( ( halt != null ) &&
                                      ( halt.accepts_good( good ) ) &&
				     ( halt.get_unhappy()[0] <= unhappy ) )
					result.append( halt )
			}
		return result
	}
}

// END OF FILE