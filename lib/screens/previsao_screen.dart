import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/previsao_repository.dart';
import '../main.dart';
import '../models/cidade.dart';
import '../models/previsao.dart';
import '../services/cptec_service.dart';
import '../widgets/comuns.dart';
import '../widgets/dia_card.dart';
import '../widgets/grafico_temperatura.dart';

class PrevisaoScreen extends StatefulWidget {
  const PrevisaoScreen({super.key, required this.cidade});

  final Cidade cidade;

  @override
  State<PrevisaoScreen> createState() => _PrevisaoScreenState();
}

class _PrevisaoScreenState extends State<PrevisaoScreen> {
  ResultadoPrevisao? _resultado;
  Object? _erro;
  bool _carregando = false;
  bool _favorita = false;

  PrevisaoRepository get _repo => RepositorioScope.of(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarFavorita();
      _atualizar();
    });
  }

  Future<void> _verificarFavorita() async {
    final fav = await _repo.local.favoritas();
    if (mounted) setState(() => _favorita = fav.contains(widget.cidade));
  }

  Future<void> _alternarFavorita() async {
    final agora = await _repo.local.alternarFavorita(widget.cidade);
    if (!mounted) return;
    setState(() => _favorita = agora);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(agora
          ? '${widget.cidade.nome} adicionada às favoritas'
          : '${widget.cidade.nome} removida das favoritas'),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _atualizar() async {
    if (_carregando) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final r = await _repo.previsao(widget.cidade);
      if (!mounted) return;
      setState(() => _resultado = r);
      if (r.doCache) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${r.avisoCache} Exibindo a última previsão salva.'),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e);
      if (_resultado != null) {
        // Já há dados na tela: avisa sem apagar o conteúdo.
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Widget _corpo() {
    final r = _resultado;
    if (r == null) {
      if (_carregando || _erro == null) {
        return const Carregando(texto: 'Consultando a previsão no CPTEC...');
      }
      final e = _erro;
      if (e is SemPrevisaoException) {
        return MensagemEstado(
          icone: Icons.cloud_queue,
          titulo: 'Previsão indisponível',
          detalhe: e.toString(),
          acao: _atualizar,
          rotuloAcao: 'Consultar novamente',
        );
      }
      final semRede = e is CptecException &&
          (e.tipo == TipoFalha.semConexao || e.tipo == TipoFalha.tempoEsgotado);
      return MensagemEstado(
        icone: semRede ? Icons.wifi_off : Icons.error_outline,
        titulo: semRede
            ? 'Sem conexão'
            : 'Não foi possível obter a previsão',
        detalhe: e is CptecException ? e.mensagem : 'Erro inesperado: $e',
        acao: _atualizar,
      );
    }

    final p = r.previsao;
    final tema = Theme.of(context);
    final atualizacao = p.atualizacao == null
        ? 'não informada'
        : DateFormat('dd/MM/yyyy').format(p.atualizacao!);

    return RefreshIndicator(
      onRefresh: _atualizar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        children: [
          if (_carregando) const LinearProgressIndicator(),
          if (r.doCache)
            Card(
              color: tema.colorScheme.errorContainer,
              child: ListTile(
                leading: Icon(Icons.cloud_off,
                    color: tema.colorScheme.onErrorContainer),
                title: Text('Modo offline',
                    style: TextStyle(color: tema.colorScheme.onErrorContainer)),
                subtitle: Text(
                  'Dados salvos em ${DateFormat('dd/MM/yyyy HH:mm').format(r.consultadoEm)}.',
                  style: TextStyle(color: tema.colorScheme.onErrorContainer),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${p.cidade}${p.uf.isEmpty ? '' : ' - ${p.uf}'}',
                    style: tema.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.update, size: 16, color: tema.hintColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text('Atualizado pelo CPTEC em $atualizacao',
                        style: tema.textTheme.bodySmall),
                  ),
                ]),
              ],
            ),
          ),
          for (var i = 0; i < p.dias.length; i++)
            DiaCard(dia: p.dias[i], destaque: i == 0),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text('Temperaturas (°C)',
                        style: tema.textTheme.titleMedium),
                  ),
                  GraficoTemperatura(dias: p.dias),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cidade.rotulo),
        actions: [
          IconButton(
            tooltip: _favorita ? 'Remover dos favoritos' : 'Favoritar',
            icon: Icon(_favorita ? Icons.star : Icons.star_border),
            color: _favorita ? Colors.amber : null,
            onPressed: _alternarFavorita,
          ),
          IconButton(
            tooltip: 'Atualizar previsão',
            icon: const Icon(Icons.refresh),
            onPressed: _carregando ? null : _atualizar,
          ),
        ],
      ),
      body: _corpo(),
      // Fonte sempre visível, independentemente da rolagem.
      bottomNavigationBar: const SafeArea(child: FonteCptec()),
    );
  }
}
