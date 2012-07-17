package ;

enum Error
{
	UnknownOption(name:String);
	BadFormat(optionName:String, option:String);
	InexistentInput(path:String);
	NoTarget;
}