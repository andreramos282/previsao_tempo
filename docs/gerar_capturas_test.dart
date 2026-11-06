import 'dart:io';

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:previsao_tempo/data/previsao_repository.dart';
import 'package:previsao_tempo/main.dart';
import 'package:previsao_tempo/services/cptec_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../test/dados_exemplo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

Future<void> _fonte(String familia, List<String> arquivos) async {
  final loader = FontLoader(familia);
  for (final a in arquivos) {
    final bytes = File(a).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

void main() {
  final fontes = '${Platform.environment['HOME']}/flutter/bin/cache/artifacts/material_fonts';
  setUpAll(() async {
    Intl.defaultLocale = 'pt_BR';
    await initializeDateFormatting('pt_BR');
    await _fonte('Roboto', [
      '$fontes/Roboto-Regular.ttf',
      '$fontes/Roboto-Medium.ttf',
      '$fontes/Roboto-Bold.ttf',
    ]);
    await _fonte('MaterialIcons', ['$fontes/MaterialIcons-Regular.otf']);
  });

  setUp(() => SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty());

  PrevisaoRepository repo({bool falhar = false, bool vazio = false}) =>
      PrevisaoRepository(
        servico: CptecService(
          client: MockClient((req) async {
            if (falhar) throw const SocketException('offline');
            if (req.url.path.contains('listaCidades')) {
              return http.Response.bytes(
                  latin1.encode(vazio ? '<cidades></cidades>' : xmlCidades), 200);
            }
            return http.Response.bytes(latin1.encode(xmlPrevisao), 200);
          }),
        ),
      );

  Future<void> abrir(WidgetTester t, PrevisaoRepository r,
      {double altura = 780}) async {
    t.view.physicalSize = Size(360 * 3, altura * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(PrevisaoTempoApp(repository: r));
    await t.pumpAndSettle();
  }

  Future<void> foto(WidgetTester t, String nome) async {
    debugDisableShadows = false;
    for (final e in find.byType(Material).evaluate()) {
      e.renderObject?.markNeedsPaint();
    }
    await t.pump();
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('capturas/$nome.png'));
    debugDisableShadows = true;
  }

  Future<void> pesquisar(WidgetTester t, String termo) async {
    await t.enterText(find.byType(TextField), termo);
    await t.tap(find.byTooltip('Pesquisar'));
    await t.pumpAndSettle();
  }

  testWidgets('fluxo', (t) async {
    final r = repo();
    await abrir(t, r);
    await foto(t, '01_inicio');
    await pesquisar(t, 'jacarei');
    await foto(t, '02_resultados');
    await t.tap(find.text('Jacareí'));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Favoritar'));
    t.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger)).clearSnackBars();
    t.view.physicalSize = const Size(1080, 1420 * 3);
    await t.pumpAndSettle();
    await foto(t, '03_previsao');
    t.view.physicalSize = const Size(1080, 780 * 3);
    t.state<NavigatorState>(find.byType(Navigator)).pop();
    await t.pumpAndSettle();
    t.state<NavigatorState>(find.byType(Navigator)).pop();
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), '');
    await t.pumpAndSettle();
    await foto(t, '04_favoritas_recentes');
  });

  testWidgets('nenhuma cidade', (t) async {
    await abrir(t, repo(vazio: true));
    await pesquisar(t, 'cidadeinexistente');
    await foto(t, '05_nenhuma_cidade');
  });

  testWidgets('sem conexao', (t) async {
    await abrir(t, repo(falhar: true));
    await pesquisar(t, 'jacarei');
    await foto(t, '06_sem_conexao');
  });
}
