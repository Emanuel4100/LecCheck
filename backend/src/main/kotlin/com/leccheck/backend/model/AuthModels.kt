package com.leccheck.backend.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class TokenResponse(
    @SerialName("access_token")
    val accessToken: String,
    @SerialName("id_token")
    val idToken: String? = null,
    @SerialName("token_type")
    val tokenType: String? = null,
    @SerialName("expires_in")
    val expiresIn: Int? = null,
    @SerialName("refresh_token")
    val refreshToken: String? = null,
    val scope: String? = null
)

@Serializable
data class GoogleUserInfo(
    val id: String,
    val email: String? = null,
    val name: String? = null,
    val picture: String? = null
)

@Serializable
data class AuthSessionResponse(
    val userId: String,
    val email: String? = null,
    val name: String? = null
)
