import 'package:shared_preferences/shared_preferences.dart';

class FavoriteService {
  static const String _key = 'favorite_foods';

  // Ambil daftar nama makanan yang difavoritkan
  static Future<Set<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.toSet();
  }

  // Toggle status favorit (tambah jika belum ada, hapus jika sudah ada)
  static Future<bool> toggleFavorite(String itemName) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    final set = list.toSet();

    final isFav = set.contains(itemName);
    if (isFav) {
      set.remove(itemName);
    } else {
      set.add(itemName);
    }

    await prefs.setStringList(_key, set.toList());
    return !isFav; // Mengembalikan status favorit terbaru
  }

  // Periksa apakah satu item tertentu merupakan favorit
  static Future<bool> isFavorite(String itemName) async {
    final favs = await getFavorites();
    return favs.contains(itemName);
  }
}