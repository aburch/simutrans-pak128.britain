/*
 *  Great Abbey - scenario - ny911
 *
 *  tested with 120.0.1 nightly r7386, pak128.Britain 1.13 r1499, using "class group"
 *  Can NOT be used in network game !
 */

const version		  = 101	       		       	// version of script
const developer_info 	  = false			// true or false; show extra informations and result list weighting
map.file			  = "great_abbey_v1.sve"	// specify the savegame to load
scenario.short_description = "Great Abbey"               // scenario name
scenario.author            = "ny911"
scenario.translation      <- "n.n."
scenario.api		 <- "112.3"			// scenario relies on this version of the api
scenario.version           = (version / 1000) + "." + ((version % 1000) / 100) + "." + ((version % 100) / 10) + (version % 10)

persistent.version        <- version		 	// stores version of script
persistent.scenario_lost  <- []				// stores if, which player lost the scenario
persistent.map_info	 <- {}				// used to store map informations at starttime


basic            	 <- null	 		// used later for class basic
supply_chains		 <- null       	 		// used later for class factory_chains
include("great_abbey")					// include file of this scenario


/*
 *  standard functions of main script
 */

function get_info_text(player)
{
         local text = ttextfile("info.txt")
	start_objects(player)
	text.scenario_name	= translate( scenario.short_description )
	text.year		= settings.get_start_time().year
	text.map_info_start	= basic.map_info( player, "start" )
	text.sign_pos		= basic.pos_to_text( result_view_pos )
	if ( developer_info )
		return get_developer_info(player,text)
         return text.tostring()
}


function get_rule_text(player)
{
         local text = ttextfile("rule.txt")
	start_objects(player)
	text.conservation_area = basic.cube_to_text( forbid_tools.abbey_area.list[0] )
	text.abbey_station = basic.cube_to_text( { nw = {x = 220, y = 245, z = -2}, se = {x = 222, y = 250, z = -2} } )
	text.hq_area = basic.cube_to_text( hq_area )
         return text.tostring()
}


function get_goal_text(player)
{
         local text = ttextfile("goal.txt")
	start_objects(player)
	text.target_text = basic.get_target_text()
         return text.tostring()
}

gl_tex1 <- ""
function get_result_text(player)
{
	local text = ttextfile("result.txt")
	start_objects(player)
	text.ratio_scenario	= basic.is_scenario_completed(player)
	text.result_list	= gl_tex1 //basic.get_result_list( player, developer_info )
         return text.tostring()
}


function get_about_text(player)
{
         local text = ttextfile("about.txt")
         text.short_description	= translate( scenario.short_description )
         text.version 		= scenario.version
         text.author		= scenario.author
         text.translation	= scenario.translation
         return text.tostring()
}


function start ()
{
	for (local i = 0; i < 15; i++)                  // set all player lost = false
		persistent.scenario_lost.append( false )
	start_objects(0)				// use here player = 0
         resume_game()                                   // setup settings and check version
	extra_translate()                               // enable extra translations
}


function new_month()					// Called at the beginning of a new year
{
	basic.set_bank_account(2,1)			// SET cash of player=1 "heritage conservation" every month
}


function new_year()					// Called at the beginning of a month
{
}


function is_scenario_completed(player)
{

	if (currt_pos){
		local t = tile_x(currt_pos.x,currt_pos.y,currt_pos.z)
		local build = t.find_object(mo_building)
		if (!t.is_marked() && build){
		  local t_list = gl_buil_list
		  foreach(t in t_list){
			t.find_object(mo_building).unmark()
		  }
		  gl_buil_list = {}
		  currt_pos = null
		}
	}

	gl_tex1 = basic.get_result_list( player, developer_info )
	start_objects(player)
         local result = basic.is_scenario_completed(player)
	return result					// return result to simutrans
}


function is_work_allowed_here(player, tool_id, name, pos, tool)
{
        	if (player == 1) return null			// player 1 is the puplic service
	return basic.is_work_allowed_here(player, tool_id, pos)
}


function is_schedule_allowed(player, schedule)
{
        	if (player == 1) return null			// player 1 is the puplic service
	return basic.is_schedule_allowed(player, schedule)
}

//Global coordinate for mark build tile
currt_pos <- null
// Mark / Unmark build in to link
gl_buil_list <- {}
function jump_to_link_executed(pos)
{
    if (currt_pos){
      local t = tile_x(currt_pos.x,currt_pos.y,currt_pos.z)
      local build = t.find_object(mo_building)
      if(build){
        local t_list = gl_buil_list
        foreach(t in t_list){
          t.find_object(mo_building).unmark()
        }
        gl_buil_list = {}
        currt_pos = null
      }
    }
    local t = tile_x(pos.x,pos.y,pos.z)
    local build = t.find_object(mo_building)

    if(build){
      local t_list = build.get_tile_list()
      foreach(t in t_list){
        gl_buil_list[coord3d_to_key(t)] <- t
        t.find_object(mo_building).mark()
      }
      currt_pos = pos
    }
    return null
  return null
}

function coord3d_to_key(c)
{
	return ("coord3d_" + c.x + "_" + c.y + "_" + c.z).toalnum();
}


// END OF FILE
