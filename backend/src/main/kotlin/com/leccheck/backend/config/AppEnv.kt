package com.leccheck.backend.config

object AppEnv {
    val googleClientId: String = System.getenv("GOOGLE_CLIENT_ID") ?: ""
    val googleClientSecret: String = System.getenv("GOOGLE_CLIENT_SECRET") ?: ""
    val redirectUrl: String = System.getenv("REDIRECT_URL")
        ?: "http://localhost:8080/api/oauth/callback"
    val frontendUrl: String = System.getenv("FRONTEND_URL")
        ?: "http://localhost:5173"
    val firebaseUrl: String = System.getenv("FIREBASE_URL")
        ?: "https://leccheck-db-default-rtdb.europe-west1.firebasedatabase.app"
}
