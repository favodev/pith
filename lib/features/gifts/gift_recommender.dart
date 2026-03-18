import '../../core/models/pith_models.dart';

class GiftSuggestion {
  const GiftSuggestion({required this.title, required this.reason});

  final String title;
  final String reason;
}

class GiftRecommender {
  static const _musicTerms = ['rap', 'hip-hop', 'hip hop', 'vinyl'];
  static const _coffeeTerms = ['coffee', 'roast', 'espresso', 'cafe'];
  static const _flowerTerms = ['garden', 'flowers', 'flor'];
  static const _classicMusicTerms = ['opera', 'piano', 'music'];
  static const _pairingTerms = ['chocolate', 'mezcal'];

  static List<GiftSuggestion> recommend(ContactProfile profile) {
    final source = '${profile.interests.map((entry) => entry.label).join(' ')} '
        '${profile.sparks.map((entry) => entry.content).join(' ')}'
            .toLowerCase();
    final circleContext = profile.subtitle.toLowerCase();

    final suggestions = <GiftSuggestion>[];

    void add(String title, String reason) {
      if (suggestions.any((item) => item.title == title)) {
        return;
      }
      suggestions.add(GiftSuggestion(title: title, reason: reason));
    }

    if (_hasAny(source, _musicTerms)) {
      add(
        'Vinilo raro de hip-hop de los 90',
        'Encaja con la preferencia del perfil por historia del rap y formatos analogos.',
      );
    }

    if (_hasAny(source, _coffeeTerms)) {
      add(
        'Set de cafe de origen unico, tueste ligero',
        'Encaja con menciones frecuentes sobre rituales de cafe y detalles de cata.',
      );
    }

    if (_hasAny(source, _flowerTerms)) {
      add(
        'Arreglo floral curado en tonos crema',
        'Alineado con notas previas sobre gusto floral y paletas calidas.',
      );
    }

    if (_hasAny(source, _classicMusicTerms)) {
      add(
        'Noche de opera o musica de camara',
        'Se apoya en la preferencia documentada por presentaciones clasicas.',
      );
    }

    if (_hasAny(source, _pairingTerms)) {
      add(
        'Maridaje artesanal de chocolate oscuro y mezcal',
        'Hace referencia directa a notas guardadas sobre preferencias de sabor.',
      );
    }

    if (circleContext.contains('familia')) {
      add(
        'Album impreso con recuerdos familiares',
        'Prioriza valor emocional y memoria compartida para un contacto de familia.',
      );
    } else if (circleContext.contains('trabajo')) {
      add(
        'Kit ejecutivo minimalista de escritorio',
        'Mantiene un tono profesional alineado al contexto laboral.',
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