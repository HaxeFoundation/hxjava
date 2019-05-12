package;

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
			if (sys.FileSystem.exists(dir)) {
				for (file in sys.FileSystem.readDirectory(dir)) {
					final path = haxe.io.Path.join([dir, file]);
					if (!sys.FileSystem.isDirectory(path)) {
						if (path.endsWith(".class")) {
							println('Process $path... ');
							final obj:NativeArray<Int8> = Files.readAllBytes(new File(path).toPath());
							final reader = new ClassReader(obj);
							final writer = new ClassWriter(ClassWriter.COMPUTE_FRAMES);
							final visitor = new MyClassVisitor(writer);

							reader.accept(visitor, 0);

							final stream = new FileOutputStream(path);
							stream.write(writer.toByteArray());
							Sys.sleep(0.001);
						}
					} else {
						process(haxe.io.Path.addTrailingSlash(path));
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

final class MyClassVisitor extends ClassVisitor {
	var isInterface:Bool = false;

	public function new(visitor:ClassVisitor) {
		super(Opcodes_Statics.ASM7, visitor);
	}

	@:overload
	override function visit(version:Int, access:Int, name:String, signature:String, superName:String, interfaces:NativeArray<String>):Void {
		cv.visit(version, access, name, signature, superName, interfaces);
		isInterface = (access & Opcodes_Statics.ACC_INTERFACE) != 0;
	}

	@:overload
	override function visitMethod(access:Int, name:String, desc:String, signature:String, exceptions:NativeArray<String>):MethodVisitor {
		final mv:MethodVisitor = cv.visitMethod(access, name, desc, signature, exceptions);
		if (!isInterface && mv != null && name != "<clinit>") {
			return new MyMethodVisitor(mv);
		}
		return mv;
	}
}

final class MyMethodVisitor extends MethodVisitor {
	final target:MethodVisitor;

	public function new(target:MethodVisitor) {
		super(Opcodes_Statics.ASM7, null);
		this.target = target;
	}

	@:overload
	override function visitCode() {
		target.visitCode();
		// target.visitTypeInsn(Opcodes_Statics.NEW, "java/io/IOException");
		// target.visitInsn(Opcodes_Statics.DUP);
		target.visitMethodInsn(Opcodes_Statics.INVOKESPECIAL, "java/io/IOException", "<init>", "()V", false);
		target.visitInsn(Opcodes_Statics.ATHROW);
		target.visitMaxs(2, 0);
		target.visitEnd();
	}
}
