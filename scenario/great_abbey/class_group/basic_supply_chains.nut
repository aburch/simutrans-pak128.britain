/*
 *  class: to show industrie supply chains and production levels
 *  Version : 0.4.0       nov 2014 	script by: ny911
 *
 */


/* DESCRIPTION OF THE CLASS

puplic:
         constructor()
	function get_informations()
privat:

END OF DESCRIPTION */



class basic_supply_chains extends basic_class
{
	// HERE SHORT FUNCTION LIST
	//
         // function get_informations() [string]


         // privat values
	textline = "_______________________________________________"
	space = ""			// to get a tree view or use "<em> </em> " or " "+(128).tochar()
	corner = (187).tochar()		// symbol for a tree list corner
	count = 0			// count the ecursively chain
	max_deep = 8			// stops recursively function
	list = {}			// create a table for factory informations

         constructor()
         {
		base.constructor()
		this.space = this.my_space 	// take my_space
		this.space+= this.space 	// make it double
		this.space+= this.space		// make it longer
	}


	function give_goods(text1, text2, goods)
	{
		local help = ""
		foreach (key,value in goods)
			{ help+= translate(key) + ", " }
		if (help.len() < 2) return ""
		return text1 + " " + help.slice(0,-2) + text2
	}


	function factory_tree( pos, goods, oldtext, tree )
	{
		// search recursively factory chain to get compelete consumption
		this.count++
		if (this.count > this.max_deep) return "error!"         // DON'T DELETE THIS
		if (this.count > 1) tree+= this.space
		local treespace= tree + this.space + this.corner + this.space	// my_space = double space
		local text     = ttext("{spaces}{name}: {position} ({c_name}) consumer: {consumer} production: {production} boost: ({boost})<br>{output}{input}")
		local factory  = factory_x(pos.x, pos.y)
		local postext  = "(" + pos.x + "," + pos.y + ")"
		text.position  =  "<a href=\"" + postext + "\">" + postext + "</a>"
		text.consumer  = factory.get_consumers().len()
		text.production= factory.get_production()[0]
		text.boost     = factory.get_boost_electric()[0] + "/" +
				 factory.get_boost_mail()[0] + "/" +
				 factory.get_boost_pax()[0]
		text.c_name    = factory.get_name()		// c_english namen !!!!
		text.spaces    = tree
		text.input     = give_goods(treespace + ttext("Input:"), "<br>", factory.input)
		text.output    = give_goods(treespace + ttext("Output:"), "<br>", factory.output)
		if (this.count == 1)
		     { text.name = "<br><br><it>" + translate(factory.get_name() ) + "</it>" }
		else { text.name = translate(factory.get_name() ) }

		// MAX_BOOST, FACTOR_GOOD, STANDARD_PRODUCTION
		// control if factory gets all goods
		// insert needed to extra list normal/boost
		// list[pos.x + "_" + pos.y]
		// gewichten bei mehreren Lieferanten für gleiche Ware

		foreach ( supplier in factory.get_suppliers() )
	                 { text+= this.factory_tree( supplier, factory.input, text.tostring(), tree ) }
		this.count--
		return text.tostring()
	}


	function factory_list(place)
	{
		local text  = ttext("{name}: {position} production: {production}<br>")
		local text2 = ttext("{good}: {normal} or {boost}<br>")
		local help  = ""
		text.name       = translate( place.name )
		text.position   = "<a href=\"" + place.postext + "\">" + place.postext + "</a>"
		text.production = place.production + "/0"
		foreach (good, slot in place.output)
		{
			text2.good   = translate( good )
			text2.normal = slot.normal.has + "/" + slot.normal.shall
			text2.boost  = slot.boost.has + "/" + slot.boost.shall
			help+= this.space + this.space + text2.tostring()
		}
		return text.tostring() + help
	}


	function create_list()
	{
		local place = {}                    // create empty table
		foreach (pos in factory_list_x() )
		{
			local factory = factory_x(pos.x,pos.y)
			if (factory.output.len() > 0)        //  get producer
			{
				place = {}                    // empty table
				foreach (key, value in factory.output)
				{                        // take every slot
					place[key] <-
					{
						normal =
						{
							has   = 0,
							shall = 0
						},
						boost =
						{
							has   = 0,
							shall = 0
						}
					}
				}
				this.list[pos.x + "_" + pos.y] <-
				{
					name       = factory.get_name(),
					postext    = "(" + pos.x + "," + pos.y + ")",
					output     = place,
					production = factory.get_production()[0]
				}
			}
		}
	}


	function custom_compare(a,b)
	{
	        a = a.tolower()
		b = b.tolower()
		if (a > b) return 1
		else if (a < b) return -1
		return 0;
	}


	function give_internal_goods()
	{
		local text = ""
		local list = []
		local tlist= []
		foreach (pos in factory_list_x() )        //  get producer list
	         	foreach (good, res in factory_x(pos.x,pos.y).output)
				if (list.find(good) == null)
					list.append(good)
	        foreach (good in list)
			tlist.append("<br>" + translate(good) + " = " + good)
		tlist.sort(custom_compare)
		text+= "<br><i>translation = internal name</i><br>used factory goods:<br>"
	        foreach (good in tlist)
			text+= good
		// add list off all goods in pakset
		text+= "<br><br><i>translation = internal name</i><br>all goods off pakset (sorted by pakset dat):<br>"
		list = good_desc_list_x()
		foreach (good in list)
			text+= "<br>" + translate(good.name) + " = " + good.name
		return text
	}


	function get_informations()
	{
		local result = ttext("<em>factory tree of endconsumers</em>{textline}{factory_tree}<br><em>factory list of goods output</em>{textline}{factory_list}<br><em>list of internal good names</em>{textline}{factory_goods}<br>{textline}")
		local info = ttext("Lists to check your factory chains and internal good names.<br>There is a delay of around 15 seconds until the correct value is shown.")
		local flist = [""]
		local text = ""
		this.create_list()
		foreach (pos in factory_list_x() )        //  get endconsumer list
			if (factory_x(pos.x,pos.y).output.len() == 0)
				{ text+= this.factory_tree(pos, null, "", "") }
		result.factory_tree = "<br>" + text + "<br>"
		text = ""
		foreach (pos in factory_list_x() )        //  get producer list
			if (factory_x(pos.x,pos.y).output.len() > 0)
				{ flist.append( this.factory_list(this.list[pos.x + "_" + pos.y]) ) }
		flist.sort()                              //  sort the list
		foreach (row in flist) text+= row         //  array to string
		result.factory_list = "<br><br>" + text + "<br>"
		result.factory_goods = "<br>" + this.give_internal_goods()
		result.textline = "<br>" + this.textline + this.textline
		return info.tostring() + "<br><br>" + result.tostring() + "<br>"      //  return result
	}

}


/* informations for this script development

List is whitout endconsumer : actual / should<br>
Tree: there is no control over the exist of necessary goods<br>
later : array of normal and maximum production to serve all consumers<br>
        make new list with factories to count max needed production<br>
        take same sources of consumers together (as group)<br>
        maybe : standard_production = production / sum(actuel boost)<br>
*/

// END OF FILE