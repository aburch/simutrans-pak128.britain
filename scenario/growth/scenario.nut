/*
 * Growth scenario
 *
 */

// TODO: new city => old owner of a factory retain materials?

const version              = 604	       		       		// version of script
map.file                   = "utopia.sve"                        // specify the savegame to load
scenario.short_description = translate("Growth - supply the population and let it grow.")
scenario.author            = "isidoro"
scenario.translation      <- "en=isidoro"
scenario.version = (version / 1000) + "." + ((version % 1000) / 100) + "." + ((version % 100) / 10) + (version % 10)
scenario.version+= " for pak128.Britain.1.15"

const maxCoalCenters=5; const coalRadius=3
const maxIronCenters=5; const ironRadius=5
const maxOilCenters =6; const oilRadius =7


include("scenario_functions")				// include functions
include("scenario_class")				// include class

global <- {} // Global data
global.needRecalculateCities   <- false
global.hasFactoryBeenAdded     <- false
global.hasAttractionBeenAdded  <- false
global.lastFactoryBuildingTile <- null
global.mapWidth                <- null
global.mapHeight               <- null
global.climateHeights          <- // From waterlevel included
 {["water"]=0,["desert"]=1,["tropic"]=1,["mediterranean"]=3,["temperate"]=6,["tundra"]=8,["rocky"]=10,["arctic"]=99}
global.coalCenters             <- []
global.ironCenters             <- []
global.oilCenters              <- []
global.cities                  <- []
global.attractions             <- []
global.factories               <- []

cachedFreshFishProduction <- null;
cachedFreshFishProductionPos <- null

rawMaterialsPakNames <-
  ["clay","Stone","Eisenerz","Kohle","Oel","woodchip","Bretter",
   "grain","vegetables","fruit","cider","FreshFish","livestock","wool","milk"]
rawMaterialsNames <-
  {["clay"]     ="clay",      ["Stone"]     ="stone",     ["Eisenerz"]="iron ore",["Kohle"]="coal", ["Oel"]="oil",
   ["woodchip"] ="woodchip",  ["Bretter"]   ="planks",
   ["grain"]    ="grain",     ["vegetables"]="vegetables",["fruit"]   ="fruit",   ["cider"]="cider",
   ["FreshFish"]="fresh fish",["livestock"] ="livestock", ["wool"]    ="wool",    ["milk"] ="milk"}



function get_about_text(player)
{
         local text = ttextfile("about.txt")
         text.short_description	= scenario.short_description
         text.version 		= scenario.version
         text.author		= scenario.author
         text.translation	= scenario.translation
         return text.tostring()
}


function get_info_text(pl)
{
         local text = ttextfile("info.txt")
	return text.tostring()
}


function get_rule_text(pl)
{
	local rule      = ttextfile("rule.txt")
	local textPS    = ttextfile("rule_public_service.txt")
	local textOther = ttextfile("rule_normal_player.txt")
	local text      = ""
	local text_help = ""

	if (pl==1) text = textPS.tostring()+"<br>"+textOther.tostring()
	else       text = textOther.tostring()+"<br>"+textPS.tostring()
	foreach (i,fq in foodGroupPercentages)
  		text_help+="<em> </em>"+(fq*100).getPercentages()+" <it>&lt;- "+i+"</it><br>"
	rule.food_percentages = text_help
	text+= rule.tostring()
	return text
}


