import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'stationery_item.dart';
import 'login.dart';
import 'favorite_service.dart';
import 'favorite_page.dart';
import 'edit_profile_page.dart';

void main() => runApp(const alattulisApp());

const kGreen = Color(0xFF0E4D45);
const kSaffron = Color(0xFFF4B32A);
const kBg = Color(0xFFF4F8F6);
const kInk = Color(0xFF16231F);
const kMuted = Color(0xFF6B7C77);

final Map<StationeryItem, int> _stationeryQuantities = {};

extension StationeryItemX on StationeryItem {
  int get quantity => _stationeryQuantities[this] ?? 0;

  set quantity(int value) {
    _stationeryQuantities[this] = value.clamp(0, 9999);
  }

  int get totalPrice => price * quantity;

  String get formattedTotal => formatPrice(totalPrice);
}

// ignore: camel_case_types
class alattulisApp extends StatelessWidget {
  const alattulisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'toko alat tulis',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kBg,
        colorScheme: ColorScheme.fromSeed(seedColor: kGreen, primary: kGreen),
      ),
      home: const AuthGate(),
    );
  }
}

// Pemeriksa Session Awal
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final username = prefs.getString('username') ?? 'Pelanggan';

    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainShell(username: username)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: kGreen),
      ),
    );
  }
}

// Shell Utama Aplikasi
class MainShell extends StatefulWidget {
  final String username;
  const MainShell({super.key, this.username = 'Pelanggan'});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;
  String _username = '';
  final List<StationeryItem> _items = StationeryItem.sampleData;
  Set<String> _favoriteNames = {};

  @override
  void initState() {
    super.initState();
    _username = widget.username;
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favs = await FavoriteService.getFavorites();
    if (mounted) setState(() => _favoriteNames = favs);
  }

  Future<void> _toggleFavorite(StationeryItem item) async {
    final isNowFav = await FavoriteService.toggleFavorite(item.name);
    setState(() {
      if (isNowFav) {
        _favoriteNames.add(item.name);
      } else {
        _favoriteNames.remove(item.name);
      }
    });
  }

  int get _grandTotal => _items.fold(0, (s, e) => s + e.totalPrice);
  int get _totalPortions => _items.fold(0, (s, e) => s + e.quantity);

  Future<void> _openDetail(StationeryItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailPage(
          item: item,
          isFavorite: _favoriteNames.contains(item.name),
          onToggleFavorite: () => _toggleFavorite(item),
        ),
      ),
    );
    setState(() {}); // Refresh setelah data barang (harga, stok, deskripsi) diperbarui
  }

  @override
  Widget build(BuildContext context) {
    final favoriteList =
        _items.where((item) => _favoriteNames.contains(item.name)).toList();

    final pages = [
      MenuPage(
        items: _items,
        favoriteNames: _favoriteNames,
        grandTotal: _grandTotal,
        totalPortions: _totalPortions,
        onTap: _openDetail,
        onToggleFavorite: _toggleFavorite,
      ),
      FavoritePage(
        favoriteItems: favoriteList,
        onTap: _openDetail,
        onToggleFavorite: _toggleFavorite,
      ),
      ProfilePage(
        name: _username,
        items: _items,
        grandTotal: _grandTotal,
        totalPortions: _totalPortions,
        onNameChanged: (newName) => setState(() => _username = newName),
      ),
    ];

    return Scaffold(
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        backgroundColor: Colors.white,
        indicatorColor: kSaffron,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store, color: kInk),
            label: 'Menu',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite, color: Colors.redAccent),
            label: 'Favorit',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: kInk),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ---------- Header bersama ----------
class Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? leading;
  final Widget? trailing;

  const Header({
    super.key,
    required this.title,
    required this.subtitle,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          12, MediaQuery.of(context).padding.top + 12, 16, 22),
      decoration: const BoxDecoration(
        color: kGreen,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          leading ?? const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFFB8D6CF), fontSize: 13),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

