import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Charger les propriétés du keystore
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.synergydev.music_box"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.synergydev.music_box"
        minSdk = 24  // Android 7.0 - Stable pour toutes les features
        targetSdk = 34
        versionCode = flutter.versionCode?.toInt() ?: 1
        versionName = flutter.versionName ?: "1.0"
    }

    signingConfigs {
        create("release") {
            // ✅ Vérifier que TOUTES les propriétés existent
            val alias = keystoreProperties.getProperty("keyAlias")
            val keyPass = keystoreProperties.getProperty("keyPassword")
            val storePath = keystoreProperties.getProperty("storeFile")
            val storePass = keystoreProperties.getProperty("storePassword")
            
            if (alias != null && keyPass != null && storePath != null && storePass != null) {
                keyAlias = alias
                keyPassword = keyPass
                storeFile = file(storePath)
                storePassword = storePass
            }
        }
    }

    buildTypes {
        release {
            // ✅ ProGuard DÉSACTIVÉ - cause des problèmes avec audio_service
            isMinifyEnabled = false
            isShrinkResources = false
            // ✅ Utiliser la signature release seulement si le keystore est complet
            val hasCompleteKeystore = keystoreProperties.getProperty("keyAlias") != null &&
                                      keystoreProperties.getProperty("keyPassword") != null &&
                                      keystoreProperties.getProperty("storeFile") != null &&
                                      keystoreProperties.getProperty("storePassword") != null
            
            signingConfig = if (hasCompleteKeystore) {
                signingConfigs.getByName("release")
            } else {
                // Utiliser debug pour dev (keystore pas nécessaire)
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.activity:activity-ktx:1.9.3")
    implementation("com.mpatric:mp3agic:0.9.1")
    
    // Firebase
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))
    implementation("com.google.firebase:firebase-analytics")
}
