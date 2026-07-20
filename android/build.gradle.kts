buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.7.2")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.0.21")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = "../build"
subprojects {
    project.buildDir = "${rootProject.buildDir}/${project.name}"
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register("clean", Delete) {
    delete rootProject.buildDir
}

// PATCH: Forzar namespace en isar_flutter_libs
subprojects {
    afterEvaluate {
        if (project.name == "isar_flutter_libs") {
            project.extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.apply {
                namespace = "dev.isar.isar_flutter_libs"
            }
        }
    }
}
