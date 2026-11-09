class SummaryMetrics {
  final double totalMilkCollected;
  final double totalMilkPasteurized;
  final double totalMilkDispensed;
  final double totalVolumeRequested;
  final double unpasteurizedStock;
  final double pasteurizedStock;
  final int pasteurizedBottles;
  final int currentPendingRequests;
  final int currentUnderReviewRequests;
  final double fulfillmentRate;
  final double avgTimeToFulfillHours;
  final int activeDonors;

  SummaryMetrics({
    required this.totalMilkCollected,
    required this.totalMilkPasteurized,
    required this.totalMilkDispensed,
    required this.totalVolumeRequested,
    required this.unpasteurizedStock,
    required this.pasteurizedStock,
    required this.pasteurizedBottles,
    required this.currentPendingRequests,
    required this.currentUnderReviewRequests,
    required this.fulfillmentRate,
    required this.avgTimeToFulfillHours,
    required this.activeDonors,
  });

  factory SummaryMetrics.fromJson(Map<String, dynamic> json) {
    return SummaryMetrics(
      totalMilkCollected: (json['totalMilkCollected'] as num?)?.toDouble() ?? 0,
      totalMilkPasteurized: (json['totalMilkPasteurized'] as num?)?.toDouble() ?? 0,
      totalMilkDispensed: (json['totalMilkDispensed'] as num?)?.toDouble() ?? 0,
      totalVolumeRequested: (json['totalVolumeRequested'] as num?)?.toDouble() ?? 0,
      unpasteurizedStock: (json['unpasteurizedStock'] as num?)?.toDouble() ?? 0,
      pasteurizedStock: (json['pasteurizedStock'] as num?)?.toDouble() ?? 0,
      pasteurizedBottles: (json['pasteurizedBottles'] as num?)?.toInt() ?? 0,
      currentPendingRequests: (json['currentPendingRequests'] as num?)?.toInt() ?? 0,
      currentUnderReviewRequests: (json['currentUnderReviewRequests'] as num?)?.toInt() ?? 0,
      fulfillmentRate: (json['fulfillmentRate'] as num?)?.toDouble() ?? 0,
      avgTimeToFulfillHours: (json['avgTimeToFulfillHours'] as num?)?.toDouble() ?? 0,
      activeDonors: (json['activeDonors'] as num?)?.toInt() ?? 0,
    );
  }
}

class ExpiringBatchAlert {
  final String id;
  final String batchNumber;
  final String poolNumber;
  final int bottlesAvailable;
  final DateTime expirationDate;
  final bool isExpired;

  ExpiringBatchAlert({
    required this.id,
    required this.batchNumber,
    required this.poolNumber,
    required this.bottlesAvailable,
    required this.expirationDate,
    required this.isExpired,
  });

