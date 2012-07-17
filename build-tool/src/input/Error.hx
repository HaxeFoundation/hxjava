package input;

enum Error
{
	UnmatchedSection(name:String, expected:String, lineNum:Int);
	Unexpected(string:String, lineNum:Int);
}