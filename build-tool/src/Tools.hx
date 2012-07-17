package ;
import sys.io.File;

class Tools 
{
	public static function copy(from:String, to:String)
	{
		File.saveBytes(to, File.getBytes(from));
	}
}