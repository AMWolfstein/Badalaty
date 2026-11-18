package com.badalaty.badalaty

import android.Manifest
import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import java.text.DateFormat
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import org.json.JSONObject

class CompactWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        WidgetData.render(context, manager, ids, false)
    }
}
class ExpandedWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        WidgetData.render(context, manager, ids, true)
    }
}
class LocalClockReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        WidgetData.refresh(context)
        if (intent.action == WidgetData.REMIND) WidgetData.notify(context)
        WidgetData.schedule(context)
    }
}

object WidgetData {
    const val REMIND = "com.badalaty.badalaty.REMIND"
    private const val MIDNIGHT = "com.badalaty.badalaty.MIDNIGHT"
    private const val CHANNEL = "allowance_reminders"

    fun preferences(context: Context) = context.getSharedPreferences("badalaty_widget", Context.MODE_PRIVATE)
    private fun data(context: Context) = runCatching {
        JSONObject(preferences(context).getString("display", "{}") ?: "{}")
    }.getOrElse { JSONObject() }

    private fun locale(context: Context, data: JSONObject): Locale {
        val language = if (data.optString("mode", "system") == "system")
            context.resources.configuration.locales[0].language
        else data.optString("mode", "en")
        return Locale.forLanguageTag(if (language == "ar") "ar" else "en")
    }

    private fun strings(context: Context, locale: Locale): Context {
        val configuration = Configuration(context.resources.configuration)
        configuration.setLocale(locale)
        return context.createConfigurationContext(configuration)
    }

    private fun key() = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Calendar.getInstance().time)

    private fun open(context: Context, route: String, request: Int): PendingIntent =
        PendingIntent.getActivity(context, request,
            Intent(context, MainActivity::class.java).putExtra("route", route)
                .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

    fun refresh(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        render(context, manager, manager.getAppWidgetIds(ComponentName(context, CompactWidget::class.java)), false)
        render(context, manager, manager.getAppWidgetIds(ComponentName(context, ExpandedWidget::class.java)), true)
    }

    fun render(context: Context, manager: AppWidgetManager, ids: IntArray, expanded: Boolean) {
        if (ids.isEmpty()) return
        val data = data(context)
        val locale = locale(context, data)
        val labels = strings(context, locale)
        val today = data.optJSONObject("days")?.optJSONObject(key())
        val dark = when (data.optString("theme")) {
            "light" -> false
            "dark" -> true
            else -> context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK == Configuration.UI_MODE_NIGHT_YES
        }
        val view = RemoteViews(context.packageName, R.layout.badalaty_widget)
        view.setInt(R.id.widget_root, "setBackgroundResource", if (dark) R.drawable.widget_dark else R.drawable.widget_light)
        view.setInt(R.id.widget_root, "setLayoutDirection", if (locale.language == "ar") View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR)
        for (id in listOf(R.id.widget_date, R.id.widget_amount, R.id.widget_details, R.id.widget_add, R.id.widget_travel, R.id.widget_history)) {
            view.setTextColor(id, if (dark) 0xFFE6F4FF.toInt() else 0xFF10294E.toInt())
        }
        view.setTextViewText(R.id.widget_date, DateFormat.getDateInstance(DateFormat.MEDIUM, locale).format(Calendar.getInstance().time))
        val numbers = NumberFormat.getIntegerInstance(locale)
        val amount = numbers.format(today?.optLong("amount") ?: 0)
        view.setTextViewText(R.id.widget_amount, "$amount ${labels.getString(R.string.widget_egp)}")
        val count = today?.optInt("count") ?: 0
        val assignment = today?.optString("assignment").orEmpty()
        val countText = labels.getString(R.string.widget_count, numbers.format(count))
        val details = if (assignment.isNotEmpty()) "$assignment · $countText"
            else if (count > 0) countText else labels.getString(R.string.widget_none)
        view.setTextViewText(R.id.widget_details, details)
        view.setTextViewText(R.id.widget_add, labels.getString(R.string.widget_add))
        view.setTextViewText(R.id.widget_travel, labels.getString(R.string.widget_travel))
        view.setTextViewText(R.id.widget_history, labels.getString(R.string.widget_history))
        for (id in listOf(R.id.widget_details, R.id.widget_travel, R.id.widget_history)) {
            view.setViewVisibility(id, if (expanded) View.VISIBLE else View.GONE)
        }
        view.setOnClickPendingIntent(R.id.widget_add, open(context, "/add", 1))
        view.setOnClickPendingIntent(R.id.widget_travel, open(context, "/entry/travel", 2))
        view.setOnClickPendingIntent(R.id.widget_history, open(context, "/history", 3))
        manager.updateAppWidget(ids, view)
    }

    fun schedule(context: Context) {
        val data = data(context)
        val clock = context.getSystemService(AlarmManager::class.java)
        val midnight = Calendar.getInstance().apply {
            add(Calendar.DATE, 1)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        fun alarm(action: String, id: Int) = PendingIntent.getBroadcast(context, id,
            Intent(context, LocalClockReceiver::class.java).setAction(action),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        clock.setAndAllowWhileIdle(AlarmManager.RTC, midnight.timeInMillis, alarm(MIDNIGHT, 4))
        val reminder = alarm(REMIND, 5)
        clock.cancel(reminder)
        if (data.optBoolean("reminders")) {
            val time = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, data.optInt("hour", 18))
                set(Calendar.MINUTE, data.optInt("minute", 0))
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
                if (timeInMillis <= System.currentTimeMillis()) add(Calendar.DATE, 1)
            }
            clock.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, time.timeInMillis, reminder)
        }
    }

    fun notify(context: Context) {
        val data = data(context)
        if (!data.optBoolean("reminders")) return
        val reminder = data.optJSONObject("days")?.optJSONObject(key())?.optString("reminder")
        val messageId = when (reminder) {
            "travel" -> R.string.reminder_travel
            "general" -> R.string.reminder_general
            else -> return
        }
        if (Build.VERSION.SDK_INT >= 33 &&
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) return
        val labels = strings(context, locale(context, data))
        val manager = context.getSystemService(NotificationManager::class.java)
        val title = labels.getString(R.string.reminder_channel)
        manager.createNotificationChannel(NotificationChannel(CHANNEL, title, NotificationManager.IMPORTANCE_DEFAULT))
        manager.notify(42, Notification.Builder(context, CHANNEL)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title).setContentText(labels.getString(messageId)).setAutoCancel(true)
            .setContentIntent(open(context, "/", 6)).build())
    }
}
