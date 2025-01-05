/*
 * Growth scenario  - file for class's
 *
 */


 class Quantities
{
  data=null
  constructor(pakNames,...)
  {
    data={}; local i=0
    local args=(vargv.len()==0 || vargv[0].len()==0)?null:vargv[0]
    foreach (name in pakNames) data[name] <- args?args[i++]:0
  }
  function _cloned(original) {data=clone original.data}
// It doesn't work... A pity...
//  function _get(idx)         {return data[idx]}
  function _set(idx,value)   {return data[idx]=value}
  function _add(other)
  {
    local result=clone this
    if (typeof other==typeof this)
      foreach (key,i in result.data) result.data[key]+=other.data[key]
    else
      foreach (key,i in result.data) result.data[key]+=other
    return result
  }
  function _sub(other)
  {
    local result=clone this
    if (typeof other==typeof this)
      foreach (key,i in result.data) result.data[key]-=other.data[key]
    else
      foreach (key,i in result.data) result.data[key]-=other
    return result
  }
  function _mul(other)
  {
    local result=clone this
    if (typeof other==typeof this)
      foreach (key,i in result.data) result.data[key]*=other.data[key]
    else
      foreach (key,i in result.data) result.data[key]*=other
    return result
  }
  function sum()             {local s=0; foreach (v in data) s+=v; return s}
  function toInts()          {foreach (key,v in data) data[key]=(data[key]+0.5).tointeger(); return this}
  function clear()           {foreach(key,i in data) data[key]=0}
  function getQuantity(bm)   {return data[bm]}
  function addQuantity(bm,q) {data[bm]+=q}
}

buildingMaterialPakNames <- ["clay","WroughtIron","Stone","Bretter","bricks","Cement","Stahl"]
buildingMaterialNames    <- {["clay"]="clay",     ["WroughtIron"]="wrought iron", ["Stone"]="stone", ["Bretter"]="planks",
                             ["bricks"]="bricks", ["Cement"]="cement",            ["Stahl"]="steel"}
class BuildingMaterialQuantities extends Quantities
{
  constructor(...)
  {
    if (vargv.len()==1) {base._cloned(vargv[0]); return} // Copy constructor
    base.constructor(::buildingMaterialPakNames,vargv)
  }
  function _tostring() {return format("[Cl:%d WI:%d Sn:%d Pl:%d Br:%d Ce:%d St:%d]", data.clay, data.WroughtIron, data.Stone,
                                      data.Bretter, data.bricks, data.Cement, data.Stahl)}
}

foodPakNames <- ["fish","meat","milk","flour","vegetables","fruit","beer","cider"]
class FoodQuantities extends Quantities
{
  constructor(...)
  {
    if (vargv.len()==1) {base._cloned(vargv[0]); return} // Copy constructor
    base.constructor(::foodPakNames,vargv)
  }
  function _tostring() {return format(translate("[Fish:%4.2f Meat:%4.2f Milk:%4.2f Flour:%4.2f Vegs:%4.2f Fruit:%4.2f Beer:%4.2f Cider:%4.2f]"),
                                      data.fish, data.meat, data.milk, data.flour, data.vegetables, data.fruit, data.beer, data.cider)}
  function getPercentages()
   {return format(translate("[Fish:%03d%% Meat:%03d%% Milk:%03d%% Flour:%03d%% Vegs:%03d%% Fruit:%03d%% Beer:%03d%% Cider:%03d%%]"),
                  data.fish, data.meat, data.milk, data.flour, data.vegetables, data.fruit, data.beer, data.cider)}
}

foodGroupNames <- ["proteins","carbos","vegefruits","drinks"]
class FoodGroupQuantities extends Quantities
{
  constructor(...)
  {
    if (vargv.len()==1) {base._cloned(vargv[0]); return} // Copy constructor
    base.constructor(::foodGroupNames,vargv)
  }
  function _tostring() {return format(translate("[Proteins:%4.2f Carbos:%4.2f VegsFr:%4.2f Drinks:%4.2f]"),
                                      data.proteins, data.carbos, data.vegefruits, data.drinks)}
}

