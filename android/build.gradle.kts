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

// PATCH: Forzar namespace y compileSdk en isar_flutter_libs
subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.gradle.LibraryExtension> {
            namespace = "dev.isar.isar_flutter_libs"
        }
        extensions.findByType(com.android.build.api.variant.AndroidComponentsExtension::class.java)
            ?.finalizeDsl { extension ->
                extension.compileSdk = 36
            }
    }
}
