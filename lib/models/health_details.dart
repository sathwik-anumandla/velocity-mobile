class HealthDetails {
  final String status;
  final String backend;
  final String hindsight;
  final String database;

  HealthDetails({
    required this.status,
    required this.backend,
    required this.hindsight,
    required this.database,
  });

  factory HealthDetails.fromJson(Map<String, dynamic> json) {
    return HealthDetails(
      status: json['status'] ?? 'offline',
      backend: json['backend'] ?? 'unreachable',
      hindsight: json['hindsight'] ?? 'unreachable',
      database: json['database'] ?? 'unreachable',
    );
  }

  bool get isHealthy =>
      backend == 'healthy' && hindsight == 'healthy' && database == 'healthy';

  bool get isDegraded =>
      backend == 'healthy' && (hindsight != 'healthy' || database != 'healthy');

  bool get isOffline => backend != 'healthy';
}
