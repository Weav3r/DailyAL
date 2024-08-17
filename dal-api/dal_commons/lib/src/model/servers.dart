class Servers {
  bool? bmacLink;
  String? discordLink;
  String? strategy;
  int? maxLoad;
  bool? errorLogging;
  bool? includeSilent;
  List<PreferredServers>? preferredServers;
  String? dalAPIUrl;
  String? telegramLink;
  String? storeUrl;
  List<PlatformMaintenances>? platformMaintenances;

  Servers({
    this.bmacLink,
    this.strategy,
    this.preferredServers,
    this.discordLink,
    this.includeSilent,
    this.dalAPIUrl,
    this.telegramLink,
    this.storeUrl,
    this.errorLogging,
    this.maxLoad,
    this.platformMaintenances,
  });

  Servers.fromJson(Map<String, dynamic>? json) {
    if (json == null) return;
    bmacLink = json['bmacLink'];
    strategy = json['strategy'];
    maxLoad = json['maxLoad'];
    discordLink = json['discordLink'];
    errorLogging = json['errorLogging'];
    includeSilent = json['includeSilent'];
    dalAPIUrl = json['dalAPIUrl'];
    telegramLink = json['telegramLink'];
    storeUrl = json['storeUrl'];
    if (json['platformMaintenances'] != null) {
      platformMaintenances = [];
      json['platformMaintenances'].forEach((v) {
        platformMaintenances?.add(PlatformMaintenances.fromJson(v));
      });
    }
    if (json['preferredServers'] != null) {
      preferredServers = [];
      json['preferredServers'].forEach((v) {
        preferredServers?.add(PreferredServers.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['bmacLink'] = bmacLink;
    data['strategy'] = strategy;
    data['maxLoad'] = maxLoad;
    data['discordLink'] = discordLink;
    data['preferredServers'] =
        preferredServers?.map((v) => v.toJson()).toList();
    data['errorLogging'] = errorLogging;
    data['includeSilent'] = includeSilent;
    data['dalAPIUrl'] = dalAPIUrl;
    data['telegramLink'] = telegramLink;
    data['storeUrl'] = storeUrl;
    data['platformMaintenances'] =
        platformMaintenances?.map((v) => v.toJson()).toList();
    return data;
  }
}

class PreferredServers {
  String? url;
  int? load;

  PreferredServers({this.url, this.load});

  PreferredServers.fromJson(Map<String, dynamic>? json) {
    if (json == null) return;
    url = json['url'];
    load = json['load'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['url'] = url;
    data['load'] = load;
    return data;
  }
}

enum PlatformType {
  myanimelist,
}

class PlatformMaintenances {
  PlatformType? platform;
  bool? maintenance;

  PlatformMaintenances({this.platform, this.maintenance});

  PlatformMaintenances.fromJson(Map<String, dynamic>? json) {
    if (json == null) return;
    platform = PlatformType.values.firstWhere(
        (e) => e.toString().split('.').last == json['platform'],
        orElse: () => PlatformType.myanimelist);
    maintenance = json['maintenance'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['platform'] = platform.toString().split('.').last;
    data['maintenance'] = maintenance;
    return data;
  }
}
