class Payment {
  final int id;
  final int rentalId;
  final double amount;
  final String bankAccount;
  final String status;
  final String? proofUrl;
  final String? createdAt;

  Payment({
    required this.id,
    required this.rentalId,
    required this.amount,
    required this.bankAccount,
    required this.status,
    this.proofUrl,
    this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> j) {
    return Payment(
      id: (j['id'] as num).toInt(),
      rentalId: (j['rental_id'] as num).toInt(),
      amount: (j['amount'] as num).toDouble(),
      bankAccount: j['bank_account'] ?? '',
      status: j['status'] ?? 'pending',
      proofUrl: j['proof_url'] as String?,
      createdAt: j['created_at'] as String?,
    );
  }
}
