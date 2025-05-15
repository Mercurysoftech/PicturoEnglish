import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:picturo_app/classes/svgfiles.dart';
import 'package:picturo_app/providers/userprovider.dart';
import 'package:picturo_app/responses/bank_account_details.dart';
import 'package:picturo_app/responses/view_bank_response.dart';
import 'package:picturo_app/screens/myprofilepage.dart';
import 'package:picturo_app/screens/verifybankaccounts.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountDetailShow extends StatefulWidget {
  const AccountDetailShow({super.key});

  @override
  State<AccountDetailShow> createState() => _AccountDetailShowState();
}

class _AccountDetailShowState extends State<AccountDetailShow> {
  late final ApiService _apiService;
  ViewBankAccountResponse? _bankDetails;
  bool _isLoading = true;
  String? _errorMessage;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _apiService = await ApiService.create();
      await _loadUserId();
      if (_userId != null) {
        await _fetchBankDetails();
      } else {
        setState(() {
          _errorMessage = 'User not logged in';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Initialization failed';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id');
    });
  }

   Future<void> _fetchBankDetails() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    final response = await _apiService.fetchBankAccount(userId: _userId!);
    
    if (response.status == "error" && 
        response.message == "No account_details found for this user.") {
      setState(() {
        _bankDetails = null; // Ensure bankDetails is null to show add button
        _isLoading = false;
      });
    } else {
      setState(() {
        _bankDetails = response;
        _isLoading = false;
      });
    }
  } catch (e) {
    setState(() {
      _errorMessage = e.toString();
      _isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7EAFF),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _bankDetails != null
                  ? _buildBankDetails()
                  : _buildAddBankCard(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: AppBar(
        backgroundColor: const Color(0xFF49329A),
        leading: Padding(
          padding: const EdgeInsets.only(top: 15.0, left: 24.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 26),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyProfileScreen()),
            ),
          ),
        ),
        title: const Padding(
          padding: EdgeInsets.only(top: 15.0),
          child: Text(
            'Bank Account Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins Regular',
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchBankDetails,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddBankCard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const VerifyBankAccount()),
            ),
            child: const Padding(
              padding: EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline, size: 50, color: Color(0xFF49329A)),
                  SizedBox(height: 20),
                  Text(
                    'Add Bank Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF49329A),
                      fontFamily: 'Poppins Regular',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

   Widget _buildBankDetails() {
  return ListView(
    padding: const EdgeInsets.all(20),
    children: [
      for (final account in _bankDetails!.accountDetails!)
        Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 20),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildBankHeader(account),
                const Divider(thickness: 1, color: Colors.grey),
                _buildDetailItem('Account Holder Name', account.accountHolderName!),
                _buildDetailItem('Account Number', account.accountNumber!),
                _buildDetailItem('IFSC Code', account.ifscCode!),
                _buildDetailItem('MICR', account.micr!),
                _buildRemoveAccountButton(account), // Pass account to remove function
              ],
            ),
          ),
        ),
      const SizedBox(height: 20),
      _buildChangeButton(),
    ],
  );
}

Widget _buildBankHeader(ViewAccountDetails account) {
  return ListTile(
    leading: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8), // Background color
        shape: BoxShape.circle, // Makes it circular
      ),
      child: SvgPicture.string(
        Svgfiles.bankSvg,
        width: 22,
        height: 22,
        color: const Color(0xFF49329A),
      ),
    ),
    title: Text(
      account.bankName!,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins Regular',
      ),
    ),
    subtitle: Text(
      account.branchName!,
      style: const TextStyle(fontFamily: 'Poppins Regular'),
    ),
  );
}


  Widget _buildDetailItem(String title, String value) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontFamily: 'Poppins Regular')),
      subtitle: Text(value, style: const TextStyle(fontFamily: 'Poppins Regular')),
    );
  }

  Widget _buildRemoveAccountButton(ViewAccountDetails account) {
  return ListTile(
    title: const Text(
      'Remove account',
      style: TextStyle(
        fontFamily: 'Poppins Regular',
        color: Color(0xFFBE0000),
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.end,
    ),
    onTap: () => _confirmRemoveAccount(account),
  );
}

  Widget _buildChangeButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VerifyBankAccount()),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF49329A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          child: const Text(
            "Add",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontFamily: 'Poppins Regular',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

 void _confirmRemoveAccount(ViewAccountDetails account) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirm Removal'),
      content: const Text('Are you sure you want to remove this bank account?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            // Navigator.pop(context);
            _removeAccount(account); // Pass the specific account to remove
          },
          child: const Text('Remove', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}

  Future<void> _removeAccount(ViewAccountDetails account) async {
    final apiService = await ApiService.create();
    final bool languageResponse = await apiService.removeBankAccount(account.accountNumber??"");
    Navigator.pop(context);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>AccountDetailShow()));
  }
}

class BankAccountDetails {
  final String accountNumber;
  final String accountHolderName;
  final String ifscCode;
  final String bankName;
  final String branchName;
  final String micr;

  BankAccountDetails({
    required this.accountNumber,
    required this.accountHolderName,
    required this.ifscCode,
    required this.bankName,
    required this.branchName,
    required this.micr,
  });
}