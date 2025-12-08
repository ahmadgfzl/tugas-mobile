import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/motorcycle_provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'motorcycle_detail_screen.dart';
import 'rentals_screen.dart';
import '../utils/api_endpoints.dart';
import 'profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/motorcycle.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedBrand;
  Timer? _refreshTimer;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Initial load with loading indicator
    Future.microtask(() => context.read<MotorcycleProvider>().load());
    
    // Auto-refresh every 5 seconds for realtime updates (silent mode)
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (mounted) {
        setState(() => _isRefreshing = true);
        await context.read<MotorcycleProvider>().load(silent: true);
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 500));
          setState(() => _isRefreshing = false);
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  List<Motorcycle> _filterMotorcycles(List<Motorcycle> items) {
    return items.where((m) {
      final matchSearch = _searchQuery.isEmpty ||
          m.brand.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.model.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.plateNumber.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchBrand = _selectedBrand == null || m.brand == _selectedBrand;
      return matchSearch && matchBrand;
    }).toList();
  }

  Set<String> _getAllBrands(List<Motorcycle> items) {
    return items.map((m) => m.brand).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MotorcycleProvider>();
    final auth = context.watch<AuthProvider>();
    Widget body;
    if (provider.loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (provider.error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text('Gagal memuat data', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(provider.error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton.icon(onPressed: () => provider.load(), icon: const Icon(Icons.refresh), label: const Text('Coba Lagi'))
          ]),
        ),
      );
    } else if (provider.items.isEmpty) {
      body = Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.motorcycle, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('Belum ada motor.'),
          const SizedBox(height: 8),
            ElevatedButton.icon(onPressed: () => provider.load(), icon: const Icon(Icons.refresh), label: const Text('Refresh'))
        ]),
      );
    } else {
      final filteredItems = _filterMotorcycles(provider.items);
      final brands = _getAllBrands(provider.items);
      
      body = RefreshIndicator(
        onRefresh: () => provider.load(),
        child: CustomScrollView(
          slivers: [
            // Header dengan greeting
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.currentUser != null 
                          ? 'Hi, ${auth.currentUser!.name.split(' ').first}!'
                          : 'Selamat Datang!',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      auth.currentUser != null 
                          ? 'Temukan motor impianmu'
                          : 'Jelajahi koleksi motor kami',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari motor...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (value) => setState(() => _searchQuery = value),
                    ),
                  ],
                ),
              ),
            ),
            // Filter chips
            if (brands.isNotEmpty)
              SliverToBoxAdapter(
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      FilterChip(
                        label: const Text('Semua'),
                        selected: _selectedBrand == null,
                        onSelected: (_) => setState(() => _selectedBrand = null),
                        backgroundColor: Colors.white,
                        selectedColor: const Color(0xFF23E5DB),
                      ),
                      const SizedBox(width: 8),
                      ...brands.map((brand) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(brand),
                          selected: _selectedBrand == brand,
                          onSelected: (_) => setState(() => _selectedBrand = brand),
                          backgroundColor: Colors.white,
                          selectedColor: const Color(0xFF23E5DB),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            // Result count
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '${filteredItems.length} motor tersedia',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w500),
                ),
              ),
            ),
            // Grid cards
            filteredItems.isEmpty
                ? const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('Tidak ada motor ditemukan'),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.all(12),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final m = filteredItems[i];
                          return _MotorcycleCard(motorcycle: m);
                        },
                        childCount: filteredItems.length,
                      ),
                    ),
                  ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('MotorKu'),
            if (_isRefreshing) ...[
              const SizedBox(width: 12),
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (auth.currentUser != null) ...[
            IconButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RentalsScreen()));
              },
              icon: const Icon(Icons.receipt_long),
              tooltip: 'Riwayat Sewa',
            ),
          ] else ...[
            TextButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              icon: const Icon(Icons.login, color: Colors.white),
              label: const Text('Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      drawer: auth.currentUser != null ? Drawer(
        child: SafeArea(
          child: Column(
            children: [
              if (auth.currentUser != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF002F34),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundImage: (auth.currentUser!.avatarUrl != null)
                            ? NetworkImage(ApiConfig.absolute(auth.currentUser!.avatarUrl!))
                            : null,
                        backgroundColor: Colors.white24,
                        child: (auth.currentUser!.avatarUrl == null)
                            ? const Icon(Icons.person, size: 35, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        auth.currentUser!.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        auth.currentUser!.email,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Profil'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: const Text('Riwayat Sewa'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const RentalsScreen()));
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text('Keluar', style: TextStyle(color: Colors.red)),
                      onTap: () async {
                        Navigator.pop(context);
                        await auth.logout();
                        if (mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (_) => false,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ) : null,
      body: body,
    );
  }
}

class _MotorcycleCard extends StatelessWidget {
  final Motorcycle motorcycle;
  const _MotorcycleCard({required this.motorcycle});

  String _formatPrice(num price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(price % 1000000 == 0 ? 0 : 1)} Jt';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(price % 1000 == 0 ? 0 : 0)} Rb';
    }
    return price.toString();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MotorcycleDetailScreen(motorcycle: motorcycle)),
      ),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with badge
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: motorcycle.firstImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: '${ApiConfig.absolute(motorcycle.firstImageUrl!)}?t=${DateTime.now().millisecondsSinceEpoch ~/ 5000}',
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: Colors.grey[200],
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.two_wheeler, size: 50, color: Colors.grey),
                          ),
                  ),
                  // Available badge
                  if (motorcycle.available)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Tersedia',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Details
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${motorcycle.brand} ${motorcycle.model}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          motorcycle.plateNumber,
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'Rp ${_formatPrice(motorcycle.pricePerDay)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF002F34),
                          ),
                        ),
                        Text(
                          '/hari',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
