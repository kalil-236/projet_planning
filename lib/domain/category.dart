/// Catégories par défaut (section 6.3).
enum TaskCategory {
  cours('Cours'),
  etude('Étude'),
  activite('Activité'),
  repos('Repos / pause'),
  autre('Autre');

  const TaskCategory(this.label);

  final String label;

  String get id => name;

  /// Un identifiant absent ou inconnu donne [TaskCategory.autre].
  static TaskCategory fromId(String? id) {
    for (final category in values) {
      if (category.id == id) return category;
    }
    return autre;
  }
}
