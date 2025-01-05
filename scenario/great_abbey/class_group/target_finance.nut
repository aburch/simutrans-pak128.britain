/*
 *  class: target_finance
 *
 *  by: ny911
 *  Can NOT be used in network game !
 */


/* DESCRIPTION OF THE CLASS

	extends scenario_target
         constructor(player, weight, time, modus, target )

	modus = "trips_pax, trips_mail, trips_goods, trips_all, cash, cash_flow,
	         net_wealth, maintenance, powerline, account_overdraft"
	time  =   -1=last calenderyear, 0= this calenderyear, 1=this month, X=sum(month)  maximum 24 month
	target =  integer; maintenance as never expected

END OF DESCRIPTION */


// ### --- todo ---
// add sales_tax(rate) to pay monthly
// add cash_flow_tax(rate,free_amount) to pay monthly
// add overdraft_charge(rate) to pay monthly
// add pay_dividend(rate,every_x_month)
// testing off all


class target_finance extends target_class
{
	time = 0		// -1=last calenderyear, 0= this calenderyear, 1=this month, X=sum(month)   maximum 24 month
	target = 0              // integer; maintenance as never expected
	modus = "trips_pax, trips_mail, trips_goods, trips_all, cash, cash_flow, net_wealth, maintenance, powerline, account_overdraft"

         constructor(player, weight, time, modus, target )
         {
		this.time = time
		this.modus = modus
		this.target = target
		if (this.modus == "account_overdraft")
		{
			weight = 0				// be sure that weight = 0 for account_overdraft
			if (target < 0) this.target =-target	// make target postiv integer
		}
		base.constructor(player, weight)
	}


	function is_completed()
	{
		local percentage = 0
		local value = this.get_value()
		percentage = min( ( value / (this.target / 100) ), 100 )
		percentage = max( percentage, 0 )		// zero is minimum

		if (this.modus == "maintenance")		// never allow to get more maintenance cost
			if (value > this.target) percentage = 100
			else persistent.scenario_lost[this.player] = true

		if (this.modus == "account_overdraft")          // bankaccount overdraft = game over
			if ( value + this.target < 0)
				persistent.scenario_lost[this.player] = true
			else percentage = 100

		if (persistent.scenario_lost[this.player])
			percentage = -100			// -100% to have a differnd value
		return percentage
	}


	function get_result_text()
	{
		local result = this.get_value()
		local timewords = ["last year", "current year", "current month", "for {number} month"]
		local text = ""
		switch( this.time )
		{
			case -1 : timewords = ttext(timewords[0]).tostring()
				break
			case  0 : timewords = ttext(timewords[1]).tostring()
				break
			case  1 : timewords = ttext(timewords[2]).tostring()
				break
			default :
			{
				timewords = ttext(timewords[3])
				timewords.number = this.time
				timewords = timewords.tostring()
			}
				break
		}
		switch( this.modus )
		{
			case "trips_pax" :
				text = ttext("{timewords} passanger transport: {result} / {target}")
				break
			case "trips_mail" :
				text = ttext("{timewords} mail transport: {result} / {target}")
				break
			case "trips_goods" :
				text = ttext("{timewords} goods transport: {result} / {target}")
				break
			case "trips_all" :
				text = ttext("{timewords} transport of all: {result} / {target}")
				break
			case "cash" :
				text = ttext("Your bank account shows {result} / {target}.")
				break
			case "cash_flow" :
				text = ttext("{timewords} lowest cash flow: {result} / {target}")
				break
			case "net_wealth" :
				text = ttext("Your net wealth is {result} / {target}.")
				break
			case "maintenance" :
				text = ttext("{timewords} heighest maintenance: {result} / {target}")
				break
			case "powerline" :
				text = ttext("{timewords} income from powerlines: {result} / {target}")
				break
			case "account_overdraft" :
				if (result > 0)
					return ttext("You didn't use your account overdraft in the last 24 month.")
				else 	text = ttext("You used a account overdraft {result} of maximum -{target}.")
				break
			default : return "finance "+this.modus+" : "+result+" / "+this.target
		}
		if (this.modus.find("trips_") != null)		// make correct integer and money print
		{
                 	text.result    = integer_to_string(result)
			text.target    = integer_to_string(this.target)
		}
		else
		{
                 	text.result    = money_to_string(result)
			text.target    = money_to_string(this.target)
		}
		text.timewords = timewords
		return text.tostring()
	}


	function get_target_text()
	{
                 local text = ""
		local help = ""
		return get_result_text()
		// time, target, modus
// ### the target text is still only the result text
//	modus = "trips_pax, trips_mail, trips_goods, trips_all, cash, cash_flow, net_wealth, maintenance, powerline, account_overdraft"
	 	return text
	}


	function is_work_allowed_here(player, tool_id, pos)
	{
                 if ( (this.modus == "account_overdraft") &&
		     (player_x(this.player).get_cash()[0] < this.target) )
			if ( tool_id == tool_remover || tool_id == tool_build_way ||
			     tool_id == tool_build_station || tool_id == tool_build_depot ||
			     tool_id == tool_headquarter || tool_id == tool_setslope ||
			     tool_id == tool_build_tunnel )
				return ttext("Your account overdraft is limited.")
		return null
	}



	function get_value()
	{
		local result = 0
		local pl = player_x(this.player)
		switch( this.modus )
		{
			case "trips_pax" :
				result = get_my_transported( pl.get_transported_pax() )
				break
			case "trips_mail" :
				result = get_my_transported( pl.get_transported_mail() )
				break
			case "trips_goods" :
				result = get_my_transported( pl.get_transported_goods() )
				break
			case "trips_all" :
				result = get_my_transported( pl.get_transported() )
				break
			case "cash" :			// current month only
				result = pl.get_cash()[0]
				break
			case "cash_flow" :              // get lowest cash flow
				result = get_my_lowest( pl.get_profit()[0] )
				break
			case "net_wealth" :		// current month only
				result = pl.get_net_wealth()[0]
				break
			case "maintenance" :		// maintenance off all kind, lowest in time
				result = get_my_lowest( pl.get_maintenance() )
				break
			case "powerline" :		// it's only the earnings of powerlines
				result = get_my_transported( pl.get_powerline() )
				break
			case "account_overdraft" :      // current month only
				result = pl.get_cash()[0]
				break
		}
		return result
	}


	function get_my_lowest(transported_array)		// get the lowest in time
	{
		local value = 0
		local start = world.get_time().month + 1
		switch( this.time )
		{
			case -1 : for (local i = start; i < start + 12; i++)
					if (transported_array[i] < value)
						value = transported_array[i]
				  break
			case 0  : for (local i = 0; i < start; i++)
					if (transported_array[i] < value)
						value = transported_array[i]
				  break
			case 1  : value = transported_array[0]
				  break
			default : for (local i = 0; i < this.time; i++)
					if (transported_array[i] < value)
						value = transported_array[i]
				  break
		}
		return value
	}


	function get_my_transported(transported_array)		// get the wanted sum() of X month
	{
		local value = 0
		local start = world.get_time().month + 1
		switch( this.time )
		{
			case -1 : for (local i = start; i < start + 12; i++)
					value = value + transported_array[i]
				  break
			case 0  : for (local i = 0; i < start; i++)
					value = value + transported_array[i]
				  break
			case 1  : value = transported_array[0]
				  break
			default : for (local i = 0; i < this.time; i++)
					value = value + transported_array[i]
				  break
		}
		return value
         }
}

// END OF FILE