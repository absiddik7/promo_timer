package com.example.promo_timer

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	companion object {
		private const val CHANNEL_NAME = "promo_timer/custom_notification"
		private const val NOTIFICATION_ID = 12001
		private const val TIMER_CHANNEL_ID = "timer_running_channel"
		private const val TIMER_CHANNEL_TITLE = "Timer Running"
		private const val TIMER_CHANNEL_DESCRIPTION =
			"Shows a persistent notification while timer is running in background."
	}

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			CHANNEL_NAME,
		).setMethodCallHandler { call, result ->
			when (call.method) {
				"showRunningTimerNotification" -> {
					val mainText = call.argument<String>("mainText") ?: "00:00:00"
					val secondaryText = call.argument<String>("secondaryText") ?: ""
					showCustomTimerNotification(
						mainText = mainText,
						secondaryText = secondaryText,
						showSecondary = true,
						ongoing = true,
						priority = NotificationCompat.PRIORITY_LOW,
						category = NotificationCompat.CATEGORY_SERVICE,
					)
					result.success(null)
				}

				"showCompletedTimerNotification" -> {
					val mainText = call.argument<String>("mainText") ?: ""
					val secondaryText = call.argument<String>("secondaryText") ?: "Session Ended"
					showCustomTimerNotification(
						mainText = mainText,
						secondaryText = secondaryText,
						showSecondary = true,
						ongoing = false,
						priority = NotificationCompat.PRIORITY_HIGH,
						category = NotificationCompat.CATEGORY_ALARM,
					)
					result.success(null)
				}

				"cancelRunningTimerNotification" -> {
					cancelRunningNotification()
					result.success(null)
				}

				else -> result.notImplemented()
			}
		}
	}

	private fun showCustomTimerNotification(
		mainText: String,
		secondaryText: String,
		showSecondary: Boolean,
		ongoing: Boolean,
		priority: Int,
		category: String,
	) {
		val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
		ensureTimerChannel(manager)

		val launchIntent = Intent(this, MainActivity::class.java).apply {
			flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
		}
		val pendingIntent = PendingIntent.getActivity(
			this,
			0,
			launchIntent,
			PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
		)

		val customView = RemoteViews(packageName, R.layout.notification_timer_running).apply {
			setTextViewText(R.id.notification_main, mainText)
			setTextViewText(R.id.notification_secondary, secondaryText)
			setViewVisibility(
				R.id.notification_main,
				if (mainText.isNotBlank()) android.view.View.VISIBLE else android.view.View.GONE,
			)
			setViewVisibility(
				R.id.notification_secondary,
				if (showSecondary) android.view.View.VISIBLE else android.view.View.GONE,
			)
		}

		val notification = NotificationCompat.Builder(this, TIMER_CHANNEL_ID)
			.setSmallIcon(R.mipmap.ic_launcher)
			.setOngoing(ongoing)
			.setOnlyAlertOnce(true)
			.setAutoCancel(false)
			.setPriority(priority)
			.setCategory(category)
			.setWhen(System.currentTimeMillis())
			.setShowWhen(false)
			.setContentIntent(pendingIntent)
			.setContentTitle(mainText)
			.setContentText(if (showSecondary) secondaryText else "")
			.setCustomContentView(customView)
			.setStyle(NotificationCompat.DecoratedCustomViewStyle())
			.build()

		manager.notify(NOTIFICATION_ID, notification)
	}

	private fun cancelRunningNotification() {
		val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
		manager.cancel(NOTIFICATION_ID)
	}

	private fun ensureTimerChannel(manager: NotificationManager) {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

		val existing = manager.getNotificationChannel(TIMER_CHANNEL_ID)
		if (existing != null) return

		val channel = NotificationChannel(
			TIMER_CHANNEL_ID,
			TIMER_CHANNEL_TITLE,
			NotificationManager.IMPORTANCE_LOW,
		).apply {
			description = TIMER_CHANNEL_DESCRIPTION
		}

		manager.createNotificationChannel(channel)
	}
}
