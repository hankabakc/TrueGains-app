/// Abonelik Paketi Modeli (Backend SubscriptionPackageDTO karşılığı)
class SubscriptionPackageModel {
  final int id;
  final String name;
  final double price;
  final int durationDays;
  final int? coachId;
  final String? description;
  final String? features;
  final int? quota;
  final int activeSubscriberCount;
  final String? levels;
  final String? mode;

  SubscriptionPackageModel({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    this.coachId,
    this.description,
    this.features,
    this.quota,
    this.activeSubscriberCount = 0,
    this.levels,
    this.mode,
  });

  factory SubscriptionPackageModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPackageModel(
      id: (json['id'] as int?) ?? 0,
      name: (json['name'] as String?) ?? 'Bilinmeyen Paket',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      durationDays: (json['durationDays'] as int?) ?? 30,
      coachId: json['coachId'] as int?,
      description: json['description'] as String?,
      features: json['features'] as String?,
      quota: (json['quota'] as num?)?.toInt(),
      activeSubscriberCount: (json['activeSubscriberCount'] as num?)?.toInt() ?? 0,
      levels: json['levels'] as String?,
      mode: json['mode'] as String?,
    );
  }
}

/// Sporcu Abonelik Modeli (Backend ClientSubscriptionDTO karşılığı)
class ClientSubscriptionModel {
  final int id;
  final String clientName;
  final String coachName;
  final String packageName;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final int daysRemaining;
  final double price;

  ClientSubscriptionModel({
    required this.id,
    required this.clientName,
    required this.coachName,
    required this.packageName,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.daysRemaining,
    required this.price,
  });

  factory ClientSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return ClientSubscriptionModel(
      id: (json['id'] as int?) ?? 0,
      clientName: (json['clientName'] as String?) ?? '',
      coachName: (json['coachName'] as String?) ?? '',
      packageName: (json['packageName'] as String?) ?? '',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : DateTime.now(),
      isActive: (json['isActive'] as bool?) ?? false,
      daysRemaining: (json['daysRemaining'] as int?) ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Ödeme İşlemi ve Sepet Öğesi Modeli (Backend PaymentTransactionDTO karşılığı)
class PaymentTransactionModel {
  final int id;
  final int packageId;
  final String packageName;
  final int durationDays;
  final double amount;
  final String status;
  final DateTime transactionDate;

  PaymentTransactionModel({
    required this.id,
    required this.packageId,
    required this.packageName,
    required this.durationDays,
    required this.amount,
    required this.status,
    required this.transactionDate,
  });

  factory PaymentTransactionModel.fromJson(Map<String, dynamic> json) {
    return PaymentTransactionModel(
      id: (json['id'] as int?) ?? 0,
      packageId: (json['packageId'] as int?) ?? 0,
      packageName: (json['packageName'] as String?) ?? 'Bilinmeyen Paket',
      durationDays: (json['durationDays'] as int?) ?? 30,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: (json['status'] as String?) ?? 'PENDING',
      transactionDate: json['transactionDate'] != null
          ? DateTime.parse(json['transactionDate'] as String)
          : DateTime.now(),
    );
  }
}

/// Satın Alma Niyeti Modeli (PurchaseIntentDTO karşılığı)
class PurchaseIntentModel {
  final String type;
  final String? currentCoachName;

  PurchaseIntentModel({
    required this.type,
    this.currentCoachName,
  });

  factory PurchaseIntentModel.fromJson(Map<String, dynamic> json) {
    return PurchaseIntentModel(
      type: (json['type'] as String?) ?? 'NONE',
      currentCoachName: json['currentCoachName'] as String?,
    );
  }
}
