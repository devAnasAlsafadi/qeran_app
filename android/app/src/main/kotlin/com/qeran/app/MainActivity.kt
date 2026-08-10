package com.qeran.app

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
 * Android only. iOS has no equivalent API; that exposure is accepted (QER-3).
 */
class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE,
        )
    }
}
