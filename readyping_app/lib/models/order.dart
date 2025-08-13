import 'package:flutter/material.dart';

class Order {
  final String id;
  final String orderId;
  final String customerName;
  final String phoneNumber;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? readyAt;
  final bool notificationSent;

  Order({
    required this.id,
    required this.orderId,
    required this.customerName,
    required this.phoneNumber,
    this.status = OrderStatus.pending,
    required this.createdAt,
    this.readyAt,
    this.notificationSent = false,
  });

  Order copyWith({
    String? id,
    String? orderId,
    String? customerName,
    String? phoneNumber,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? readyAt,
    bool? notificationSent,
  }) {
    return Order(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      customerName: customerName ?? this.customerName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      readyAt: readyAt ?? this.readyAt,
      notificationSent: notificationSent ?? this.notificationSent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'customerName': customerName,
      'phoneNumber': phoneNumber,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'readyAt': readyAt?.toIso8601String(),
      'notificationSent': notificationSent,
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      orderId: json['orderId'],
      customerName: json['customerName'],
      phoneNumber: json['phoneNumber'],
      status: OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      readyAt: json['readyAt'] != null ? DateTime.parse(json['readyAt']) : null,
      notificationSent: json['notificationSent'] ?? false,
    );
  }
}

enum OrderStatus {
  pending,
  ready,
  completed,
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.completed:
        return 'Completed';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.completed:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.ready:
        return Icons.check_circle;
      case OrderStatus.completed:
        return Icons.done_all;
    }
  }
} 