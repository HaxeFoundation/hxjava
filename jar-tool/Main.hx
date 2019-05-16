package;

import haxe.io.Path;
import sys.FileSystem;
import java.StdTypes.Int8;
import java.NativeArray;
import java.io.FileOutputStream;
import java.io.File;
import java.nio.file.Files;
import org.objectweb.asm.ClassReader;
import org.objectweb.asm.ClassWriter;
import org.objectweb.asm.ClassVisitor;
import org.objectweb.asm.MethodVisitor;
import org.objectweb.asm.Opcodes.Opcodes_Statics;
import java.Lib.println;

using StringTools;

/**
 * HOW TO USE:
 *
 * 1) Unzip JAR file into some folder. For example "jar_content";
 * 2) Run `java -jar Main.jar jar_content`;
 * 3) Pick up generated `hxjava-std.jar`.
 */
final class Main {
	static function main():Void {
		function process(dir:String) {
			if (FileSystem.exists(dir)) {
				for (file in FileSystem.readDirectory(dir)) {
					final path = Path.join([dir, file]);
					if (!FileSystem.isDirectory(path)) {
						if (path.endsWith(".class")) {
							println('Process $path... ');
							final obj:NativeArray<Int8> = Files.readAllBytes(new File(path).toPath());
							final reader = new ClassReader(obj);
							final writer = new ClassWriter(ClassWriter.COMPUTE_FRAMES | ClassWriter.COMPUTE_MAXS);
							final visitor = new CustomClassVisitor(writer);

							reader.accept(visitor, 0);

							final stream = new FileOutputStream(path);
							stream.write(writer.toByteArray());
						}
					} else {
						process(Path.addTrailingSlash(path));
					}
				}
			} else {
				println('Wrong path. $dir is not exists');
			}
		}

		final args:Array<String> = Sys.args();
		if (args.length > 0) {
			final dir = args[0];
			process(dir);
			println("\nPacking jar...\n");
			if (Sys.command('jar', ["cvf", "hxjava-std.jar", "-C", dir, "."]) == 0) {
				println("\nDone!\n");
			} else {
				println("Oops, something went wrong.");
			}
		}
	}
}

@:nativeGen
class CustomClassVisitor extends ClassVisitor {

	public function new(visitor:ClassVisitor) {
		super(Opcodes_Statics.ASM7, visitor);
	}

	@:overload
	override function visit(version:Int, access:Int, name:String, signature:String, superName:String, interfaces:NativeArray<String>):Void {
		cv.visit(version, access, name, signature, superName, interfaces);
	}

	/**
	 * Starts the visit of the method's code, if any (i.e. non abstract method).
	 */
	@:overload
	override function visitMethod(access:Int, name:String, desc:String, signature:String, exceptions:NativeArray<String>):MethodVisitor {
		final mv:MethodVisitor = cv.visitMethod(access, name, desc, signature, exceptions);
		if (mv != null) {
			return new CustomMethodVisitor(mv);
		}
		return mv;
	}
}

@:nativeGen
class CustomMethodVisitor extends MethodVisitor {
	final target:MethodVisitor;

	public function new(target:MethodVisitor) {
		super(Opcodes_Statics.ASM7, null);
		this.target = target;
	}

	@:overload
	override function visitCode() {
		target.visitCode();
		target.visitMaxs(0, 0);
		target.visitEnd();
	}
}
