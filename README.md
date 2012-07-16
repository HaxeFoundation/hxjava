hxjava
======

Haxe Java support library. Build scripts and support code.

For now there is still only the stub implementations, but the roadmap is that until Haxe 3.0, we will have here:
 - Java standard library externs: once they are ready and tested. For now you may want to check out http://code.google.com/p/haxe-java-extern/ and https://github.com/Dr-Emann/java-haxe-extern-creator (among others). Feel free to fork and provide implementations!
 - JNI-written CFFI compatibility: be able to use unmodified .ndlls (though recompilation is needed) from hxcpp and neko in Java
 - Automatic java build tool: The compiler already calls hxjava haxelib after building all java files; A later version should call the java compiler and build all files automatically.

