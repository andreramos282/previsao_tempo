import 'package:flutter/material.dart';

import '../main.dart';
import '../models/cidade.dart';
import '../widgets/comuns.dart';
import 'previsao_screen.dart';

class ResultadosScreen extends StatefulWidget {
  const ResultadosScreen({super.key, required this.termo});

  final String termo;

  @override
  State<ResultadosScreen> createState() => _ResultadosScreenState();
}

class _ResultadosScreenState extends State<ResultadosScreen> {
  Future<List<Cidade>>? _futuro;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _futuro ??= _buscar();
  }

  Future<List<Cidade>> _buscar() =>
      RepositorioScope.of(context).buscarCidades(widget.termo);

  void _tentarNovamente() => setState(() => _futuro = _buscar());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Resultados para "${widget.termo}"')),
      body: FutureBuilder<List<Cidade>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Carregando(texto: 'Buscando localidades no CPTEC...');
          }
          if (snap.hasError) {
            return MensagemEstado(
              icone: Icons.cloud_off,
              titulo: 'Não foi possível buscar as cidades',
              detalhe: '${snap.error}',
              acao: _tentarNovamente,
            );
          }
          final cidades = snap.data ?? const [];
          if (cidades.isEmpty) {
            return MensagemEstado(
              icone: Icons.location_off_outlined,
              titulo: 'Nenhuma cidade encontrada',
              detalhe: 'Não há localidades com o nome "${widget.termo}". '
                  'Verifique a grafia e tente novamente.',
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('${cidades.length} localidade(s) encontrada(s)',
                      style: Theme.of(context).textTheme.labelLarge),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: cidades.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final c = cidades[i];
                    return ListTile(
                      leading: CircleAvatar(child: Text(c.uf)),
                      title: Text(c.nome),
                      subtitle: Text('UF: ${c.uf}  •  código ${c.id}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => PrevisaoScreen(cidade: c)),
                      ),
                    );
                  },
                ),
              ),
              const FonteCptec(),
            ],
          );
        },
      ),
    );
  }
}
