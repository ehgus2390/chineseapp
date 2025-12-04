// android/app/build.gradle.kts

import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

/* -----------------------------------------------------
   🔐 Signing Properties Load (release / dev fallback)
----------------------------------------------------- */
val signingProperties = Properties()

val releaseKeystore = rootProject.file("key.properties")
val devKeystore = rootProject.file("key.properties.dev")

val activeKeystore = when {
    releaseKeystore.exists() -> releaseKeystore
    devKeystore.exists() -> devKeystore
    else -> null
}

activeKeystore?.inputStream()?.use(signingProperties::load)


android {
    namespace = "com.ant.company"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.ant.company"
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
        multiDexEnabled = true
    }


    /* -----------------------------------------------------
       🔐 signingConfigs — release는 여기서 딱 1번만 생성!
    ----------------------------------------------------- */
    signingConfigs {

        // 기본 debug
        getByName("debug")

        // release 생성 (중복 금지!)
        create("release") {
            if (signingProperties.isNotEmpty()) {
                val storeFilePath = signingProperties.getProperty("storeFile")
                if (!storeFilePath.isNullOrBlank()) {
                    storeFile = file(storeFilePath)
                }
                storePassword = signingProperties.getProperty("storePassword")
                keyAlias = signingProperties.getProperty("keyAlias")
                keyPassword = signingProperties.getProperty("keyPassword")
            } else {
                println("⚠️ key.properties 없음 → release 빌드에 debug 서명 사용")
                initWith(getByName("debug"))
            }
        }
    }

    /* -----------------------------------------------------
       🔨 buildTypes 설정
    ----------------------------------------------------- */
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
}
