package ;
import sys.io.File;

class Tools 
{
	public static function copy(from:String, to:String)
	{
		File.saveBytes(to, File.getBytes(from));
	}
	
	public static function addPath(basePath:String, path:String)
	{
		//see if path is absolute
		if (path.length == 0)
			return basePath;
		switch(path.charCodeAt(0))
		{
		case 
			'/'.code, //unix absolute 
			'\\'.code: //windows newtork absolute
				
				return path;
		default:
			if (path.charCodeAt(1) == ':'.code) //windows absolute
				return path;
			return basePath + "/" + path;
		}
	}
}