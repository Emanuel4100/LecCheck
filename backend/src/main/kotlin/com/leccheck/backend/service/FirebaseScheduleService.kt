package com.leccheck.backend.service

import com.leccheck.backend.config.AppEnv
import com.leccheck.backend.http.HttpClients
import io.ktor.client.call.body
import io.ktor.client.request.get
import io.ktor.client.request.put
import io.ktor.client.request.setBody
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.contentType
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull

class FirebaseScheduleService {
    private val json = Json { ignoreUnknownKeys = true }

    suspend fun getSchedule(userId: String): JsonElement? {
        val response = HttpClients.jsonClient.get(firebasePath(userId))
        val text = response.bodyAsText()
        val parsed = json.parseToJsonElement(text)
        return if (parsed is JsonNull) null else parsed
    }

    suspend fun putSchedule(userId: String, schedule: JsonElement): JsonElement {
        val response = HttpClients.jsonClient.put(firebasePath(userId)) {
            contentType(ContentType.Application.Json)
            setBody(schedule)
        }
        return response.body()
    }

    private fun firebasePath(userId: String): String =
        "${AppEnv.firebaseUrl}/users/$userId/schedule.json"
}