buildingMaterialPercentages <- // TODO: This should be done automatically in start()
{                                // Clay Wiro Ston Bret Bric Ceme Stahl
  [1800]=BuildingMaterialQuantities(0.09,0.09,0.47,0.35,0.00,0.00,0.00),
  [1855]=BuildingMaterialQuantities(0.00,0.07,0.08,0.25,0.25,0.35,0.00),
  [1905]=BuildingMaterialQuantities(0.00,0.00,0.00,0.20,0.27,0.27,0.26),
  [1961]=BuildingMaterialQuantities(0.00,0.00,0.00,0.20,0.26,0.27,0.27),
  [1985]=BuildingMaterialQuantities(0.00,0.00,0.00,0.19,0.27,0.27,0.27),
  [9999]=BuildingMaterialQuantities(0.00,0.00,0.00,0.19,0.27,0.27,0.27)
}
function neededMaterials(yearOfAppearance,pasLevel,...) // Optional arguments: size.x, size.y, production (for factories)
{ // (alpha + beta * pasLevel + gamma * production) * size
  local factor= 15;                          // alpha = 15
  factor+= 0.9*pasLevel;                     // beta  = 0.9, so that bigger buildings need less materials/inhabitant
  if (vargv.len()>=3) factor+= 0.5*vargv[2]; // gamma=0.5
  if (vargv.len()>=1) factor*= vargv[0];     // size calculation
  if (vargv.len()>=2) factor*= vargv[1];
  foreach (key,bmq in buildingMaterialPercentages)
    if (key>=yearOfAppearance) return (bmq*factor).toInts()
  return BuildingMaterialQuantities()
}

foodGroupPercentages <-
{                            // Fish Meat Milk Flour Vegs Fruit Beer Cider
  ["proteins"]  =FoodQuantities(1.0, 1.0, 0.4, 0.15, 0.0, 0.00, 0.0, 0.00),
  ["carbos"]    =FoodQuantities(0.0, 0.0, 0.2, 0.85, 0.0, 0.15, 0.1, 0.15),
  ["vegefruits"]=FoodQuantities(0.0, 0.0, 0.0, 0.00, 1.0, 0.85, 0.0, 0.00),
  ["drinks"]    =FoodQuantities(0.0, 0.0, 0.4, 0.00, 0.0, 0.00, 0.9, 0.85)
}

// How much of the surplus isn't rotten the following month for each kind of food
                                      // Fish Meat Milk Flour Vegs Fruit Beer Cider
preservationPercentages <- FoodQuantities(0.0, 0.1, 0.1, 0.95, 0.8, 0.55, 1.0, 1.0)

// How much (%) of each food group is needed
                                   // Prots Carbos Vegs Drinks
foodGroupNeeds <- FoodGroupQuantities(0.1,  0.3,   0.3, 0.3)
function calculateNeededFoodGroup(population) {return (foodGroupNeeds*(population/18.0)).toInts()}
function calculateFoodGroupQuantities(fq)
{
  return FoodGroupQuantities((fq*foodGroupPercentages["proteins"]  ).sum(),
                             (fq*foodGroupPercentages["carbos"]    ).sum(),
                             (fq*foodGroupPercentages["vegefruits"]).sum(),
                             (fq*foodGroupPercentages["drinks"]    ).sum())
}

function calculateTemperature(height)
{
  local season=world.get_season() // 0=winter, 1=spring, 2=summer, 3=autumn
  height+=(season%2?0:2-2*season)
  return 25-(height-persistent.seaLevel)*2
}
function calculateNeededClothes(population, temperature) {return (population/30.0*(1+(30.0-temperature)/40.0)).tointeger()}
function calculateNeededFurniture(nBuildings)            {return nBuildings<25?0:30*(nBuildings-25)}
function calculateNeededPottery(nBuildings)              {return nBuildings<50?0:20*(nBuildings-50)}

function getMaxFactoryProduction(year) {return 20+year-1800}

