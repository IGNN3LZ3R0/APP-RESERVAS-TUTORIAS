package com.example.app_tesis

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.app_tesis/deeplink"
    private val TAG = "MainActivity"
    private var methodChannel: MethodChannel? = null
    private var pendingDeepLink: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "onCreate llamado")
        
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            methodChannel = MethodChannel(messenger, CHANNEL).apply {
                setMethodCallHandler { call, result ->
                    when (call.method) {
                        "getInitialLink" -> {
                            Log.d(TAG, "Flutter solicita initial link: $pendingDeepLink")
                            result.success(pendingDeepLink)
                        }
                        else -> result.notImplemented()
                    }
                }
            }
            Log.d(TAG, "MethodChannel configurado")
        }
        
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d(TAG, "onNewIntent llamado")
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        val action = intent?.action
        val data: Uri? = intent?.data

        Log.d(TAG, "handleIntent - Action: $action, Data: $data")

        if (Intent.ACTION_VIEW == action && data != null) {
            val deepLink = data.toString()
            Log.d(TAG, "📱 Deep link recibido: $deepLink")
            
            if (methodChannel != null) {
                Log.d(TAG, "Enviando deep link a Flutter inmediatamente")
                methodChannel?.invokeMethod("onDeepLink", deepLink)
            } else {
                Log.d(TAG, "Canal no listo, guardando deep link pendiente")
                pendingDeepLink = deepLink
            }
        }
    }

    override fun onResume() {
        super.onResume()
        Log.d(TAG, "onResume llamado")
        
        pendingDeepLink?.let { link ->
            methodChannel?.let {
                Log.d(TAG, "Enviando deep link pendiente: $link")
                it.invokeMethod("onDeepLink", link)
                pendingDeepLink = null
            }
        }
    }
}