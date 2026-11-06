import 'package:flutter/material.dart';

class CondicaoTempo {
  final String descricao;
  final IconData icone;
  final Color cor;
  const CondicaoTempo(this.descricao, this.icone, this.cor);
}

const _sol = Color(0xFFF9A825);
const _nuvem = Color(0xFF78909C);
const _chuva = Color(0xFF1E88E5);
const _tempestade = Color(0xFF5E35B1);
const _frio = Color(0xFF4DD0E1);

/// Tabela de siglas de "tempo" conforme a documentação do CPTEC/INPE
/// (http://servicos.cptec.inpe.br/XML/#condicoes-tempo).
const Map<String, CondicaoTempo> condicoesTempo = {
  'ec': CondicaoTempo('Encoberto com Chuvas Isoladas', Icons.grain, _chuva),
  'ci': CondicaoTempo('Chuvas Isoladas', Icons.grain, _chuva),
  'c': CondicaoTempo('Chuva', Icons.water_drop, _chuva),
  'in': CondicaoTempo('Instável', Icons.thunderstorm_outlined, _tempestade),
  'pp': CondicaoTempo('Possibilidade de Pancadas de Chuva', Icons.grain, _chuva),
  'cm': CondicaoTempo('Chuva pela Manhã', Icons.water_drop, _chuva),
  'cn': CondicaoTempo('Chuva à Noite', Icons.water_drop, _chuva),
  'pt': CondicaoTempo('Pancadas de Chuva à Tarde', Icons.grain, _chuva),
  'pm': CondicaoTempo('Pancadas de Chuva pela Manhã', Icons.grain, _chuva),
  'np': CondicaoTempo('Nublado e Pancadas de Chuva', Icons.grain, _chuva),
  'pc': CondicaoTempo('Pancadas de Chuva', Icons.grain, _chuva),
  'pn': CondicaoTempo('Parcialmente Nublado', Icons.wb_cloudy_outlined, _sol),
  'cv': CondicaoTempo('Chuvisco', Icons.grain, _chuva),
  'ch': CondicaoTempo('Chuvoso', Icons.umbrella, _chuva),
  't': CondicaoTempo('Tempestade', Icons.thunderstorm, _tempestade),
  'ps': CondicaoTempo('Predomínio de Sol', Icons.wb_sunny, _sol),
  'e': CondicaoTempo('Encoberto', Icons.cloud, _nuvem),
  'n': CondicaoTempo('Nublado', Icons.cloud_outlined, _nuvem),
  'cl': CondicaoTempo('Céu Claro', Icons.wb_sunny_outlined, _sol),
  'nv': CondicaoTempo('Nevoeiro', Icons.foggy, _nuvem),
  'g': CondicaoTempo('Geada', Icons.ac_unit, _frio),
  'ne': CondicaoTempo('Neve', Icons.ac_unit, _frio),
  'nd': CondicaoTempo('Não Definido', Icons.help_outline, _nuvem),
  'pnt': CondicaoTempo('Pancadas de Chuva à Noite', Icons.grain, _chuva),
  'psc': CondicaoTempo('Possibilidade de Chuva', Icons.umbrella, _chuva),
  'pcm': CondicaoTempo('Possibilidade de Chuva pela Manhã', Icons.umbrella, _chuva),
  'pct': CondicaoTempo('Possibilidade de Chuva à Tarde', Icons.umbrella, _chuva),
  'pcn': CondicaoTempo('Possibilidade de Chuva à Noite', Icons.umbrella, _chuva),
  'npt': CondicaoTempo('Nublado com Pancadas à Tarde', Icons.grain, _chuva),
  'npn': CondicaoTempo('Nublado com Pancadas à Noite', Icons.grain, _chuva),
  'ncn': CondicaoTempo(
      'Nublado com Possibilidade de Chuva à Noite', Icons.umbrella, _chuva),
  'nct': CondicaoTempo(
      'Nublado com Possibilidade de Chuva à Tarde', Icons.umbrella, _chuva),
  'ncm': CondicaoTempo(
      'Nublado com Possibilidade de Chuva pela Manhã', Icons.umbrella, _chuva),
  'npm': CondicaoTempo('Nublado com Pancadas pela Manhã', Icons.grain, _chuva),
  'npp': CondicaoTempo(
      'Nublado com Possibilidade de Chuva', Icons.umbrella, _chuva),
  'vn': CondicaoTempo('Variação de Nebulosidade', Icons.filter_drama, _nuvem),
  'ct': CondicaoTempo('Chuva à Tarde', Icons.water_drop, _chuva),
  'ppn': CondicaoTempo(
      'Possibilidade de Pancadas de Chuva à Noite', Icons.grain, _chuva),
  'ppt': CondicaoTempo(
      'Possibilidade de Pancadas de Chuva à Tarde', Icons.grain, _chuva),
  'ppm': CondicaoTempo(
      'Possibilidade de Pancadas de Chuva pela Manhã', Icons.grain, _chuva),
};

const _desconhecida =
    CondicaoTempo('Condição não informada', Icons.help_outline, _nuvem);

CondicaoTempo condicaoPorSigla(String? sigla) =>
    condicoesTempo[(sigla ?? '').trim().toLowerCase()] ?? _desconhecida;

/// Classificação do índice ultravioleta (escala da OMS).
({String rotulo, Color cor}) classificarIuv(double iuv) {
  if (iuv < 3) return (rotulo: 'Baixo', cor: const Color(0xFF43A047));
  if (iuv < 6) return (rotulo: 'Moderado', cor: const Color(0xFFFDD835));
  if (iuv < 8) return (rotulo: 'Alto', cor: const Color(0xFFFB8C00));
  if (iuv < 11) return (rotulo: 'Muito alto', cor: const Color(0xFFE53935));
  return (rotulo: 'Extremo', cor: const Color(0xFF8E24AA));
}