class City
{
  theCity=null
  factories=null;   factoryErased=false
  attractions=null; attractionErased=false
  nBuildings=0;     height=0.0

                           //        0 1   2    3    4
  function nextTile(previ) // previ [x,y,xmin,xmax,ymax]
  {
    if (previ)
    {
      previ[0]++;
      if (previ[0]>previ[3]) {previ[0]=previ[2]; previ[1]++; return previ[1]<=previ[4]?previ:null}
      return previ
    }
    local nwTile=theCity.get_pos_nw(); local seTile=theCity.get_pos_se()
    if (nwTile.x>seTile.x) {local temp=nwTile.x; nwTile.x=seTile.x; seTile.x=temp}
    if (nwTile.y>seTile.y) {local temp=nwTile.y; nwTile.y=seTile.y; seTile.y=temp}
    previ=[nwTile.x,nwTile.y,nwTile.x,seTile.x,seTile.y]
    if (is_within_limits(previ[0]-1,previ[1]  )) {previ[0]--; previ[2]--}
    if (is_within_limits(previ[0],  previ[1]-1))  previ[1]--
    if (is_within_limits(previ[3]+1,previ[4]  ))  previ[3]++
    if (is_within_limits(previ[3]  ,previ[4]+1))  previ[4]++
    return previ
  }

  bmQuantities=         null // Building material quantities, including built objects
  bmThisMonthQuantities=null // Building materials produced this month
  bmBuiltQuantities=    null // Building materials in built objects
  recalculateBmBuiltQuantities=false

  function clearBmThisMonthQuantities() {bmThisMonthQuantities.clear()}
  function addBmThisMonthQuantity(bm,q) {bmThisMonthQuantities.addQuantity(bm,q)}
  function addBmQuantity(bm,q)          {bmQuantities.addQuantity(bm,q)}
  function getBmQuantity(bm)
  {
    if (recalculateBmBuiltQuantities) calculateBmBuiltQuantities()
    return bmThisMonthQuantities.getQuantity(bm)+bmQuantities.getQuantity(bm)-bmBuiltQuantities.getQuantity(bm)
  }

  foodQuantities         =null // Accumulated food quantities
  foodThisMonthQuantities=null // Food quantities produced this month
  function clearFoodThisMonthQuantities() {foodThisMonthQuantities.clear()}
  function addFoodThisMonthQuantity(f,q)  {foodThisMonthQuantities.addQuantity(f,q)}
  function addFoodQuantity(f,q)           {foodQuantities.addQuantity(f,q)}
  function getRemainingFoodGroupQuantity(f) // Food available minus food needed up to this month's date
  {
    local now=world.get_time()
    local fractionOfMonth=1.0-(now.next_month_ticks.tofloat()-now.ticks)/now.ticks_per_month
    local neededFoodGroup=calculateNeededFoodGroup(theCity.get_citizens()[1])*fractionOfMonth
    return (foodGroupPercentages[f]*(foodThisMonthQuantities+foodQuantities)).sum()-neededFoodGroup.getQuantity(f)
  }

  clothesQuantity=0; clothesThisMonthQuantity=0; neededClothes=0
  function getClothesQuantity() {return clothesQuantity+clothesThisMonthQuantity-neededClothes}
  furnitureQuantity=0; furnitureThisMonthQuantity=0; neededFurniture=0
  function getFurnitureQuantity() {return furnitureQuantity+furnitureThisMonthQuantity-neededFurniture}
  potteryQuantity=0;   potteryThisMonthQuantity=0;   neededPottery=0
  function getPotteryQuantity()   {return potteryQuantity+potteryThisMonthQuantity-neededPottery}

  function setFactoryErased()        {factoryErased       =true; recalculateBmBuiltQuantities=true}
  function setAttractionErased()     {attractionErased    =true; recalculateBmBuiltQuantities=true}
  function setRecalculateBuildings() {                           recalculateBmBuiltQuantities=true}

