/*
 * INCLUDE FILE for scenario.nut - great abbey scenario
 * by ny911
 */

// list of include files "class group"
const class_path = "class_group/"
include( class_path + "basic_class" )
include( class_path + "basic_scenario" )
include( class_path + "basic_supply_chains" )
include( class_path + "target_class" )
include( class_path + "target_connected" )
include( class_path + "target_finance" )
include( class_path + "target_factory" )
include( class_path + "target_hq" )
include( class_path + "target_linelist" )


// translateable text
const err_no_work    = "no works in heritage conservation area"
const err_station    = "You can build stations only under the middle of the abbey at level -2."
const err_savegame   = "Savegame has a different {more_info} script version! Maybe, it will work."
const develop_title  = "<br><em>DEVELOPER INFORMATIONS</em><br>"
const develop_cities = "<br><em>list of cities</em><br><br>{city_list}<br>"
const develop_map    = "<br>Map Information on start:<br>{map_info_start}<br>Map Information now:<br>{map_info_now}<br>"
const develop_chain  = "<br><em>factory chain list</em><br>{factory_chains}<br>"


// scenario settings
startcash	<- 0.100000                             	// startcash in million
result_view_pos  <- { x = 0, y = 0, z = 3 }			// place for mo_label to set result view to long or short
target_trips     <- { type="trips_pax", time=6, value=750000 }	// 6=half year; trips to be done by player
hq_area 		<- { nw = {x = 130, y = 170, z = -2}, se = {x = 300, y = 320, z = 2} }
target_goods_list<- [                                    	// target list for factory class
	// market 1
	{ pos = {x = 217, y = 248} , good = "fruit", target = 5000, type = "Consumed", time=12},
	{ pos = {x = 217, y = 248} , good = "vegetables", target = 100, type = "Arrived", time=2 },
	{ pos = {x = 217, y = 248} , good = "meat", target = 100, type = "Arrived", time=3 },
	{ pos = {x = 217, y = 248} , good = "fish", target = 600, type = "Storage", time=6 },
	// market 2
	{ pos = {x = 218, y = 248} , good = "fruit", target = 5000, type = "Consumed", time=12},
	{ pos = {x = 218, y = 248} , good = "vegetables", target = 100, type = "Arrived", time=2 },
	{ pos = {x = 218, y = 248} , good = "meat", target = 100, type = "Arrived", time=3 },
	{ pos = {x = 218, y = 248} , good = "fish", target = 600, type = "Storage", time=6 },
	// market 3
	{ pos = {x = 224, y = 248} , good = "fruit", target = 5000, type = "Consumed", time=12},
	{ pos = {x = 224, y = 248} , good = "vegetables", target = 100, type = "Arrived", time=2 },
	{ pos = {x = 224, y = 248} , good = "meat", target = 100, type = "Arrived", time=3 },
	{ pos = {x = 224, y = 248} , good = "fish", target = 600, type = "Storage", time=6 },
	// market 4
	{ pos = {x = 225, y = 248} , good = "fruit", target = 5000, type = "Consumed", time=12},
	{ pos = {x = 225, y = 248} , good = "vegetables", target = 100, type = "Arrived", time=2 },
	{ pos = {x = 225, y = 248} , good = "meat", target = 100, type = "Arrived", time=3 },
	{ pos = {x = 225, y = 248} , good = "fish", target = 600, type = "Storage", time=6 },
	// Pub 1
	{ pos = {x = 218, y = 244} , good = "beer", target = 8000, type = "Consumed", time=12},
	{ pos = {x = 218, y = 244} , good = "cider", target = 4000, type = "Consumed", time=12},
	// Pub 2
	{ pos = {x = 224, y = 244} , good = "beer", target = 8000, type = "Consumed", time=12},
	{ pos = {x = 224, y = 244} , good = "cider", target = 4000, type = "Consumed", time=12},
	// Pub 3 (college)
	{ pos = {x = 294, y = 244} , good = "beer", target = 2000, type = "Consumed", time=12},
	{ pos = {x = 294, y = 244} , good = "cider", target = 1000, type = "Consumed", time=12},
	// Pub 4 (college)
	{ pos = {x = 293, y = 242} , good = "beer", target = 2000, type = "Consumed", time=12},
	{ pos = {x = 293, y = 242} , good = "cider", target = 1000, type = "Consumed", time=12},
	// dairy 1
	{ pos = {x = 217, y = 241} , good = "milk", target = 900, type = "Consumed", time=12},
	// dairy 2
	{ pos = {x = 225, y = 241} , good = "milk", target = 900, type = "Consumed", time=12},
	]
linelist <- [                                              	// list for class line_list
	{ pos = { x=221, y=249, z=0}, type="count_lines_over_all", good=0, way=wt_rail, target=3, minimum_halts=6, unhappy_time=6, unhappy_max=300},
	{ pos = { x=221, y=249, z=0}, type="count_lines_over_all", good=0, way=wt_road, target=2, minimum_halts=8, unhappy_time=1, unhappy_max=50}
	]                                                       // end line_list

connected_list <- [						// list for connected positions targets
 	{
		pos_from	= { x =   4, y =  66, z = 10 },
		pos_to		= { x = 221, y = 249, z =  0 },
		waytype		= [wt_road], 			// [wt_all, wt_rail, wt_road, wt_air, wt_tram, wt_water],
		good		= 0,            		// 0=Passengers, 1=Mail, 2=None, >=3 anything else
		min_transfer	= 0,
		max_transfer	= 0,				// 0 = direct line
		max_unhappy	= 0
	}
	]                                                       // end connected_list