function get_goal_text(pl)
{
  local text        = ttextfile("goal.txt")
  local text_limits = "<br>"+translate("is_within_limits")
  local text_help   = ""

  calculatePersistent()
  text_help+=translate("persistent") + " = " + recursive_save(persistent, "  ", [ persistent ])
  text_help+=text_limits+"(0,0):"+is_within_limits(0,0)
  text_help+=text_limits+"(0,1):"+is_within_limits(0,1)
  text_help+=text_limits+"(1,0):"+is_within_limits(1,0)
  text_help+=text_limits+"(1000,1):"+is_within_limits(1000,1)
  text_help+=text_limits+"(1,1000):"+is_within_limits(1,1000)
  text.persistent_info = text_help

  text_help = ""
  local list = factory_list_x()
  foreach (factory in global.factories)
  {
    text_help+="<em>   * "+factory.theFactory.get_name()+"</em>: ("+factory.theFactory.x+","+factory.theFactory.y+") -> <it>"+
                  factory.getOwnerCityName()+"</it> ->[ "
    foreach (item,dummy in factory.theFactory.input)
    	text_help+=my_translate(item)+" ";
    text_help+="] <st>"+translate("PAS")+"</st>:["+translate("Gen")+":"+factory.theFactory.get_pax_generated()[0]+
                ","+translate("Dep")+":"+factory.theFactory.get_pax_departed()[0]+
                ","+translate("Arr")+":"+factory.theFactory.get_pax_arrived()[0]+"] &lt;-[ "
    foreach (item,dummy in factory.theFactory.output)
    	text_help+=my_translate(item)+" ";
    // no tranlation here ???
    text_help+="] "+ factory.materials+ "<br>"
  }
  text.factories_info = text_help

	return text.tostring()
}