  function reset() {factories=[]; attractions=[]}
  function updateStatistics()
  {
    clearThisMonthQuantities()
    forAllFactories
    (
      function(f)
      {
        if (f.isEndFactory)
        {
          if (f.consumeBuildingMaterials)
          {
            foreach (bm in buildingMaterialPakNames)
              if (bm in f.theFactory.input)   addBmThisMonthQuantity(bm,f.theFactory.input[bm].get_consumed()[0])
          }
          if (f.consumeFood)
          {
            foreach (food in foodPakNames)
              if (food in f.theFactory.input) addFoodThisMonthQuantity(food,f.theFactory.input[food].get_consumed()[0])
          }
          if (f.consumeClothes)
          {
            clothesThisMonthQuantity+=f.theFactory.input["textile"].get_consumed()[0]
          }
          if (f.consumeFurniture)
          {
            furnitureThisMonthQuantity+=f.theFactory.input["Moebel"].get_consumed()[0]
          }
          if (f.consumePottery)
          {
            if ("hardware" in f.theFactory.input)
              potteryThisMonthQuantity+=f.theFactory.input["hardware"].get_consumed()[0]
            if ("china" in f.theFactory.input)
              potteryThisMonthQuantity+=f.theFactory.input["china"].get_consumed()[0]
          }
        }
      }
    )
  }
  function calculateBmBuiltQuantities()
  {
    recalculateBmBuiltQuantities=false
    bmBuiltQuantities.clear()

    // Factories
    forAllFactories  (@(f) bmBuiltQuantities+=f.materials)

    // Attractions
    forAllAttractions(@(a) bmBuiltQuantities+=a.materials)

    // City buildings and monuments: those that belong to a city in the game
    height=0.0; nBuildings=0
    for (local i=null;i=nextTile(i);)
    {
      local ground=square_x(i[0],i[1]).get_ground_tile()
      local building=ground.find_object(mo_building)
      if (building && building.get_city() &&
          building.get_city().get_pos().x==theCity.get_pos().x &&
          building.get_city().get_pos().y==theCity.get_pos().y)
      {
        bmBuiltQuantities+=neededMaterials(building.get_desc().get_intro_date().year,
                                           building.get_passenger_level())
        height+=ground.z; nBuildings++
      }
    }
    if (nBuildings>0) height/=nBuildings
  }
  function calculateInitialBmQuantities()
  {
     calculateBmBuiltQuantities(); bmQuantities=clone bmBuiltQuantities
  }
  function calculateResetBmQuantities()
  {
     bmQuantities-=bmBuiltQuantities; calculateBmBuiltQuantities(); bmQuantities+=bmBuiltQuantities
  }
  function getShortageBuildingMaterials(year)
  {
    calculateBmBuiltQuantities()
    local bmqp=null
    foreach (y,bmq in buildingMaterialPercentages)
      if (y>=year) bmqp=bmq
    local relevantQuantities=(bmQuantities+bmThisMonthQuantities-bmBuiltQuantities)*bmqp
    local sbm=""; local n=0
    foreach (bmn in buildingMaterialPakNames)
      if (relevantQuantities.getQuantity(bmn)<0)
      {
        n++
        sbm=buildingMaterialNames[bmn]+(n==2?" and ":"")+(n>2?", ":"")+sbm
      }
    return sbm==""?null:sbm
  }

  buildings=0; b1799=0; b1849=0; b1904=0; b1959=0; b1984=0; brest=0

