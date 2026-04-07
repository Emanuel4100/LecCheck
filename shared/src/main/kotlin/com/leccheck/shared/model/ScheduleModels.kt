package com.leccheck.shared.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class SemesterSchedule(
    val language: String = "he",
    @SerialName("semester_start")
    val semesterStart: String? = null,
    @SerialName("semester_end")
    val semesterEnd: String? = null,
    @SerialName("show_weekend")
    val showWeekend: Boolean = false,
    @SerialName("enable_meeting_numbers")
    val enableMeetingNumbers: Boolean = true,
    val courses: List<Course> = emptyList()
)

@Serializable
data class Course(
    @SerialName("course_id")
    val courseId: String,
    val title: String,
    val lecturer: String = "",
    @SerialName("course_code")
    val courseCode: String = "",
    val link: String = "",
    val color: String = "surfaceVariant",
    val meetings: List<MeetingRule> = emptyList(),
    val lectures: List<LectureSession> = emptyList()
)

@Serializable
data class MeetingRule(
    @SerialName("day_name")
    val dayName: String,
    @SerialName("start_time")
    val startTime: String,
    @SerialName("end_time")
    val endTime: String,
    val location: String = "",
    @SerialName("meeting_type")
    val meetingType: String = "meeting_types.lecture"
)

@Serializable
data class LectureSession(
    @SerialName("session_id")
    val sessionId: String,
    val title: String,
    val lecturer: String = "",
    @SerialName("date_str")
    val dateStr: String,
    @SerialName("start_time")
    val startTime: String = "",
    @SerialName("end_time")
    val endTime: String = "",
    @SerialName("duration_mins")
    val durationMins: Int? = null,
    val room: String = "",
    val status: String = "status.needs_watching",
    @SerialName("course_color")
    val courseColor: String = "surfaceVariant",
    @SerialName("is_one_off")
    val isOneOff: Boolean = false,
    @SerialName("meeting_number")
    val meetingNumber: Int? = null,
    @SerialName("external_link")
    val externalLink: String = "",
    @SerialName("meeting_type")
    val meetingType: String = ""
)
