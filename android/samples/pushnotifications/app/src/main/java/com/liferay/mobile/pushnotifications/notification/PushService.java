package com.liferay.mobile.pushnotifications.notification;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.TaskStackBuilder;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.media.RingtoneManager;
import android.net.Uri;
import android.support.v4.app.NotificationCompat;

import com.liferay.mobile.android.service.Session;
import com.liferay.mobile.android.v62.dlfileentry.DLFileEntryService;
import com.liferay.mobile.pushnotifications.R;
import com.liferay.mobile.pushnotifications.activities.NotificationsActivity;
import com.liferay.mobile.pushnotifications.download.DownloadPicture;
import com.liferay.mobile.screens.context.LiferayServerContext;
import com.liferay.mobile.screens.context.SessionContext;
import com.liferay.mobile.screens.push.AbstractPushService;
import com.liferay.mobile.screens.util.LiferayLogger;

import org.json.JSONException;
import org.json.JSONObject;

/**
 * @author Javier Gamarra
 */
public class PushService extends AbstractPushService {

	public static final int NOTIFICATION_ID = 2;

	@Override
	protected void processJSONNotification(final JSONObject json) throws Exception {
		boolean creation = json.has("newNotification") && json.getBoolean("newNotification");
		String titleHeader = (creation ? "New" : "Updated") + " notification: ";
		String title = titleHeader + getString(json, "title");
		String description = getString(json, "description");
		String photo = getString(json, "photo");

		createGlobalNotification(title, description, tryToLoadPhoto(photo));
	}

	private void createGlobalNotification(String title, String description, Bitmap bitmap) {
		Uri uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);

		NotificationCompat.Builder builder = new NotificationCompat.Builder(this)
			.setContentTitle(title)
			.setContentText(description)
			.setAutoCancel(true)
			.setSound(uri)
			.setVibrate(new long[]{2000, 1000, 2000, 1000})
			.setSmallIcon(R.drawable.liferay_glyph);

		if (bitmap != null) {
			builder.setLargeIcon(bitmap);
		}

		builder.setContentIntent(createPendingIntentForNotifications());

		Notification notification = builder.build();
		NotificationManager notificationManager =
			(NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
		notificationManager.notify(NOTIFICATION_ID, notification);
	}

	private PendingIntent createPendingIntentForNotifications() {
		Intent resultIntent = new Intent(this, NotificationsActivity.class);

		TaskStackBuilder stackBuilder = TaskStackBuilder.create(this);
		stackBuilder.addNextIntent(resultIntent);
		return stackBuilder.getPendingIntent(0, PendingIntent.FLAG_UPDATE_CURRENT);
	}

	private Bitmap tryToLoadPhoto(String photo) {
		if (photo != null && !photo.isEmpty()) {
			try {
				JSONObject jsonObject = new JSONObject(photo);
				final String uuid = getString(jsonObject, "uuid");
				final Long groupId = jsonObject.getLong("groupId");

				String username = getString(R.string.anonymous_user);
				String password = getString(R.string.anonymous_password);
				Session session = SessionContext.createBasicSession(username, password);

				DLFileEntryService entryService = new DLFileEntryService(session);
				JSONObject result = entryService.getFileEntryByUuidAndGroupId(uuid, groupId);

				return new DownloadPicture().createRequest(this, result,
					LiferayServerContext.getServer(), 100).get();
			}
			catch (Exception e) {
				LiferayLogger.e("Error loading picture", e);
			}
		}
		return null;
	}

	private String getString(final JSONObject json, final String element) throws JSONException {
		return json.has(element) ? json.getString(element) : "";
	}
}
