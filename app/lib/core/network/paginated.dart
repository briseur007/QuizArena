/// Réponse paginée de l'API : `{ items, page, limit, total }` (A9).
class Paginated<T> {
  const Paginated({required this.items, required this.page, required this.total});

  factory Paginated.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) itemFromJson) => Paginated(
    items: (json['items'] as List).cast<Map<String, dynamic>>().map(itemFromJson).toList(),
    page: (json['page'] as num?)?.toInt() ?? 1,
    total: (json['total'] as num?)?.toInt() ?? 0,
  );

  final List<T> items;
  final int page;
  final int total;
}
