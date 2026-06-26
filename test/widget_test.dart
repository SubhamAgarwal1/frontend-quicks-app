import 'package:flutter_test/flutter_test.dart';
import 'package:quicks/models/brain.dart';
import 'package:quicks/models/card.dart';

void main() {
  test('QuicksCard parses from backend JSON', () {
    final card = QuicksCard.fromJson({
      'id': 'abc',
      'hook': 'A hook',
      'insight_body': 'Body.',
      'twist': 'Twist.',
      'l1_domain': 'Psychology',
      'l2_subdomain': 'Bias',
      'l3_tags': ['power', 'identity'],
      'image_url': 'https://x/y.jpg',
      'overall_score': 0.85,
      'is_saved': true,
    });
    expect(card.id, 'abc');
    expect(card.l3Tags, ['power', 'identity']);
    expect(card.isSaved, true);
  });

  test('BrainGraph parses domains, bridges, and stats', () {
    final g = BrainGraph.fromJson({
      'domains': [
        {
          'l1_domain': 'History',
          'engagement_score': 9.4,
          'card_count': 4,
          'subdomains': [
            {'l2_subdomain': 'Empires', 'sub_engagement': 2.0, 'sub_card_count': 1, 'card_ids': ['1']}
          ],
        }
      ],
      'all_domains': ['Psychology', 'History'],
      'bridge_nodes': [
        {'concept': 'power', 'domain_count': 2, 'card_count': 3, 'connected_domains': ['History', 'Economics']}
      ],
      'stats': {
        'total_saved': 21,
        'total_completed': 21,
        'total_served': 21,
        'domains_explored': 6,
        'bridge_connections': 11,
      },
      'bio_threshold_reached': true,
    });
    expect(g.domains.first.l1Domain, 'History');
    expect(g.bridges.first.concept, 'power');
    expect(g.stats.totalSaved, 21);
    expect(g.bioThresholdReached, true);
  });
}
