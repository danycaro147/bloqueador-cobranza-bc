package com.danycaro.bloqueadorcobranza

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.ContactsContract

data class Decision(val block: Boolean, val reason: String, val code: String)

/**
 * Decide si una llamada entrante se bloquea. Orden de prioridad:
 *  1. Protección apagada        -> permitir
 *  2. Número oculto             -> bloquear (si está activado)
 *  3. Lista "Siempre permitir"  -> permitir
 *  4. Lista de bloqueo          -> bloquear
 *  5. Está en tus contactos     -> permitir (nunca se bloquea a un contacto)
 *  6. Número falsificado (red)  -> bloquear (si está activado)
 *  7. Desconocido               -> bloquear (si está activado), salvo que insista 2 veces en 3 min
 */
object Rules {

    private const val REPEAT_WINDOW_MS = 3 * 60 * 1000L

    fun digitsOf(number: String): String = number.filter { it.isDigit() }

    /** Últimos 10 dígitos = número nacional en México (quita +52 / 52 / 521). */
    private fun national(digits: String): String =
        if (digits.length > 10) digits.takeLast(10) else digits

    /**
     * Patrón exacto: "5512345678" (acepta +52, espacios, guiones).
     * Patrón por prefijo: termina en "*", p. ej. "5588*" bloquea todo lo que empiece con 55 88.
     */
    fun matches(patterns: List<String>, digits: String): Boolean {
        if (digits.isEmpty()) return false
        val nat = national(digits)
        for (p in patterns) {
            val trimmed = p.trim()
            val isPrefix = trimmed.endsWith("*")
            val pd = digitsOf(trimmed)
            if (pd.isEmpty()) continue
            if (isPrefix) {
                if (nat.startsWith(pd) || digits.startsWith(pd)) return true
            } else {
                if (national(pd) == nat) return true
            }
        }
        return false
    }

    /** true / false, o null si no hay permiso para leer contactos. */
    fun isContact(context: Context, rawNumber: String): Boolean? {
        if (context.checkSelfPermission(Manifest.permission.READ_CONTACTS)
            != PackageManager.PERMISSION_GRANTED
        ) return null
        return try {
            val uri = Uri.withAppendedPath(
                ContactsContract.PhoneLookup.CONTENT_FILTER_URI,
                Uri.encode(rawNumber)
            )
            context.contentResolver.query(
                uri, arrayOf(ContactsContract.PhoneLookup._ID), null, null, null
            )?.use { it.count > 0 } ?: false
        } catch (e: Exception) {
            null
        }
    }

    private fun recentlyBlockedUnknown(store: BlockerStore, digits: String): Boolean {
        val now = System.currentTimeMillis()
        return store.getLog().any {
            it["digits"] == digits &&
                it["code"] == "unknown" &&
                now - (it["time"] as Long) < REPEAT_WINDOW_MS
        }
    }

    fun decide(context: Context, rawNumber: String, spoofed: Boolean): Decision {
        val store = BlockerStore(context)
        if (!store.getBool(BlockerStore.KEY_ENABLED)) {
            return Decision(false, "Protección desactivada", "off")
        }

        val digits = digitsOf(rawNumber)
        if (digits.isEmpty()) {
            return if (store.getBool(BlockerStore.KEY_BLOCK_HIDDEN))
                Decision(true, "Número oculto o privado", "hidden")
            else Decision(false, "Número oculto (permitido)", "hidden_ok")
        }

        if (matches(store.getList(BlockerStore.LIST_ALLOW), digits)) {
            return Decision(false, "En tu lista de permitidos", "allow")
        }
        if (matches(store.getList(BlockerStore.LIST_BLOCK), digits)) {
            return Decision(true, "En tu lista de bloqueo", "list")
        }

        val contact = isContact(context, rawNumber)
        if (contact == true) {
            return Decision(false, "Contacto guardado", "contact")
        }

        if (spoofed && store.getBool(BlockerStore.KEY_BLOCK_SPOOFED)) {
            return Decision(true, "Número falsificado (la red no lo verificó)", "spoofed")
        }

        if (store.getBool(BlockerStore.KEY_BLOCK_UNKNOWN)) {
            if (contact == null) {
                // Sin permiso de contactos no podemos saber si es alguien conocido:
                // por seguridad NO bloqueamos.
                return Decision(false, "Desconocido (falta permiso de contactos)", "noperm")
            }
            if (store.getBool(BlockerStore.KEY_ALLOW_REPEAT) && recentlyBlockedUnknown(store, digits)) {
                return Decision(false, "Insistió 2 veces en 3 min (posible urgencia)", "repeat")
            }
            return Decision(true, "Número desconocido", "unknown")
        }

        return Decision(false, "Desconocido (permitido)", "unknown_ok")
    }
}
