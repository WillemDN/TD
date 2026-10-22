package be.willem.guardians;

import android.app.Activity;
import android.app.PendingIntent;
import android.content.Intent;
import android.content.pm.PackageInstaller;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.OutputStream;

/**
 * Installs a downloaded APK over the running app using Android's PackageInstaller
 * session API. Called from GDScript through JavaClassWrapper
 * (see client/app_updater.gd). The result goes to InstallResultReceiver.
 */
public final class Updater {
    private Updater() {}

    /** Directory (inside the app's private cache) where updates are downloaded. */
    public static String updateDir(Activity activity) {
        File dir = new File(activity.getCacheDir(), "updates");
        dir.mkdirs();
        return dir.getAbsolutePath();
    }

    /** Android 8+ requires the user to allow "install unknown apps" for this app once. */
    public static boolean canInstall(Activity activity) {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.O
                || activity.getPackageManager().canRequestPackageInstalls();
    }

    public static void openInstallSettings(Activity activity) {
        Intent intent = new Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                Uri.parse("package:" + activity.getPackageName()));
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        activity.startActivity(intent);
    }

    /**
     * Streams the APK into an install session and commits it. Android then shows its
     * "Do you want to update this app?" prompt (via InstallResultReceiver).
     * Returns "" on success or an error message.
     */
    public static String install(Activity activity, String apkPath) {
        try {
            File apk = new File(apkPath);
            PackageInstaller installer = activity.getPackageManager().getPackageInstaller();
            PackageInstaller.SessionParams params =
                    new PackageInstaller.SessionParams(PackageInstaller.SessionParams.MODE_FULL_INSTALL);
            params.setAppPackageName(activity.getPackageName());
            int sessionId = installer.createSession(params);
            try (PackageInstaller.Session session = installer.openSession(sessionId)) {
                try (InputStream in = new FileInputStream(apk);
                     OutputStream out = session.openWrite("update", 0, apk.length())) {
                    byte[] buffer = new byte[1 << 16];
                    int read;
                    while ((read = in.read(buffer)) > 0) {
                        out.write(buffer, 0, read);
                    }
                    session.fsync(out);
                }
                Intent resultIntent = new Intent(activity, InstallResultReceiver.class);
                int flags = PendingIntent.FLAG_UPDATE_CURRENT
                        | (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ? PendingIntent.FLAG_MUTABLE : 0);
                PendingIntent pending = PendingIntent.getBroadcast(activity, sessionId, resultIntent, flags);
                session.commit(pending.getIntentSender());
            }
            return "";
        } catch (Exception e) {
            return "Install failed: " + e.getMessage();
        }
    }
}
