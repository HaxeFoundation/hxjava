package compiler;
import input.Data;
import sys.FileSystem;
import sys.io.File;

class Javac extends Compiler
{
	var name:String;
	var path:String;
	
	public function new() 
	{
		
	}
	
	override public function compile(data:Data):Void
	{
		var name = Sys.getCwd();
		name = name.substr(0, name.length - 1);
		if (name.lastIndexOf("\\") > name.lastIndexOf("/"))
			this.name = name.split("\\").pop();
		else
			this.name = name.split("/").pop();
		
		if (!FileSystem.exists("obj"))
			FileSystem.createDirectory("obj");
		var params = ["-sourcepath", "src", "-classpath", "obj", "-d", "obj"];
		//handle parameters
		changeParams(data, params);
		//add main target
		params.push("src/" + data.main.split(".").join("/") + ".java");
		callJavac(params);
		//now copy the resources if any
		for (res in FileSystem.readDirectory("src"))
		{
			if (!FileSystem.isDirectory("src/" + res))
				Tools.copy("src/" + res, "obj/" + res);
		}
		
		makeJar(data);
	}
	
	function changeParams(data:Data, params:Array<String>)
	{
		if (data.defines.exists("debug"))
			params.push("-g");
		else
			params.push("-g:none");
	}
	
	function makeJar(data:Data)
	{
		try
		{
			if (data.main != null)
			{
				File.saveContent("mainClass", "Main-Class: " + data.main + "\n\r");
				Sys.command(path + "jar", ["cmf", "mainClass", this.name + ".jar", "-C", "obj/", "."]);
			} else {
				Sys.command(path + "jar", ["cf", this.name + ".jar", "-C", "obj/", "."]);
			}
		}
		catch (e:Dynamic)
		{
			Sys.println("Could not find jar packaging");
		}
	}
	
	function callJavac(params:Array<String>)
	{
		path = tryPath("");
		if (path == null)
		{
			var home = Sys.getEnv("JAVA_HOME");
			if (home != null)
				path = tryPath(home);
		}
		
		if (path == null)
		{
			if (Sys.systemName() == "Windows")
				path = tryPath("C:\\Program Files\\java\\jdk1.7.0\\bin\\");
		}
		
		if (path == null)
		{
			throw Error.CompilerNotFound;
		}
		
		var suffix = if (Sys.systemName() == "Windows") ".exe" else "";
		var ret = Sys.command(path + "javac" + suffix, params);
		
		if (ret != 0)
			throw Error.BuildFailed;
	}
	
	function tryPath(path:String):String
	{
		var suffix = if (Sys.systemName() == "Windows") ".exe" else "";
		try
		{
			var ret = Sys.command(path + "javac" + suffix, ["-version"]);
			if (ret == 0)
				return path;
		}
		catch (e:Dynamic) { }
		
		return null;
	}
	
}