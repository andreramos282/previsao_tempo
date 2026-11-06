import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:previsao_tempo/data/armazenamento_local.dart';
import 'package:previsao_tempo/data/previsao_repository.dart';
import 'package:previsao_tempo/models/cidade.dart';
import 'package:previsao_tempo/services/cptec_parser.dart';
import 'package:previsao_tempo/services/cptec_service.dart';
import 'package:previsao_tempo/utils/condicoes_tempo.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'dados_exemplo.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('CptecParser', () {
    test('interpreta lista de cidades em ISO-8859-1', () {
      final texto = CptecParser.decodificar(latin1.encode(xmlCidades));
      final cidades = CptecParser.cidades(texto);
      expect(cidades.length, 2);
      expect(cidades.first.nome, 'Jacareí');
      expect(cidades.first.uf, 'SP');
      expect(cidades.first.id, 2641);
    });

    test('lista vazia quando nenhuma cidade é encontrada', () {
      expect(CptecParser.cidades('<cidades></cidades>'), isEmpty);
    });

    test('ignora cidades sem id', () {
      const xml = '<cidades><cidade><nome>X</nome><uf>SP</uf></cidade></cidades>';
      expect(CptecParser.cidades(xml), isEmpty);
    });

    test('interpreta previsão de 4 dias', () {
      final p = CptecParser.previsao(xmlPrevisao)!;
      expect(p.cidade, 'Jacareí');
      expect(p.atualizacao, DateTime(2026, 11, 6));
      expect(p.dias.length, 4);
      expect(p.dias[0].sigla, 'ps');
      expect(p.dias[0].maxima, 31);
      expect(p.dias[0].minima, 17);
      expect(p.dias[0].iuv, 11.0);
    });

    test('campos ausentes não quebram a interpretação', () {
      const xml = '''<cidade><nome>Teste</nome><uf>SP</uf>
        <previsao><dia>2026-11-06</dia></previsao>
        <previsao><dia>2026-11-07</dia><tempo>c</tempo><maxima>abc</maxima></previsao>
      </cidade>''';
      final p = CptecParser.previsao(xml)!;
      expect(p.atualizacao, isNull);
      expect(p.dias.length, 2);
      expect(p.dias[0].sigla, 'nd');
      expect(p.dias[0].maxima, isNull);
      expect(p.dias[1].iuv, isNull);
    });

    test('cidade sem previsão retorna null', () {
      const xml = '<cidade><nome>null</nome><uf>null</uf>'
          '<atualizacao>null</atualizacao></cidade>';
      expect(CptecParser.previsao(xml), isNull);
    });

    test('XML malformado gera RespostaInvalidaException', () {
      expect(() => CptecParser.previsao('<cidade><nome>x</cidade'),
          throwsA(isA<RespostaInvalidaException>()));
      expect(() => CptecParser.cidades('<html>erro</html>'),
          throwsA(isA<RespostaInvalidaException>()));
      expect(() => CptecParser.cidades(''),
          throwsA(isA<RespostaInvalidaException>()));
    });
  });

  group('Condições do tempo', () {
    test('converte siglas em descrições', () {
      expect(condicaoPorSigla('ps').descricao, 'Predomínio de Sol');
      expect(condicaoPorSigla('PN').descricao, 'Parcialmente Nublado');
      expect(condicaoPorSigla('t').descricao, 'Tempestade');
      expect(condicaoPorSigla('xyz').descricao, 'Condição não informada');
      expect(condicaoPorSigla(null).descricao, 'Condição não informada');
    });

    test('tabela contém as 40 siglas do CPTEC', () {
      expect(condicoesTempo.length, 40);
    });
  });

  group('CptecService', () {
    test('remove acentos do parâmetro city', () {
      expect(CptecService.normalizarNome('  São José  dos Campos '),
          'sao jose dos campos');
      expect(CptecService.normalizarNome('Jacareí'), 'jacarei');
    });

    test('monta a URL de busca com o parâmetro city', () async {
      Uri? chamada;
      final s = CptecService(
        client: MockClient((req) async {
          chamada = req.url;
          return http.Response.bytes(latin1.encode(xmlCidades), 200);
        }),
      );
      await s.buscarCidades('Jacareí');
      expect(chamada.toString(),
          'http://servicos.cptec.inpe.br/XML/listaCidades?city=jacarei');
    });

    test('HTTP 500 vira falha de indisponibilidade', () async {
      final s = CptecService(
          client: MockClient((_) async => http.Response('erro', 503)));
      expect(
        s.buscarPrevisao(1),
        throwsA(isA<CptecException>()
            .having((e) => e.tipo, 'tipo', TipoFalha.indisponivel)),
      );
    });

    test('falha de rede vira semConexao', () async {
      final s = CptecService(
          client: MockClient((_) async => throw const SocketException('x')));
      expect(
        s.buscarCidades('x'),
        throwsA(isA<CptecException>()
            .having((e) => e.tipo, 'tipo', TipoFalha.semConexao)),
      );
    });
  });

  group('PrevisaoRepository', () {
    const cidade = Cidade(id: 2641, nome: 'Jacareí', uf: 'SP');

    test('salva cache e usa quando a rede falha', () async {
      var online = true;
      final repo = PrevisaoRepository(
        servico: CptecService(
          client: MockClient((_) async {
            if (!online) throw const SocketException('offline');
            return http.Response.bytes(latin1.encode(xmlPrevisao), 200);
          }),
        ),
        local: ArmazenamentoLocal(),
      );

      final r1 = await repo.previsao(cidade);
      expect(r1.doCache, isFalse);

      online = false;
      final r2 = await repo.previsao(cidade);
      expect(r2.doCache, isTrue);
      expect(r2.previsao.dias.length, 4);
      expect(await repo.local.recentes(), [cidade]);
    });

    test('sem previsão lança SemPrevisaoException', () async {
      final repo = PrevisaoRepository(
        servico: CptecService(
          client: MockClient((_) async => http.Response(
              '<cidade><nome>null</nome><uf>null</uf></cidade>', 200)),
        ),
      );
      expect(repo.previsao(cidade), throwsA(isA<SemPrevisaoException>()));
    });

    test('favoritas alternam e persistem', () async {
      final local = ArmazenamentoLocal();
      expect(await local.alternarFavorita(cidade), isTrue);
      expect(await local.favoritas(), [cidade]);
      expect(await local.alternarFavorita(cidade), isFalse);
      expect(await local.favoritas(), isEmpty);
    });
  });
}
