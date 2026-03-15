import '../../core/models/pith_models.dart';

class GiftSuggestion {
  const GiftSuggestion({required this.title, required this.reason});

  final String title;
  final String reason;
}

class GiftRecommender {
  static List<GiftSuggestion> recommend(ContactProfile profile) {
    final source = '${profile.interests.map((entry) => entry.label).join(' ')} '
        '${profile.sparks.map((entry) => entry.content).join(' ')}'
            .toLowerCase();

    final suggestions = <GiftSuggestion>[];

    void add(String title, String reason) {
      if (suggestions.any((item) => item.title == title)) {
        return;
      }
      suggestions.add(GiftSuggestion(title: title, reason: reason));
    }

    if (_hasAny(source, ['rap', 'hip-hop', 'hip hop', 'vinyl'])) {
      add(
        'Vinilo raro de hip-hop de los 90',
        'Encaja con la preferencia del perfil por historia del rap y formatos analogos.',
      );
    }

    if (_hasAny(source, ['coffee', 'roast', 'espresso'])) {
      add(
        'Set de cafe de origen unico, tueste ligero',
        'Encaja con menciones frecuentes sobre rituales de cafe y detalles de cata.',
      );
    }

    if (_hasAny(source, ['garden', 'flowers', 'flor'])) {
      add(
        'Arreglo floral curado en tonos crema',
        'Alineado con sparks previos sobre gusto floral y paletas calidas.',
      );
    }

    if (_hasAny(source, ['opera', 'piano', 'music'])) {
      add(
        'Noche de opera o musica de camara',
        'Se apoya en la preferencia documentada por presentaciones clasicas.',
      );
    }

    if (_hasAny(source, ['chocolate', 'mezcal'])) {
      add(
        'Maridaje artesanal de chocolate oscuro y mezcal',
        'Hace referencia directa a sparks guardados sobre preferencias de sabor.',
      );
    }

    if (suggestions.isEmpty) {
      add(
        'Nota de regalo premium escrita a mano',
        'Alternativa segura mientras se recopilan mas senales de preferencia.',
      );
    }

    return suggestions.take(3).toList(growable: false);
  }

  static bool _hasAny(String source, List<String> terms) {
    for (final term in terms) {
      if (source.contains(term)) {
        return true;
      }
    }
    return false;
  }
}