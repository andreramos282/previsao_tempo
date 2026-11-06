import 'dart:convert';

import 'package:xml/xml.dart';

import '../models/cidade.dart';
import '../models/previsao.dart';

class RespostaInvalidaException implements Exception {
  final String detalhe;
  const RespostaInvalidaException(this.detalhe);
  @override
  String toString() => 'Resposta inválida do CPTEC: $detalhe';
}

/// Funções puras de interpretação do XML do CPTEC/INPE (testáveis sem rede).
class CptecParser {
  const CptecParser._();

  /// O CPTEC costuma responder em ISO-8859-1; respeita o encoding declarado.
  static String decodificar(List<int> bytes) {
    final inicio = latin1.decode(
      bytes.length > 120 ? bytes.sublist(0, 120) : bytes,
      allowInvalid: true,
    );
    final declarado = RegExp(r'encoding="([^"]+)"', caseSensitive: false)
        .firstMatch(inicio)
        ?.group(1)
        ?.toLowerCase();
    if (declarado != null &&
        (declarado.contains('8859') || declarado.contains('latin'))) {
      return latin1.decode(bytes, allowInvalid: true);
    }
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return latin1.decode(bytes, allowInvalid: true);
    }
  }

  static XmlDocument _parse(String xml) {
    if (xml.trim().isEmpty) {
      throw const RespostaInvalidaException('corpo vazio');
    }
    try {
      return XmlDocument.parse(xml.trim());
    } on XmlException catch (e) {
      throw RespostaInvalidaException('XML malformado (${e.message})');
    }
  }

  static String? _texto(XmlElement e, String tag) {
    final t = e.getElement(tag)?.innerText.trim();
    if (t == null || t.isEmpty || t.toLowerCase() == 'null') return null;
    return t;
  }

  static DateTime? _data(String? t) => t == null ? null : DateTime.tryParse(t);

  static int? _inteiro(String? t) {
    if (t == null) return null;
    return int.tryParse(t) ?? double.tryParse(t.replaceAll(',', '.'))?.round();
  }

  static double? _decimal(String? t) =>
      t == null ? null : double.tryParse(t.replaceAll(',', '.'));

  /// `<cidades><cidade><nome/><uf/><id/></cidade>...</cidades>`
  static List<Cidade> cidades(String xml) {
    final doc = _parse(xml);
    final raiz = doc.rootElement;
    if (raiz.name.local != 'cidades') {
      throw RespostaInvalidaException('raiz <${raiz.name.local}> inesperada');
    }
    final lista = <Cidade>[];
    for (final c in raiz.findElements('cidade')) {
      final id = _inteiro(_texto(c, 'id'));
      final nome = _texto(c, 'nome');
      if (id == null || nome == null) continue; // ignora registros incompletos
      lista.add(Cidade(id: id, nome: nome, uf: _texto(c, 'uf') ?? ''));
    }
    return lista;
  }

  /// Estrutura esperada: `cidade` > `nome`, `uf`, `atualizacao` e vários
  /// `previsao` > `dia`, `tempo`, `maxima`, `minima`, `iuv`.
  ///
  /// Retorna `null` quando o serviço não tem previsão para a localidade.
  static Previsao? previsao(String xml) {
    final doc = _parse(xml);
    final raiz = doc.rootElement;
    if (raiz.name.local != 'cidade') {
      throw RespostaInvalidaException('raiz <${raiz.name.local}> inesperada');
    }
    final dias = <PrevisaoDia>[];
    for (final p in raiz.findElements('previsao')) {
      final dia = PrevisaoDia(
        data: _data(_texto(p, 'dia')),
        sigla: _texto(p, 'tempo') ?? 'nd',
        maxima: _inteiro(_texto(p, 'maxima')),
        minima: _inteiro(_texto(p, 'minima')),
        iuv: _decimal(_texto(p, 'iuv')),
      );
      // Um dia sem data e sem temperaturas não tem informação útil.
      if (dia.data == null && dia.maxima == null && dia.minima == null) {
        continue;
      }
      dias.add(dia);
    }
    final nome = _texto(raiz, 'nome');
    if (dias.isEmpty || nome == null) return null;
    return Previsao(
      cidade: nome,
      uf: _texto(raiz, 'uf') ?? '',
      atualizacao: _data(_texto(raiz, 'atualizacao')),
      dias: dias,
    );
  }
}
