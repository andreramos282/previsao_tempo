import 'package:flutter/material.dart';

/// Rodapé que identifica a fonte dos dados.
class FonteCptec extends StatelessWidget {
  const FonteCptec({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.satellite_alt_outlined, size: 16, color: tema.hintColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Fonte dos dados: CPTEC/INPE',
              style: tema.textTheme.bodySmall?.copyWith(color: tema.hintColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado de mensagem centralizada (vazio, erro, sem previsão...).
class MensagemEstado extends StatelessWidget {
  const MensagemEstado({
    super.key,
    required this.icone,
    required this.titulo,
    this.detalhe,
    this.acao,
    this.rotuloAcao = 'Tentar novamente',
  });

  final IconData icone;
  final String titulo;
  final String? detalhe;
  final VoidCallback? acao;
  final String rotuloAcao;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 64, color: tema.colorScheme.primary),
            const SizedBox(height: 16),
            Text(titulo,
                style: tema.textTheme.titleMedium, textAlign: TextAlign.center),
            if (detalhe != null) ...[
              const SizedBox(height: 8),
              Text(detalhe!, textAlign: TextAlign.center),
            ],
            if (acao != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: acao,
                icon: const Icon(Icons.refresh),
                label: Text(rotuloAcao),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class Carregando extends StatelessWidget {
  const Carregando({super.key, required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(texto),
          ],
        ),
      );
}
