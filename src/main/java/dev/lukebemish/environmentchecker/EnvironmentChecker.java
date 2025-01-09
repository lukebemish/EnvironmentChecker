package dev.lukebemish.environmentchecker;

import net.neoforged.fml.ModList;
import net.neoforged.fml.loading.FMLPaths;
import org.objectweb.asm.ClassReader;
import org.objectweb.asm.ClassVisitor;
import org.objectweb.asm.FieldVisitor;
import org.objectweb.asm.MethodVisitor;
import org.objectweb.asm.Opcodes;
import org.slf4j.Logger;

import com.mojang.logging.LogUtils;

import net.neoforged.fml.common.Mod;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.StandardOpenOption;
import java.util.function.Consumer;

@Mod(EnvironmentChecker.MODID)
public class EnvironmentChecker {
    public static final String MODID = "environmentchecker";
    private static final Logger LOGGER = LogUtils.getLogger();
    
    public EnvironmentChecker() {
        LOGGER.info("EnvironmentChecker starting up; dumping current Minecraft class and member names to a file.");
        var targetFile = FMLPaths.GAMEDIR.get().resolve("environmentchecker.txt");
        
        try (var writer = Files.newBufferedWriter(targetFile, StandardOpenOption.CREATE)) {
            var container = ModList.get().getModContainerById("minecraft").orElseThrow();
            var start = container.getModInfo().getOwningFile().getFile().findResource("");
            try (var files = Files.walk(start)) {
                files.forEach(path -> {
                    var relative = start.relativize(path).toString().replace(File.separatorChar, '/');
                    if (relative.endsWith(".class") && (relative.startsWith("net/minecraft/") || relative.startsWith("com/mojang/"))) {
                        try {
                            var data = Files.readAllBytes(path);
                            dumpMembers(str -> {
                                try {
                                    writer.write(str);
                                    writer.newLine();
                                } catch (IOException e) {
                                    throw new RuntimeException(e);
                                }
                            }, data);
                        } catch (IOException e) {
                            throw new RuntimeException(e);
                        }
                    }
                });
            }
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        
        LOGGER.info("EnvironmentChecker finished; dumped class and member names to {}", targetFile);
    }
    
    private static void dumpMembers(Consumer<String> writer, byte[] classFile) {
        var classReader = new ClassReader(classFile);
        var visitor = new ClassVisitor(Opcodes.ASM9) {
            private String className;
            
            @Override
            public void visit(int version, int access, String name, String signature, String superName, String[] interfaces) {
                writer.accept(String.format("class: %s", name));
                className = name;
                super.visit(version, access, name, signature, superName, interfaces);
            }

            @Override
            public MethodVisitor visitMethod(int access, String name, String descriptor, String signature, String[] exceptions) {
                writer.accept(String.format("method: %s.%s%s", className, name, descriptor));
                return super.visitMethod(access, name, descriptor, signature, exceptions);
            }

            @Override
            public FieldVisitor visitField(int access, String name, String descriptor, String signature, Object value) {
                writer.accept(String.format("field: %s.%s:%s", className, name, descriptor));
                return super.visitField(access, name, descriptor, signature, value);
            }
        };
        classReader.accept(visitor, ClassReader.SKIP_CODE | ClassReader.SKIP_DEBUG | ClassReader.SKIP_FRAMES);
    }
}
