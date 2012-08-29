package input;

enum ModuleType
{
	MEnum(path:String);
	MClass(path:String);
}

typedef Data =
{
	var baseDir:String;
	var defines:Hash<Bool>;
	var modules:Array<{ path:String, types:Array<ModuleType> }>;
	var main:Null<String>;
	var resources:Array<String>;
	var libs:Array<String>;
}