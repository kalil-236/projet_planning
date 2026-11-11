package com.kalil236.assistant_planning

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone

/// Widget « Prochaine mission ». L'application y dépose les tâches à faire
/// d'aujourd'hui et de demain (clé `plan`) ; le widget choisit lui-même la tâche
/// en cours ou la suivante, et se réveille à la prochaine heure de début ou de
/// fin pour rester juste quand l'application est fermée.
class TodayWidgetProvider : HomeWidgetProvider() {

    private data class Item(val title: String, val date: String, val start: Int, val end: Int)

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val plan = widgetData.getString(KEY_PLAN, null)
        val timezone = plan?.let { runCatching { JSONObject(it).optString("tz") }.getOrNull() }
        val zone = TimeZone.getTimeZone(if (timezone.isNullOrEmpty()) "Africa/Porto-Novo" else timezone)
        val now = Calendar.getInstance(zone)
        val today = isoDate(now)
        val minutes = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        val items = parse(plan)

        val views = RemoteViews(context.packageName, R.layout.today_widget)
        views.setTextViewText(R.id.widget_date, shortDate(now))
        views.setOnClickPendingIntent(R.id.widget_root, openApp(context))

        val todayLeft = items.filter { it.date == today && it.end > minutes }
        val tomorrow = items.filter { it.date > today }
        val current = todayLeft.firstOrNull { it.start <= minutes }
        val main = current ?: todayLeft.firstOrNull()
        val following = todayLeft.filter { it != main }.take(2)

        when {
            main != null -> {
                views.setTextViewText(
                    R.id.widget_label,
                    if (current != null) "En cours" else "Prochaine mission",
                )
                views.setTextViewText(R.id.widget_title, main.title)
                views.setTextViewText(
                    R.id.widget_time,
                    if (current != null) {
                        "jusqu'à ${hour(main.end)}"
                    } else {
                        "${hour(main.start)} – ${hour(main.end)}"
                    },
                )
                setLine(views, R.id.widget_next1, following.getOrNull(0))
                setLine(views, R.id.widget_next2, following.getOrNull(1))
            }
            plan == null -> {
                views.setTextViewText(R.id.widget_label, "Bonjour monsieur")
                views.setTextViewText(R.id.widget_title, "Ouvrez F.R.I.D.A.Y")
                views.setTextViewText(R.id.widget_time, "pour afficher vos missions.")
                setLine(views, R.id.widget_next1, null)
                setLine(views, R.id.widget_next2, null)
            }
            else -> {
                views.setTextViewText(R.id.widget_label, "Journée terminée")
                views.setTextViewText(R.id.widget_title, "Rien d'autre aujourd'hui, monsieur.")
                val first = tomorrow.firstOrNull()
                views.setTextViewText(
                    R.id.widget_time,
                    if (first == null) "Demain est libre." else "Demain ${hour(first.start)} : ${first.title}",
                )
                setLine(views, R.id.widget_next1, null)
                setLine(views, R.id.widget_next2, null)
            }
        }
        for (id in appWidgetIds) appWidgetManager.updateAppWidget(id, views)
        scheduleNextRefresh(context, now, todayLeft, minutes)
    }

    private fun setLine(views: RemoteViews, id: Int, item: Item?) {
        if (item == null) {
            views.setViewVisibility(id, View.GONE)
        } else {
            views.setViewVisibility(id, View.VISIBLE)
            views.setTextViewText(id, "${hour(item.start)}  ${item.title}")
        }
    }

    private fun parse(plan: String?): List<Item> {
        if (plan == null) return emptyList()
        return runCatching {
            val days = JSONObject(plan).getJSONArray("days")
            buildList {
                for (d in 0 until days.length()) {
                    val day = days.getJSONObject(d)
                    val date = day.getString("date")
                    val tasks = day.getJSONArray("tasks")
                    for (t in 0 until tasks.length()) {
                        val task = tasks.getJSONObject(t)
                        add(Item(task.getString("title"), date, task.getInt("start"), task.getInt("end")))
                    }
                }
            }.sortedWith(compareBy({ it.date }, { it.start }))
        }.getOrDefault(emptyList())
    }

    /// Prochain début ou fin de tâche, sinon minuit : le widget s'y redessine.
    private fun scheduleNextRefresh(context: Context, now: Calendar, todayLeft: List<Item>, minutes: Int) {
        val next = todayLeft.flatMap { listOf(it.start, it.end) }.filter { it > minutes }.minOrNull()
            ?: (24 * 60)
        val at = (now.clone() as Calendar).apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 5)
            set(Calendar.MILLISECOND, 0)
            add(Calendar.MINUTE, next)
        }
        val alarms = context.getSystemService(AlarmManager::class.java) ?: return
        // Alarme inexacte : quelques minutes de retard au pire, sans permission.
        alarms.set(AlarmManager.RTC, at.timeInMillis, refreshIntent(context))
    }

    private fun refreshIntent(context: Context): PendingIntent {
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(ComponentName(context, TodayWidgetProvider::class.java))
        val intent = Intent(context, TodayWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        }
        return PendingIntent.getBroadcast(
            context,
            REFRESH_REQUEST,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun openApp(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context,
            OPEN_REQUEST,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun isoDate(calendar: Calendar): String = String.format(
        Locale.ROOT,
        "%04d-%02d-%02d",
        calendar.get(Calendar.YEAR),
        calendar.get(Calendar.MONTH) + 1,
        calendar.get(Calendar.DAY_OF_MONTH),
    )

    /// « mar. 10 nov. »
    private fun shortDate(calendar: Calendar): String {
        val days = arrayOf("dim.", "lun.", "mar.", "mer.", "jeu.", "ven.", "sam.")
        val months = arrayOf(
            "janv.", "févr.", "mars", "avr.", "mai", "juin",
            "juil.", "août", "sept.", "oct.", "nov.", "déc.",
        )
        return "${days[calendar.get(Calendar.DAY_OF_WEEK) - 1]} " +
            "${calendar.get(Calendar.DAY_OF_MONTH)} ${months[calendar.get(Calendar.MONTH)]}"
    }

    /// « 8h » ou « 14h30 », comme dans l'application.
    private fun hour(minutes: Int): String {
        val h = minutes / 60
        val m = minutes % 60
        return if (m == 0) "${h}h" else "${h}h${m.toString().padStart(2, '0')}"
    }

    companion object {
        private const val KEY_PLAN = "plan"
        private const val REFRESH_REQUEST = 4101
        private const val OPEN_REQUEST = 4102
    }
}