function get_result_text(pl)
{
  local text_help = ""
  if (global.needRecalculateCities || global.hasFactoryBeenAdded) recalculate()
  local now=world.get_time()
  local text="<h1>"+translate(["JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"][now.month])+
             "-"+now.year+"</h1>"
  text_help=ttext("Total population: {world_citizens}<br>")
  text_help.world_citizens = world.get_citizens()[0]
  text+= text_help.tostring()

  // TODO: Max production of relevant industries in last place seen.  Better if this could be enforced
  if (pl==1)
  {
    text+= translate("<br><h1>Maximum factory production per tile:</h1>")
    local generalLim=getMaxFactoryProduction(world.get_time().year)
    text_help = ttext("<em> </em>General limitation in this date: <it>{generalLim}</it><br>")
    text_help.generalLim = generalLim
    text+= text_help.tostring()
    if (global.lastFactoryBuildingTile)
    {
      text_help = ttext("<em> </em>Additional limitations for tile {pos_factory}:<br><em> </em><em> </em>")
      text_help.pos_factory = "("+global.lastFactoryBuildingTile.x+","+global.lastFactoryBuildingTile.y+")"
      text+= text_help.tostring()
      local n=0
      // Coal
      local p=0
      if (isCoalPossible(global.lastFactoryBuildingTile))
        foreach (pos in global.coalCenters)
        {
          local dx=pos.x-global.lastFactoryBuildingTile.x; local dy=pos.y-global.lastFactoryBuildingTile.y
          if (dx*dx+dy*dy<coalRadius*coalRadius) p+=150
        }
      if (p<generalLim) {text+=" "+translate("Coal")+": <it>"+p+" </it>"; n++}
      // Iron
      p=0
      if (isIronPossible(global.lastFactoryBuildingTile))
        foreach (pos in global.ironCenters)
        {
          local dx=pos.x-global.lastFactoryBuildingTile.x; local dy=pos.y-global.lastFactoryBuildingTile.y
          if (dx*dx+dy*dy<ironRadius*ironRadius) p+=50
        }
      if (p<generalLim) {text+=" "+translate("Iron")+": <it>"+p+" </it>"; n++}
      // Oil
      p=0
      if (isOilPossible(global.lastFactoryBuildingTile))
        foreach (pos in global.oilCenters)
        {
          local dx=pos.x-global.lastFactoryBuildingTile.x; local dy=pos.y-global.lastFactoryBuildingTile.y
          if (dx*dx+dy*dy<oilRadius*oilRadius) p+=300
        }
      if (p<generalLim) {text+=" "+translate("Oil")+": <it>"+p+" </it>"; n++}
      // Clay
      p=(isClayPossible(global.lastFactoryBuildingTile)?25:0)
      if (p<generalLim) {text+=" "+translate("Clay")+": <it>"+p+" </it>"; n++}
      // Stone
      p=(isStonePossible(global.lastFactoryBuildingTile)?20:0)
      if (p<generalLim) {text+=" "+translate("Stone")+": <it>"+p+" </it>"; n++}
      // Wood
      p=getWoodMaxProduction(global.lastFactoryBuildingTile)
      if (p<generalLim) {text+=" "+translate("Wood")+": <it>"+p+" </it>"; n++}

      if (n>0) text+="<br><em> </em><em> </em>"
      local m=0
      // Grain
      p=getGrainMaxProduction(global.lastFactoryBuildingTile)
      if (p<generalLim) {text+=" "+translate("Grain")+": <it>"+p+" </it>"; m++}
      // Vegetables
      p=getVegetablesMaxProduction(global.lastFactoryBuildingTile)
      if (p<generalLim) {text+=" "+translate("Vegetables")+": <it>"+p+" </it>"; m++}
      // Fruit
      p=getFruitMaxProduction(global.lastFactoryBuildingTile)
      if (p<generalLim) {text+=" "+translate("Fruit")+": <it>"+p+" </it>"; m++}
      // Cattle
      p=getCattleMaxProduction(global.lastFactoryBuildingTile)
      if (p<generalLim) {text+=" "+translate("Cattle")+": <it>"+p+" </it>"; m++}
      // Sheep
      p=getSheepMaxProduction(global.lastFactoryBuildingTile)
      if (p<generalLim) {text+=" "+translate("Sheep")+": <it>"+p+" </it>"; m++}
      // Fresh fish
      p=getFreshFishMaxProduction(global.lastFactoryBuildingTile)
      if (p<generalLim) {text+=" "+translate("Fresh Fish")+": <it>"+p+" </it>"; m++}

      if (n==0 && m==0){
		text+=" "+translate("No.")+"<br>"}
      else{
		 text+=" <br>"
      }
    }
    // TODO: Better if construction could be prevented in case of out of limits of resources
    text+=translate("<br><h1>Raw materials:</h1>")
    text+="<em> </em>"+translate("Coal")+": "
    foreach (i in global.coalCenters) text+="(<a href='("+i.x+","+i.y+")'>"+i.x+","+i.y+"</a>) "
    text+="<br><em> </em>"+translate("Iron")+": "
    foreach (i in global.ironCenters) text+="(<a href='("+i.x+","+i.y+")'>"+i.x+","+i.y+"</a>) "
    text+="<br><em> </em>"+translate("Oil")+": "
    foreach (i in global.oilCenters)  text+="(<a href='("+i.x+","+i.y+")'>"+i.x+","+i.y+"</a>) "
    text+="<br>"
  }

  text+=translate("<br><h1>Cities:</h1>")
  foreach (city in global.cities)
  {
    city.updateStatistics()
    city.calculateBuildings()
    text+=format(translate("<a href='(%d,%d)'>%s</a> (Population: %d, height: %.1f, temperature= %.1f C, buildings:%d)<br><em>  </em>Protein:%s  Carbos:%s  Vegs:%s Drinks:%s Clothes:%s Furniture:%s Pottery:%s<br><em> </em>Clay:%s WIron:%s Stone:%s Planks:%s Bricks:%s Cement:%s Steel:%s<br>"),
                 city.theCity.x,city.theCity.y,city.theCity.get_name(),city.theCity.get_citizens()[0],city.height,
                 calculateTemperature(city.height),city.buildings,
                 fN(city.getRemainingFoodGroupQuantity("proteins")),   fN(city.getRemainingFoodGroupQuantity("carbos")),
                 fN(city.getRemainingFoodGroupQuantity("vegefruits")), fN(city.getRemainingFoodGroupQuantity("drinks")),
                 fN(city.getClothesQuantity()),fN(city.getFurnitureQuantity()),fN(city.getPotteryQuantity()),
                 fN(city.getBmQuantity("clay")),      fN(city.getBmQuantity("WroughtIron")), fN(city.getBmQuantity("Stone")),
                 fN(city.getBmQuantity("Bretter")),   fN(city.getBmQuantity("bricks")),      fN(city.getBmQuantity("Cement")),
                 fN(city.getBmQuantity("Stahl"))
                 )
    city.forAllFactories
    (
      function(f)
      {
        text+=format(translate("<em> </em><em> </em> * %s PAS:[Gen:%02d,Dep:%02d,Arr:%02d] <em>"+f.materials+"</em><br>"),
                     f.getFormattedName(),f.theFactory.get_pax_generated()[0],f.theFactory.get_pax_departed()[0],
                     f.theFactory.get_pax_arrived()[0])
      }
    )
    text+="<br>"
  }

  text+=translate("<br><h1>Attractions:</h1>")
  foreach (attraction in global.attractions)
  {
    text+=format("<em> </em>* %s <em>%s</em> -> <it>%s</it><br>",
                 attraction.getFormattedName(),attraction.materials.tostring(),attraction.getOwnerCityName())
  }
  text+="<br>"
  return text
}

