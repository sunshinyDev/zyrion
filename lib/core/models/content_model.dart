import 'package:cloud_firestore/cloud_firestore.dart';

enum ContentType { movie, series, liveChannel, sport }

enum ContentCategory { all, movies, series, kids, sports, liveTV }

class ContentModel {
  final String id;
  final String title;
  final String? description;
  final String? posterUrl;
  final String? backdropUrl;
  final String? logoUrl;
  final String? streamUrl;
  final ContentType type;
  final List<String> categories;
  final List<String> genres;
  final double? rating;
  final int? year;
  final String? duration;
  final bool isLive;
  final bool isFeatured;
  final bool isNew;
  final int? episodeCount;
  final int? seasonCount;
  final DateTime? createdAt;

  const ContentModel({
    required this.id,
    required this.title,
    this.description,
    this.posterUrl,
    this.backdropUrl,
    this.logoUrl,
    this.streamUrl,
    required this.type,
    this.categories = const [],
    this.genres = const [],
    this.rating,
    this.year,
    this.duration,
    this.isLive = false,
    this.isFeatured = false,
    this.isNew = false,
    this.episodeCount,
    this.seasonCount,
    this.createdAt,
  });

  factory ContentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContentModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      posterUrl: data['posterUrl'],
      backdropUrl: data['backdropUrl'],
      logoUrl: data['logoUrl'],
      streamUrl: data['streamUrl'],
      type: ContentType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ContentType.movie,
      ),
      categories: List<String>.from(data['categories'] ?? []),
      genres: List<String>.from(data['genres'] ?? []),
      rating: (data['rating'] as num?)?.toDouble(),
      year: data['year'],
      duration: data['duration'],
      isLive: data['isLive'] ?? false,
      isFeatured: data['isFeatured'] ?? false,
      isNew: data['isNew'] ?? false,
      episodeCount: data['episodeCount'],
      seasonCount: data['seasonCount'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'posterUrl': posterUrl,
      'backdropUrl': backdropUrl,
      'logoUrl': logoUrl,
      'streamUrl': streamUrl,
      'type': type.name,
      'categories': categories,
      'genres': genres,
      'rating': rating,
      'year': year,
      'duration': duration,
      'isLive': isLive,
      'isFeatured': isFeatured,
      'isNew': isNew,
      'episodeCount': episodeCount,
      'seasonCount': seasonCount,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }
}

/// Sample data for development/preview
class SampleContent {
  static List<ContentModel> get featured => [
        const ContentModel(
          id: 'f1',
          title: 'Duna: Parte Dois',
          description:
              'Paul Atreides une forças com Chani e os Fremen enquanto busca vingança contra os conspiradores que destruíram sua família.',
          posterUrl:
              'https://image.tmdb.org/t/p/w500/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg',
          backdropUrl:
              'https://image.tmdb.org/t/p/original/xOMo8BRK7PfcJv9JCnx7s5hj0PX.jpg',
          type: ContentType.movie,
          genres: ['Ficção Científica', 'Aventura'],
          rating: 8.5,
          year: 2024,
          duration: '2h 46min',
          isFeatured: true,
        ),
        const ContentModel(
          id: 'f2',
          title: 'The Last of Us',
          description:
              'Após uma pandemia devastadora, Joel é contratado para contrabandear Ellie para fora de uma zona de quarentena.',
          posterUrl:
              'https://image.tmdb.org/t/p/w500/uKvVjHNqB5VmOrdxqAt2F7J78ED.jpg',
          backdropUrl:
              'https://image.tmdb.org/t/p/original/uDgy6hyPd7ipXOuLnPYqXiyZe9O.jpg',
          type: ContentType.series,
          genres: ['Drama', 'Ação', 'Suspense'],
          rating: 9.0,
          year: 2023,
          isFeatured: true,
          seasonCount: 2,
        ),
      ];

