package compiler.cs;
import compiler.Compiler;
import compiler.Error;
import haxe.io.BytesOutput;
import input.Data;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;

class CSharpCompiler extends Compiler
{
	private var path:String;
	private var compiler:String;
	
	public var version(default, null):Null<Int>;
	public var silverlight(default, null):Bool;
	public var unsafe(default, null):Bool;
	public var debug(default, null):Bool;
	public var dll(default, null):Bool;
	public var name(default, null):String;
	
	public var data(default, null):Data;
	
	public function new() 
	{
		
	}
	
	override public function compile(data:Data):Void
	{
		var delim = Sys.systemName() == "Windows" ? "\\" : "/";
		this.data = data;
		preProcess();
		if (!FileSystem.exists("bin"))
			FileSystem.createDirectory("bin");
		findCompiler();
		writeProject();
		
		
		var args = ['/nologo', '/optimize' + (debug ? '-' : '+'), '/debug' + (debug ? '+' : '-'), '/unsafe' + (unsafe ? '+' : '-'), '/out:bin/' + this.name + "." + (dll ? "dll" : "exe"), '/target:' + (dll ? "library" : "exe") ];
		if (data.main != null)
			args.push('/main:' + (data.main == "Main" ? "EntryPoint__Main" : data.main));
		for (res in data.resources)
			args.push('/res:src' + delim + 'Resources' + delim + res + ",src.Resources." + res);
		for (file in data.modules)
			args.push("src" + delim + file.path.split(".").join(delim) + ".cs");
		
		var ret = 0;
		try
		{
			Sys.println(this.path + this.compiler + " " + args.join(" "));
			ret = Sys.command(this.path + this.compiler + (Sys.systemName() == "Windows" ? (this.compiler == "csc" ? ".exe" : ".bat") : ""), args);
		}
		catch (e:Dynamic)
		{
			throw Error.CompilerNotFound;
		}
		
		if (ret != 0)
			throw Error.BuildFailed;
	}
	
	private function writeProject()
	{
		var bytes = new BytesOutput();
		new CsProjWriter(bytes).write(this);
		
		var bytes = bytes.getBytes();
		if (FileSystem.exists(this.name + ".csproj"))
		{
			if (File.getBytes(this.name + ".csproj").compare(bytes) == 0)
				return;
		}
		
		File.saveBytes(this.name + ".csproj", bytes);
	}
	
	private function findCompiler()
	{
		//if windows look first for MSVC toolchain
		if (Sys.systemName() == "Windows")
			findMsvc();
		
		if (path == null)
		{
			//look for mono
			if (exists("mcs"))
			{
				this.path = "";
				this.compiler = "mcs";
			} else if ((version == null || version <= 20) && exists("gmcs")) {
				this.path = "";
				this.compiler = "gmcs";
			} else if ((version == null || version <= 21 && silverlight) && exists("smcs")) {
				this.path = "";
				this.compiler = "smcs";
			} else if (exists("dmcs")) {
				this.path = "";
				this.compiler = "dmcs";
			}
		}
		
		if (path == null)
		{
			//TODO look for mono path
			throw Error.CompilerNotFound;
		}
	}
	
	private function exists(exe:String):Bool
	{
		if (Sys.systemName() == "Windows")
			return _exists(exe + ".exe") || _exists(exe + ".bat");
		return _exists(exe);
	}
	
	private function _exists(exe:String):Bool
	{
		try
		{
			var cmd = new Process(exe, []);
			cmd.exitCode();
			return true;
		}
		catch (e:Dynamic)
		{
			return false;
		}
	}
	
	private function findMsvc()
	{
		//se if it is in path
		if (exists("csc"))
		{
			this.path = "";
			this.compiler = "csc";
		}
		
		var is64:Bool = neko.Lib.load("std", "sys_is64", 0)();
		var windir = Sys.getEnv("windir");
		if (windir == null)
			windir = "C:\\Windows";
		var path = null;
		
		if (is64)
		{
			path = windir + "\\Microsoft.NET\\Framework64";
		} else {
			path = windir + "\\Microsoft.NET\\Framework";
		}
		
		var foundVer:Null<Float> = null;
		var foundPath = null;
		if (FileSystem.exists(path))
		{
			var regex = ~/v(\d+.\d+)/;
			for (f in FileSystem.readDirectory(path))
			{
				if (regex.match(f))
				{
					var ver = Std.parseFloat(regex.matched(1));
					if (ver != null && (foundVer == null || foundVer < ver))
					{
						if (FileSystem.exists((path + "/" + f + "/csc.exe")))
						{
							foundPath = path + '/' + f;
							foundVer = ver;
						}
					}
				}
			}
		}
		
		if (foundPath != null)
		{
			this.path = foundPath + "/";
			this.compiler = "csc";
		}
	}
	
	
	
	private function preProcess() 
	{
		//get requested version
		var version = null;
		for (ver in [45,40,35,30,21,20])
		{
			if (data.defines.exists("NET_" + ver))
			{
				version = ver;
				break;
			}
		}
		this.version = version;
		
		//get important defined vars
		this.silverlight = data.defines.exists("silverlight");
		this.dll = data.defines.exists("dll");
		this.debug = data.defines.exists("debug");
		this.unsafe = data.defines.exists("unsafe");
		
		//get name
		var name = Sys.getCwd();
		name = name.substr(0, name.length - 1);
		if (name.lastIndexOf("\\") > name.lastIndexOf("/"))
			this.name = name.split("\\").pop();
		else
			this.name = name.split("/").pop();
	}
	
}