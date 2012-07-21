package ;

import input.Reader;
import neko.Lib;
import sys.FileSystem;
import sys.io.File;

/**
 * Java build tool. For now there is only a stub implementation, but
 * an automatic java build tool is intended to be supported.
 * @author waneck
 */

class Main 
{
	
	static function main() 
	{
		var target = null;
		try
		{
			//pre-process args:
			var cmd = new CommandLine();
			var args = Sys.args();
			var last = args[args.length - 1];
			if (last != null && FileSystem.exists(last = last.substr(0,last.length-1))) //was called from haxelib
			{
				Sys.setCwd(last);
				args.pop();
			}
			
			//get options
			cmd.process(args);
			if (cmd.target == null)
				throw Error.NoTarget;
			
			//read input
			if (!FileSystem.exists(target = cmd.target))
				throw Error.InexistentInput(cmd.target);
			var f = File.read(cmd.target);
			var data = new Reader(f).read();
			f.close();
			
			//compile
			#if !target_cs
			new compiler.java.Javac().compile(data);
			#else
			new compiler.cs.CSharpCompiler().compile(data);
			#end
		}
		
		catch (e:Error)
		{
			switch(e)
			{
			case UnknownOption(name):
				Sys.println("Unknown command-line option " + name);
			case BadFormat(optionName, option):
				Sys.println("Unrecognized '" + option + "' value for " + optionName);
			case InexistentInput(path):
				Sys.println("File at path " + path + " not found");
			case NoTarget:
				Sys.println("No target defined");
			}
			
			Sys.println(new CommandLine().getOptions());
			
			Sys.exit(1);
		}
		
		catch (e:input.Error)
		{
			Sys.println("Error when reading input file");
			switch(e)
			{
			case UnmatchedSection(name, expected, lineNum):
				Sys.println(target + " : line " + lineNum + " : Unmatched end section. Expected " + expected + ", got " + name);
			case Unexpected(string, lineNum):
				Sys.println(target + " : line " + lineNum + " : Unexpected " + string);
			}
			Sys.exit(2);
		}
		
		catch (e:compiler.Error)
		{
			Sys.println("Compilation error");
			switch(e)
			{
			case CompilerNotFound:
				Sys.println("Native compiler not found. Please make sure it is installed or its path is set correctly");
			case BuildFailed:
				Sys.println("Native compilation failed");
			}
			Sys.exit(3);
		}
		
	}
}