import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/previsao.dart';
import '../utils/condicoes_tempo.dart';

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String rotuloDia(DateTime? d, {bool curto = false}) {
  if (d == null) return 'Data não informada';
  final hoje = DateTime.now();
  final mesmoDia =
      d.year == hoje.year && d.month == hoje.month && d.day == hoje.day;
  if (curto) return '${DateFormat('E', 'pt_BR').format(d).replaceAll('.', '')}\n${DateFormat('dd/MM').format(d)}';
  final base = _cap(DateFormat("EEEE, dd/MM", 'pt_BR').format(d));
  return mesmoDia ? 'Hoje • $base' : base;
}

String temperatura(int? t) => t == null ? '--' : '$t°C';

class DiaCard extends StatelessWidget {
  const DiaCard({super.key, required this.dia, this.destaque = false});

  final PrevisaoDia dia;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cond = condicaoPorSigla(dia.sigla);
    final iuv = dia.iuv;
    final classe = iuv == null ? null : classificarIuv(iuv);

    return Card(
      color: destaque ? tema.colorScheme.primaryContainer : null,
      child: Padding(
        padding: EdgeInsets.all(destaque ? 20 : 14),
        child: Row(
          children: [
            Container(
              width: destaque ? 72 : 52,
              height: destaque ? 72 : 52,
              decoration: BoxDecoration(
                color: cond.cor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(cond.icone,
                  color: cond.cor, size: destaque ? 44 : 30,
                  semanticLabel: cond.descricao),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rotuloDia(dia.data),
                      style: (destaque
                              ? tema.textTheme.titleMedium
                              : tema.textTheme.titleSmall)
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(cond.descricao, style: tema.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _Temp(Icons.arrow_downward, temperatura(dia.minima),
                          Colors.blue),
                      _Temp(Icons.arrow_upward, temperatura(dia.maxima),
                          Colors.red),
                      if (classe != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: classe.cor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: classe.cor),
                          ),
                          child: Text(
                            'UV ${iuv!.toStringAsFixed(iuv % 1 == 0 ? 0 : 1)} • ${classe.rotulo}',
                            style: tema.textTheme.labelSmall,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Temp extends StatelessWidget {
  const _Temp(this.icone, this.texto, this.cor);
  final IconData icone;
  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 16, color: cor),
          Text(texto,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      );
}