function recalculate()
{
  local list=null
  if (global.needRecalculateCities)
  {
    global.needRecalculateCities=false
    list=city_list_x()
    foreach (city in list)
      if (!(city.x+","+city.y in global.cities)) global.cities[city.x+","+city.y] <- City(city)
      else                                       global.cities[city.x+","+city.y].reset()
    global.factories <- {}
    list=factory_list_x()
    foreach (factory in list) global.factories[factory.x+","+factory.y] <- Factory(factory)
    global.attractions <- {}
    list=world.get_attraction_list()
    foreach (att in list) global.attractions[att.get_pos().x+","+att.get_pos().y] <- Attraction(att)
    foreach (city in global.cities) city.calculateResetBmQuantities()
  }
  else
  {
    if (global.hasFactoryBeenAdded)
    {
      list=factory_list_x()
      foreach (factory in list)
        if (!(factory.x+","+factory.y in global.factories)) global.factories[factory.x+","+factory.y] <- Factory(factory)
    }
    if (global.hasAttractionBeenAdded)
    {
      list=world.get_attraction_list()
      foreach(att in list)
        if (!(att.x+","+att.y in global.attractions)) global.attractions[att.x+","+att.y] <- Attraction(att)
    }
  }
  global.hasFactoryBeenAdded=false
  global.hasAttractionBeenAdded=false
}

function calculatePersistent()
{
  if (global.needRecalculateCities || global.hasFactoryBeenAdded) recalculate()
  local cities=[]
  foreach (city in global.cities)
  {
    local thisCity={coords=city.theCity.x+","+city.theCity.y,
                    bmQuantities=city.bmQuantities.data,      foodQuantities=city.foodQuantities.data}
    if (  city.clothesQuantity>0) thisCity.clothesQuantity  <-city.clothesQuantity
    if (city.furnitureQuantity>0) thisCity.furnitureQuantity<-city.furnitureQuantity
    if (  city.potteryQuantity>0) thisCity.potteryQuantity  <-city.potteryQuantity
    cities.append(thisCity)
  }
  persistent.cities <- cities
}

