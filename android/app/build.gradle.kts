plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.weather"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // Updated NDK version

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        getByName("debug") {
            // Default debug signing config
        }
create("release") {
        storeFile = file("my-release-key.jks")
        storePassword = "suresh"
        keyAlias = "Texas"
        keyPassword = "suresh"
    }
    }

    defaultConfig {
        applicationId = "com.example.weather"
        minSdk = 23 // Updated to 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

buildTypes {
    getByName("release") {
        isMinifyEnabled = true
        isShrinkResources = true
        signingConfig = signingConfigs.getByName("release") // Use release config, not debug
        proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
    }
}
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.1.0"))
    implementation("com.google.firebase:firebase-auth")
}