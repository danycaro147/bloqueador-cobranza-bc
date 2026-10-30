package com.danycaro.bloqueadorcobranza

import android.os.Build
import android.telecom.Call
import android.telecom.CallScreeningService
import android.telecom.CallScreeningService.CallResponse
import android.telecom.Connection
import android.telecom.TelecomManager

/**
 * Servicio de FILTRADO de llamadas (rol ROLE_CALL_SCREENING).
 *
 * Importante: este rol NO convierte la app en la app de teléfono predeterminada.
 * Android solo nos pregunta "¿dejo pasar esta llamada?" y la llamada que pasa
 * suena y se contesta en tu app de Teléfono nativa, como siempre.
 */
class BlockerScreeningService : CallScreeningService() {

    override fun onScreenCall(details: Call.Details) {
        // Solo nos interesan las entrantes; las salientes nunca se tocan.
        if (details.callDirection != Call.Details.DIRECTION_INCOMING) {
            respondToCall(details, CallResponse.Builder().build())
            return
        }

        val raw = details.handle?.schemeSpecificPart ?: ""
        val hidden = raw.isBlank() ||
            details.handlePresentation == TelecomManager.PRESENTATION_RESTRICTED
        val number = if (hidden) "" else raw

        val spoofed = Build.VERSION.SDK_INT >= Build.VERSION_CODES.R &&
            details.callerNumberVerificationStatus == Connection.VERIFICATION_STATUS_FAILED

        val decision = try {
            Rules.decide(this, number, spoofed)
        } catch (e: Exception) {
            Decision(false, "Error interno (se dejó pasar)", "error")
        }

        val response = if (decision.block) {
            CallResponse.Builder()
                .setDisallowCall(true)      // no deja que suene
                .setRejectCall(true)        // la cuelga
                .setSkipNotification(true)  // sin notificación de llamada perdida
                .setSkipCallLog(false)      // sí queda en el registro del teléfono
                .build()
        } else {
            CallResponse.Builder().build()
        }
        respondToCall(details, response)

        try {
            BlockerStore(this).addLog(
                number = if (hidden) "Número oculto" else raw,
                digits = Rules.digitsOf(number),
                blocked = decision.block,
                reason = decision.reason,
                code = decision.code,
            )
        } catch (_: Exception) {
        }
    }
}
