buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.7.2")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.20")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = file("../build")
subprojects {
    project.buildDir = file("${rootProject.buildDir}/${project.name}")
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}

// PATCH: Forzar namespace en isar_flutter_libs
subprojects {
    afterEvaluate {
        if (project.name == "isar_flutter_libs") {
            val libExtension = project.extensions.findByName("android") as? com.android.build.gradle.LibraryExtension
            libExtension?.namespace = "dev.isar.isar_flutter_libs"
        }
    }
}
