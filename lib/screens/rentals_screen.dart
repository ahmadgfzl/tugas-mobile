import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/payment_service.dart';
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
  final Map<int, String> _orderIds = <int, String>{};
  final Map<int, String> _orderCreatedAts = <int, String>{};
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
        // Choose latest payment per rental by created_at
        final Map<int, Map<String, dynamic>> latest = {};
        for (final p in items) {
          final rid = (p['rental_id'] as num).toInt();
          final prev = latest[rid];
          if (prev == null) {
            latest[rid] = p;
          } else {
            final a = DateTime.tryParse(p['created_at'] ?? '')?.millisecondsSinceEpoch ?? 0;
            final b = DateTime.tryParse(prev['created_at'] ?? '')?.millisecondsSinceEpoch ?? 0;
            if (a >= b) latest[rid] = p;
          }
        }
        latest.forEach((rid, p) {
          if ((p['proof_url'] ?? '') != '') {
            _proofUploadedRentalIds.add(rid);
            _proofUrls[rid] = p['proof_url'] as String;
          }
          if ((p['order_id'] ?? '') != '') {
            _orderIds[rid] = p['order_id'] as String;
          }
          if ((p['created_at'] ?? '') != '') {
            _orderCreatedAts[rid] = p['created_at'] as String;
          }
        });
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
      if ((payment.orderId ?? '').isNotEmpty) {
        _orderIds[rentalId] = payment.orderId!;
      }
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
                            // Single order number row (with fallback)
                            _buildOrderIdRow(r.id, r.startDate, _orderIds[r.id]),
                            if ((_orderCreatedAts[r.id] ?? '').isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Order dibuat pada ${_formatDateTime(_orderCreatedAts[r.id]!)}',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                  ),
                                  Text(
                                    _relativeTime(_orderCreatedAts[r.id]!),
                                    style: TextStyle(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            
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
                                const SizedBox(height: 6),
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
                                      try {
                                        await launcher.launchUrl(uri, mode: launcher.LaunchMode.externalApplication);
                                      } catch (_) {
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
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () async {
                                    try {
                                      // Fetch latest payment for this rental
                                      final items = await PaymentService().listMyPayments();
                                      Map<String, dynamic>? latest;
                                      for (final p in items) {
                                        if ((p['rental_id'] as num).toInt() == r.id) {
                                          if (latest == null) { latest = p; }
                                          else {
                                            final a = DateTime.tryParse(p['created_at'] ?? '')?.millisecondsSinceEpoch ?? 0;
                                            final b = DateTime.tryParse(latest['created_at'] ?? '')?.millisecondsSinceEpoch ?? 0;
                                            if (a >= b) latest = p;
                                          }
                                        }
                                      }
                                      if (latest == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Data pembayaran tidak ditemukan')),
                                        );
                                        return;
                                      }
                                      final settings = await PaymentService().fetchBankAccountSettings();
                                      final bankInfo = '${settings['bank_name']} ${settings['account_number']} a.n ${settings['account_name']}';
                                      // Show receipt dialog
                                      // User sees summary; proof image/link is not shown here
                                      // They can screenshot or use OS print from share menu if available
                                      // Keep it lightweight: no extra packages
                                      //
                                      if (!mounted) return;
                                      await showDialog<void>(
                                        context: context,
                                        builder: (ctx) {
                                          return AlertDialog(
                                            title: const Text('Struk Pembayaran'),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(children: [
                                                  const Icon(Icons.confirmation_number, size: 16),
                                                  const SizedBox(width: 6),
                                                  Text('No. Order: ${latest!['order_id'] ?? _orderIds[r.id] ?? '-'}'),
                                                ]),
                                                const SizedBox(height: 8),
                                                Text('Tanggal: ' + _formatDateTime(latest['created_at'] ?? '')),
                                                const SizedBox(height: 8),
                                                Text('Metode: Transfer Bank'),
                                                const SizedBox(height: 8),
                                                Text('Tujuan: ' + bankInfo),
                                                const SizedBox(height: 8),
                                                Text('Jumlah: Rp ' + _formatPrice((latest['amount'] ?? 0) as num)),
                                                const SizedBox(height: 12),
                                                const Text('Catatan: Simpan struk ini sebagai bukti pembayaran.'),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
                                            ],
                                          );
                                        },
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Gagal menampilkan struk: $e')),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.receipt_long),
                                  label: const Text('Cetak Bukti Pembayaran'),
                                ),
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

  String _fallbackOrderIdForRental(int rentalId, String startDate) {
    try {
      final dt = DateTime.parse(startDate);
      final y = dt.year.toString();
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      return 'PM-' + y + m + d + '-' + rentalId.toString().padLeft(4, '0');
    } catch (e) {
      return 'PM-' + rentalId.toString().padLeft(4, '0');
    }
  }

  String _formatDateTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
      final hh = date.hour.toString().padLeft(2, '0');
      final mm = date.minute.toString().padLeft(2, '0');
      return '${date.day} ${months[date.month - 1]} ${date.year} ${hh}:${mm}';
    } catch (e) {
      return dateStr;
    }
  }

  String _relativeTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inSeconds < 60) return 'baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      if (diff.inDays < 7) return '${diff.inDays} hari lalu';
      // Fallback to date only for older entries
      return _formatDate(dateStr);
    } catch (e) {
      return '';
    }
  }

  Widget _buildOrderIdRow(int rentalId, String startDate, String? orderId) {
    final id = (orderId ?? '').isNotEmpty ? orderId! : _fallbackOrderIdForRental(rentalId, startDate);
    if (id.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.confirmation_number, size: 16),
          const SizedBox(width: 6),
          Expanded(child: Text('No. Order: ' + id)),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            tooltip: 'Copy No. Order',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: id));
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No. Order disalin')),
              );
            },
          ),
        ],
      ),
    );
  }
}
