package ;
import sys.FileSystem;
import sys.io.File;

class Tools 
{
	public static function copy(from:String, to:String)
	{
		File.saveBytes(to, File.getBytes(from));
	}
	
	public static function copyTree(from:String, to:String)
	{
		if (FileSystem.isDirectory(from))
		{
			if (!FileSystem.exists(to))
			{
				FileSystem.createDirectory(to);
			}
			
			var path = from + "/";
			var pathto = to + "/";
			for (file in FileSystem.readDirectory(from))
			{
				copyTree(path + file, pathto + file);
			}
		} else if (FileSystem.exists(to)) {
			//compare dates
			var lmFrom = FileSystem.stat(from).mtime.getTime();
			var lmTo = FileSystem.stat(to).mtime.getTime();
			if (lmFrom > lmTo)
				copy(from, to);
		} else {
			copy(from, to);
		}
		
		
	}
	
	public static function addPath(basePath:String, path:String)
	{
		//see if path is absolute
		if (path.length == 0)
			return basePath;
		else if (basePath.length == 0)
			basePath = ".";
		
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