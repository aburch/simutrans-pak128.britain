echo off

if "%1" == "" goto errore
if "%2" == "" goto errore

echo on

echo creating directory

cd %1
md sound
md text
md config
md scenario
cd ..

echo copying directory

xcopy %2\sound\*.* %1\sound\*.* /s
xcopy %2\text\*.* %1\text\*.* /s
xcopy %2\config\*.* %1\config\*.* /s
xcopy %2\scenario\*.* %1\scenario\*.* /s

echo copying files

copy %2\compat.tab %1\*.*
copy %2\readme.txt %1\*.*
copy %2\licence.txt %1\*.*
copy %2\demo.sve %1\*.*

echo paking - 128

makeobj PAK128 %1/BritAttractions-Ex %2/attractions/
makeobj PAK128 %1/BritBoats-Ex %2/boats/
makeobj PAK128 %1/BritBus-Ex %2/bus/
makeobj PAK128 %1/BritCitybuildings-Ex %2/citybuildings/
makeobj PAK128 %1/BritCitycars-Ex %2/citycars/
makeobj PAK128 %1/BritConfig-Ex %2/config/
makeobj PAK128 %1/BritDepots-Ex %2/depots/
makeobj PAK128 %1/BritGoods-Ex %2/goods/
makeobj PAK128 %1/BritGrounds-Ex %2/grounds/
makeobj PAK128 %1/BritGUI128-Ex %2/gui/gui128/
makeobj PAK128 %1/BritHq-Ex %2/hq/
makeobj PAK128 %1/BritIndustry-Ex %2/industry/
makeobj PAK128 %1/BritLU-Ex %2/london-underground/
makeobj PAK128 %1/BritMaglev-Ex %2/maglev/
makeobj PAK128 %1/BritPedestrians-Ex %2/pedestrians/
makeobj PAK128 %1/BritSmokes-Ex %2/smokes/
makeobj PAK128 %1/BritStations-Ex %2/stations/
makeobj PAK128 %1/BritTownhall-Ex %2/townhall/
makeobj PAK128 %1/BritTrains-Ex %2/trains/
makeobj PAK128 %1/BritTrams-Ex %2/trams/
makeobj PAK128 %1/BritTrees-Ex %2/trees/
makeobj PAK128 %1/BritWays-Ex %2/ways/
makeobj PAK128 %1/BritAir-Ex %2/air/
makeobj PAK128 %1/BritNarrowGauge-Ex %2/narrowgauge/
makeobj PAK128 %1/signalboxes-Ex %2/signalboxes/

echo IMPORTANT NOW PAKING SINGLE FILES -- UPDATE THIS

echo Build ground.Outside.pak

makeobj PAK128 %1/ %2/pak1file/128/

echo paking - 32

makeobj PAK32 %1/Holds256-Ex %2/boats/holds/

echo paking - 64

makeobj PAK64 %1/BritGUI64-Ex %2/gui/gui64/

echo paking - 192

makeobj PAK192 %1/BritBoats192-Ex %2/boats/boats192/
makeobj PAK192 %1/BritAir192-Ex %2/air/air192/

echo paking - 224

makeobj PAK224 %1/BritBoats224-Ex %2/boats/boats224/

echo paking - 256

makeobj PAK256 %1/BritAir256-Ex %2/air/air256/

goto fine

:errore
echo Place pak.bat in a folder with makeobj.exe and the needed dll.
echo Usage PAK pak_dest pak_source
echo Example "PAK pak.britaindest pak.britainsource"
:fine