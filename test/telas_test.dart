import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:previsao_tempo/data/previsao_repository.dart';
import 'package:previsao_tempo/main.dart';
import 'package:previsao_tempo/services/cptec_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'dados_exemplo.dart';

PrevisaoRepository _repo(Future<http.Response> Function(http.Request) h) =>
    PrevisaoRepository(servico: CptecService(client: MockClient(h)));

http.Response _ok(String xml) => http.Response.bytes(latin1.encode(xml), 200);

void main() {
  setUpAll(() async {
    Intl.defaultLocale = 'pt_BR';
    await initializeDateFormatting('pt_BR');
  });

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  Future<void> abrir(WidgetTester tester, PrevisaoRepository repo) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(PrevisaoTempoApp(repository: repo));
    await tester.pumpAndSettle();
  }

  testWidgets('fluxo completo: pesquisa → resultados → previsão',
      (tester) async {
    await abrir(
      tester,
      _repo((req) async => req.url.path.contains('listaCidades')
          ? _ok(xmlCidades)
          : _ok(xmlPrevisao)),
    );

    await tester.enterText(find.byType(TextField), 'jacarei');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('2 localidade(s) encontrada(s)'), findsOneWidget);
    expect(find.text('Jacareí'), findsOneWidget);

    await tester.tap(find.text('Jacareí'));
    await tester.pumpAndSettle();
    expect(find.text('Predomínio de Sol'), findsOneWidget);
    expect(find.text('Parcialmente Nublado'), findsOneWidget);
    expect(find.textContaining('Atualizado pelo CPTEC em 06/11/2026'),
        findsOneWidget);
    expect(find.textContaining('UV 11'), findsOneWidget);
    expect(find.text('Fonte dos dados: CPTEC/INPE'), findsWidgets);

    // Atualizar
    await tester.tap(find.byTooltip('Atualizar previsão'));
    await tester.pumpAndSettle();
    expect(find.text('Predomínio de Sol'), findsOneWidget);

    // Favoritar e voltar à home
    await tester.tap(find.byTooltip('Favoritar'));
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.text('Favoritas'), findsOneWidget);
    expect(find.text('Consultadas recentemente'), findsOneWidget);
  });

  testWidgets('nenhuma cidade encontrada', (tester) async {
    await abrir(tester, _repo((_) async => _ok('<cidades></cidades>')));
    await tester.enterText(find.byType(TextField), 'xyzxyz');
    await tester.tap(find.byTooltip('Pesquisar'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma cidade encontrada'), findsOneWidget);
  });

  testWidgets('falha de serviço mostra erro com opção de tentar novamente',
      (tester) async {
    await abrir(tester, _repo((_) async => http.Response('', 503)));
    await tester.enterText(find.byType(TextField), 'jacarei');
    await tester.tap(find.byTooltip('Pesquisar'));
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível buscar as cidades'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });

  testWidgets('resposta inválida na previsão é tratada', (tester) async {
    await abrir(
      tester,
      _repo((req) async => req.url.path.contains('listaCidades')
          ? _ok(xmlCidades)
          : http.Response('<html>manutenção</html>', 200)),
    );
    await tester.enterText(find.byType(TextField), 'jacarei');
    await tester.tap(find.byTooltip('Pesquisar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jacareí'));
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível obter a previsão'), findsOneWidget);
  });
}
