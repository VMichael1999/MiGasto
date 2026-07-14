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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    val subProject = this
    
    // 1. Immediately patch build.gradle files on disk before they are evaluated by Gradle
    val buildFiles = listOf(
        subProject.file("build.gradle"),
        subProject.file("build.gradle.kts")
    )
    for (file in buildFiles) {
        if (file.exists()) {
            try {
                var content = file.readText()
                val regex = Regex("""(compileSdk(?:Version)?\s*=?\s*)(\d+)""")
                var modified = false
                val newContent = regex.replace(content) { matchResult ->
                    val prefix = matchResult.groups[1]?.value ?: ""
                    val versionStr = matchResult.groups[2]?.value ?: "0"
                    val version = versionStr.toIntOrNull() ?: 0
                    if (version in 1..33) {
                        modified = true
                        "${prefix}34"
                    } else {
                        matchResult.value
                    }
                }
                if (modified) {
                    file.writeText(newContent)
                    subProject.logger.lifecycle("Successfully forced compileSdk to 34 on disk in ${file.absolutePath}")
                }
            } catch (e: Exception) {
                // Ignore
            }
        }
    }

    // 2. Immediately patch AndroidManifest.xml package attribute on disk before AGP evaluates it
    val manifestFile = subProject.file("src/main/AndroidManifest.xml")
    if (manifestFile.exists()) {
        try {
            var content = manifestFile.readText()
            val regex = Regex("""package\s*=\s*["'][^"']*["']""")
            if (regex.containsMatchIn(content)) {
                content = content.replace(regex, "")
                manifestFile.writeText(content)
                subProject.logger.lifecycle("Successfully removed package attribute on disk from manifest for project ${subProject.name}")
            }
        } catch (e: Exception) {
            // Ignore
        }
    }

    // 3. Keep plugins callback to hook missing namespaces dynamically during evaluation
    subProject.plugins.withId("com.android.library") {
        configureAndroidNamespace(subProject)
    }
    subProject.plugins.withId("com.android.application") {
        configureAndroidNamespace(subProject)
    }
}

fun configureAndroidNamespace(project: Project) {
    val android = project.extensions.findByName("android")
    if (android != null) {
        try {
            val getNamespace = android.javaClass.getMethod("getNamespace")
            val namespace = getNamespace.invoke(android)
            if (namespace == null) {
                val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                val fallbackNamespace = "com.example.fallback.${project.name.replace("-", "_").replace(":", "_")}"
                setNamespace.invoke(android, fallbackNamespace)
            }
        } catch (e: Exception) {
            // Ignore if getNamespace/setNamespace are not available
        }
    }
}