  factory ExpiringBatchAlert.fromJson(Map<String, dynamic> json) {
    return ExpiringBatchAlert(
      id: json['id']?.toString() ?? '',
      batchNumber: json['batchNumber']?.toString() ?? 'N/A',
      poolNumber: json['poolNumber']?.toString() ?? 'N/A',
      bottlesAvailable: (json['bottlesAvailable'] as num?)?.toInt() ?? 0,
      expirationDate: json['expirationDate'] != null
          ? DateTime.tryParse(json['expirationDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isExpired: json['isExpired'] == true,
    );
  }
}

class MetricsAlerts {
  final List<ExpiringBatchAlert> expiringBatches;
  final bool lowStock;
  final double currentPasteurizedStock;
  final double threshold;
  final int pendingOlderThan24h;
  final int requestsExceedingStock;

  MetricsAlerts({
    required this.expiringBatches,
    required this.lowStock,
    required this.currentPasteurizedStock,
    required this.threshold,
    required this.pendingOlderThan24h,
    required this.requestsExceedingStock,
  });

  factory MetricsAlerts.fromJson(Map<String, dynamic> json) {
    List<ExpiringBatchAlert> batches = [];
    if (json['expiringBatches'] is List) {
      for (final b in json['expiringBatches']) {
        if (b is Map) batches.add(ExpiringBatchAlert.fromJson(Map<String, dynamic>.from(b)));
      }
    }

    return MetricsAlerts(
      expiringBatches: batches,
      lowStock: json['lowStock'] == true,
      currentPasteurizedStock: (json['currentPasteurizedStock'] as num?)?.toDouble() ?? 0,
      threshold: (json['threshold'] as num?)?.toDouble() ?? 1000,
      pendingOlderThan24h: (json['pendingOlderThan24h'] as num?)?.toInt() ?? 0,
      requestsExceedingStock: (json['requestsExceedingStock'] as num?)?.toInt() ?? 0,
    );
  }
}

class TopDonorEntry {
  final String name;
  final double volume;

  TopDonorEntry({required this.name, required this.volume});

  factory TopDonorEntry.fromJson(Map<String, dynamic> json) {
    return TopDonorEntry(
      name: json['name']?.toString() ?? 'Donor',
      volume: (json['volume'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DashboardMetricsResponse {
  final DateTime lastUpdated;
  final SummaryMetrics summary;
  final Map<String, int> requestsByStatus;
  final Map<String, int> requestsByRelationship;
  final Map<String, int> pasteurizedByBottleType;
  final List<TopDonorEntry> topDonors;
  final List<Map<String, dynamic>> collectionsOverTime;
  final MetricsAlerts alerts;

  DashboardMetricsResponse({
    required this.lastUpdated,
    required this.summary,
    required this.requestsByStatus,
    required this.requestsByRelationship,
    required this.pasteurizedByBottleType,
    required this.topDonors,
    required this.collectionsOverTime,
    required this.alerts,
  });

  factory DashboardMetricsResponse.fromJson(Map<String, dynamic> json) {
    final charts = json['charts'] is Map ? json['charts'] as Map : {};
    final alertsJson = json['alerts'] is Map ? json['alerts'] as Map : {};

    Map<String, int> reqStatus = {};
    if (charts['requestsByStatus'] is Map) {
      charts['requestsByStatus'].forEach((k, v) {
        reqStatus[k.toString()] = (v as num).toInt();
      });
    }

    Map<String, int> reqRel = {};
    if (charts['requestsByRelationship'] is Map) {
      charts['requestsByRelationship'].forEach((k, v) {
        reqRel[k.toString()] = (v as num).toInt();
      });
    }

    Map<String, int> bottlesMap = {};
    if (charts['pasteurizedByBottleType'] is Map) {
      charts['pasteurizedByBottleType'].forEach((k, v) {
        bottlesMap[k.toString()] = (v as num).toInt();
      });
    }

    List<TopDonorEntry> donors = [];
    if (charts['topDonors'] is List) {
      for (final d in charts['topDonors']) {
        if (d is Map) donors.add(TopDonorEntry.fromJson(Map<String, dynamic>.from(d)));
      }
    }

    List<Map<String, dynamic>> colTime = [];
    if (charts['collectionsOverTime'] is List) {
      for (final c in charts['collectionsOverTime']) {
        if (c is Map) colTime.add(Map<String, dynamic>.from(c));
      }
    }

    return DashboardMetricsResponse(
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'].toString()) ?? DateTime.now()
          : DateTime.now(),
      summary: SummaryMetrics.fromJson(
        json['summary'] is Map ? Map<String, dynamic>.from(json['summary']) : {},
      ),
      requestsByStatus: reqStatus,
      requestsByRelationship: reqRel,
      pasteurizedByBottleType: bottlesMap,
      topDonors: donors,
      collectionsOverTime: colTime,
      alerts: MetricsAlerts.fromJson(Map<String, dynamic>.from(alertsJson)),
    );
  }
}

