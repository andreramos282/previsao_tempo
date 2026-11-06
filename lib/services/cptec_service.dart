import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/cidade.dart';
import '../models/previsao.dart';
import 'cptec_parser.dart';

enum TipoFalha { semConexao, tempoEsgotado, indisponivel, respostaInvalida }

class CptecException implements Exception {
  final TipoFalha tipo;
  final String mensagem;
  const CptecException(this.tipo, this.mensagem);
  @override
  String toString() => mensagem;
}

/// Cliente do serviço XML do CPTEC/INPE.
/// Documentação: http://servicos.cptec.inpe.br/XML/
class CptecService {
  CptecService({http.Client? client}) : _client = client ?? http.Client();

  static const base = 'http://servicos.cptec.inpe.br/XML';
  static const _timeout = Duration(seconds: 20);
  final http.Client _client;

  /// O serviço não aceita acentos no parâmetro `city`.
  static String normalizarNome(String nome) {
    const com = 'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ';
    const sem = 'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN';
    final buffer = StringBuffer();
    for (final ch in nome.trim().split('')) {
      final i = com.indexOf(ch);
      buffer.write(i >= 0 ? sem[i] : ch);
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  /// GET /listaCidades?city={nome}
  Future<List<Cidade>> buscarCidades(String nome) async {
    final uri = Uri.parse('$base/listaCidades')
        .replace(queryParameters: {'city': normalizarNome(nome)});
    final xml = await _get(uri);
    return _interpretar(() => CptecParser.cidades(xml));
  }

  /// GET /cidade/{codigo}/previsao.xml (previsão para 4 dias).
  /// Retorna o XML bruto (para cache) e a previsão interpretada.
  Future<({String xml, Previsao? previsao})> buscarPrevisao(int codigo) async {
    final xml = await _get(Uri.parse('$base/cidade/$codigo/previsao.xml'));
    return (xml: xml, previsao: _interpretar(() => CptecParser.previsao(xml)));
  }

  T _interpretar<T>(T Function() f) {
    try {
      return f();
    } on RespostaInvalidaException catch (e) {
      throw CptecException(TipoFalha.respostaInvalida, e.toString());
    }
  }

  Future<String> _get(Uri uri) async {
    try {
      final resp = await _client.get(uri).timeout(_timeout);
      if (resp.statusCode >= 500 || resp.statusCode == 404) {
        throw CptecException(
          TipoFalha.indisponivel,
          'O serviço do CPTEC/INPE está indisponível no momento '
          '(HTTP ${resp.statusCode}). Tente novamente mais tarde.',
        );
      }
      if (resp.statusCode != 200) {
        throw CptecException(
          TipoFalha.respostaInvalida,
          'Resposta inesperada do CPTEC/INPE (HTTP ${resp.statusCode}).',
        );
      }
      return CptecParser.decodificar(resp.bodyBytes);
    } on CptecException {
      rethrow;
    } on TimeoutException {
      throw const CptecException(
        TipoFalha.tempoEsgotado,
        'O CPTEC/INPE demorou demais para responder. Tente novamente.',
      );
    } on SocketException {
      throw const CptecException(
        TipoFalha.semConexao,
        'Sem conexão com a internet. Verifique sua rede.',
      );
    } on HandshakeException {
      throw const CptecException(
        TipoFalha.semConexao,
        'Falha na conexão segura com o servidor.',
      );
    } on http.ClientException {
      throw const CptecException(
        TipoFalha.semConexao,
        'Falha de conexão com o servidor do CPTEC/INPE.',
      );
    }
  }
}
