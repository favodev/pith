class CircleLabels {
  const CircleLabels._();

  static const family = 'Familia';
  static const friends = 'Amigos';
  static const work = 'Trabajo';
  static const acquaintances = 'Conocidos';

  static const values = <String>[family, friends, work, acquaintances];

  static String normalize(String raw) {
    final value = raw.trim().toLowerCase();
    if (value == 'familia' || value == 'family') {
      return family;
    }
    if (value == 'amigos' || value == 'friend' || value == 'friends' || value == 'circulo cercano' || value == 'inner circle') {
      return friends;
    }
    if (value == 'trabajo' || value == 'work') {
      return work;
    }
    if (value == 'conocidos' || value == 'todos' || value == 'all contacts' || value == 'vip') {
      return acquaintances;
    }
    return acquaintances;
  }
}
