/// A Quicks knowledge card. Mirrors CardResponse from the backend.
class QuicksCard {
  final String id;
  final String hook;
  final String insightBody;
  final String twist;
  final String l1Domain;
  final String l2Subdomain;
  final List<String> l3Tags;
  final String imageUrl;
  final double? overallScore;
  final String sourceType;
  final String? sourceUrl;
  final bool isSaved;

  const QuicksCard({
    required this.id,
    required this.hook,
    required this.insightBody,
    required this.twist,
    required this.l1Domain,
    required this.l2Subdomain,
    required this.l3Tags,
    required this.imageUrl,
    this.overallScore,
    this.sourceType = 'manual',
    this.sourceUrl,
    this.isSaved = false,
  });

  QuicksCard copyWith({bool? isSaved}) => QuicksCard(
        id: id,
        hook: hook,
        insightBody: insightBody,
        twist: twist,
        l1Domain: l1Domain,
        l2Subdomain: l2Subdomain,
        l3Tags: l3Tags,
        imageUrl: imageUrl,
        overallScore: overallScore,
        sourceType: sourceType,
        sourceUrl: sourceUrl,
        isSaved: isSaved ?? this.isSaved,
      );

  factory QuicksCard.fromJson(Map<String, dynamic> json) => QuicksCard(
        id: json['id'].toString(),
        hook: json['hook'] ?? '',
        insightBody: json['insight_body'] ?? '',
        twist: json['twist'] ?? '',
        l1Domain: json['l1_domain'] ?? '',
        l2Subdomain: json['l2_subdomain'] ?? '',
        l3Tags: (json['l3_tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        imageUrl: json['image_url'] ?? '',
        overallScore: (json['overall_score'] as num?)?.toDouble(),
        sourceType: json['source_type'] ?? 'manual',
        sourceUrl: json['source_url'],
        isSaved: json['is_saved'] ?? false,
      );
}
