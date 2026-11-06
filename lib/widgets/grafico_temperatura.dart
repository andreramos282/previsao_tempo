import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/previsao.dart';
import 'dia_card.dart';

/// Gráfico de linhas com as temperaturas mínima e máxima de cada dia.
class GraficoTemperatura extends StatelessWidget {
  const GraficoTemperatura({super.key, required this.dias});

  final List<PrevisaoDia> dias;

  static const corMax = Color(0xFFE53935);
  static const corMin = Color(0xFF1E88E5);

  @override
  Widget build(BuildContext context) {
    final temps = [
      for (final d in dias) ...[d.maxima, d.minima]
    ].whereType<int>().toList();

    if (temps.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(child: Text('Temperaturas não informadas pelo serviço.')),
      );
    }

    final minY = (temps.reduce(math.min) - 4).toDouble();
    final maxY = (temps.reduce(math.max) + 4).toDouble();
    final tema = Theme.of(context);

    FlSpot ponto(int i, int? v) =>
        v == null ? FlSpot.nullSpot : FlSpot(i.toDouble(), v.toDouble());

    LineChartBarData linha(Color cor, int? Function(PrevisaoDia) valor) =>
        LineChartBarData(
          spots: [for (var i = 0; i < dias.length; i++) ponto(i, valor(dias[i]))],
          isCurved: true,
          preventCurveOverShooting: true,
          color: cor,
          barWidth: 3,
          dotData: FlDotData(
            getDotPainter: (_, _, _, _) => FlDotCirclePainter(
              radius: 4,
              color: cor,
              strokeWidth: 2,
              strokeColor: tema.colorScheme.surface,
            ),
          ),
          belowBarData: BarAreaData(show: true, color: cor.withValues(alpha: 0.08)),
        );

    return Column(
      children: [
        SizedBox(
          height: 230,
          child: Padding(
            padding: const EdgeInsets.only(right: 12, top: 8),
            child: LineChart(
              LineChartData(
                minX: -0.25,
                maxX: dias.length - 0.75,
                minY: minY,
                maxY: maxY,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: tema.dividerColor.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 4,
                      reservedSize: 40,
                      getTitlesWidget: (v, meta) {
                        if (v == meta.min || v == meta.max) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Text('${v.toInt()}°',
                              style: const TextStyle(fontSize: 11)),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 36,
                      getTitlesWidget: (v, meta) {
                        final i = v.round();
                        if (v != i || i < 0 || i >= dias.length) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            rotuloDia(dias[i].data, curto: true),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => tema.colorScheme.inverseSurface,
                    getTooltipItems: (spots) => spots
                        .map((s) => LineTooltipItem(
                              '${s.barIndex == 0 ? 'Máx' : 'Mín'}: ${s.y.toInt()}°C',
                              TextStyle(
                                color: s.barIndex == 0 ? corMax : corMin,
                                fontWeight: FontWeight.bold,
                              ),
                            ))
                        .toList(),
                  ),
                ),
                lineBarsData: [
                  linha(corMax, (d) => d.maxima),
                  linha(corMin, (d) => d.minima),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Legenda(cor: corMax, texto: 'Máxima'),
            SizedBox(width: 20),
            _Legenda(cor: corMin, texto: 'Mínima'),
          ],
        ),
      ],
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda({required this.cor, required this.texto});
  final Color cor;
  final String texto;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 4,
            decoration: BoxDecoration(
                color: cor, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 6),
          Text(texto, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}