  constructor(c)
  {
    theCity=c;
    bmQuantities=     BuildingMaterialQuantities(); bmThisMonthQuantities=BuildingMaterialQuantities()
    bmBuiltQuantities=BuildingMaterialQuantities()
    foodQuantities=   FoodQuantities();             foodThisMonthQuantities=FoodQuantities()
    neededClothes=calculateNeededClothes(theCity.get_citizens()[0],calculateTemperature(height))
    calculateBuildings()
    neededFurniture=calculateNeededFurniture(buildings); neededPottery=calculateNeededPottery(buildings)
    factories=[]; attractions=[]
  }
  function new_month()
  {
    clearThisMonthQuantities()
    forAllFactories
    (
      function(f)
      {
        if (f.isEndFactory)
        {
          if (f.consumeBuildingMaterials)
          {
            foreach (bm in buildingMaterialPakNames)
              if (bm in f.theFactory.input) addBmQuantity(bm,f.theFactory.input[bm].get_consumed()[1])
          }
          if (f.consumeFood)
          {
            foreach (food in foodPakNames)
              if (food in f.theFactory.input)  addFoodThisMonthQuantity(food,f.theFactory.input[food].get_consumed()[1])
          }
          if (f.consumeClothes)
          {
            clothesThisMonthQuantity+=f.theFactory.input["textile"].get_consumed()[1]
          }
          if (f.consumeFurniture)
          {
            furnitureThisMonthQuantity+=f.theFactory.input["Moebel"].get_consumed()[1]
          }
          if (f.consumePottery)
          {
            if ("hardware" in f.theFactory.input)
              potteryThisMonthQuantity+=f.theFactory.input["hardware"].get_consumed()[1]
            if ("china" in f.theFactory.input)
              potteryThisMonthQuantity+=f.theFactory.input["china"].get_consumed()[1]
          }
        }
      }
    )

    local text=theCity.get_name()+":<br>"
    // Food degradation
    foodQuantities*=preservationPercentages
    foodQuantities+=foodThisMonthQuantities
    text+=" "+translate("foodQuantities")+":"+foodQuantities+"<br>"
    local foodGroupAvailable=calculateFoodGroupQuantities(foodQuantities)
    text+=" "+translate("foodGroupAvailable")+":"+foodGroupAvailable+"<br>"
    local neededFoodGroup=calculateNeededFoodGroup(theCity.get_citizens()[1])
    local firstFoodRatio=null
    for (;;)
    {
      local ratio=1e6
      local chosenKey=null
      text+=" "+translate("neededFoodGroup before")+":"+neededFoodGroup+"<br>"
      foreach (key in foodGroupNames)
        if (neededFoodGroup.data[key]>0 && ratio>foodGroupAvailable.data[key]/neededFoodGroup.data[key])
        {
          ratio=foodGroupAvailable.data[key]/neededFoodGroup.data[key]
          chosenKey=key
        }
      if (firstFoodRatio==null) firstFoodRatio=ratio
      text+=" "+translate("ratio")+"="+ratio+" "+translate("firstFoodRatio")+"="+firstFoodRatio+" "+translate("chosenKey")+"="+chosenKey
      if (chosenKey==null || ratio<=0) break;
      // Subtract consumed food
      local ratioCapped=(ratio>=1?1:ratio)
      text+=" "+translate("ratioCapped")+"="+ratioCapped+"<br>"
      text+=" "+translate("foodGroupPercentages")+"["+chosenKey+"]="+foodGroupPercentages[chosenKey]+"<br>"
      local consumedFoodQuantities=FoodQuantities()
      foreach (key in foodPakNames)
        if (foodGroupPercentages[chosenKey].data[key]>0)
          consumedFoodQuantities[key]=foodQuantities.data[key]*ratioCapped/ratio
      foodQuantities-=consumedFoodQuantities
      text+=" "+translate("foodQuantities after")+":"+foodQuantities+"<br>"
      neededFoodGroup-=calculateFoodGroupQuantities(consumedFoodQuantities)
      text+=" "+translate("neededFoodGroup after")+":"+neededFoodGroup+"<br>"
      foodGroupAvailable=calculateFoodGroupQuantities(foodQuantities)
      text+=" "+translate("foodGroupAvailable")+":"+foodGroupAvailable+"<br>----------------<br>"
    }

    // Clothes degradation and new production
    clothesQuantity=clothesQuantity*0.95+clothesThisMonthQuantity
    local firstClothesRatio=clothesQuantity/neededClothes
    text+=" "+translate("clothesQuantity")+":"+clothesQuantity+" "+translate("firstClothesRatio")+":"+firstClothesRatio+"<br>"

    // Furniture and pottery
    furnitureQuantity+=furnitureThisMonthQuantity
    local firstFurnitureRatio=(neededFurniture>0?furnitureQuantity.tofloat()/neededFurniture:9999.0)
    text+=" "+translate("furnitureQuantity")+":"+furnitureQuantity+" "+translate("neededFurniture")+":"+neededFurniture+
          " "+translate("firstFurnitureRatio")+":"+firstFurnitureRatio+"<br>"
    if (firstFurnitureRatio<1.0) firstFurnitureRatio=1.0 // Don't shrink due to furniture
    potteryQuantity+=potteryThisMonthQuantity
    local firstPotteryRatio=(neededPottery>0?potteryQuantity.tofloat()/neededPottery:9999.0)
    text+=" "+translate("potteryQuantity")+":"+potteryQuantity+" "+translate("firstPotteryRatio")+":"+firstPotteryRatio+"<br>"
    if (firstPotteryRatio<1.0) firstPotteryRatio=1.0 // Don't shrink due to furniture

    // Limit growth/shrink
    local firstRatio=(firstFoodRatio<firstClothesRatio?firstFoodRatio:firstClothesRatio)
    if (firstRatio>firstFurnitureRatio) firstRatio=firstFurnitureRatio
    if (firstRatio>firstPotteryRatio)   firstRatio=firstPotteryRatio
    text+=" "+translate("firstRatio")+":"+firstRatio+"<br>"
    if      (firstRatio>1.1) firstRatio=1.1
    else if (firstRatio<0.8) firstRatio=0.8
    if (firstRatio<1 || firstRatio>1 && theCity.get_citygrowth_enabled())
      theCity.change_size((theCity.get_citizens()[1]*(firstRatio-1)).tointeger())
    neededClothes=calculateNeededClothes(theCity.get_citizens()[0],calculateTemperature(height))
    neededFurniture=calculateNeededFurniture(buildings)
    neededPottery=calculateNeededPottery(buildings)
    text+=" "+translate("neededClothes")+":"+neededClothes+" "+translate("neededFurniture")+":"+neededFurniture+" "+translate("neededPottery")+":"+neededPottery+"<br>"
    //assert(theCity.get_name()!="Helmsley")
  }
  function registerFactory(f)    {  factories.append(f); recalculateBmBuiltQuantities=true}
  function forAllFactories(f)
  {
    if (factoryErased)
    {
      factoryErased=false; for (local key=factories.len()-1;key>=0;--key) if (!factories[key]) factories.remove(key)
    }
    foreach (factory in factories) f.call(this,factory)
  }
  function registerAttraction(a) {attractions.append(a); recalculateBmBuiltQuantities=true}
  function forAllAttractions(f)
  {
    if (attractionErased)
    {
      attractionErased=false; for (local key=attractions.len()-1;key>=0;--key) if (!attractions[key]) attractions.remove(key)
    }
    foreach (a in attractions) f.call(this,a)
  }
  function clearThisMonthQuantities()
   {clearFoodThisMonthQuantities(); clearBmThisMonthQuantities(); clothesThisMonthQuantity=0; furnitureThisMonthQuantity=0;
    potteryThisMonthQuantity=0}
  function calculateBuildings()
  {
   buildings=0; b1799=0; b1849=0; b1904=0; b1959=0; b1984=0; brest=0
   local nwTile=theCity.get_pos_nw(); local seTile=theCity.get_pos_se()
   if (nwTile.x>seTile.x) {local temp=nwTile.x; nwTile.x=seTile.x; seTile.x=temp}
   if (nwTile.y>seTile.y) {local temp=nwTile.y; nwTile.y=seTile.y; seTile.y=temp}
   for (local x=nwTile.x; x<=seTile.x; ++x)
     for (local y=nwTile.y; y<=seTile.y; ++y)
     {
       local mapObject=square_x(x,y).get_ground_tile().find_object(mo_building)
       if (mapObject)
       {
          buildings++
          local introYear=mapObject.get_desc().get_intro_date().year
          if      (introYear<=1799) b1799++
          else if (introYear<=1849) b1849++
          else if (introYear<=1904) b1904++
          else if (introYear<=1959) b1959++
          else if (introYear<=1984) b1984++
          else                      brest++
       }
     }
  }
}


