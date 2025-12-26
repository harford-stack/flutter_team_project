import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// .env 파일에서 네이버 로그인 인증 정보 읽기
fun loadEnvFile(): Properties {
    val envFile = rootProject.file("../.env")
    val properties = Properties()
    if (envFile.exists()) {
        FileInputStream(envFile).use { properties.load(it) }
    } else {
        println("⚠️  .env 파일을 찾을 수 없습니다. .env.example을 참고하여 .env 파일을 생성하세요.")
        println("⚠️  .env 파일이 없으면 strings.xml의 플레이스홀더 값이 그대로 사용됩니다.")
    }
    return properties
}

val envProperties = loadEnvFile()

// strings.xml 파일의 플레이스홀더를 .env 값으로 치환하는 태스크
tasks.register("replaceStringsXml") {
    doLast {
        val stringsXmlFile = file("src/main/res/values/strings.xml")
        
        if (!stringsXmlFile.exists()) {
            throw GradleException("⚠️  strings.xml 파일을 찾을 수 없습니다: ${stringsXmlFile.absolutePath}")
        }
        
        // .env 파일에서 값 읽기 (없으면 플레이스홀더 그대로 유지)
        val clientId = envProperties.getProperty("NAVER_CLIENT_ID", "@NAVER_CLIENT_ID@")
        val clientSecret = envProperties.getProperty("NAVER_CLIENT_SECRET", "@NAVER_CLIENT_SECRET@")
        val clientName = envProperties.getProperty("NAVER_CLIENT_NAME", "@NAVER_CLIENT_NAME@")
        
        // strings.xml 파일 읽기
        var content = stringsXmlFile.readText()
        
        // 플레이스홀더 치환
        content = content.replace("@NAVER_CLIENT_ID@", clientId)
        content = content.replace("@NAVER_CLIENT_SECRET@", clientSecret)
        content = content.replace("@NAVER_CLIENT_NAME@", clientName)
        
        // 파일에 다시 쓰기
        stringsXmlFile.writeText(content)
        
        if (envProperties.getProperty("NAVER_CLIENT_ID") != null) {
            println("✅ strings.xml의 민감한 값이 .env 파일에서 주입되었습니다.")
        } else {
            println("⚠️  .env 파일이 없어 strings.xml의 플레이스홀더 값이 그대로 사용됩니다.")
        }
    }
}

// 빌드 전에 strings.xml의 플레이스홀더를 .env 값으로 치환
tasks.named("preBuild").configure {
    dependsOn("replaceStringsXml")
}

android {
    namespace = "com.example.flutter_team_project"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.flutter_team_project"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
