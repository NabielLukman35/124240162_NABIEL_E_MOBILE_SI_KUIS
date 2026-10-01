import 'package:flutter/material.dart';
import 'stationery_item.dart';
import 'main.dart'; // Mengambil style kInk, kMuted, kSaffron, dan Header

class FavoritePage extends StatelessWidget {
  final List<StationeryItem> favoriteItems;
  final void Function(StationeryItem) onTap;
  final void Function(StationeryItem) onToggleFavorite;

  const FavoritePage({
    super.key,
    required this.favoriteItems,
    required this.onTap,
    required this.onToggleFavorite,
  });

  Widget imageurl(String imageUrl, {double h = 84, double w = 84}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        imageUrl,
        width: w,
        height: h,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F6F4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.image_not_supported_outlined, color: kMuted),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Header(
          title: 'item Favorit',
          subtitle: 'Daftar item yang kamu sukai',
        ),
        Expanded(
          child: favoriteItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.book_outlined, size: 72, color: kMuted),
                      SizedBox(height: 12),
                      Text(
                        'Belum ada item favorit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kInk,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tekan ikon hati pada item untuk menambahkan',
                        style: TextStyle(fontSize: 13, color: kMuted),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  itemCount: favoriteItems.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (_, i) {
                    final item = favoriteItems[i];
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => onTap(item),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE1EAE6)),
                          ),
                          child: Row(
                            children: [
                              imageurl(item.imageUrl, h: 84, w: 84),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: kInk,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rp ${item.formattedPrice}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: kGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.favorite, color: Colors.redAccent),
                                onPressed: () => onToggleFavorite(item),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}