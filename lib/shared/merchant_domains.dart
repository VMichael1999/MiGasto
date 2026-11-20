/// Relaciona el nombre de un comercio con su sitio web, para buscar su logo.
/// Son solo textos: las imágenes no viajan con la app, se piden por internet y se guardan en caché.
const Map<String, String> _merchantDomains = {
  // Entrega y transporte
  'rappi': 'rappi.com',
  'uber': 'uber.com',
  'uber eats': 'ubereats.com',
  'cabify': 'cabify.com',
  'indrive': 'indrive.com',
  'pedidosya': 'pedidosya.com',
  'lime': 'li.me',
  // Suscripciones y entretenimiento
  'spotify': 'spotify.com',
  'netflix': 'netflix.com',
  'disney': 'disneyplus.com',
  'disney plus': 'disneyplus.com',
  'hbo': 'max.com',
  'max': 'max.com',
  'prime video': 'primevideo.com',
  'amazon prime': 'primevideo.com',
  'youtube': 'youtube.com',
  'crunchyroll': 'crunchyroll.com',
  'twitch': 'twitch.tv',
  'steam': 'steampowered.com',
  'playstation': 'playstation.com',
  'xbox': 'xbox.com',
  'nintendo': 'nintendo.com',
  'tinder': 'tinder.com',
  // Tecnología
  'icloud': 'icloud.com',
  'apple': 'apple.com',
  'google': 'google.com',
  'google one': 'one.google.com',
  'chatgpt': 'openai.com',
  'openai': 'openai.com',
  'claude': 'claude.ai',
  'anthropic': 'anthropic.com',
  'microsoft': 'microsoft.com',
  'adobe': 'adobe.com',
  'canva': 'canva.com',
  'notion': 'notion.so',
  'github': 'github.com',
  'dropbox': 'dropbox.com',
  'zoom': 'zoom.us',
  'paypal': 'paypal.com',
  'amazon': 'amazon.com',
  'airbnb': 'airbnb.com',
  'booking': 'booking.com',
  // Tiendas y supermercados
  'mercadolibre': 'mercadolibre.com.pe',
  'mercado libre': 'mercadolibre.com.pe',
  'falabella': 'falabella.com.pe',
  'ripley': 'ripley.com.pe',
  'oechsle': 'oechsle.pe',
  'plaza vea': 'plazavea.com.pe',
  'plazavea': 'plazavea.com.pe',
  'wong': 'wong.pe',
  'metro': 'metro.pe',
  'tottus': 'tottus.com.pe',
  'tambo': 'tambo.pe',
  'inkafarma': 'inkafarma.com.pe',
  'mifarma': 'mifarma.com.pe',
  'aliexpress': 'aliexpress.com',
  'temu': 'temu.com',
  'shein': 'shein.com',
  // Comida
  'bembos': 'bembos.com.pe',
  'kfc': 'kfc.com.pe',
  'mcdonalds': 'mcdonalds.com.pe',
  'burger king': 'burgerking.com.pe',
  'pizza hut': 'pizzahut.com.pe',
  'dominos': 'dominos.com.pe',
  'papa johns': 'papajohns.com.pe',
  'starbucks': 'starbucks.pe',
  'pinkberry': 'pinkberry.com.pe',
  // Pagos, bancos y servicios
  'yape': 'yape.com.pe',
  'plin': 'plin.pe',
  'bcp': 'viabcp.com',
  'interbank': 'interbank.pe',
  'bbva': 'bbva.pe',
  'scotiabank': 'scotiabank.com.pe',
  'claro': 'claro.com.pe',
  'movistar': 'movistar.com.pe',
  'entel': 'entel.pe',
  'bitel': 'bitel.com.pe',
  'sedapal': 'sedapal.com.pe',
  'luz del sur': 'luzdelsur.com.pe',
  'enel': 'enel.pe',
  'cineplanet': 'cineplanet.com.pe',
  'cinemark': 'cinemark-peru.com',
};

String _normalize(String s) {
  const from = 'áàäâãéèëêíìïîóòöôõúùüûñ';
  const to = 'aaaaaeeeeiiiiooooouuuun';
  final sb = StringBuffer();
  for (final r in s.toLowerCase().runes) {
    final ch = String.fromCharCode(r);
    final i = from.indexOf(ch);
    sb.write(i >= 0 ? to[i] : ch);
  }
  // Cualquier símbolo cuenta como separador: «UBER *TRIP» → «uber trip».
  return sb.toString().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}

/// Sitio web del comercio si es uno conocido; `null` si no (se usa el ícono de la categoría).
/// Se compara por palabras completas, así «metro» no coincide con «metropolitano».
String? merchantDomain(String merchant) {
  final text = ' ${_normalize(merchant)} ';
  if (text.trim().isEmpty) return null;
  String? best;
  var bestLength = 0;
  _merchantDomains.forEach((key, domain) {
    if (key.length > bestLength && text.contains(' $key ')) {
      best = domain;
      bestLength = key.length;
    }
  });
  return best;
}
