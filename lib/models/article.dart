/// Mirrors frontend/src/mockData/mockArticles.ts `Article`.
class Article {
  final String id;
  final String tag;
  final String title;
  final String image;
  final String readTime;

  const Article({
    required this.id,
    required this.tag,
    required this.title,
    required this.image,
    required this.readTime,
  });

  Map<String, dynamic> toJson() => {'id': id, 'tag': tag, 'title': title, 'image': image, 'readTime': readTime};

  factory Article.fromJson(Map<String, dynamic> json) => Article(
        id: json['id'] as String,
        tag: json['tag'] as String,
        title: json['title'] as String,
        image: json['image'] as String,
        readTime: json['readTime'] as String,
      );
}
