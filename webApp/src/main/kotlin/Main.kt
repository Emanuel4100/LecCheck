import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.engine.js.Js
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.request.get
import io.ktor.serialization.kotlinx.json.json
import kotlinx.browser.document
import kotlinx.browser.window
import kotlinx.coroutines.await
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import org.w3c.dom.HTMLDivElement

private val scope = MainScope()
private val json = Json { ignoreUnknownKeys = true } // kept for future payload work
private val apiBase = "http://localhost:8080"
private val http = HttpClient(Js) { install(ContentNegotiation) { json(json) } }

@Serializable
private data class SessionDto(val userId: String, val email: String? = null, val name: String? = null)

fun main() {
    val root = ensureRoot()
    root.innerHTML = "Loading LecCheck..."

    scope.launch {
        try {
            val lang = resolveLanguage()
            val locale = loadLocale(lang)
            val sessionId = window.location.search
                .removePrefix("?")
                .split("&")
                .mapNotNull {
                    val parts = it.split("=")
                    if (parts.size == 2) parts[0] to parts[1] else null
                }
                .toMap()["session_id"]

            if (sessionId == null) {
                renderLogin(root, locale, lang)
                return@launch
            }

            try {
                val session = http.get("$apiBase/api/auth/session/$sessionId").body<SessionDto>()
                renderScheduleShell(root, session, locale)
            } catch (_: Throwable) {
                renderLogin(root, locale, lang)
            }
        } catch (e: Throwable) {
            console.error("Boot error", e)
            val fallback = JSON.parse<dynamic>(
                """{"app":{"title":"Lecture Tracker"},"login":{"welcomeTitle":"Welcome to LecCheck","welcomeSubtitle":"Manage your schedule.","google":"Sign in with Google","guest":"Continue as guest","secure":"Secured by Google"}}"""
            )
            renderLogin(root, fallback, "en")
        }
    }
}

private suspend fun loadLocale(lang: String): dynamic {
    return try {
        val response = window.fetch("locales/$lang.json").await()
        val text = response.text().await()
        JSON.parse<dynamic>(text)
    } catch (_: Throwable) {
        JSON.parse<dynamic>("""{"app":{"title":"LecCheck"}}""")
    }
}

private fun resolveLanguage(): String {
    val queryLang = window.location.search
        .removePrefix("?")
        .split("&")
        .mapNotNull {
            val parts = it.split("=")
            if (parts.size == 2) parts[0] to parts[1] else null
        }
        .toMap()["lang"]
    if (queryLang == "en" || queryLang == "he") return queryLang
    return if (window.navigator.language.lowercase().startsWith("he")) "he" else "en"
}

private fun t(locale: dynamic, key: String, fallback: String): String {
    var current: dynamic = locale
    for (part in key.split(".")) {
        current = current?.asDynamic()?.get(part)
        if (current == undefined || current == null) return fallback
    }
    return current as? String ?: fallback
}

private fun renderLogin(root: HTMLDivElement, locale: dynamic, lang: String) {
    root.innerHTML = """
        <main class="login">
          <section class="card login-box">
            <div style="font-size:64px;line-height:1">🎓</div>
            <div style="height:14px"></div>
            <div class="brand">${t(locale, "login.welcomeTitle", "Welcome to LecCheck")}</div>
            <p class="muted">${t(locale, "login.welcomeSubtitle", "Manage your schedule with cloud sync.")}</p>
            <div style="height:20px"></div>
            <a href="$apiBase/api/oauth/redirect"><button class="btn btn-primary" style="width:320px">${t(locale, "login.google", "Sign in with Google")}</button></a>
            <div style="height:10px"></div>
            <button id="guest-btn" class="btn btn-ghost">${t(locale, "login.guest", "Continue as guest")}</button>
            <p class="muted" style="font-size:12px">${t(locale, "login.secure", "Secured by Google")}</p>
            <div style="height:10px"></div>
            <div>
              <button id="lang-he" class="btn ${if (lang == "he") "btn-primary" else "btn-ghost"}">HE</button>
              <button id="lang-en" class="btn ${if (lang == "en") "btn-primary" else "btn-ghost"}">EN</button>
            </div>
          </section>
        </main>
    """.trimIndent()

    document.getElementById("guest-btn")?.addEventListener("click", {
        renderScheduleShell(root, SessionDto(userId = "guest"), locale)
    })
    document.getElementById("lang-he")?.addEventListener("click", { window.location.href = "?lang=he" })
    document.getElementById("lang-en")?.addEventListener("click", { window.location.href = "?lang=en" })
}

