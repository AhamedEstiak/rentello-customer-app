class InvoiceLineItem {
  final String label;
  final double amount;

  const InvoiceLineItem({
    required this.label,
    required this.amount,
  });

  factory InvoiceLineItem.fromJson(Map<String, dynamic> json) =>
      InvoiceLineItem(
        label: json['label'] as String,
        amount: (json['amount'] as num).toDouble(),
      );
}

class Invoice {
  final String? id;
  final String invoiceNumber;
  final String bookingId;
  final String? customerId;
  final String? customerName;
  final List<InvoiceLineItem> items;
  final double subtotal;
  final double? vatPercent;
  final double? vatAmount;
  final double totalAmount;
  final double paidAmount;
  final double dueAmount;
  final String status;
  final DateTime issuedDate;
  final DateTime dueDate;

  const Invoice({
    this.id,
    required this.invoiceNumber,
    required this.bookingId,
    this.customerId,
    this.customerName,
    required this.items,
    required this.subtotal,
    this.vatPercent,
    this.vatAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.dueAmount,
    required this.status,
    required this.issuedDate,
    required this.dueDate,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
        id: json['id'] as String?,
        invoiceNumber: json['invoiceNumber'] as String,
        bookingId: json['bookingId'] as String,
        customerId: json['customerId'] as String?,
        customerName: json['customerName'] as String?,
        items: (json['items'] as List<dynamic>?)
                ?.map((e) =>
                    InvoiceLineItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        subtotal: (json['subtotal'] as num).toDouble(),
        vatPercent: (json['vatPercent'] as num?)?.toDouble(),
        vatAmount: (json['vatAmount'] as num?)?.toDouble(),
        totalAmount: (json['totalAmount'] as num).toDouble(),
        paidAmount: (json['paidAmount'] as num).toDouble(),
        dueAmount: (json['dueAmount'] as num).toDouble(),
        status: json['status'] as String,
        issuedDate: DateTime.parse(json['issuedDate'].toString()),
        dueDate: DateTime.parse(json['dueDate'].toString()),
      );
}