  static List<ContentModel> get movies => [
        const ContentModel(
          id: 'm1',
          title: 'Oppenheimer',
          posterUrl:
              'https://image.tmdb.org/t/p/w500/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg',
          type: ContentType.movie,
          genres: ['Drama', 'História'],
          rating: 8.9,
          year: 2023,
          duration: '3h',
        ),
        const ContentModel(
          id: 'm2',
          title: 'Barbie',
          posterUrl:
              'https://image.tmdb.org/t/p/w500/iuFNMS8vlbzfAVF9HVveYqGKk99.jpg',
          type: ContentType.movie,
          genres: ['Comédia', 'Aventura'],
          rating: 7.0,
          year: 2023,
          duration: '1h 54min',
        ),
        const ContentModel(
          id: 'm3',
          title: 'Pobres Criaturas',
          posterUrl:
              'https://image.tmdb.org/t/p/w500/kCGlIMHnOm8JPXIf6bf9ONe3fRu.jpg',
          type: ContentType.movie,
          genres: ['Fantasia', 'Romance'],
          rating: 8.0,
          year: 2023,
          duration: '2h 21min',
          isNew: true,
        ),
        const ContentModel(
          id: 'm4',
          title: 'Wonka',
          posterUrl:
              'https://image.tmdb.org/t/p/w500/qhb1qOilapbapxWQn9jtRCMwXJF.jpg',
          type: ContentType.movie,
          genres: ['Fantasia', 'Comédia'],
          rating: 7.2,
          year: 2023,
          duration: '1h 56min',
        ),
      ];

  static List<ContentModel> get series => [
        const ContentModel(
          id: 's1',
          title: 'Fallout',
          posterUrl:
              'https://image.tmdb.org/t/p/w500/AnsSKR8GkGbHkFBFBFBFBFBFBFBF.jpg',
          type: ContentType.series,
          genres: ['Ficção Científica', 'Ação'],
          rating: 8.5,
          year: 2024,
          seasonCount: 1,
          isNew: true,
        ),
        const ContentModel(
          id: 's2',
          title: 'Shogun',
          posterUrl:
              'https://image.tmdb.org/t/p/w500/7O4iVfOMQmdCSxhOg1WnzG1AgYT.jpg',
          type: ContentType.series,
          genres: ['Drama', 'História'],
          rating: 9.0,
          year: 2024,
          seasonCount: 1,
          isNew: true,
        ),
        const ContentModel(
          id: 's3',
          title: 'House of the Dragon',
          posterUrl:
              'https://image.tmdb.org/t/p/w500/z2yahl2uefxDCl0nogcRBstwruJ.jpg',
          type: ContentType.series,
          genres: ['Fantasia', 'Drama'],
          rating: 8.4,
          year: 2022,
          seasonCount: 2,
        ),
        const ContentModel(
          id: 's4',
          title: 'Severance',
          posterUrl:
              'https://image.tmdb.org/t/p/w500/lNSLFHCEFBFBFBFBFBFBFBFBFBFB.jpg',
          type: ContentType.series,
          genres: ['Suspense', 'Sci-Fi'],
          rating: 8.7,
          year: 2022,
          seasonCount: 2,
        ),
      ];

  static List<ContentModel> get liveChannels => [
        const ContentModel(
          id: 'l1',
          title: 'Globo',
          logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/Globo_logo.svg/200px-Globo_logo.svg.png',
          type: ContentType.liveChannel,
          isLive: true,
          categories: ['Entretenimento'],
        ),
        const ContentModel(
          id: 'l2',
          title: 'SBT',
          logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/SBT_logo.svg/200px-SBT_logo.svg.png',
          type: ContentType.liveChannel,
          isLive: true,
          categories: ['Entretenimento'],
        ),
        const ContentModel(
          id: 'l3',
          title: 'ESPN',
          logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2f/ESPN_wordmark.svg/200px-ESPN_wordmark.svg.png',
          type: ContentType.liveChannel,
          isLive: true,
          categories: ['Esportes'],
        ),
        const ContentModel(
          id: 'l4',
          title: 'CNN Brasil',
          logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b1/CNN_Brasil.svg/200px-CNN_Brasil.svg.png',
          type: ContentType.liveChannel,
          isLive: true,
          categories: ['Notícias'],
        ),
      ];
}