private fun renderScheduleShell(root: HTMLDivElement, session: SessionDto, locale: dynamic) {
    root.innerHTML = """
        <div class="app-shell">
          <header class="topbar">
            <span>⚙️</span>
            <strong>${t(locale, "app.title", "Lecture Tracker")}</strong>
            <span>${session.email ?: session.userId}</span>
          </header>
          <nav class="tabs">
            <button class="tab active" data-tab="weekly">${t(locale, "schedule.weekly", "Weekly")}</button>
            <button class="tab" data-tab="lectures">${t(locale, "schedule.lectures", "Lectures")}</button>
            <button class="tab" data-tab="stats">${t(locale, "schedule.stats", "Statistics")}</button>
            <button class="tab" data-tab="settings">${t(locale, "schedule.settings", "Settings")}</button>
          </nav>
          <section class="content" id="content-area"></section>
          <button class="btn btn-primary fab">+</button>
        </div>
    """.trimIndent()

    val content = document.getElementById("content-area") ?: return
    fun weeklyView() = """
      <div class="card">
        <div style="display:flex;justify-content:space-between;align-items:center">
          <button class="btn">${t(locale, "common.prev", "Prev")}</button>
          <strong>${t(locale, "schedule.weekOf", "Week of")}: ${js("new Date().toLocaleDateString('he-IL')")}</strong>
          <button class="btn">${t(locale, "common.next", "Next")}</button>
        </div>
      </div>
      <div class="grid">
        <div class="day"><div class="day-header">${t(locale, "days.sunday", "Sunday")}</div><div class="day-body">${t(locale, "schedule.noLectures", "No lectures")}</div></div>
        <div class="day"><div class="day-header">${t(locale, "days.monday", "Monday")}</div><div class="day-body">${t(locale, "schedule.noLectures", "No lectures")}</div></div>
        <div class="day"><div class="day-header">${t(locale, "days.tuesday", "Tuesday")}</div><div class="day-body">${t(locale, "schedule.noLectures", "No lectures")}</div></div>
        <div class="day"><div class="day-header">${t(locale, "days.wednesday", "Wednesday")}</div><div class="day-body">${t(locale, "schedule.noLectures", "No lectures")}</div></div>
        <div class="day"><div class="day-header">${t(locale, "days.thursday", "Thursday")}</div><div class="day-body">${t(locale, "schedule.noLectures", "No lectures")}</div></div>
      </div>
    """.trimIndent()
    fun lecturesView() = """
      <div class="card"><strong>${t(locale, "lectures.pending", "Pending lectures")}</strong><p class="muted">${t(locale, "schedule.noLectures", "No lectures")}</p></div>
      <div class="card"><strong>${t(locale, "lectures.future", "Future lectures")}</strong><p class="muted">${t(locale, "schedule.noLectures", "No lectures")}</p></div>
      <div class="card"><strong>${t(locale, "lectures.past", "Past lectures")}</strong><p class="muted">${t(locale, "schedule.noLectures", "No lectures")}</p></div>
    """.trimIndent()
    fun statsView() = """
      <div class="card"><strong>${t(locale, "stats.totalTime", "Total time")}</strong><p class="muted">0</p></div>
      <div class="card"><strong>${t(locale, "stats.completedTime", "Completed time")}</strong><p class="muted">0</p></div>
      <div class="card"><strong>${t(locale, "stats.totalMeetings", "Total meetings")}</strong><p class="muted">0</p></div>
    """.trimIndent()
    fun settingsView() = """
      <div class="card"><strong>${t(locale, "schedule.settings", "Settings")}</strong><p class="muted">${t(locale, "settings.hint", "Semester dates, language, display settings.")}</p></div>
      <div class="card"><strong>${t(locale, "settings.user", "User")}</strong><p class="muted">${session.email ?: session.userId}</p></div>
    """.trimIndent()

    fun setTab(name: String) {
        content.innerHTML = when (name) {
            "lectures" -> lecturesView()
            "stats" -> statsView()
            "settings" -> settingsView()
            else -> weeklyView()
        }
        val tabs = document.querySelectorAll(".tab")
        for (i in 0 until tabs.length) {
            val el = tabs.item(i)
            val attr = el?.asDynamic()?.dataset?.tab as? String
            if (attr == name) {
                el?.asDynamic()?.className = "tab active"
            } else {
                el?.asDynamic()?.className = "tab"
            }
        }
    }

    setTab("weekly")
    val tabs = document.querySelectorAll(".tab")
    for (i in 0 until tabs.length) {
        val tab = tabs.item(i)
        tab?.addEventListener("click", {
            val name = tab.asDynamic().dataset.tab as? String ?: "weekly"
            setTab(name)
        })
    }
}

private fun ensureRoot(): HTMLDivElement {
    val existing = document.getElementById("root")
    if (existing is HTMLDivElement) return existing
    val newRoot = document.createElement("div") as HTMLDivElement
    newRoot.id = "root"
    document.body?.appendChild(newRoot)
    return newRoot
}
