class MotorcycleImage {
  final int id;
  final String url;
  MotorcycleImage({required this.id, required this.url});
}

class Motorcycle {
  final int id;
  final String brand;
  final String model;
  final String plateNumber;
  final num pricePerDay;
  final bool available;
  final String? imageUrl; // cover
  final List<MotorcycleImage> images; // gallery images

  Motorcycle({
    required this.id,
    required this.brand,
    required this.model,
    required this.plateNumber,
    required this.pricePerDay,
    required this.available,
    this.imageUrl,
    this.images = const [],
  });

  String? get firstImageUrl => imageUrl ?? (images.isNotEmpty ? images.first.url : null);
  List<String> get imageUrls => images.map((e) => e.url).toList();

  factory Motorcycle.fromJson(Map<String, dynamic> j) {
    final imgs = <MotorcycleImage>[];
    final raw = j['images'];
    if (raw is List) {
      for (final it in raw) {
        if (it is Map) {
          final url = it['image_url'];
          final imgId = it['id'];
          if (url is String) {
            imgs.add(MotorcycleImage(id: (imgId is int) ? imgId : 0, url: url));
          }
        } else if (it is String) {
          imgs.add(MotorcycleImage(id: 0, url: it));
        }
      }
    }
    return Motorcycle(
      id: _asInt(j['id']),
      brand: j['brand'] ?? '',
      model: j['model'] ?? '',
      plateNumber: j['plate_number'] ?? '',
      pricePerDay: _asNum(j['price_per_day']),
      available: (j['available'] == 1 || j['available'] == true),
      imageUrl: j['image_url'] as String?,
      images: imgs,
    );
  }
}

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  if (v is num) return v.toInt();
  return 0;
}

num _asNum(dynamic v) {
  if (v is num) return v;
  if (v is String) return num.tryParse(v) ?? 0;
  return 0;
}
