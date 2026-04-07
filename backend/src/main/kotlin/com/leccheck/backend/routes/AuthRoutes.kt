package com.leccheck.backend.routes

import com.leccheck.backend.config.AppEnv
import com.leccheck.backend.model.AuthSessionResponse
import com.leccheck.backend.service.OAuthService
import io.ktor.http.HttpStatusCode
import io.ktor.server.application.call
import io.ktor.server.response.respond
import io.ktor.server.response.respondRedirect
import io.ktor.server.routing.Route
import io.ktor.server.routing.get
import io.ktor.server.routing.route
import java.net.URLEncoder
import java.nio.charset.StandardCharsets
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

private val authService = OAuthService()
private val sessionStore = ConcurrentHashMap<String, AuthSessionResponse>()

fun Route.authRoutes() {
    route("/api/oauth") {
        get("/redirect") {
            if (AppEnv.googleClientId.isBlank() || AppEnv.googleClientSecret.isBlank()) {
                call.respond(HttpStatusCode.InternalServerError, mapOf("error" to "Missing Google OAuth env vars"))
                return@get
            }
            val state = UUID.randomUUID().toString()
            val scope = urlEncode("openid email profile")
            val redirectUri = urlEncode(AppEnv.redirectUrl)
            val authUrl = "https://accounts.google.com/o/oauth2/v2/auth" +
                "?client_id=${urlEncode(AppEnv.googleClientId)}" +
                "&redirect_uri=$redirectUri" +
                "&response_type=code" +
                "&scope=$scope" +
                "&access_type=offline" +
                "&prompt=consent" +
                "&state=$state"
            call.respondRedirect(authUrl)
        }

        get("/callback") {
            val code = call.request.queryParameters["code"]
            if (code.isNullOrBlank()) {
                call.respond(HttpStatusCode.BadRequest, mapOf("error" to "Missing code query parameter"))
                return@get
            }

            val token = authService.exchangeCodeForToken(code)
            val user = authService.fetchUserInfo(token.accessToken)
            val sessionId = UUID.randomUUID().toString()
            sessionStore[sessionId] = AuthSessionResponse(
                userId = user.id,
                email = user.email,
                name = user.name
            )

            val returnUrl = "${AppEnv.frontendUrl}/?session_id=${urlEncode(sessionId)}"
            call.respondRedirect(returnUrl)
        }
    }

    get("/api/auth/session/{sessionId}") {
        val sessionId = call.parameters["sessionId"]
        if (sessionId.isNullOrBlank()) {
            call.respond(HttpStatusCode.BadRequest, mapOf("error" to "Missing session id"))
            return@get
        }

        val session = sessionStore[sessionId]
        if (session == null) {
            call.respond(HttpStatusCode.NotFound, mapOf("error" to "Session not found"))
            return@get
        }

        call.respond(session)
    }
}

private fun urlEncode(value: String): String = URLEncoder.encode(value, StandardCharsets.UTF_8)
