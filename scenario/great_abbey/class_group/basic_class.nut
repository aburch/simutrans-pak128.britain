/*
 *  class: basic_class
 *
 *  by: ny911
 *  Can NOT be used in network game !
 */

/* DESCRIPTION OF THE CLASS

         constructor()
	function is_numeric( str )		[return: bool]
	function leading_zero( number, size )	[return: string]
	function round_up( a, b )		[return: integer]
	function sum( a, b )			[return: integer]	// to use:  [array].reduce( this.sum )
	function time_str( time )		[return: string]	// pretty print time as date
	function pos_to_text( pos )             [return: string]
	function cube_to_text( cube )           [return: string]
         function cord_rotation( pos )           [return: string]	// didn't work in the moment

END OF DESCRIPTION */

class basic_class
{
	month = ["January","February","March","April","May","June","July","August","September","October","November","December"]
	my_space = "<em> </em>"		// to be used with normal space or use (128).tochar()


         constructor()
         {
         }


	function is_numeric( str )
	{
		try { str.tointeger() }
		catch(str) { return false }
		return true
	}


	function leading_zero( number, size )
	{
                 number = number.tostring()
		while (number.len() < size) number = "0" + number
		return number
	}


	function round_up( a, b )
	{
		local c = (a / b).tointeger()
		if (c * b != a) { c++ }
		return c
	}


	function sum( a, b )		       		// to use:  [array].reduce( sum )
	{
		return a + b
	}


	function time_str( time )			//  pretty print time as date
	{
                 local str = ttext("{month} {year}")
                 str.month = ttext( this.month[ time.month ] )
		str.year = time.year
		return str.tostring()
	}


	function pos_to_text( pos )
	{
		return "(" + pos.x + "," + pos.y + "," + pos.z + ")"
         }


	function cube_to_text( cube )
	{
		return this.pos_to_text(cube.nw) + " - " + this.pos_to_text(cube.se)
         }


         function cord_rotation( pos )
	{
// ### Koordinate und rotation bei einer Textanzeige
// http://www.simutrans-forum.de/forum/index.php?page=Thread&postID=92378#post92378
// was ist bei unsymetrischen karten
// east : x=max-1-y   y = x
// south: x=max-1-x   y = max-1-y
	 	return pos			// in the moment return only input parameter pos
	}
}


// END OF FILE