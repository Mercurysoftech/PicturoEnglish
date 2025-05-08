class ViewBankAccountResponse {
  final String status;
  final String? message;
  final List<ViewAccountDetails>? accountDetails;

  ViewBankAccountResponse({
    required this.status,
    this.message,
    this.accountDetails,
  });

  factory ViewBankAccountResponse.fromJson(Map<String, dynamic> json) {
    return ViewBankAccountResponse(
      status: json['status'] as String,
      message: json['message'] as String?,
      // Parse as List and map each item to AccountDetails
       accountDetails: json['status'] == 'success' && json['account_details'] != null
          ? (json['account_details'] as List)
              .map((item) => ViewAccountDetails.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'message':message,
        'account_details': accountDetails?.map((detail) => detail.toJson()).toList(),
      };
}

class ViewAccountDetails {
  final String? accountNumber;
  final String? accountHolderName;
  final String? ifscCode;
  final String? bankName;
  final String? branchName;
  final String? micr;

  ViewAccountDetails({
    required this.accountNumber,
    required this.accountHolderName,
    required this.ifscCode,
    required this.bankName,
    required this.branchName,
    required this.micr,
  });

  factory ViewAccountDetails.fromJson(Map<String, dynamic> json) {
    return ViewAccountDetails(
      accountNumber: json['account_number'] as String,
      accountHolderName: json['account_holder_name'] as String,
      ifscCode: json['ifsc_code'] as String,
      bankName: json['bank_name'] as String,
      branchName: json['branch_name'] as String,
      micr: json['micr'] as String,
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
