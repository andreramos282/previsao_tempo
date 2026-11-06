class PrevisaoDia {
  final DateTime? data;

  /// Sigla da condição do tempo (ex.: "ps", "pn", "c").
  final String sigla;
  final int? maxima;
  final int? minima;

  /// Índice ultravioleta (pode não vir no XML).
  final double? iuv;

  const PrevisaoDia({
    required this.data,
    required this.sigla,
    this.maxima,
    this.minima,
    this.iuv,
  });
}

class Previsao {
  final String cidade;
  final String uf;
  final DateTime? atualizacao;
  final List<PrevisaoDia> dias;

  const Previsao({
    required this.cidade,
    required this.uf,
    required this.atualizacao,
    required this.dias,
  });
}

/// Previsão acompanhada da origem dos dados (rede ou cache local).
class ResultadoPrevisao {
  final Previsao previsao;
  final DateTime consultadoEm;
  final bool doCache;

  /// Motivo pelo qual o cache foi usado (falha de rede, etc.).
  final String? avisoCache;

  const ResultadoPrevisao({
    required this.previsao,
    required this.consultadoEm,
    this.doCache = false,
    this.avisoCache,
  });
}
