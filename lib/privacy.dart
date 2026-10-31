import 'package:flutter/material.dart';

/// Texto de la política de privacidad (también publicado en PRIVACIDAD.md).
const privacySections = [
  (
    'Qué hace la app',
    'Bloqueador Cobranza revisa cada llamada entrante y decide si la deja pasar '
        'o la bloquea, según las reglas que tú eliges. Usa la función oficial '
        'de Android para filtrar llamadas y no reemplaza tu app de Teléfono.'
  ),
  (
    'Datos que usa',
    '• Número de quien llama: para aplicar tus reglas y mostrarlo en el '
        'Historial.\n'
        '• Tus contactos (solo si das permiso): para comprobar si quien llama '
        'está guardado y nunca bloquearlo. La comparación ocurre en tu teléfono; '
        'no se copian ni se guardan tus contactos.\n'
        '• Tus listas, ajustes e historial: se guardan solo en tu teléfono.'
  ),
  (
    'Qué NO hacemos',
    'La app no tiene permiso de acceso a internet: no envía, vende ni comparte '
        'ningún dato. No hay cuentas, analíticas ni anuncios de terceros. No lee '
        'el contenido de tus llamadas ni tus mensajes.'
  ),
  (
    'Tus decisiones',
    'Puedes borrar el historial desde la app, quitar el permiso de contactos en '
        'los ajustes de Android o desinstalar la app; al hacerlo se elimina toda '
        'la información guardada.'
  ),
  (
    'Contacto',
    'BrainCode México · contacto@braincode.com.mx · braincode.com.mx'
  ),
];

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Privacidad')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            Text('Tus datos no salen de tu teléfono.',
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final s in privacySections) ...[
              const SizedBox(height: 16),
              Text(s.$1,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(s.$2, style: tt.bodyMedium?.copyWith(height: 1.5)),
            ],
          ],
        ),
      ),
    );
  }
}
