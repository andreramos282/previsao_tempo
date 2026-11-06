import 'package:flutter/material.dart';

import '../main.dart';
import '../models/cidade.dart';
import '../widgets/comuns.dart';
import 'previsao_screen.dart';
import 'resultados_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _busca = TextEditingController();
  List<Cidade> _favoritas = [];
  List<Cidade> _recentes = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarSalvos());
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  Future<void> _carregarSalvos() async {
    final local = RepositorioScope.of(context).local;
    final fav = await local.favoritas();
    final rec = await local.recentes();
    if (!mounted) return;
    setState(() {
      _favoritas = fav;
      _recentes = rec;
      _carregando = false;
    });
  }

  void _pesquisar() {
    final termo = _busca.text.trim();
    if (termo.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite ao menos 2 letras do nome da cidade.')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ResultadosScreen(termo: termo)),
    ).then((_) => _carregarSalvos());
  }

  void _abrir(Cidade c) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PrevisaoScreen(cidade: c)),
    ).then((_) => _carregarSalvos());
  }

  Future<void> _removerRecente(Cidade c) async {
    await RepositorioScope.of(context).local.removerRecente(c);
    _carregarSalvos();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Previsão do Tempo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Para onde você quer ver a previsão?',
              style: tema.textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _busca,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _pesquisar(),
            decoration: InputDecoration(
              hintText: 'Nome da cidade (ex.: Jacareí)',
              prefixIcon: const Icon(Icons.location_city),
              suffixIcon: IconButton(
                tooltip: 'Pesquisar',
                icon: const Icon(Icons.search),
                onPressed: _pesquisar,
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_carregando)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_favoritas.isEmpty && _recentes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.wb_sunny_outlined,
                      size: 80, color: tema.colorScheme.primary),
                  const SizedBox(height: 12),
                  const Text(
                    'Pesquise uma cidade para ver a previsão de 4 dias.\n'
                    'Suas cidades favoritas e recentes aparecerão aqui.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else ...[
            if (_favoritas.isNotEmpty) ...[
              _Secao(icone: Icons.star, titulo: 'Favoritas'),
              Card(
                child: Column(
                  children: [
                    for (final c in _favoritas)
                      ListTile(
                        leading: const Icon(Icons.star, color: Colors.amber),
                        title: Text(c.nome),
                        subtitle: Text(c.uf),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _abrir(c),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_recentes.isNotEmpty) ...[
              _Secao(icone: Icons.history, titulo: 'Consultadas recentemente'),
              Card(
                child: Column(
                  children: [
                    for (final c in _recentes)
                      ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(c.nome),
                        subtitle: Text(c.uf),
                        trailing: IconButton(
                          tooltip: 'Remover do histórico',
                          icon: const Icon(Icons.close),
                          onPressed: () => _removerRecente(c),
                        ),
                        onTap: () => _abrir(c),
                      ),
                  ],
                ),
              ),
            ],
          ],
          const FonteCptec(),
        ],
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao({required this.icone, required this.titulo});
  final IconData icone;
  final String titulo;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Row(children: [
          Icon(icone, size: 18),
          const SizedBox(width: 8),
          Text(titulo, style: Theme.of(context).textTheme.titleSmall),
        ]),
      );
}
