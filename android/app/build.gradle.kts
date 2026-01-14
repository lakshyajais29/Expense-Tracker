plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.mukhla.splitw"
    compileSdk = 36  // ← CHANGED to 36
    ndkVersion = "27.0.12077973"  // ← CHANGED to 27

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"  // ← SIMPLIFIED (use old syntax)
    }

    defaultConfig {
        applicationId = "com.mukhla.splitw"
        minSdk = flutter.minSdkVersion  // ← HARDCODED
        targetSdk = 36  // ← CHANGED to 36
        versionCode = 1
        versionName = "1.0.0"
        multiDexEnabled = true  // ← ADD THIS
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")  // ← ADD THIS
}
