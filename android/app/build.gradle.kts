plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.nota_ia_app"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.nota_ia_app"
        minSdk = 21
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    androidResources {
        noCompress = listOf("tflite")
    }

    packagingOptions {
        resources {
            excludes += "META-INF/*"
        }
    }
}

flutter {
    source = "../.."
}

tasks.register("patchIsarManifest") {
    doLast {
        val manifestFile = file("build/intermediates/merged_manifests/release/AndroidManifest.xml")
        if (manifestFile.exists()) {
            val content = manifestFile.readText()
            val patched = content.replace("""package="dev.isar.isar_flutter_libs"""", "")
            manifestFile.writeText(patched)
            println("Patched package attribute in merged manifest")
        }
    }
}
tasks.named("processReleaseManifest") {
    dependsOn("patchIsarManifest")
}
