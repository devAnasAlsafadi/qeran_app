package com.qeran.app

import android.content.pm.ApplicationInfo
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

/**
 * Qeran hosts BOTH roles — the user app and the matchmaker app — as role-gated
 * shells inside one FlutterActivity, so this single window is every screen the
 * product has.
 *
 * FLAG_SECURE blocks screenshots and screen recording (the recorder captures a
 * black frame) and keeps the window out of the recents thumbnail. It is set
 * app-wide rather than per-route because nearly every surface renders a user
 * photo, and because toggling the flag per route needs a platform channel and
 * makes the surface flash as it is re-created. Modal bottom sheets — the match
 * gallery and the matchmaker share sheet — live in this same window, so they
 * are covered by construction.
 *
 * Release builds only. Debug and profile builds are debuggable (Flutter's
 * profile build type is initialised from debug), so they skip the flag and
 * screenshots work for design and QA. The gate reads the debuggable bit rather
 * than a build-type name because Play Console rejects debuggable uploads: any
 * build that reaches the store is protected by construction, with no switch to
 * remember to turn back on.
 *
 * Android only. iOS has no equivalent API; its protection is deferred to
 * after release (QER-3; Phase 4 Q24).
 */
class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (!isDebuggable()) {
            window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE,
            )
        }
    }

    private fun isDebuggable(): Boolean =
        (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
}
