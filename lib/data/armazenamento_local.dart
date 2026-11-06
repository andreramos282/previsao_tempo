import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cidade.dart';

/// Persistência local com shared_preferences.
///
/// Chaves usadas:
/// - `cidades_recentes`: lista JSON com as últimas cidades consultadas (máx. 8).
/// - `cidades_favoritas`: lista JSON com as cidades marcadas como favoritas.
/// - `previsao_cache_<codigo>`: JSON `{xml, consultadoEm}` com a última
///   resposta XML válida de cada cidade, usada quando não há conexão.
class ArmazenamentoLocal {
  ArmazenamentoLocal({SharedPreferencesAsync? prefs})
      : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  static const _recentes = 'cidades_recentes';
  static const _favoritas = 'cidades_favoritas';
  static const _maxRecentes = 8;
  static String _chaveCache(int codigo) => 'previsao_cache_$codigo';

  Future<List<Cidade>> _lerLista(String chave) async {
    try {
      final json = await _prefs.getString(chave);
      if (json == null) return [];
      final dados = jsonDecode(json);
      if (dados is! List) return [];
      return dados.map(Cidade.fromJson).whereType<Cidade>().toList();
    } catch (_) {
      return []; // dado corrompido não deve derrubar o app
    }
  }

  Future<void> _salvarLista(String chave, List<Cidade> lista) =>
      _prefs.setString(chave, jsonEncode(lista.map((c) => c.toJson()).toList()));

  // ------------ Recentes ------------
  Future<List<Cidade>> recentes() => _lerLista(_recentes);

  Future<void> registrarRecente(Cidade c) async {
    final lista = await recentes();
    lista
      ..remove(c)
      ..insert(0, c);
    await _salvarLista(_recentes, lista.take(_maxRecentes).toList());
  }

  Future<void> removerRecente(Cidade c) async {
    final lista = await recentes()..remove(c);
    await _salvarLista(_recentes, lista);
  }

  // ------------ Favoritas ------------
  Future<List<Cidade>> favoritas() => _lerLista(_favoritas);

  Future<bool> alternarFavorita(Cidade c) async {
    final lista = await favoritas();
    final eraFavorita = lista.remove(c);
    if (!eraFavorita) lista.add(c);
    lista.sort((a, b) => a.nome.compareTo(b.nome));
    await _salvarLista(_favoritas, lista);
    return !eraFavorita;
  }

  // ------------ Cache de previsão ------------
  Future<void> salvarPrevisao(int codigo, String xml, DateTime quando) =>
      _prefs.setString(
        _chaveCache(codigo),
        jsonEncode({'xml': xml, 'consultadoEm': quando.toIso8601String()}),
      );

  Future<({String xml, DateTime consultadoEm})?> previsaoSalva(
      int codigo) async {
    try {
      final json = await _prefs.getString(_chaveCache(codigo));
      if (json == null) return null;
      final m = jsonDecode(json) as Map<String, dynamic>;
      final quando = DateTime.tryParse('${m['consultadoEm']}');
      final xml = m['xml'];
      if (xml is! String || quando == null) return null;
      return (xml: xml, consultadoEm: quando);
    } catch (_) {
      return null;
    }
  }
}
