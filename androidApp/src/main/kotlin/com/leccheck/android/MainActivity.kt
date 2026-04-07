package com.leccheck.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.TextButton
import androidx.compose.material3.Text
import androidx.compose.material3.Button
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.leccheck.shared.ui.Screen
import com.leccheck.shared.ui.ScheduleTab
import com.leccheck.shared.ui.StringsRepo

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                val strings = StringsRepo.he
                val screen = remember { mutableStateOf(Screen.Login) }
                val tab = remember { mutableStateOf(ScheduleTab.Weekly) }

                Surface(color = Color(0xFFF8FAFD), modifier = Modifier.fillMaxSize()) {
                    when (screen.value) {
                        Screen.Login -> LoginScreen(
                            title = strings.welcomeTitle,
                            subtitle = strings.welcomeSubtitle,
                            loginText = strings.loginGoogle,
                            guestText = strings.guestMode,
                            onContinue = { screen.value = Screen.Onboarding }
                        )
                        Screen.Onboarding -> OnboardingScreen(
                            title = strings.setupTitle,
                            continueText = strings.continueText,
                            onContinue = { screen.value = Screen.Schedule }
                        )
                        else -> ScheduleShell(
                            appTitle = strings.appTitle,
                            selectedTab = tab.value,
                            onTabSelected = { tab.value = it },
                            tabs = listOf(
                                ScheduleTab.Weekly to strings.weeklyTab,
                                ScheduleTab.Lectures to strings.lecturesTab,
                                ScheduleTab.Statistics to strings.statsTab
                            )
                        )
                    }
                }
            }
        }
    }
}

@androidx.compose.runtime.Composable
private fun LoginScreen(
    title: String,
    subtitle: String,
    loginText: String,
    guestText: String,
    onContinue: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text("🎓", style = MaterialTheme.typography.displaySmall)
        Spacer(Modifier.height(12.dp))
        Text(title, style = MaterialTheme.typography.headlineMedium, color = Color(0xFF1976D2))
        Spacer(Modifier.height(8.dp))
        Text(subtitle, color = Color(0xFF5B6B7B))
        Spacer(Modifier.height(24.dp))
        Button(onClick = onContinue, modifier = Modifier.fillMaxWidth()) { Text(loginText) }
        Spacer(Modifier.height(8.dp))
        TextButton(onClick = onContinue) { Text(guestText) }
        Spacer(Modifier.height(6.dp))
        Text("החיבור מאובטח על ידי שרתי Google", color = Color(0xFF5B6B7B))
    }
}

@androidx.compose.runtime.Composable
private fun OnboardingScreen(title: String, continueText: String, onContinue: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(title, style = MaterialTheme.typography.headlineSmall, color = Color(0xFF1976D2))
        Spacer(Modifier.height(10.dp))
        Text("שלב 1: תאריכי הסמסטר", fontWeight = FontWeight.Bold)
        Spacer(Modifier.height(8.dp))
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
            FakeChip("בחר התחלה")
            FakeChip("בחר סיום")
        }
        Spacer(Modifier.height(16.dp))
        Button(onClick = onContinue) { Text(continueText) }
    }
}

@androidx.compose.runtime.Composable
private fun ScheduleShell(
    appTitle: String,
    selectedTab: ScheduleTab,
    onTabSelected: (ScheduleTab) -> Unit,
    tabs: List<Pair<ScheduleTab, String>>
) {
    Column(Modifier.fillMaxSize()) {
        Box(
            modifier = Modifier.fillMaxWidth().background(Color(0xFF1976D2)).padding(16.dp),
            contentAlignment = Alignment.Center
        ) { Text(appTitle, color = Color.White, fontWeight = FontWeight.Bold) }

        Row(Modifier.fillMaxWidth().padding(8.dp), horizontalArrangement = Arrangement.Center) {
            tabs.forEach { (tab, label) ->
                val active = tab == selectedTab
                TextButton(onClick = { onTabSelected(tab) }) {
                    Text(label, color = if (active) Color(0xFF1976D2) else Color(0xFF5B6B7B))
                }
            }
        }

        when (selectedTab) {
            ScheduleTab.Weekly -> WeeklyBoard()
            ScheduleTab.Lectures -> LecturesList()
            ScheduleTab.Statistics -> StatsPanel()
        }
    }
}

@androidx.compose.runtime.Composable
private fun WeeklyBoard() {
    LazyColumn(Modifier.fillMaxSize().padding(12.dp)) {
        item { Text("שבוע מתאריך: 07/04", fontWeight = FontWeight.Bold) }
        item { Spacer(Modifier.height(8.dp)) }
        items(listOf("ראשון", "שני", "שלישי", "רביעי", "חמישי")) { day ->
            Card(
                modifier = Modifier.fillMaxWidth().padding(vertical = 5.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White)
            ) {
                Column(Modifier.padding(14.dp)) {
                    Text(day, fontWeight = FontWeight.Bold)
                    Text("אין הרצאות להצגה", color = Color(0xFF5B6B7B))
                }
            }
        }
    }
}

@androidx.compose.runtime.Composable
private fun LecturesList() {
    LazyColumn(Modifier.fillMaxSize().padding(12.dp)) {
        items((1..5).map { "הרצאה #$it" }) { lecture ->
            Card(modifier = Modifier.fillMaxWidth().padding(vertical = 5.dp)) {
                Column(Modifier.padding(14.dp)) {
                    Text(lecture, fontWeight = FontWeight.Bold)
                    Text("סטטוס: להשלמה", color = Color(0xFF5B6B7B))
                }
            }
        }
    }
}

@androidx.compose.runtime.Composable
private fun StatsPanel() {
    Column(Modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        FakeMetric("זמן כולל (בסמסטר)", "0 שעות")
        FakeMetric("זמן למידה שהושלם", "0 שעות")
        FakeMetric("סך הכל מפגשים", "0")
    }
}

@androidx.compose.runtime.Composable
private fun FakeMetric(label: String, value: String) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Row(
            Modifier.fillMaxWidth().padding(14.dp),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(label)
            Text(value, fontWeight = FontWeight.Bold)
        }
    }
}

@androidx.compose.runtime.Composable
private fun FakeChip(text: String) {
    Card {
        Text(text, modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp))
    }
}
