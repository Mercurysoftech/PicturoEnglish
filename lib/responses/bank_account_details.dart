class BankAccountResponse {
  final String status;
  final AccountDetails accountDetails;

  BankAccountResponse({
    required this.status,
    required this.accountDetails,
  });

  factory BankAccountResponse.fromJson(Map<String, dynamic> json) {
    return BankAccountResponse(
      status: json['status'],
      accountDetails: AccountDetails.fromJson(json['account_details']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'account_details': accountDetails.toJson(),
    };
  }
}

class AccountDetails {
  final String accountNumber;
  final String accountHolderName;
  final String ifscCode;
  final String bankName;
  final String branchName;
  final String micr;

  AccountDetails({
    required this.accountNumber,
    required this.accountHolderName,
    required this.ifscCode,
    required this.bankName,
    required this.branchName,
    required this.micr,
  });

  factory AccountDetails.fromJson(Map<String, dynamic> json) {
    return AccountDetails(
      accountNumber: json['account_number'],
      accountHolderName: json['account_holder_name'],
      ifscCode: json['ifsc_code'],
      bankName: json['bank_name'],
      branchName: json['branch_name'],
      micr: json['micr'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'account_number': accountNumber,
      'account_holder_name': accountHolderName,
      'ifsc_code': ifscCode,
      'bank_name': bankName,
      'branch_name': branchName,
      'micr': micr,
    };
  }
}