class Factory
{
  theFactory=null
  theBuilding=null
  ownerCity=null
  materials=null
  formattedName=""; cachedName=""
  consumeBuildingMaterials=false; consumeFood=false; consumeClothes=false; consumeFurniture=false; consumePottery=false
  isEndFactory=false
  constructor(f)
  {
    theFactory=f
    theBuilding=square_x(f.x,f.y).get_ground_tile().find_object(mo_building)
    calculateOwnerCity()
    if (f.output.len()==0) isEndFactory=true
    foreach (i in buildingMaterialPakNames)
      if (i in f.input) {consumeBuildingMaterials=true;break}
    foreach (i in foodPakNames)
      if (i in f.input) {consumeFood             =true;break}
    consumeClothes=("textile" in f.input); consumeFurniture=("Moebel" in f.input);
    consumePottery=("hardware" in f.input || "china" in f.input)
    materials=neededMaterials(theBuilding.get_desc().get_intro_date().year,
                              theBuilding.get_passenger_level(),
                              theBuilding.get_desc().get_size(0).x, theBuilding.get_desc().get_size(0).y,
                              theFactory.get_production()[0])
  }
  function calculateOwnerCity()
  {
    ownerCity=null
    local minDistance=1e20
    foreach (city in global.cities)
    {
      local xDistance=city.theCity.x-theFactory.x
      local yDistance=city.theCity.y-theFactory.y
      local d=xDistance*xDistance+yDistance*yDistance
      if (d<minDistance) {minDistance=d; ownerCity=city}
    }
    if (ownerCity) ownerCity.registerFactory(weakref())
  }
  function getOwnerCityName()
  {
    if (ownerCity) return ownerCity.theCity.get_name()
    calculateOwnerCity()
    if (!ownerCity) return "no city"
    return ownerCity.theCity.get_name()
  }
  function getFormattedName()
  {
    if (theFactory.get_name()==cachedName) return formattedName
    cachedName=theFactory.get_name()
    formattedName="<a href='("+theFactory.x+","+theFactory.y+")'>"+approxFormat(cachedName,15)+"</a>"
    return formattedName
  }
}

