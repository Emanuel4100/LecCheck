package com.leccheck.backend.service

import com.leccheck.backend.config.AppEnv
import com.leccheck.backend.http.HttpClients
import com.leccheck.backend.model.GoogleUserInfo
import com.leccheck.backend.model.TokenResponse
import io.ktor.client.call.body
import io.ktor.client.request.forms.FormDataContent
import io.ktor.client.request.get
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.http.Parameters

class OAuthService {
    suspend fun exchangeCodeForToken(code: String): TokenResponse {
        return HttpClients.jsonClient.post("https://oauth2.googleapis.com/token") {
            setBody(
                FormDataContent(
                    Parameters.build {
                        append("code", code)
                        append("client_id", AppEnv.googleClientId)
                        append("client_secret", AppEnv.googleClientSecret)
                        append("redirect_uri", AppEnv.redirectUrl)
                        append("grant_type", "authorization_code")
                    }
                )
            )
        }.body()
    }

    suspend fun fetchUserInfo(accessToken: String): GoogleUserInfo {
        return HttpClients.jsonClient.get("https://www.googleapis.com/oauth2/v1/userinfo?alt=json") {
            headers.append("Authorization", "Bearer $accessToken")
        }.body()
    }
}
