import 'package:flutter/material.dart';
import '../models/motorcycle.dart';
import '../utils/api_endpoints.dart';
import 'package:provider/provider.dart';
import '../providers/rental_provider.dart';
import '../providers/motorcycle_provider.dart';
import '../providers/auth_provider.dart';
import '../services/motorcycle_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'login_screen.dart';

class MotorcycleDetailScreen extends StatefulWidget {
  final Motorcycle motorcycle;
  const MotorcycleDetailScreen({super.key, required this.motorcycle});
  @override
  State<MotorcycleDetailScreen> createState() => _MotorcycleDetailScreenState();
}

class _MotorcycleDetailScreenState extends State<MotorcycleDetailScreen> {
  DateTime? start;
  DateTime? end;

  Future<void> pickStart() async {
    final now = DateTime.now();
    final d = await showDatePicker(context: context, firstDate: now, lastDate: now.add(const Duration(days: 365)), initialDate: now);
    if(d!=null) setState(()=> start=d);
  }
  Future<void> pickEnd() async {
    final base = start ?? DateTime.now();
    final d = await showDatePicker(context: context, firstDate: base, lastDate: base.add(const Duration(days: 365)), initialDate: base);
    if(d!=null) setState(()=> end=d);
  }

  @override
  Widget build(BuildContext context) {
    final rentalProv = context.watch<RentalProvider>();
    final m = widget.motorcycle;
    final int days = (start != null && end != null) ? end!.difference(start!).inDays + 1 : 0;
    final int totalPrice = days > 0 ? (m.pricePerDay * days).toInt() : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('${m.brand} ${m.model}'),
        actions: [
          if (context.read<AuthProvider>().currentUser?.role == 'admin')
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {},
              tooltip: 'Edit Motor',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel
            _ImagesCarousel(m: m),
            
            // Info Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price Tag
                  Row(
                    children: [
                      Text(
                        'Rp ${_formatPrice(m.pricePerDay)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF002F34),
                        ),
                      ),
                      Text(
                        ' / hari',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    '${m.brand} ${m.model}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: m.available ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: m.available ? Colors.green : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          m.available ? Icons.check_circle : Icons.cancel,
                          size: 16,
                          color: m.available ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          m.available ? 'Tersedia' : 'Tidak Tersedia',
                          style: TextStyle(
                            color: m.available ? Colors.green.shade800 : Colors.red.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Specifications Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Spesifikasi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SpecRow(icon: Icons.confirmation_number, label: 'Plat Nomor', value: m.plateNumber),
                  const Divider(height: 24),
                  _SpecRow(icon: Icons.motorcycle, label: 'Merk', value: m.brand),
                  const Divider(height: 24),
                  _SpecRow(icon: Icons.directions_bike, label: 'Model', value: m.model),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Rental Form Card
            if (m.available)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Periode Sewa',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Start Date
                    _DatePickerRow(
                      label: 'Tanggal Mulai',
                      date: start,
                      onTap: pickStart,
                    ),
                    const SizedBox(height: 12),
                    
                    // End Date
                    _DatePickerRow(
                      label: 'Tanggal Selesai',
                      date: end,
                      onTap: pickEnd,
                    ),
                    
                    if (days > 0) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Durasi',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            '$days hari',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Harga',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Rp ${_formatPrice(totalPrice)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF002F34),
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    if (rentalProv.error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                rentalProv.error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            
            const SizedBox(height: 80),
          ],
        ),
      ),
      
      // Bottom Action Button
      bottomNavigationBar: m.available
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (rentalProv.loading || start == null || end == null)
                        ? null
                        : () async {
                            // Check if user is logged in
                            final auth = context.read<AuthProvider>();
                            if (auth.currentUser == null) {
                              // Show login dialog
                              final shouldLogin = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: const Text('Login Diperlukan'),
                                  content: const Text(
                                    'Anda harus login terlebih dahulu untuk menyewa motor.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Batal'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Login'),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (shouldLogin == true && mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                );
                              }
                              return;
                            }
                            
                            // Proceed with rental
                            final ok = await rentalProv.create(
                              m.id,
                              start!.toIso8601String().substring(0, 10),
                              end!.toIso8601String().substring(0, 10),
                            );
                            if (ok && mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Sewa berhasil dibuat'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: rentalProv.loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Sewa Sekarang',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  String _formatPrice(num price) {
    if (price >= 1000000) {
      final val = price / 1000000;
      return '${val.toStringAsFixed(val % 1 == 0 ? 0 : 1)} Jt';
    } else if (price >= 1000) {
      final val = price / 1000;
      return '${val.toStringAsFixed(val % 1 == 0 ? 0 : 0)} Rb';
    }
    return price.toString();
  }
}

class _SpecRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  
  const _SpecRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF002F34), size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  
  const _DatePickerRow({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: const Color(0xFF002F34), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date == null ? 'Pilih tanggal' : _formatDate(date!),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: date == null ? Colors.grey : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _ImagesCarousel extends StatefulWidget {
  final Motorcycle m;
  const _ImagesCarousel({required this.m});

  @override
  State<_ImagesCarousel> createState() => _ImagesCarouselState();
}

class _ImagesCarouselState extends State<_ImagesCarousel> {
  int _index = 0;
  late List<MotorcycleImage> _images;
  String? _coverUrl;
  final _service = MotorcycleService();
  final _picker = ImagePicker();
  bool _showHint = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showHint = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    _images = widget.m.images;
    _coverUrl = widget.m.imageUrl;
    final urls = _images.isNotEmpty ? _images.map((e) => e.url).toList() : (_coverUrl != null ? [_coverUrl!] : <String>[]);

    if (urls.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Text('No Image'),
      );
    }

    final isAdmin = context.read<AuthProvider>().currentUser?.role == 'admin';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Spacer(),
            if (isAdmin)
              TextButton.icon(
                onPressed: _pickAndUpload,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Tambah Gambar'),
              ),
          ],
        ),
        Stack(
          children: [
            AspectRatio(
              aspectRatio: 16/9,
              child: PageView.builder(
                itemCount: urls.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: _ImageSlide(
                          url: '${ApiConfig.absolute(urls[i])}?t=${DateTime.now().millisecondsSinceEpoch ~/ 5000}',
                          isAdmin: isAdmin,
                          onLongPressDelete: () => _confirmDelete(context, i),
                        ),
                      ),
                      if (isAdmin && _images.isNotEmpty)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Material(
                            color: Colors.black45,
                            shape: const CircleBorder(),
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.white),
                              onPressed: () => _confirmDelete(context, i),
                              tooltip: 'Hapus gambar',
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            if (isAdmin && _showHint)
              Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: IgnorePointer(
                  ignoring: true,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Long press untuk hapus',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (urls.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(urls.length, (i) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == _index ? Colors.blueAccent : Colors.grey.shade400,
              ),
            )),
          ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, int index) async {
    if (_images.isEmpty || index < 0 || index >= _images.length) return;
    final image = _images[index];
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Gambar'),
        content: const Text('Yakin ingin menghapus gambar ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    ) ?? false;
    if (!ok) return;
    try {
      await _service.deleteImage(widget.m.id, image.id);
      // refresh local images by removing
      setState(() {
        _images.removeAt(index);
        if (_coverUrl == image.url) {
          _coverUrl = _images.isNotEmpty ? _images.first.url : null;
        }
        if (_index >= _images.length) _index = (_images.isEmpty ? 0 : _images.length - 1);
      });
      // refresh list page
      if (mounted) {
        context.read<MotorcycleProvider>().load();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gambar dihapus')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal hapus: $e')));
      }
    }
  }

  Future<void> _pickAndUpload() async {
    try {
      final picks = await _picker.pickMultiImage();
      if (picks.isEmpty) return;
      final paths = picks.map((x) => x.path).toList();
      final uploaded = await _service.uploadImagesPaths(widget.m.id, paths);
      setState(() {
        _images = uploaded;
        if (_images.isNotEmpty) {
          _coverUrl ??= _images.first.url;
        }
      });
      if (mounted) {
        context.read<MotorcycleProvider>().load();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gambar diunggah')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal unggah: $e')));
      }
    }
  }
}

class _ImageSlide extends StatelessWidget {
  final String url;
  final bool isAdmin;
  final VoidCallback onLongPressDelete;
  const _ImageSlide({required this.url, required this.isAdmin, required this.onLongPressDelete});

  @override
  Widget build(BuildContext context) {
    final img = CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
      errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
    );
    if (!isAdmin) return img;
    return GestureDetector(
      onLongPress: onLongPressDelete,
      child: img,
    );
  }
}