function common_start()
{
	// No new industries will be created when a city grows
	settings.set_industry_increase_every(0)

  // These settings will go in the scenario .sve file, since there is no Squirrel interface at the moment
  // factory_worker_minimum_towns 1 (default)
  // factory_worker_maximum_towns 1 (default 4)
  // passenger_factor 10 (default 16)
  // passenger_multiplier 0
  // mail_multiplier 0
  // goods_multiplier 0
  // growthfactor_villages 0
  // growthfactor_cities 0
  // growthfactor_capitals 0
  // bonus_base_factor? (def. 125)
  // toll_running_cost_percentage? To incentivate private investment in ways
  // toll_waycost_percentage?

  // Allow change of players (to get public service)
  local idx=scenario.forbidden_tools.find(tool_switch_player)
  if (idx!=null) scenario.forbidden_tools.remove(idx)
  rules.clear_forbid_tool(player_all,tool_switch_player)
  rules.forbid_tool(1,tool_land_chain)        // Not allowed: we can't prevent other industries in the chain to be built
  rules.forbid_tool(1,tool_city_chain)        // Idem
  rules.forbid_tool(1,tool_increase_industry) // Idem
  rules.forbid_tool(1,tool_lock_game)         // To prevent to shoot our own foot

  // Some nice parameters
  for (global.mapWidth=0;  is_within_limits(global.mapWidth, 0); ++global.mapWidth );
  for (global.mapHeight=0; is_within_limits(0,global.mapHeight); ++global.mapHeight);

  // Adjust climate heights
  foreach (key,h in global.climateHeights) global.climateHeights[key]+=persistent.seaLevel

  // Distribute raw materials
  // Coal
  for (local i=0; i<maxCoalCenters; ++i)
    for (local j=0; j<100; ++j)
    {
      local ground=square_x(rand(global.mapWidth),rand(global.mapHeight)).get_ground_tile()
      if (isCoalPossible(ground)) {global.coalCenters.append(ground); break}
    }
  // Iron
  for (local i=0; i<maxIronCenters; ++i)
    for (local j=0; j<100; ++j)
    {
      local ground=square_x(rand(global.mapWidth),rand(global.mapHeight)).get_ground_tile()
      if (isIronPossible(ground)) {global.ironCenters.append(ground); break}
    }
  // Oil
  for (local i=0; i<maxOilCenters; ++i)
    for (local j=0; j<100; ++j)
    {
      local ground=square_x(rand(global.mapWidth),rand(global.mapHeight)).get_ground_tile()
      if (isOilPossible(ground))  {global.oilCenters.append(ground); break}
    }

  global.cities <- {}
  local list=city_list_x()
  foreach (city in list) global.cities[city.x+","+city.y] <- City(city)
  global.factories <- {}
  list=factory_list_x()
  foreach (factory in list) global.factories[factory.x+","+factory.y] <- Factory(factory)
  global.attractions <- {}
  list=world.get_attraction_list()
  foreach (att in list) global.attractions[att.get_pos().x+","+att.get_pos().y] <- Attraction(att)
  foreach (city in global.cities) city.calculateInitialBmQuantities()
}

function start()
{
  local minHeight= 9999
  local maxHeight=-9999
  local seaLevel=  9999
  local tile=null
  while (tile=nextWorldTile(tile))
  {
    local ground=square_x(tile[0],tile[1]).get_ground_tile()
    if (ground.z<minHeight) minHeight=ground.z
    if (ground.z>maxHeight) maxHeight=ground.z
    if (ground.is_water() && seaLevel>ground.z)  seaLevel=ground.z
  }
  if (seaLevel==null) seaLevel=minHeight-1
  persistent.maxHeight <- maxHeight
  persistent.minHeight <- minHeight
  persistent.seaLevel  <- seaLevel
  common_start()
  calculatePersistent()
}

function resume_game()
{
  common_start()
  foreach (city in persistent.cities)
    if (city.coords in global.cities) // It should be always true, but...
    {
      global.cities[city.coords].bmQuantities.data  =city.bmQuantities
      global.cities[city.coords].foodQuantities.data=city.foodQuantities
      global.cities[city.coords].clothesQuantity    =(  "clothesQuantity" in city?city.clothesQuantity  :0)
      global.cities[city.coords].furnitureQuantity  =("furnitureQuantity" in city?city.furnitureQuantity:0)
      global.cities[city.coords].potteryQuantity    =(  "potteryQuantity" in city?city.potteryQuantity :0)
    }
  calculatePersistent()
}

