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
subprojects {
    tasks.withType<JavaCompile>().configureEach {
        if (sourceCompatibility == "1.8" || sourceCompatibility == "8") {
            sourceCompatibility = "17"
        }
        if (targetCompatibility == "1.8" || targetCompatibility == "8") {
            targetCompatibility = "17"
        }
        // Do NOT set options.release here; Android Gradle Plugin manages bootclasspath.
    }
    tasks.withType<KotlinCompile>().configureEach {
        kotlinOptions {
            if (jvmTarget == "1.8" || jvmTarget == "8") {
                jvmTarget = "17"
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
