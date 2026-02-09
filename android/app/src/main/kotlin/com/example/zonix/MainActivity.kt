package com.example.zonix

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    /**
     * Evita NullPointerException cuando el selector de fotos (u otra Activity)
     * devuelve un Intent con extras null. El plugin image_picker llama
     * getExtras().getString(...) y falla si getExtras() es null.
     */
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        val safeData = when {
            data == null -> Intent().putExtras(Bundle())
            data.extras == null -> Intent().putExtras(Bundle()).apply { this.data = data.data }
            else -> data
        }
        super.onActivityResult(requestCode, resultCode, safeData)
    }
}
