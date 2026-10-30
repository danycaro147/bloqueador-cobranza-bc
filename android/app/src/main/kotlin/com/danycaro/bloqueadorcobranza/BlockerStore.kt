package com.danycaro.bloqueadorcobranza

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * Almacenamiento nativo (SharedPreferences). Lo usan tanto el servicio de filtrado
 * (que corre sin Flutter) como la interfaz Flutter vía MethodChannel.
 */
class BlockerStore(context: Context) {

    private val prefs = context.applicationContext
        .getSharedPreferences("bloqueador", Context.MODE_PRIVATE)

    companion object {
        const val KEY_ENABLED = "enabled"
        const val KEY_BLOCK_UNKNOWN = "blockUnknown"
        const val KEY_BLOCK_HIDDEN = "blockHidden"
        const val KEY_ALLOW_REPEAT = "allowRepeat"
        const val KEY_BLOCK_SPOOFED = "blockSpoofed"

        const val LIST_BLOCK = "blocklist"
        const val LIST_ALLOW = "whitelist"

        private const val KEY_LOG = "log"
        private const val MAX_LOG = 300

        val DEFAULTS = mapOf(
            KEY_ENABLED to true,
            KEY_BLOCK_UNKNOWN to true,
            KEY_BLOCK_HIDDEN to true,
            KEY_ALLOW_REPEAT to true,
            KEY_BLOCK_SPOOFED to true,
        )
    }

    fun getBool(key: String): Boolean = prefs.getBoolean(key, DEFAULTS[key] ?: false)

    fun setBool(key: String, value: Boolean) {
        prefs.edit().putBoolean(key, value).apply()
    }

    fun settings(): Map<String, Boolean> = DEFAULTS.keys.associateWith { getBool(it) }

    fun getList(name: String): List<String> {
        val raw = prefs.getString(name, null) ?: return emptyList()
        return try {
            val arr = JSONArray(raw)
            (0 until arr.length()).map { arr.getString(it) }
        } catch (e: Exception) {
            emptyList()
        }
    }

    fun setList(name: String, items: List<String>) {
        val arr = JSONArray()
        items.map { it.trim() }.filter { it.isNotEmpty() }.distinct().forEach { arr.put(it) }
        prefs.edit().putString(name, arr.toString()).apply()
    }

    /** Historial de llamadas filtradas, la más reciente primero. */
    fun getLog(): List<Map<String, Any>> {
        val raw = prefs.getString(KEY_LOG, null) ?: return emptyList()
        return try {
            val arr = JSONArray(raw)
            (0 until arr.length()).map {
                val o = arr.getJSONObject(it)
                mapOf(
                    "number" to o.optString("number"),
                    "digits" to o.optString("digits"),
                    "time" to o.optLong("time"),
                    "blocked" to o.optBoolean("blocked"),
                    "reason" to o.optString("reason"),
                    "code" to o.optString("code"),
                )
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    @Synchronized
    fun addLog(number: String, digits: String, blocked: Boolean, reason: String, code: String) {
        val old = try {
            JSONArray(prefs.getString(KEY_LOG, "[]"))
        } catch (e: Exception) {
            JSONArray()
        }
        val arr = JSONArray()
        arr.put(
            JSONObject()
                .put("number", number)
                .put("digits", digits)
                .put("time", System.currentTimeMillis())
                .put("blocked", blocked)
                .put("reason", reason)
                .put("code", code)
        )
        for (i in 0 until minOf(old.length(), MAX_LOG - 1)) arr.put(old.get(i))
        // commit() síncrono: el servicio puede terminar justo después.
        prefs.edit().putString(KEY_LOG, arr.toString()).commit()
    }

    fun clearLog() {
        prefs.edit().remove(KEY_LOG).apply()
    }
}
