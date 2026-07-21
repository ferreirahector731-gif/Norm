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

// PATCH CORRECTO para isar_flutter_libs (SIN afterEvaluate)
subprojects {
    if (project.name == "isar_flutter_libs") {
        project.plugins.withId("com.android.library") {
            val libExtension = project.extensions.getByName("android") as com.android.build.gradle.LibraryExtension
            libExtension.namespace = "dev.isar.isar_flutter_libs"
        }
    }
}
