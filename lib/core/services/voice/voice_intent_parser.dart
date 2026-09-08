enum VoiceIntentType {
  search,
  dailySales,
  checkStock,
  checkLowStock,
  help,
}

class VoiceIntent {
  final VoiceIntentType type;
  final String? query;
  final String rawText;

  const VoiceIntent({
    required this.type,
    this.query,
    required this.rawText,
  });

  @override
  String toString() => 'VoiceIntent(type: $type, query: $query, raw: "$rawText")';
}

class VoiceIntentParser {
  /// Parses raw speech transcript into a structured [VoiceIntent].
  static VoiceIntent parse(String rawSpeech) {
    final text = rawSpeech.trim().toLowerCase();
    if (text.isEmpty) {
      return VoiceIntent(type: VoiceIntentType.search, query: '', rawText: rawSpeech);
    }

    // 1. Daily Sales Patterns (English & Tagalog)
    final salesPatterns = [
      'magkano benta ngayon',
      'magkano benta natin ngayon',
      'magkano benta natin',
      'magkano benta',
      'magkano kita ngayon',
      'kita ngayon',
      'benta ngayon',
      'how much did we sell today',
      'how much we sold today',
      'how much sales today',
      'today sales',
      'todays sales',
      "today's sales",
      'total sales today',
      'sales today',
      'daily sales',
      'total revenue today',
      'today revenue',
    ];

    for (final p in salesPatterns) {
      if (text.contains(p) || text == p) {
        return VoiceIntent(type: VoiceIntentType.dailySales, rawText: rawSpeech);
      }
    }

    // 2. Low Stock / Out of Stock Patterns
    final lowStockPatterns = [
      'anong mga low stock',
      'anong low stock',
      'anong mga paubos na',
      'anong paubos na',
      'mga paubos na gamit',
      'mga paubos na pyesa',
      'mga paubos na',
      'paubos na stock',
      'paubos na',
      'what is low on stock',
      'what items are low on stock',
      'what is low stock',
      'show low stock',
      'check low stock',
      'low stock items',
      'low stock',
      'out of stock',
      'critical stock',
      'restock list',
      'items to restock',
    ];

    for (final p in lowStockPatterns) {
      if (text.contains(p) || text == p) {
        return VoiceIntent(type: VoiceIntentType.checkLowStock, rawText: rawSpeech);
      }
    }

    // 3. Stock Check for a Specific Product
    // e.g. "how many motul left", "ilan pa ang spark plug", "check stock of aerox belt"
    final stockCheckPrefixes = [
      'how many',
      'how much stock of',
      'how much stock for',
      'check stock of',
      'check stock for',
      'stock of',
      'stock for',
      'do we have',
      'ilan pa ang stock ng',
      'ilan pa ang stock',
      'ilan pa stock ng',
      'ilan pa ang',
      'ilan na lang ang',
      'may stock pa ba ng',
      'mayroon pa bang',
      'may stock pa ba',
    ];

    for (final prefix in stockCheckPrefixes) {
      if (text.startsWith(prefix)) {
        String remaining = text.substring(prefix.length).trim();
        // Clean trailing question words like "left", "pa", "remaining"
        remaining = remaining
            .replaceAll(RegExp(r'\b(left|remaining|pa|available)\b'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (remaining.isNotEmpty) {
          return VoiceIntent(
            type: VoiceIntentType.checkStock,
            query: remaining,
            rawText: rawSpeech,
          );
        }
      }
    }

    // 4. Help pattern
    if (text == 'help' || text == 'tulong' || text.contains('what can you do')) {
      return VoiceIntent(type: VoiceIntentType.help, rawText: rawSpeech);
    }

    // 5. Default: Product / Model / Brand Search
    // Clean search prefixes like "search for", "find", "hanapin mo", "patingin ng"
    String searchQuery = text;
    final searchPrefixes = [
      'search for',
      'search',
      'find',
      'look for',
      'hanapin mo ang',
      'hanapin ang',
      'hanapin mo',
      'hanapin',
      'patingin ng',
      'tingnan ang',
      'show me',
      'show',
    ];

    for (final prefix in searchPrefixes) {
      if (searchQuery.startsWith(prefix)) {
        searchQuery = searchQuery.substring(prefix.length).trim();
        break;
      }
    }

    return VoiceIntent(
      type: VoiceIntentType.search,
      query: searchQuery.isNotEmpty ? searchQuery : text,
      rawText: rawSpeech,
    );
  }
}
