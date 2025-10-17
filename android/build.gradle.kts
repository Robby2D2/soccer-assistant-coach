import org.gradle.api.tasks.compile.JavaCompile
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Ensure all Java/Kotlin compilation uses Java 17 instead of legacy 1.8 to remove
// warnings like: "source value 8 is obsolete". This overrides plugin defaults.
// Removed forced upgrade of Java/Kotlin compilation to 17 to prevent JVM target mismatch with plugins

// Bump any lingering plugin modules still on 1.8 up to Java/Kotlin 11 (safe modern baseline)
subprojects {
    // Restore light-touch adjustments: only raise extremely old targets to 1.8; leave others unchanged.
    tasks.withType<JavaCompile>().configureEach {
        if (sourceCompatibility == "1.6" || sourceCompatibility == "6") sourceCompatibility = "1.8"
    if (targetCompatibility == "1.6" || targetCompatibility == "6") targetCompatibility = "1.8"
    // Suppress warnings about obsolete Java options
    options.compilerArgs.add("-Xlint:-options")
    }
    tasks.withType<KotlinCompile>().configureEach {
        kotlinOptions {
            if (jvmTarget == "1.6") jvmTarget = "1.8"
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
