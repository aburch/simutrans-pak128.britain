/*
 *  class: target_factory
 *
 *  by: ny911
 *  Can NOT be used in network game !
 */


/* DESCRIPTION OF THE CLASS

	extends scenario_target

END OF DESCRIPTION */




class target_factory extends target_class
{
//	[  { pos = {x = 217, y = 248} , good = "fruit", target = 10, type = "[]", time=12},
//	   { pos = {x = 217, y = 248} , good = "fruit", target = 10, type = "[]", time=12}  ]
//	type : Consumed/Arrived/Storage/In Transit/Delivered/Produced
//		[for post & pax  use unly : Arrived/Departed/Generated]
//	time : 0=now, 12=year
//	good : [goods],mail,pax
	list   = []				// for the target list of factory goods
	space  = ""

         constructor( player, weight, list )
         {
		this.list = list
		base.constructor(player, weight)
		this.space = this.my_space + " " + this.my_space + " " + this.my_space
	}


	function is_completed()
	{
		local percentage = 0
		for (local i = 0; i < this.list.len(); i++)
			percentage+= min( 100 * this.get_value(i) / this.list[i].target, 100)
		return percentage / this.list.len()
	}


	function get_factory_textlink(pos)
	{
		return "<a href=\"(" + pos.x + "," + pos.y + ")\">" + translate( factory_x(pos.x,pos.y).get_name() ) + " (" + pos.x + "," + pos.y + ")</a>"
	}


	function get_result_text()
	{
		local f      = this.list[0]
		local result = 0
		local text   = translate("factory service targets")
		local h      = ""
		local g      = ( this.list.len() < 10 ? "":"0" )
		if ( this.is_label_set( result_view_pos, "short" ) )
			return text
		text+= "<br>"
		for (local i = 0; i < this.list.len(); i++)
		{
			h = ttext("{name}: {what} {result}/{target} {good}, period of time {month} month<br>")
                         f = this.list[i]
			result = this.get_value(i)
			h.name = get_factory_textlink(f.pos)
			h.result = (result < f.target ? "<st>"+integer_to_string( result )+"</st>":integer_to_string( result ) )
			h.target = integer_to_string( f.target )
			h.good = translate(f.good)
			h.what = translate(f.type)
			h.month = f.time
			text+= this.space + this.leading_zero( (i+1), 2 ) + ". " + h.tostring()
		}
		text+= space + translate("result from this list of factory targets:")
		return text
	}


	function get_target_text()
	{
		local f    = this.list[0]
		local text = translate("factory service targets")
		local h    = ""
		local g    = ( this.list.len() < 10 ? "":"0" )
		for (local i = 0; i < this.list.len(); i++)
		{
			h = ttext("{name}: {what} {target} {good}, period of time {month} month")
                         f = this.list[i]
			h.name = get_factory_textlink(f.pos)
			h.target = integer_to_string( f.target )
			h.good = translate(f.good)
			h.what = translate(f.type)
			h.month = f.time
			text+= "<br>" + this.space + this.leading_zero( (i+1), 2 ) + ". " + h.tostring()
		}
		return text
	}


	function is_work_allowed_here(player, tool_id, pos)
	{
		return null
	}


	function get_value(position_number)
	{
                 local position = this.list[position_number]
	 	local factory = factory_x(position.pos.x,position.pos.y)
		local good = position.good
		local result = []
		local sum = 0
		switch( good )
		{
			case "pax"  : switch( position.type )
			{
				case "Arrived"  : result = factory.get_pax_arrived()
						break
				case "Departed" : result = factory.get_pax_departed()
						break
				case "Generated": result = factory.get_pax_generated()
						break
				default 	: return 0
			}
					break
			case "mail"  : switch( position.type )
			{
				case "Arrived"  : result = factory.get_mail_arrived()
						break
				case "Departed" : result = factory.get_mail_departed()
						break
				case "Generated": result = factory.get_mail_generated()
						break
				default 	: return 0
			}
					break
			default: switch( position.type )
			{
				case "Consumed" : result = factory.input[good].get_consumed()
						break
				case "Arrived"  : result = factory.input[good].get_received()
						break
				case "Storage"  : result = factory.input[good].get_storage()
						break
				case "In Transit":result = factory.input[good].get_in_transit()
						break
				case "Delivered": result = factory.input[good].get_delivered()
						break
				case "Produced" : result = factory.input[good].get_produced()
						break
				default 	: return 0
			}
		}
		sum = result[0]
		for (local i = 1; i < position.time-1; i++)
			sum =sum + result[i]
                 return sum
	}


}

// END OF FILE