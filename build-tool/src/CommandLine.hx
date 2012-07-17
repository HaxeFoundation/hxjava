package ;

class CommandLine 
{
	//Required: Where to build
	public var target:String;
	public var version:Int;
	
	public function new() 
	{
		
	}
	
	public function process(args:Array<String>, arg:Int = 0)
	{
		var len = args.length;
		this.target = args[arg++];
		while (arg < len)
		{
			switch(args[arg++])
			{
			case "--haxe-version":
				var ver = Std.parseInt(args[arg++]);
				if (ver == null)
					throw Error.BadFormat("--haxe-version", args[arg - 1]);
				this.version = ver;
			default:
				if (arg != len) //seems like haxelib adds an argument at the end
					throw Error.UnknownOption(args[arg - 1]);
			}
		}
	}
	
	public function getOptions()
	{
		return
		' Usage : haxelib run hxjava buildFile.txt [?... options]\n' +
		' Options :\n' +
		'  --haxe-version <version> : sets what baseline haxe version was it compiled with\n';
	}
	
}