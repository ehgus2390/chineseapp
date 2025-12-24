import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

/* -----------------------------------------------------
   🔐 Signing: release → key.properties / key.properties.dev
----------------------------------------------------- */
val signingProps = Properties()

val releaseKey = rootProject.file("key.properties")
val devKey = rootProject.file("key.properties.dev")

val activeKeyFile = when {
    releaseKey.exists() -> releaseKey
    devKey.exists() -> devKey
    else -> null
}

activeKeyFile?.inputStream()?.use(signingProps::load)

android {
    namespace = "com.ant.company"
    compileSdk = 34
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
       🔐 signingConfigs — release는 여기에서 1번만 생성
    ----------------------------------------------------- */
    signingConfigs {
        getByName("debug")

        create("release") {
            if (signingProps.isNotEmpty()) {
                val store = signingProps.getProperty("storeFile")
                if (!store.isNullOrBlank()) {
                    storeFile = file(store)
                }
                storePassword = signingProps.getProperty("storePassword")
                keyAlias = signingProps.getProperty("keyAlias")
                keyPassword = signingProps.getProperty("keyPassword")
            } else {
                println("⚠️ key.properties 없음 → release도 debug 키로 서명됩니다.")
                initWith(getByName("debug"))
            }
        }
    }

    /* -----------------------------------------------------
       🔨 buildTypes (중복 없이 단 하나만)
    ----------------------------------------------------- */
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
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