function is_scenario_completed(pl)
{
	local percentage = 69
	return percentage
}

function new_month()
{
  if (global.needRecalculateCities || global.hasFactoryBeenAdded || global.hasAttractionBeenAdded) recalculate()
  foreach (city in global.cities) city.new_month()
}

function is_work_allowed_here(pl,tool_id,name,pos,tool)
{
//  if (pl==1 && tool_id==4096)
//  {
//    return "The eye of the beholder."
//  }
  if (pl==1 && tool_id==tool_remover)
  {
    local building=tile_x(pos.x,pos.y,pos.z).find_object(mo_building)
    if (building)
    {
      if (building.is_townhall()) return translate("You may not delete a city!")
      local f=building.get_factory()
      if (f && (f.x+","+f.y in global.factories))
      {
        local ownerCity=global.factories[f.x+","+f.y].ownerCity
        if (ownerCity) ownerCity.setFactoryErased()
        delete global.factories[f.x+","+f.y]
        return null
      }
      if (building.get_desc().is_attraction())
      {
        local scoord=getAttraction([pos.x,pos.y])
        if (scoord)
        {
          local ownerCity=global.attractions[scoord].ownerCity
          if (ownerCity) ownerCity.setAttractionErased()
          delete global.attractions[scoord]
          return null
        }
      }
    }
  }
  // Other buildings may be erased successfully by all players
  if (tool_id==tool_remover)
  {
    local building=tile_x(pos.x,pos.y,pos.z).find_object(mo_building)
    if (building)
    {
      local city=building.get_city()
      if (city) global.cities[city.x+","+city.y].setRecalculateBuildings()
    }
  }
  // Building new factories is confirmed
  if (tool_id==tool_build_factory)
    if (global.lastFactoryBuildingTile && global.lastFactoryBuildingTile.x==pos.x && global.lastFactoryBuildingTile.y==pos.y)
       global.lastFactoryBuildingTile=null
    else
    {
      global.lastFactoryBuildingTile=square_x(pos.x,pos.y).get_ground_tile()
      gui.open_info_win()
      return translate("Please confirm by clicking again on the same tile once you adjust production following the scenario progress information")
    }
  // Check if there are enough building materials if trying to build something
  // TODO: Since we don't have information about what is being built, we asume
  //       that only the materials relevant for the present year are needed...
  if (tool_id==tool_change_city_size || tool_id==tool_build_house || tool_id==tool_build_factory)
  {
    local city=world.find_nearest_city({x=pos.x,y=pos.y})
    if (city)
    {
      global.hasFactoryBeenAdded   =(global.hasFactoryBeenAdded    || tool_id==tool_build_factory)
      // Attraction are considered like houses for this tool
      global.hasAttractionBeenAdded=(global.hasAttractionBeenAdded || tool_id==tool_build_house)
      recalculate()
      local sbm=global.cities[city.x+","+city.y].getShortageBuildingMaterials(world.get_time().year)
      if (sbm)
      {
        local returntext= ttext("Impossible to build. {city_name} doesn't have enough {sbm}")
        returntext.city_name = global.cities[city.x+","+city.y].theCity.get_name()
        returntext.sbm = sbm
        return returntext.tostring()
      }
    }
  }
  if (tool_id==tool_change_city_size || tool_id==tool_build_house)
  {
    local city=world.find_nearest_city({x=pos.x,y=pos.y})
    if (city) global.cities[city.x+","+city.y].setRecalculateBuildings()
    return null
  }
  else if (tool_id==tool_add_city)      {global.needRecalculateCities=true; return null}
  return null
}


function getAttraction(c)
{
  foreach (key,a in global.attractions) if (a.ownsCoordinate(c)) return key
  return null
}
