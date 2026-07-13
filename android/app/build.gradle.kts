plugins {
    id("com.android.application")
    id("kotlin-android")
    id("org.jetbrains.kotlin.plugin.compose")
}

val versionName: String = File(rootProject.projectDir.parentFile, "version.txt")
    .takeIf { it.exists() }?.readText()?.trim()?.ifBlank { "0.0.0" } ?: "0.0.0"
val versionCode: Int = versionName.split(".").let { p ->
    (p.getOrNull(0)?.toIntOrNull() ?: 0) * 10000 +
    (p.getOrNull(1)?.toIntOrNull() ?: 0) * 100 +
    (p.getOrNull(2)?.toIntOrNull() ?: 0)
}

android {
    namespace = "com.death.countdown"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.death.countdown"
        minSdk = 27
        targetSdk = 36
        this.versionCode = versionCode
        this.versionName = versionName
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
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

    buildFeatures {
        compose = true
        buildConfig = true
    }

    packaging {
        resources.excludes += "/META-INF/{AL2.0,LGPL2.1}"
    }
}

dependencies {
    implementation(platform("androidx.compose:compose-bom:2026.05.01"))
    implementation("androidx.activity:activity-compose:1.13.0")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.core:core-ktx:1.18.0")
    implementation("androidx.datastore:datastore-preferences:1.1.7")
}
