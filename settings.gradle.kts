pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "LecCheckKotlin"

include(":shared")
include(":backend")
include(":webApp")
include(":androidApp")
