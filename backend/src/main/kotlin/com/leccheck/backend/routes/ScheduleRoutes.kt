package com.leccheck.backend.routes

import com.leccheck.backend.service.FirebaseScheduleService
import io.ktor.http.HttpStatusCode
import io.ktor.server.application.call
import io.ktor.server.request.receive
import io.ktor.server.response.respond
import io.ktor.server.routing.Route
import io.ktor.server.routing.get
import io.ktor.server.routing.put
import io.ktor.server.routing.route
import kotlinx.serialization.json.JsonElement

private val scheduleService = FirebaseScheduleService()

fun Route.scheduleRoutes() {
    route("/api/users/{userId}/schedule") {
        get {
            val userId = call.parameters["userId"]
            if (userId.isNullOrBlank()) {
                call.respond(HttpStatusCode.BadRequest, mapOf("error" to "Missing user id"))
                return@get
            }

            val schedule = scheduleService.getSchedule(userId)
            if (schedule == null) {
                call.respond(HttpStatusCode.NotFound, mapOf("error" to "No schedule found"))
                return@get
            }

            call.respond(schedule)
        }

        put {
            val userId = call.parameters["userId"]
            if (userId.isNullOrBlank()) {
                call.respond(HttpStatusCode.BadRequest, mapOf("error" to "Missing user id"))
                return@put
            }

            val body = call.receive<JsonElement>()
            scheduleService.putSchedule(userId, body)
            call.respond(HttpStatusCode.OK, mapOf("message" to "Schedule saved"))
        }
    }
}
