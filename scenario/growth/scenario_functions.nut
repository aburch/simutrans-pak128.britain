/*
 * Growth scenario  - file for special functions
 *
 */

function abs(x)
{
	return x<0?-x:x
}


randSeed <- 6969
function rand(...)
{
	randSeed = ((1103515245*randSeed+12345)&0x7FFFFFFF)
	if (vargv.len() == 0 )
		return randSeed;
	return (randSeed/4)%vargv[0]
}


function is_within_limits(xx,yy)
{
	return world.is_coord_valid({x=xx,y=yy})
}


function fN(n) // Format number
{
	if (n>  9999) return "^^^^"
	if (n>= 0)    return format("%04.0f",n)
	if (n>=-9999) return format("<st>%04.0f</st>",-n)
	return "<st>vvvv</st>"
}

                              //        0 1
function nextWorldTile(previ) // previ [x,y]
{
	if (previ)
	{
		previ[0]++
		if (!is_within_limits(previ[0],previ[1]))
		{
			previ[0]=0; previ[1]++;
			return is_within_limits(previ[0],previ[1])?previ:null
		}
		return previ
	}
	return [0,0]
}


function my_translate(text)
{
         if (text != "") text = translate(text)		// don't translate empty string
 	return text
}


function approxFormat(s,n)
{
  local l=0
  local nChars=0
  foreach (c in s)
  {
    if (c>32 && c<128)
      l+="47878745587463775777777774476779777766775676877777777797775757647777757735639777747577967653575".slice(c-33,c-32).tointeger()
    else l+=7
    if (l>n*7) return s.slice(0,nChars)
    nChars++
  }
  for (local i=0; i<7*n-l; i+=10) s+="<st> </st>"
  return s
}


function isCoalPossible(ground)
{
  return ground.z<=global.climateHeights["rocky"] && ground.z>global.climateHeights["temperate"] && !ground.is_water()
}

function isIronPossible(ground)
{
  return ground.z<=global.climateHeights["tundra"] && ground.z>global.climateHeights["desert"] && !ground.is_water()
}

function isOilPossible(ground)
{
  return ground.z<=global.climateHeights["mediterranean"]
}

function isClayPossible(ground)
{
  return isOilPossible(ground) && !ground.is_water()
}

function isStonePossible(ground)
{
  return ground.z<=global.climateHeights["rocky"] && ground.z>global.climateHeights["tundra"] && !ground.is_water()
}
function getWoodMaxProduction(ground)
{
  if (ground.is_water() || ground.z<=global.climateHeights["desert"] || ground.z>global.climateHeights["rocky"]) return 0
  local nTrees=0
  foreach (o in ground.get_objects()) if (o.get_type()==mo_tree) nTrees++
  return 50*nTrees
}
function getGrainMaxProduction(ground)
{
  if (ground.is_water() || ground.z<=global.climateHeights["tropic"] || ground.z>global.climateHeights["rocky"]) return 0
  local p=1000-150*abs(global.climateHeights["temperate"]-ground.z)
  return p>0?p:0
}
function getVegetablesMaxProduction(ground)
{
  if (ground.is_water() || ground.z<=global.climateHeights["tropic"] || ground.z>global.climateHeights["tundra"]) return 0
  local p=200-100*abs(global.climateHeights["temperate"]-ground.z)
  return p>0?p:0
}
function getFruitMaxProduction(ground)
{
  if (ground.is_water() || ground.z<=global.climateHeights["water"] || ground.z>global.climateHeights["rocky"]) return 0
  local p=400-50*abs(global.climateHeights["mediterranean"]-ground.z)
  return p>0?p:0
}
function getCattleMaxProduction(ground)
{
  if (ground.is_water() || ground.z<=global.climateHeights["tropic"] || ground.z>global.climateHeights["rocky"]) return 0
  local p=500-100*abs(global.climateHeights["temperate"]-ground.z)
  return p>0?p:0
}
function getSheepMaxProduction(ground)
{
  if (ground.is_water() || ground.z<=global.climateHeights["tropic"] || ground.z>global.climateHeights["tundra"]) return 0
  local p=500-100*abs(global.climateHeights["mediterranean"]-ground.z)
  return p>0?p:0
}


function getFreshFishMaxProduction(ground)
{
  // TODO: better if I knew water depth
  if (!ground.is_water()) return 0
  if (cachedFreshFishProductionPos && cachedFreshFishProductionPos.x==ground.x && cachedFreshFishProductionPos.y==ground.y)
    return cachedFreshFishProduction
  local d
  for (d=1; d<=25; ++d)
  {
    if (!is_within_limits(ground.x+d,ground.y  ) || !tile_x(ground.x+d,ground.y  ,persistent.seaLevel).is_water()) break;
    if (!is_within_limits(ground.x-d,ground.y  ) || !tile_x(ground.x-d,ground.y  ,persistent.seaLevel).is_water()) break;
    if (!is_within_limits(ground.x  ,ground.y+d) || !tile_x(ground.x,  ground.y+d,persistent.seaLevel).is_water()) break;
    if (!is_within_limits(ground.x  ,ground.y-d) || !tile_x(ground.x,  ground.y-d,persistent.seaLevel).is_water()) break;
    if (!is_within_limits(ground.x+d,ground.y+d) || !tile_x(ground.x+d,ground.y+d,persistent.seaLevel).is_water()) break;
    if (!is_within_limits(ground.x+d,ground.y-d) || !tile_x(ground.x+d,ground.y-d,persistent.seaLevel).is_water()) break;
    if (!is_within_limits(ground.x-d,ground.y+d) || !tile_x(ground.x-d,ground.y+d,persistent.seaLevel).is_water()) break;
    if (!is_within_limits(ground.x-d,ground.y-d) || !tile_x(ground.x-d,ground.y-d,persistent.seaLevel).is_water()) break;
  }
  local p=500+(d-25)*40
  cachedFreshFishProductionPos=ground
  return cachedFreshFishProduction=(p>0?p:0)
}
