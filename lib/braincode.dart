import 'package:flutter/material.dart';

import 'bridge.dart';
import 'privacy.dart';

/// Datos de BrainCode México (autores de la app).
class BrainCode {
  static const name = 'BrainCode México';
  static const tagline = 'Tecnología que mueve a tu empresa.';
  static const email = 'contacto@braincode.com.mx';

  static String site(String campaign) =>
      'https://braincode.com.mx/?utm_source=bloqueador_cobranza'
      '&utm_medium=app&utm_campaign=$campaign';

  static const whatsapp = 'https://wa.me/525521088557?text='
      'Hola%20BrainCode%2C%20vengo%20de%20la%20app%20Bloqueador%20Cobranza%20'
      'y%20me%20interesa%20una%20soluci%C3%B3n%20para%20mi%20empresa.';

  static const mail = 'mailto:contacto@braincode.com.mx'
      '?subject=Contacto%20desde%20Bloqueador%20Cobranza';

  static const services = [
    (Icons.phone_iphone_rounded, 'Apps móviles',
        'Para tu equipo en campo y tus clientes, incluso sin conexión.'),
    (Icons.code_rounded, 'Software a la medida',
        'Portales, cotizadores y herramientas que reemplazan papel y Excel.'),
    (Icons.hub_rounded, 'Odoo ERP',
        'Implementación, migración, facturación CFDI 4.0 y capacitación.'),
    (Icons.cloud_rounded, 'Nube AWS y Azure',
        'Migración, respaldos verificados, seguridad y control de costos.'),
  ];

  static Future<void> open(BuildContext context, String url) async {
    final ok = await NativeBridge.openUrl(url);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace.')));
    }
  }
}

/// Isotipo de BrainCode, se tiñe con el color del tema (claro/oscuro).
class BrainCodeMark extends StatelessWidget {
  final double size;
  final Color? color;
  const BrainCodeMark({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/images/braincode_isotipo.png',
        width: size,
        height: size,
        color: color ?? Theme.of(context).colorScheme.onSurface,
        colorBlendMode: BlendMode.srcIn,
        filterQuality: FilterQuality.medium,
        semanticLabel: 'BrainCode México',
      );
}

/// Firma discreta "Una app de BrainCode México". Al tocarla abre "Acerca de".
class MadeByBrainCode extends StatelessWidget {
  const MadeByBrainCode({super.key});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const AboutPage())),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Una app de ', style: TextStyle(color: muted, fontSize: 13)),
              BrainCodeMark(size: 18, color: muted),
              const SizedBox(width: 4),
              Text(BrainCode.name,
                  style: TextStyle(
                      color: muted, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta promocional no invasiva: aparece al final de la pantalla principal,
/// se puede cerrar y no vuelve a salir en 30 días.
class BrainCodePromoCard extends StatelessWidget {
  final VoidCallback onDismiss;
  const BrainCodePromoCard({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const BrainCodeMark(size: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DE LOS CREADORES DE ESTA APP',
                          style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              letterSpacing: .6,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('¿Tu empresa necesita una app?',
                          style: tt.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        'En BrainCode México creamos apps móviles, software a '
                        'la medida y soluciones con Odoo ERP.',
                        style: tt.bodyMedium
                            ?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Ocultar',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close_rounded,
                      size: 20, color: cs.onSurfaceVariant),
                  onPressed: onDismiss,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () =>
                    BrainCode.open(context, BrainCode.site('tarjeta_inicio')),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Conocer BrainCode'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  final String version;
  const AboutPage({super.key, this.version = ''});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: cs.outlineVariant.withAlpha(110))),
                child: const BrainCodeMark(size: 68),
              ),
            ),
            const SizedBox(height: 16),
            Text(BrainCode.name,
                textAlign: TextAlign.center,
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(BrainCode.tagline,
                textAlign: TextAlign.center,
                style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 20),
            Text(
              'Hicimos Bloqueador Cobranza para recuperar la tranquilidad de tu '
              'teléfono. Es gratuita, no tiene anuncios de terceros y no recopila '
              'tus datos. Si tu empresa necesita tecnología, nos encantará '
              'ayudarte.',
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(height: 1.45),
            ),
            const SectionTitle('Lo que hacemos'),
            Card(
              child: Column(
                children: [
                  for (final (i, s) in BrainCode.services.indexed) ...[
                    if (i > 0) const Divider(indent: 72),
                    ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: cs.primaryContainer,
                        child: Icon(s.$1, color: cs.onPrimaryContainer, size: 22),
                      ),
                      title: Text(s.$2,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(s.$3),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => BrainCode.open(context, BrainCode.site('acerca_de')),
              icon: const Icon(Icons.public_rounded),
              label: const Text('Visitar braincode.com.mx'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => BrainCode.open(context, BrainCode.whatsapp),
              icon: const Icon(Icons.chat_rounded),
              label: const Text('Escríbenos por WhatsApp'),
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: () => BrainCode.open(context, BrainCode.mail),
              icon: const Icon(Icons.mail_outline_rounded),
              label: const Text(BrainCode.email),
            ),
            const SizedBox(height: 16),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock_outline_rounded),
              title: const Text('Política de privacidad'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PrivacyPage())),
            ),
            if (version.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Bloqueador Cobranza · versión $version',
                    textAlign: TextAlign.center,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ),
          ],
        ),
      ),
    );
  }
}
