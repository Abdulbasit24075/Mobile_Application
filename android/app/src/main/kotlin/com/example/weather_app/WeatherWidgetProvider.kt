package com.example.weather_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.text.SimpleDateFormat
import java.util.*

class WeatherWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { widgetId ->
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.weather_widget)

    // Get data from HomeWidget (current API: getData(context) -> SharedPreferences)
    val prefs = HomeWidgetPlugin.getData(context)

    // Read values from SharedPreferences providing defaults
    val location = prefs.getString("location", "Lahore") ?: "Lahore"
    val temperature = prefs.getString("temperature", "--") ?: "--"
    val condition = prefs.getString("condition", "Loading...") ?: "Loading..."
    val icon = prefs.getString("icon", "☀️") ?: "☀️"
    val humidity = prefs.getString("humidity", "--") ?: "--"
    val wind = prefs.getString("wind", "--") ?: "--"

        // Get current time
        val currentTime = SimpleDateFormat("hh:mm a", Locale.getDefault()).format(Date())

        // Update views
        views.setTextViewText(R.id.widget_location, location)
        views.setTextViewText(R.id.widget_temperature, "$temperature°")
        views.setTextViewText(R.id.widget_condition, condition)
        views.setTextViewText(R.id.widget_icon, icon)
        views.setTextViewText(R.id.widget_humidity, "$humidity%")
        views.setTextViewText(R.id.widget_wind, "$wind km/h")
        views.setTextViewText(R.id.widget_updated, "Updated: $currentTime")

        // Update background color based on condition - use the main layout ID
        val backgroundDrawable = getBackgroundForCondition(condition)
        views.setInt(R.id.widget_root_layout, "setBackgroundResource", backgroundDrawable)

        appWidgetManager.updateAppWidget(widgetId, views)
    }

    private fun getBackgroundForCondition(condition: String): Int {
        return when {
            condition.contains("clear", ignoreCase = true) ||
                    condition.contains("sunny", ignoreCase = true) -> R.drawable.widget_background
            condition.contains("rain", ignoreCase = true) -> R.drawable.widget_background_rainy
            condition.contains("cloud", ignoreCase = true) -> R.drawable.widget_background_cloudy
            else -> R.drawable.widget_background
        }
    }
}