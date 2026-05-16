class SymbolCard {
  final String id;
  final String nameEnglish;
  final String nameUrdu;        // اردو label
  final String nameRomanUrdu;   // "Billi" for cat
  final String category;
  final String emoji;           // Fallback if image fails to load
  final String imagePath;       // ARASAAC URL or local asset path
  final String audioPath;
  final int difficultyLevel;    // 1=easy, 2=medium, 3=hard

  // Not const — imagePath is a computed URL string
  SymbolCard({
    required this.id,
    required this.nameEnglish,
    required this.nameUrdu,
    required this.nameRomanUrdu,
    required this.category,
    this.emoji = '❓',
    required this.imagePath,
    required this.audioPath,
    this.difficultyLevel = 1,
  });
}

enum SymbolCategory {
  animals,
  food,
  family,
  emotions,
  dailyRoutines,
  transport,
}
