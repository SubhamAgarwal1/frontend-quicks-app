/// The Brain knowledge graph. Mirrors BrainResponse from the backend.
class BrainGraph {
  final List<DomainNode> domains;
  final List<String> allDomains;
  final List<BridgeNode> bridges;
  final BrainStats stats;
  final bool bioThresholdReached;

  const BrainGraph({
    required this.domains,
    required this.allDomains,
    required this.bridges,
    required this.stats,
    required this.bioThresholdReached,
  });

  factory BrainGraph.fromJson(Map<String, dynamic> json) => BrainGraph(
        domains: (json['domains'] as List? ?? [])
            .map((e) => DomainNode.fromJson(e))
            .toList(),
        allDomains: (json['all_domains'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        bridges: (json['bridge_nodes'] as List? ?? [])
            .map((e) => BridgeNode.fromJson(e))
            .toList(),
        stats: BrainStats.fromJson(json['stats'] ?? const {}),
        bioThresholdReached: json['bio_threshold_reached'] ?? false,
      );

  bool get isEmpty => domains.isEmpty;
}

class DomainNode {
  final String l1Domain;
  final double engagementScore;
  final int cardCount;
  final List<SubdomainNode> subdomains;

  const DomainNode({
    required this.l1Domain,
    required this.engagementScore,
    required this.cardCount,
    required this.subdomains,
  });

  factory DomainNode.fromJson(Map<String, dynamic> json) => DomainNode(
        l1Domain: json['l1_domain'] ?? '',
        engagementScore: (json['engagement_score'] as num?)?.toDouble() ?? 0,
        cardCount: json['card_count'] ?? 0,
        subdomains: (json['subdomains'] as List? ?? [])
            .map((e) => SubdomainNode.fromJson(e))
            .toList(),
      );
}

class SubdomainNode {
  final String l2Subdomain;
  final double subEngagement;
  final int subCardCount;
  final List<String> cardIds;

  const SubdomainNode({
    required this.l2Subdomain,
    required this.subEngagement,
    required this.subCardCount,
    required this.cardIds,
  });

  factory SubdomainNode.fromJson(Map<String, dynamic> json) => SubdomainNode(
        l2Subdomain: json['l2_subdomain'] ?? '',
        subEngagement: (json['sub_engagement'] as num?)?.toDouble() ?? 0,
        subCardCount: json['sub_card_count'] ?? 0,
        cardIds: (json['card_ids'] as List? ?? []).map((e) => e.toString()).toList(),
      );
}

class BridgeNode {
  final String concept;
  final int domainCount;
  final int cardCount;
  final List<String> connectedDomains;

  const BridgeNode({
    required this.concept,
    required this.domainCount,
    required this.cardCount,
    required this.connectedDomains,
  });

  factory BridgeNode.fromJson(Map<String, dynamic> json) => BridgeNode(
        concept: json['concept'] ?? '',
        domainCount: json['domain_count'] ?? 0,
        cardCount: json['card_count'] ?? 0,
        connectedDomains:
            (json['connected_domains'] as List? ?? []).map((e) => e.toString()).toList(),
      );
}

class BrainStats {
  final int totalSaved;
  final int totalCompleted;
  final int totalServed;
  final int domainsExplored;
  final int bridgeConnections;

  const BrainStats({
    required this.totalSaved,
    required this.totalCompleted,
    required this.totalServed,
    required this.domainsExplored,
    required this.bridgeConnections,
  });

  factory BrainStats.fromJson(Map<String, dynamic> json) => BrainStats(
        totalSaved: json['total_saved'] ?? 0,
        totalCompleted: json['total_completed'] ?? 0,
        totalServed: json['total_served'] ?? 0,
        domainsExplored: json['domains_explored'] ?? 0,
        bridgeConnections: json['bridge_connections'] ?? 0,
      );
}

/// Payload for the shareable Brain export (GET /api/v1/brain/share).
class BrainShare {
  final String username;
  final String? bio;
  final List<({String domain, double score})> topDomains;
  final BrainStats stats;

  const BrainShare({
    required this.username,
    required this.bio,
    required this.topDomains,
    required this.stats,
  });

  factory BrainShare.fromJson(Map<String, dynamic> json) => BrainShare(
        username: json['username'] ?? 'anonymous',
        bio: json['bio'],
        topDomains: (json['top_domains'] as List? ?? [])
            .map((e) => (
                  domain: (e['domain'] ?? '').toString(),
                  score: (e['engagement_score'] as num?)?.toDouble() ?? 0,
                ))
            .toList(),
        stats: BrainStats.fromJson(json['stats'] ?? const {}),
      );
}
