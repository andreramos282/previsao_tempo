class Cidade {
  /// Código da localidade retornado pelo próprio serviço do CPTEC.
  final int id;
  final String nome;
  final String uf;

  const Cidade({required this.id, required this.nome, required this.uf});

  String get rotulo => uf.isEmpty ? nome : '$nome - $uf';

  Map<String, Object?> toJson() => {'id': id, 'nome': nome, 'uf': uf};

  static Cidade? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = int.tryParse('${json['id']}');
    final nome = json['nome']?.toString();
    if (id == null || nome == null || nome.isEmpty) return null;
    return Cidade(id: id, nome: nome, uf: json['uf']?.toString() ?? '');
  }

  @override
  bool operator ==(Object other) => other is Cidade && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
