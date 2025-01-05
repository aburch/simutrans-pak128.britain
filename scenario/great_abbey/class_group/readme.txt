Simutrans Squirrel Scenario Class Group
--------------------------------------------------------------
date    : 01/dec/2014
version : 0.1
author  : ny911
licence : Artistic License
--------------------------------------------------------------

List of all classes with a short introduction. For more
informations about the functions and paramter take a 
look into the files of the class.

basic_class
		This is the pattern class with some very often
		used functions, no useful direct use
basic_scenario
		The main class to run all other classes
		with central output of rule and result text
		for all target classes
		extends the basic_class
basic_supply_chains
		developer informations of industry supply
		chains, internal good names and the amount
		of industrie production input/output
		extends the basic_class


target_class
		pattern for target classes with the minimum 
		of needed functions, no useful direct use
		extends the basic_class
target_connected
		will check if too coord3d are connected for
		a given good (passengers, mail, freight) and 
		minimum/maximum transfers and unhappy people
		extends the target_class
target_factory
		allows useful targets of factory productions
		including 12 month time checks
		extends the target_class
target_finance
		finance check and alls statistc targets like
		transported amount of X
		including 12 month time checks
		extends the target_class
target_hq
		define the level and optional the area where
		the player has to build a headquarter
		extends the target_class
target_linelist
		did a given list of stations have service of
		lines which will have a minimum of different
		stations halts of given waytype and good
		extends the target_class

--------------------------------------------------------------
example scenario using the class group to show the functions,
paramters and allowed values. Take a look into the file
files XXX and YYY
--------------------------------------------------------------