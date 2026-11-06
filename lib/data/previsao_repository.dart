import '../models/cidade.dart';
import '../models/previsao.dart';
import '../services/cptec_parser.dart';
import '../services/cptec_service.dart';
import 'armazenamento_local.dart';

class SemPrevisaoException implements Exception {
  const SemPrevisaoException();
  @override
  String toString() =>
      'Não há previsão disponível para esta localidade no momento.';
}

/// Junta o serviço remoto e o armazenamento local:
/// consulta o CPTEC e, se falhar a conexão, devolve a última previsão salva.
class PrevisaoRepository {
  PrevisaoRepository({CptecService? servico, ArmazenamentoLocal? local})
      : servico = servico ?? CptecService(),
        local = local ?? ArmazenamentoLocal();

  final CptecService servico;
  final ArmazenamentoLocal local;

  Future<List<Cidade>> buscarCidades(String nome) =>
      servico.buscarCidades(nome);

  Future<ResultadoPrevisao> previsao(Cidade cidade) async {
    await local.registrarRecente(cidade);
    try {
      final r = await servico.buscarPrevisao(cidade.id);
      if (r.previsao == null) throw const SemPrevisaoException();
      final agora = DateTime.now();
      await local.salvarPrevisao(cidade.id, r.xml, agora);
      return ResultadoPrevisao(previsao: r.previsao!, consultadoEm: agora);
    } on CptecException catch (e) {
      // Só recorre ao cache em falhas de rede/serviço.
      final salvo = await local.previsaoSalva(cidade.id);
      if (salvo == null) rethrow;
      final p = _parseSeguro(salvo.xml);
      if (p == null) rethrow;
      return ResultadoPrevisao(
        previsao: p,
        consultadoEm: salvo.consultadoEm,
        doCache: true,
        avisoCache: e.mensagem,
      );
    }
  }

  Previsao? _parseSeguro(String xml) {
    try {
      return CptecParser.previsao(xml);
    } catch (_) {
      return null;
    }
  }
}