Widget bookImage(String url, {double? h, double? w, double radius = 16}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: Image.network(
      url,
      height: h,
      width: w,
      fit: BoxFit.cover,
      loadingBuilder: (c, child, p) => p == null
          ? child
          : Container(height: h, width: w, color: const Color(0xFFE3EDE9)),
      errorBuilder: (c, e, s) => Container(
        height: h,
        width: w,
        color: const Color(0xFFE3EDE9),
        child: const Icon(Icons.book, color: kMuted),
      ),
    ),
  );
}

// ---------- Halaman Menu ----------
class MenuPage extends StatelessWidget {
  final List<StationeryItem> items;
  final Set<String> favoriteNames;
  final int grandTotal;
  final int totalPortions;
  final void Function(StationeryItem) onTap;
  final void Function(StationeryItem) onToggleFavorite;

  const MenuPage({
    super.key,
    required this.items,
    required this.favoriteNames,
    required this.grandTotal,
    required this.totalPortions,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Header(title: 'Daftar Item', subtitle: 'Mau beli apa hari ini?'),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (_, i) => _bookCard(
              item: items[i],
              isFav: favoriteNames.contains(items[i].name),
              onTap: () => onTap(items[i]),
              onToggleFavorite: () => onToggleFavorite(items[i]),
            ),
          ),
        ),
        if (totalPortions > 0)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: kInk,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_outlined, color: kSaffron),
                const SizedBox(width: 10),
                Text('$totalPortions pcs',
                    style: const TextStyle(color: Colors.white70)),
                const Spacer(),
                Text(
                  'Rp ${formatPrice(grandTotal)}',
                  style: const TextStyle(
                    color: kSaffron,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ignore: camel_case_types
class _bookCard extends StatelessWidget {
  final StationeryItem item;
  final bool isFav;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const _bookCard({
    required this.item,
    required this.isFav,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final active = item.quantity > 0;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: active ? kSaffron : const Color(0xFFE1EAE6),
                width: active ? 1.6 : 1),
          ),
          child: Row(
            children: [
              Hero(
                tag: item.name,
                child: bookImage(item.imageUrl, h: 96, w: 96),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: kInk,
                            ),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.redAccent : kMuted,
                            size: 22,
                          ),
                          onPressed: onToggleFavorite,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: kMuted, height: 1.3),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: active ? kSaffron : const Color(0xFFEAF1EE),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${item.quantity} pcs',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: kInk,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('Rp ${item.formattedPrice} / pcs',
                                  style: const TextStyle(fontSize: 11, color: kMuted)),
                            ],
                          ),
                        ),
                        Text(
                          'Rp ${item.formattedTotal}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: active ? kGreen : kMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Halaman Detail/Edit Barang ----------
class DetailPage extends StatefulWidget {
  final StationeryItem item;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const DetailPage({
    super.key,
    required this.item,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late bool _fav;
  late final TextEditingController _descCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _fav = widget.isFavorite;
    _descCtrl = TextEditingController(text: widget.item.description);
    _stockCtrl = TextEditingController(text: '${widget.item.quantity}');
    _priceCtrl = TextEditingController(text: '${widget.item.price}');
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _stockCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final int newStock = int.tryParse(_stockCtrl.text.trim()) ?? widget.item.quantity;
    final int newPrice = int.tryParse(_priceCtrl.text.trim()) ?? widget.item.price;
    final String newDesc = _descCtrl.text.trim();

    widget.item.quantity = newStock;
    widget.item.price = newPrice;
    widget.item.description = newDesc;

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: kInk,
      content: Text('Perubahan data ${widget.item.name} berhasil disimpan'),
    ));
  }

  InputDecoration _inputDecoration(String label, {String? prefixText}) {
    return InputDecoration(
      labelText: label,
      prefixText: prefixText,
      filled: true,
      fillColor: const Color(0xFFF9FBFB),
      labelStyle: const TextStyle(color: kMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE1EAE6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE1EAE6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kGreen, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Scaffold(
      body: Column(
        children: [
          Header(
            title: item.name,
            subtitle: 'Ubah Informasi Barang',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            trailing: IconButton(
              icon: Icon(
                _fav ? Icons.favorite : Icons.favorite_border,
                color: _fav ? Colors.redAccent : Colors.white,
                size: 26,
              ),
              onPressed: () {
                setState(() => _fav = !_fav);
                widget.onToggleFavorite();
              },
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Hero(
                  tag: item.name,
                  child: bookImage(item.imageUrl, h: 200, radius: 24),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE1EAE6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: kInk,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('Harga Satuan', prefixText: 'Rp '),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _stockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('Stok / Jumlah (pcs)'),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _descCtrl,
                        maxLines: 3,
                        decoration: _inputDecoration('Deskripsi Barang'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: kSaffron,
                    foregroundColor: kInk,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _save,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text(
                    'Simpan Perubahan',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Halaman Profil ----------
class ProfilePage extends StatefulWidget {
  final String name;
  final List<StationeryItem> items;
  final int grandTotal;
  final int totalPortions;
  final void Function(String)? onNameChanged;

  const ProfilePage({
    super.key,
    required this.name,
    required this.items,
    required this.grandTotal,
    required this.totalPortions,
    this.onNameChanged,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _displayName = '';
  String _phone = 'Belum diatur';
  String _bio = 'Pelanggan setia toko alat tulis';

  @override
  void initState() {
    super.initState();
    _displayName = widget.name;
    _loadProfileDetails();
  }

  Future<void> _loadProfileDetails() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _displayName = prefs.getString('username') ?? widget.name;
        _phone = prefs.getString('user_phone') ?? 'Belum diatur';
        _bio = prefs.getString('user_bio') ?? 'Pelanggan setia toko alat tulis';
      });
    }
  }

  Future<void> _openEditProfile() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(
          currentName: _displayName,
          currentPhone: _phone == 'Belum diatur' ? '' : _phone,
          currentBio: _bio == 'Pelanggan setia toko Nabiel' ? '' : _bio,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _displayName = result['name'] ?? _displayName;
        _phone = (result['phone']?.isNotEmpty ?? false)
            ? result['phone']!
            : 'Belum diatur';
        _bio = (result['bio']?.isNotEmpty ?? false)
            ? result['bio']!
            : 'Pelanggan setia toko alat tulis';
      });
      widget.onNameChanged?.call(_displayName);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordered = widget.items.where((e) => e.quantity > 0).toList();
    return Column(
      children: [
        Header(
          title: 'Profil',
          subtitle: 'Akun pelanggan',
          trailing: IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            tooltip: 'Edit Profil',
            onPressed: _openEditProfile,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: kSaffron),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: kGreen,
                    child: Text(
                      _displayName.isNotEmpty ? _displayName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  _displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: kInk,
                  ),
                ),
              ),
              Center(
                child: Text(
                  _phone,
                  style: const TextStyle(color: kMuted, fontSize: 13),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _bio,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: kInk, fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kGreen,
                    side: const BorderSide(color: kGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _openEditProfile,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Profil'),
                ),
              ),
              const SizedBox(height: 20),
              _InfoTile(
                icon: Icons.store_outlined,
                title: 'Daftar Item',
                sub: 'Pesan item favoritmu dengan mudah.',
              ),
              const SizedBox(height: 10),
              _InfoTile(
                icon: Icons.receipt_long,
                title: 'Pemesanan',
                sub: ordered.isEmpty
                    ? 'Belum ada pesanan.'
                    : '${ordered.map((e) => '${e.name} x${e.quantity}').join(', ')}\n'
                        'Total ${widget.totalPortions} pcs: Rp ${formatPrice(widget.grandTotal)}',
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Keluar Akun',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  const _InfoTile({required this.icon, required this.title, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1EAE6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: kSaffron,
            child: Icon(icon, color: kInk, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: kInk,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(sub,
                    style: const TextStyle(color: kMuted, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}