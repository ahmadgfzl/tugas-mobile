import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/payment_service.dart';
import '../utils/api_endpoints.dart';
import 'package:provider/provider.dart';
import '../providers/rental_provider.dart';

class RentalsScreen extends StatefulWidget {
  const RentalsScreen({super.key});
  @override
  State<RentalsScreen> createState() => _RentalsScreenState();
}

class _RentalsScreenState extends State<RentalsScreen> {
  final Set<int> _proofUploadedRentalIds = <int>{};
  final Map<int, String> _proofUrls = <int, String>{};
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      // Seed from local storage first to avoid flicker on navigation
      try {
        final prefs = await SharedPreferences.getInstance();
        final stored = prefs.getStringList('proof_uploaded_rental_ids') ?? [];
        _proofUploadedRentalIds.addAll(stored.map((e) => int.tryParse(e)).whereType<int>());
      } catch (_) {}
      await context.read<RentalProvider>().load();
      // Seed proof uploaded state from server
      try {
        final svc = PaymentService();
        final items = await svc.listMyPayments();
        for (final p in items) {
          if ((p['proof_url'] ?? '') != '') {
            _proofUploadedRentalIds.add(p['rental_id'] as int);
            _proofUrls[p['rental_id'] as int] = p['proof_url'] as String;
          }
        }
        // Persist merged set
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList(
            'proof_uploaded_rental_ids',
            _proofUploadedRentalIds.map((e) => e.toString()).toList(),
          );
        } catch (_) {}
        if (mounted) setState(() {});
      } catch (_) {}
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'returned':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _submitPayment(BuildContext context, int rentalId, double amount) async {
    final svc = PaymentService();
    try {
      final bank = await svc.fetchBankAccountSettings();
      final bankInfo = '${bank['bank_name']} ${bank['account_number']} a.n ${bank['account_name']}';
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Konfirmasi Pembayaran'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Silakan transfer ke rekening berikut:'),
                const SizedBox(height: 8),
                Text(bankInfo),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        final accountNumber = bank['account_number'] ?? '';
                        Clipboard.setData(ClipboardData(text: accountNumber));
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Nomor rekening disalin')),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Nomor Rekening'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Setelah transfer, pilih gambar bukti untuk diunggah.'),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lanjut')),
            ],
          );
        },
      );
      if (confirmed != true) return;

      final picker = ImagePicker();
      final XFile? proof = await picker.pickImage(source: ImageSource.gallery, maxWidth: 2000, maxHeight: 2000, imageQuality: 85);
      if (proof == null) return;

      final payment = await svc.createPayment(rentalId: rentalId, amount: amount, bankAccount: bankInfo);
      await svc.uploadProof(paymentId: payment.id, filePath: proof.path);
      if (!mounted) return;
      _proofUploadedRentalIds.add(rentalId);
      // Persist locally so state survives navigation/back/refresh
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
          'proof_uploaded_rental_ids',
          _proofUploadedRentalIds.map((e) => e.toString()).toList(),
        );
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembayaran dikirim, menunggu konfirmasi admin')));
      await context.read<RentalProvider>().load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal kirim pembayaran: $e')));
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_bottom;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'returned':
        return Icons.reply;
      default:
        return Icons.help;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'approved':
        return 'Dikonfirmasi';
      case 'rejected':
        return 'Ditolak';
      case 'returned':
        return 'Dikembalikan';
      default:
        return status;
    }
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

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RentalProvider>();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Riwayat Sewa'),
      ),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : prov.rentals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada riwayat sewa',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: prov.rentals.length,
                  itemBuilder: (c, i) {
                    final r = prov.rentals[i];
                    final statusColor = _getStatusColor(r.status);
                    final statusIcon = _getStatusIcon(r.status);
                    String statusLabel = _getStatusLabel(r.status);
                    if (r.status.toLowerCase() == 'pending' && _proofUploadedRentalIds.contains(r.id)) {
                      statusLabel = 'Menunggu Konfirmasi Admin';
                    }
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with status badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${r.motorcycleBrand ?? ''} ${r.motorcycleModel ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: statusColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(statusIcon, size: 14, color: statusColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        statusLabel,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Date info
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDate(r.startDate),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey[400]),
                                ),
                                Text(
                                  _formatDate(r.endDate),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Biaya',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  'Rp ${_formatPrice(r.totalPrice)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF002F34),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (r.status.toLowerCase() == 'pending') ...[
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _proofUploadedRentalIds.contains(r.id)
                                      ? null
                                      : () => _submitPayment(context, r.id, r.totalPrice.toDouble()),
                                  icon: const Icon(Icons.attach_money),
                                  label: Text(
                                    _proofUploadedRentalIds.contains(r.id)
                                        ? 'Bukti sudah diunggah'
                                        : 'Bayar & Upload Bukti',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_proofUploadedRentalIds.contains(r.id)) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.hourglass_bottom, size: 14, color: Colors.orange[700]),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Menunggu konfirmasi admin',
                                      style: TextStyle(color: Colors.orange[700], fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Admin akan memverifikasi bukti transfer Anda.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey, fontSize: 11),
                                ),
                              ],
                            ]
                            else ...[
                              const SizedBox(
                                width: double.infinity,
                                child: Text(
                                  'Pembayaran dikonfirmasi, tidak perlu upload bukti.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.green),
                                ),
                              ),
                              if (_proofUploadedRentalIds.contains(r.id)) ...[
                                const SizedBox(height: 6),
                                const Text(
                                  'Bukti transfer telah diunggah. Terima kasih.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey, fontSize: 11),
                                )
                              ]
                              ,
                              if (r.status.toLowerCase() == 'approved') ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      // Use phone from settings if available
                                      String phone = '6281234567890';
                                      try {
                                        final s = await PaymentService().fetchBankAccountSettings();
                                        if ((s['whatsapp_phone'] ?? '').isNotEmpty) {
                                          phone = s['whatsapp_phone']!;
                                        }
                                      } catch (_) {}
                                      final message = Uri.encodeComponent('Halo Admin, saya ingin mengambil motor untuk sewa #${r.id}.');
                                      final uri = Uri.parse('https://wa.me/$phone?text=$message');
                                      if (await launcher.canLaunchUrl(uri)) {
                                        await launcher.launchUrl(uri, mode: launcher.LaunchMode.externalApplication);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Tidak dapat membuka WhatsApp')),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.chat),
                                    label: const Text('Hubungi WhatsApp untuk pengambilan motor'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF25D366),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                                if (_proofUrls[r.id] != null && _proofUrls[r.id]!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: () async {
                                      final url = ApiConfig.absolute(_proofUrls[r.id]!);
                                      final uri = Uri.parse(url);
                                      if (await launcher.canLaunchUrl(uri)) {
                                        await launcher.launchUrl(uri, mode: launcher.LaunchMode.externalApplication);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Tidak dapat membuka bukti')),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.open_in_new),
                                    label: const Text('Lihat Bukti'),
                                  ),
                                ],
                              ]
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
