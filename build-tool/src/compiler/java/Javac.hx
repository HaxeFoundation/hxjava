package compiler.java;
import haxe.io.Path;
import input.Data;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;

using Lambda;

class Javac extends Compiler
{
	var path:String;
	var cmd:CommandLine;

	public function new(cmd:CommandLine)
	{
		this.cmd = cmd;
	}

	@:access(haxe.io.Path.escape)
	override public function compile(data:Data):Void
	{
		var name = if (data.main != null)
		{
			var idx = data.main.lastIndexOf(".");
			if (idx != -1)
				data.main.substr(idx + 1);
			else
				data.main;
		}
		else
		{
			var name = Sys.getCwd();
			name = name.substr(0, name.length - 1);
			if (name.lastIndexOf("\\") > name.lastIndexOf("/"))
				name = name.split("\\").pop();
			else
				name = name.split("/").pop();
		}
		if (data.defines.exists("debug"))
			name += "-Debug";

		if (cmd.output == null)
		{
			cmd.output = name;
		} else {
			cmd.output = Tools.addPath(data.baseDir, cmd.output);
		}

		if (!FileSystem.exists("obj"))
			FileSystem.createDirectory("obj");
		var params = ["-sourcepath", "src", "-d", "obj"];
		//handle parameters
		changeParams(data, params);

		//android sane defaults
		if (data.defines.exists("java-android")) {
			if (data.opts.indexOf('-source') < 0)
			{
				params.push('-source'); params.push('1.5');
			}
			if (data.opts.indexOf('-target') < 0)
			{
				params.push('-target'); params.push('1.5');
			}
		}

		for (opt in data.opts)
			params.push(opt);

		var outFile = null;
		if (!data.defines.exists("LONG_COMMAND_LINE"))
		{
			outFile = sys.io.File.write("cmd");
			params.push("@cmd");
		}
		//add main target
		for (module in data.modules)
		{
			for (t in module.types)
			{
				switch(t)
				{
					case MEnum(p), MClass(p):
						var path = "src/" + p.split(".").join("/") + ".java";
						if (outFile != null)
							outFile.writeString(path + "\n");
						else
							params.push(path);
				}
			}
		}

		if (outFile != null)
			outFile.close();
		callJavac(params);

		//now copy the resources if any
		for (res in data.resources)
		{
			res = haxe.io.Path.escape(res, true);
			var targetPath = "obj/" + res;
			var targetDir = Path.directory(targetPath);
			if (!FileSystem.exists(targetDir))
				FileSystem.createDirectory(targetDir);
			Tools.copy("src/" + res, targetPath);
		}

		makeJar(data);
	}

	function changeParams(data:Data, params:Array<String>)
	{
		if (data.defines.exists("debug"))
			params.push("-g");
		else
			params.push("-g:none");

		var libdir = Tools.addPath(Path.directory(cmd.output), "lib");
		if (data.libs.length > 0 && !FileSystem.exists(libdir))
		{
			FileSystem.createDirectory(libdir);
		}


		if (data.libs != null && data.libs.length > 0)
		{
			params.push("-classpath");
			params.push(libdir + "/*");
			for (lib in data.libs)
			{
				Tools.copyTree(
						Tools.addPath(data.baseDir, lib), libdir + "/" + Path.withoutDirectory(lib)
						);
			}
		}

	}

	function makeJar(data:Data)
	{
		try
		{
			var contents = new StringBuf();

			if (data.main != null)
			{
				contents.add("Main-Class: " + data.main + "\n");
			}
			if (data.libs.length > 0)
			{
				contents.add("Class-Path:");
				for (lib in data.libs)
				{
					contents.add(" lib/" + Path.withoutDirectory(lib) + " \n");
				}
			}

			var c = contents.toString();
			if (c.length != 0)
			{
				File.saveContent("manifest", c);
				Sys.command(path + "jar", ["cmf", "manifest", this.cmd.output + ".jar", "-C", "obj/", "."]);
			} else {
				Sys.command(path + "jar", ["cf", this.cmd.output + ".jar", "-C", "obj/", "."]);
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
			{
				path = tryPath(home);
				if (path == null)
					path = tryPath(home + "/bin/");
			}

		}

		if (path == null)
		{
			if (Sys.systemName() == "Windows")
			{
				var pfiles = [Sys.getEnv("ProgramFiles")];
				if (pfiles[0] == null) {
					pfiles[0] = "C:\\Program Files";
				} else {
					var pf = Sys.getEnv("ProgramFiles(x86)");
					if (pf != null && pf == pfiles[0])
					{
						pfiles[1] = pf.split(" (x86)")[0];
					}
				}

				for (pfile in pfiles)
				{
					var java = pfile + "\\java";

					if (FileSystem.exists(java) && FileSystem.isDirectory(java))
					{
						var regex = ~/jdk(\d+\.)+/;
						var bestPath = null;
						for (file in FileSystem.readDirectory(java))
						{
							if (regex.match(file))
							{
								var p = regex.matched(1).split(".").map(function(v):Int return Std.parseInt(v));
								if (bestPath == null || isMostRecent(p, bestPath))
								{
									path = tryPath(java + '\\' + file + '\\bin\\');
									bestPath = p;
								}
							}
						}
					}
				}

			}
		}

		if (path == null)
		{
			throw Error.CompilerNotFound;
		}

		var suffix = if (Sys.systemName() == "Windows") ".exe" else "";
		Sys.println(path + "javac" + suffix + ' "' + params.join('" "') + '"');
		var ret = Sys.command(path + "javac" + suffix, params);

		if (ret != 0)
			throw Error.BuildFailed;
	}

	static function isMostRecent(base:Array<Int>, than:Array<Int>)
	{
		var b = base.iterator();
		var t = than.iterator();

		while (b.hasNext() && t.hasNext())
		{
			var b = b.next();
			var t = t.next();
			if (b < t)
				return false;
		}

		return true;
	}

	function tryPath(path:String):String
	{
		var suffix = if (Sys.systemName() == "Windows") ".exe" else "";
		try
		{
			var exe = path + 'javac' + suffix;

			var cmd = new Process(exe, ["-help"]);
			var ret = cmd.exitCode();
			if (ret == 0)
				return path;
		}
		catch (e:Dynamic) { }

		return null;
	}

}