forbid_tools	<- {					// array of forbid_tools
	abbey_area = {					// protect abbey area
		waytyp= wt_all,
		tool  = [
			{ id = 4135,			error = err_no_work },  // tool "climate zones" = 4135
			{ id = tool_raise_land,		error = err_no_work },
			{ id = tool_setslope,		error = err_no_work },
			{ id = tool_build_way,		error = err_no_work },
			{ id = tool_build_bridge,	error = err_no_work },
			{ id = tool_build_depot,   	error = err_no_work },
			{ id = tool_build_wayobj,  	error = err_no_work },
			{ id = tool_build_roadsign,	error = err_no_work },
			{ id = tool_build_station,	error = err_no_work },
			{ id = tool_remover, 		error = err_no_work },
			{ id = tool_remove_way,		error = err_no_work }
			],
		list  = [                               // allowed types: coord3d or coord
			{ nw = {x = 212, y = 237, z =12}, se = {x = 230, y = 257, z = 0} }
			]
		}
	abbey_underground = {				// abbey underground station area is free
		waytyp= wt_all,
		tool  = [
			{ id = tool_build_station,	error = err_station }
			],
		list  = [                               // allowed types: coord3d or coord
			{ nw = {x = 212, y = 237, z = -3}, se = {x = 230, y = 257, z = -8} },
			{ nw = {x = 212, y = 237, z = -1}, se = {x = 219, y = 257, z = -2} },
			{ nw = {x = 223, y = 237, z = -1}, se = {x = 230, y = 257, z = -2} },
			{ nw = {x = 220, y = 237, z = -1}, se = {x = 222, y = 244, z = -2} },
			{ nw = {x = 220, y = 251, z = -1}, se = {x = 222, y = 257, z = -2} }
			]
		}
	}


/*
 *  additional functions for main script
 */

function start_objects(player)
{
         if (basic == null)
	{
		rules.forbid_tool( player, tool_set_traffic_level )
		rules.forbid_tool( player, tool_make_stop_public )
		rules.forbid_way_tool( player, tool_build_station, wt_air, "" )
		rules.forbid_way_tool( player, tool_build_station, wt_monorail, "" )
		rules.forbid_way_tool( player, tool_build_station, wt_maglev, "" )

		basic <- basic_scenario(player,startcash) 	// set player and startcash inside of class

		basic.add_to_scenario( target_hq( player, 5, 0, hq_area ) )	// 5 for weight; 0 for hq target level
		basic.add_to_scenario( target_finance( player, 10, target_trips.time ,target_trips.type, target_trips.value ) )
		//basic.add_to_scenario( target_finance( player,100,-1,"trips_mail",1234) )
		//basic.add_to_scenario( target_finance( player,0,0,"account_overdraft",50000) )
		//basic.add_to_scenario( target_finance( player,20,0,"net_wealth",5000000) )
		basic.add_to_scenario( target_factory( player, 40, target_goods_list ) )
		basic.add_to_scenario( target_linelist( player, 40, linelist ) )
		basic.add_to_scenario( target_connected( player, 5, connected_list, 4 ) )


		basic.set_bank_account(1,0.05)		// SET cash of player=1 "puplic hand", just to have a nice view
		basic.set_bank_account(2,1)		// SET cash of player=2 "heritage conservation"
		supply_chains <- basic_supply_chains()	// to view the factory chains later

		if (player != 1)			// don't set public player
		{
			basic.forbid_tools(player,forbid_tools)
			// basic.allow_tools(player,forbid_tools)
		}
	}
}	// end start_objects(player)


function resume_game()
{
         // check for script version and compatibility, then use update
         if ( persistent.version < version ) update() 	// do update old versions
         else gui.open_info_win()			// show scenario window
         // if wanted, correct some settings of savegame or startgame
         settings.set_industry_increase_every(0) 	// correct set of industry_increase !!!
	settings.set_traffic_level(5)         		// correct set of traffic level
}


function update()                			// update for older versions
{
         local text = ttext(err_savegame)
         text.more_info = "(" + (version / 1000) + "." + ((version % 1000) / 100) + "." + ((version % 100) / 10) + (version % 10) + ")"
         gui.add_message( text.tostring() )              // show user the message
         // if (persistent.version <= 0)			// update version 0.0.x
	//	 include("example_file")
         // END of update version 0.xxx
         persistent.version = version    		// change the old version number
}


function get_developer_info(player,text)
{
	local result = text.tostring()
	result+= translate( develop_title )

	text = ttext( develop_cities )
	text.city_list		= basic.city_list("citizens","year")
	result+= text.tostring()

	text = ttext( develop_map )
	text.map_info_start	= basic.map_info(player,"start")
	text.map_info_now	= basic.map_info(player,"now")
	result+= text.tostring()

	text = ttext( develop_chain )
	text.factory_chains	= supply_chains.get_informations()
	result+= text.tostring()

	return result
}


function extra_translate()
{
	// translate Player: Heritage Conservation
	// use the translation file [language].tab

	// translate attraction names
	// use the translation file [language].tab

	// translate citynames, use file [language].tab and function
	basic.translate_all_city_names()

	// translate factorynames and special factorynames, use file [language].tab and function
	basic.translate_all_factory_names()

	// translate players textlabels
	// local label = tile_x(221,256,-1).find_object( mo_label )
	// gui.add_message( label.get_name() )
}


// END OF FILE