class Attraction
{
  theAttraction=null
  theBuilding=null
  ownerCity=null
  materials=null
  formattedName=null
  constructor(att)
  {
    theAttraction=att
    theBuilding=square_x(att.x,att.y).get_ground_tile().find_object(mo_building)
    calculateOwnerCity()
    materials=neededMaterials(theBuilding.get_desc().get_intro_date().year,
                              theBuilding.get_passenger_level(),
                              theBuilding.get_desc().get_size(0).x,theBuilding.get_desc().get_size(0).y)
  }
  function calculateOwnerCity()
  {
    ownerCity=null
    local minDistance=1e20
    foreach (city in global.cities)
    {
      local xDistance=city.theCity.x-theBuilding.get_pos().x
      local yDistance=city.theCity.y-theBuilding.get_pos().y
      local d=xDistance*xDistance+yDistance*yDistance
      if (d<minDistance) {minDistance=d; ownerCity=city}
    }
    if (ownerCity) ownerCity.registerAttraction(weakref())
  }
  function getOwnerCityName()
  {
    if (ownerCity) return ownerCity.theCity.get_name()
    calculateOwnerCity()
    if (!ownerCity) return translate("no city")
    return ownerCity.theCity.get_name()
  }
  function ownsCoordinate(c)
  {
    return c[0]>=theAttraction.x && c[0]<theAttraction.x+theBuilding.get_desc().get_size(0).x &&
           c[1]>=theAttraction.y && c[1]<theAttraction.y+theBuilding.get_desc().get_size(0).y
  }
  function getFormattedName()
  {
    if (!formattedName)
      formattedName="<a href='("+theAttraction.x+","+theAttraction.y+")'>"+
                    approxFormat( translate( theBuilding.get_desc().get_name() ),15)+"</a>"
    return formattedName
  }
}
