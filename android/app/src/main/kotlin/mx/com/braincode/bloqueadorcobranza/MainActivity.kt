package mx.com.braincode.bloqueadorcobranza

import android.Manifest
import android.app.role.RoleManager
import android.content.Intent
import android.net.Uri
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channelName = "bloqueador/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                val store = BlockerStore(this)
                try {
                    when (call.method) {
                        "getState" -> result.success(
                            mapOf(
                                "roleHeld" to isScreeningRoleHeld(),
                                "roleAvailable" to isScreeningRoleAvailable(),
                                "onboardingDone" to store.getBool("onboardingDone"),
                                "promoHiddenUntil" to store.getLong("promoHiddenUntil"),
                                "appVersion" to appVersion(),
                                "contactsGranted" to (checkSelfPermission(Manifest.permission.READ_CONTACTS)
                                    == PackageManager.PERMISSION_GRANTED),
                                "settings" to store.settings(),
                                "blocklist" to store.getList(BlockerStore.LIST_BLOCK),
                                "whitelist" to store.getList(BlockerStore.LIST_ALLOW),
                                "log" to store.getLog(),
                            )
                        )
                        "requestRole" -> {
                            requestScreeningRole()
                            result.success(null)
                        }
                        "requestContacts" -> {
                            requestPermissions(arrayOf(Manifest.permission.READ_CONTACTS), 42)
                            result.success(null)
                        }
                        "setSetting" -> {
                            store.setBool(call.argument<String>("key")!!, call.argument<Boolean>("value")!!)
                            result.success(null)
                        }
                        "setList" -> {
                            store.setList(call.argument<String>("name")!!, call.argument<List<String>>("items")!!)
                            result.success(null)
                        }
                        "setLong" -> {
                            val v = call.argument<Number>("value")!!.toLong()
                            store.setLong(call.argument<String>("key")!!, v)
                            result.success(null)
                        }
                        "openUrl" -> {
                            val url = call.argument<String>("url")!!
                            val ok = try {
                                startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url))
                                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                                true
                            } catch (e: Exception) {
                                false
                            }
                            result.success(ok)
                        }
                        "openAppSettings" -> {
                            startActivity(Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                Uri.fromParts("package", packageName, null)))
                            result.success(null)
                        }
                        "clearLog" -> {
                            store.clearLog()
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("ERR", e.message, null)
                }
            }
    }

    private fun isScreeningRoleAvailable(): Boolean {
        val rm = getSystemService(RoleManager::class.java) ?: return false
        return rm.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING)
    }

    private fun appVersion(): String = try {
        packageManager.getPackageInfo(packageName, 0).versionName ?: ""
    } catch (e: Exception) {
        ""
    }

    private fun isScreeningRoleHeld(): Boolean {
        val rm = getSystemService(RoleManager::class.java) ?: return false
        return rm.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING) &&
            rm.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)
    }

    /**
     * Pide SOLO el rol de filtro de llamadas (ROLE_CALL_SCREENING).
     * Nunca se pide ROLE_DIALER: la app de Teléfono nativa sigue siendo la predeterminada.
     */
    private fun requestScreeningRole() {
        val rm = getSystemService(RoleManager::class.java) ?: return
        if (!rm.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING)) return
        @Suppress("DEPRECATION")
        startActivityForResult(rm.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING), 41)
    }
}
