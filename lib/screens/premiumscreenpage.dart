import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:picturo_app/classes/svgfiles.dart';
import 'package:picturo_app/cubits/premium_cubit/premium_plans_cubit.dart';
import 'package:picturo_app/models/premium_plan_model.dart';
import 'package:picturo_app/screens/premium_plans_screen.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/profileprovider.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key, required this.userName,required this.selectedPlan});

  final String userName;
  final PlanModel selectedPlan;

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    // Handle payment success
    updateUserPricePlan();
  }

  String calculateEndDate(String startDateStr, String validatePlan) {
    // Parse the start date string
    DateTime startDate = DateFormat("yyyy-MM-dd HH:mm:ss").parse(startDateStr);

    // Clean and process validatePlan
    validatePlan = validatePlan.toLowerCase().trim();

    DateTime endDate = startDate;

    if (validatePlan.contains("day")) {
      int days = int.tryParse(validatePlan.split(" ")[0]) ?? 0;
      endDate = startDate.add(Duration(days: days));
    } else if (validatePlan.contains("month")) {
      int months = int.tryParse(validatePlan.split(" ")[0]) ?? 0;
      endDate = DateTime(startDate.year, startDate.month + months, startDate.day,
          startDate.hour, startDate.minute, startDate.second);
    } else if (validatePlan.contains("year")) {
      int years = int.tryParse(validatePlan.split(" ")[0]) ?? 0;
      endDate = DateTime(startDate.year + years, startDate.month, startDate.day,
          startDate.hour, startDate.minute, startDate.second);
    }

    return DateFormat("yyyy-MM-dd HH:mm:ss").format(endDate);
  }

  int convertVoiceCallToSeconds(String voiceCall) {
    voiceCall = voiceCall.toLowerCase().trim(); // Normalize input

    if (voiceCall.contains("unlimited")) {
      return -1; // Use -1 or any special value for "unlimited"
    }

    final parts = voiceCall.split("/").first.trim(); // e.g. "10min" or "1 hour"

    if (parts.contains("min")) {
      final minutes = int.tryParse(parts.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return minutes * 60;
    } else if (parts.contains("hour")) {
      final hours = int.tryParse(parts.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return hours * 3600;
    } else if (parts.contains("sec")) {
      final seconds = int.tryParse(parts.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return seconds;
    }

    return 0; // fallback for "0" or unknown format
  }

  Future<void> updateUserPricePlan() async {
    const String url = 'https://picturoenglish.com/api/priceplan-updateuser.php';

    final Map<String, dynamic> body = {
      // "membership": "${widget.selectedPlan.name}",
      // "plan_voicecall": "${convertVoiceCallToSeconds(widget.selectedPlan.voiceCall)<0?0:convertVoiceCallToSeconds(widget.selectedPlan.voiceCall)}",
      // "plan_message": "${widget.selectedPlan.message}",
      // "plan_games": "${widget.selectedPlan.games}",
      // "plan_chatbot": "${widget.selectedPlan.chatBot}",
      // "plan_start_time": "${widget.selectedPlan.createdAt}",
      // "plan_end_time": "${calculateEndDate(widget.selectedPlan.createdAt, widget.selectedPlan.validatePlan)}"
      "planid": widget.selectedPlan.id
    };
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("auth_token");
    try {

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token"
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Navigator.pop(context);
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PremiumPlansScreen(userName: widget.userName,)), // Navigate to PremiumScreen
        );

      } else {
        print("Failed with status: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    } catch (e) {
      print("Error occurred: $e");
    }
  }
  void _handlePaymentError(PaymentFailureResponse response) {
    // Handle payment failure
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Payment Failed"),
        content: Text("Error: ${response.message}"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Handle external wallet
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("External Wallet Selected"),
        content: Text("Wallet: ${response.walletName}"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  bool paymentLoading = false;

  void openCheckout() async {
    setState(() {
      paymentLoading = true;
    });
    // try {
    final mobile = context.read<ProfileProvider>().mobile;

      // Call your backend to create the order
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("auth_token");
      final url = Uri.parse('https://picturoenglish.com/api/create_order.php');

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"amount": widget.selectedPlan.price}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final orderData = json.decode(response.body);
        print("Order created successfully: ${orderData['razorpay_order_id']}");
      } else {
        print("Failed to create order. Status: ${response.statusCode}");
        print("Body: ${response.body}");
      }

      if (response.statusCode == 200) {
        final orderData = json.decode(response.body);

        if (orderData['razorpay_order_id'] != null && orderData['amount'] != null) {
          var options = {

            'key': 'rzp_test_NPGwHpFZReb6dh',
            // Replace with your real Razorpay Key ID
            'amount': orderData['amount'],
            // Amount in paise
            'currency': 'INR',
            'name': '${widget.selectedPlan.name}',
            'description': 'One-Time Premium Purchase',
            'order_id': orderData['razorpay_order_id'],
            // Use Razorpay Order ID from backend
            'prefill': {
              'name': widget.userName,
              'contact': '${mobile}',
              // 'email': 'user@example.com',
            },
            'theme': {
              'color': '#49329A',
            }
          };
          _razorpay.open(options);
        } else {
          _showErrorDialog("Invalid order data received.");
        }
      } else {

        _showErrorDialog("Failed to create order.");
      }

      setState(() {
        paymentLoading = false;
      });
    // } catch (e) {
    //   debugPrint('Error: $e');
    //   _showErrorDialog("Something went wrong. Please try again.");
    //   setState(() {
    //     paymentLoading = false;
    //   });
    // }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE0F7FF),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80), // Increased app bar height
        child: AppBar(
          backgroundColor: Color(0xFF49329A),
          leading: Padding(
            padding: const EdgeInsets.only(top: 15.0, left: 24.0),
            // Adjust top padding
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 26),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 15.0), // Adjust top padding
            child: Row(
              children: [
                Text(
                  'Unlock ${widget.selectedPlan.name}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins Regular',
                  ),
                ),
              ],
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE0F7FF),
              Color(0xFFEAE4FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(25, 0, 25, 35),
          child: SingleChildScrollView(
            child: Center(
              child: Container(
                padding: EdgeInsets.fromLTRB(25, 30, 25, 35),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFEEEFFF),
                      Color(0xFFFFF0D3),
                      Color(0xFFE7F8FF),
                      Color(0xFFEEEFFF)
                    ], // Set your gradient colors here
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Color(0xFFC6B5FF), // Set your border color here
                    width: 1.0, // Set the border width
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      // Add this to minimize extra space
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Picturo',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0XFF49329A),
                                fontFamily: 'Poppins Regular',
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 12,
                                  child: Divider(
                                    color: Color(0xFF5C2E9B),
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: Text(
                                    'English',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0XFF49329A),
                                      fontFamily: 'Poppins Regular',
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 12,
                                  child: Divider(
                                    color: Color(0XFF49329A),
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(width: 30),
                        // Reduce spacing between 'Picturo' and 'Premium'
                        Text(
                          '${widget.selectedPlan.name}',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                              color: Color(0XFF49329A)),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFFDDDDDD)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Unlock Premium',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF464646),
                                  fontFamily: 'Poppins Regular',
                                ),
                              ),
                              Text(
                                widget.selectedPlan.validityDays??'',
                                style: TextStyle(
                                  color: Color(0xFF464646),
                                  fontFamily: 'Poppins Regular',
                                ),
                              ),
                            ],
                          ),
                          Text(
                            widget.selectedPlan.price??'',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF464646),
                              fontFamily: 'Poppins Regular',
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      'Enjoy the best experience with our one-time purchase.',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Poppins Regular',
                      ),
                    ),
                    SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: Row(
                        children: [
                          SvgPicture.string(
                            Svgfiles.diamondSvg,
                            width: 22,
                            height: 22,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            'Premium Features',
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Poppins Regular',
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child:       Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text("Call limit per day")),
                              Expanded(child: Text("${widget.selectedPlan.callLimitPerDay ?? 'N/A'}")),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(child: Text("Chatbot prompt limit")),
                              Expanded(child: Text("${widget.selectedPlan.chatbotPromptLimit ?? 'N/A'}")),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(child: Text("Is unlimited call")),
                              Expanded(child: Text(widget.selectedPlan.isUnlimitedCall == 1 ? "Yes" : "No")),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(child: Text("Is unlimited chat")),
                              Expanded(child: Text(widget.selectedPlan.isUnlimitedChat == 1 ? "Yes" : "No")),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(child: Text("Price")),
                              Expanded(child: Text("₹ ${widget.selectedPlan.price}")),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(child: Text("Created at")),
                              Expanded(child: Text(widget.selectedPlan.createdAt.toString())),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(child: Text("Updated at")),
                              Expanded(child: Text(widget.selectedPlan.updatedAt.toString())),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 15),

                    Container(
                      padding: EdgeInsets.fromLTRB(15, 5, 10, 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFFDDDDDD)),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Referral Code (i.e SD2334F) Optional',
                          hintStyle: TextStyle(
                            color: Color(0xFFAAAAAA),
                            fontFamily: 'Poppins Regular',
                          ),
                          border:
                              InputBorder.none, // Remove default TextField border
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF464646),
                          fontFamily: 'Poppins Regular',
                        ),
                      ),
                    ),
                    SizedBox(height: 50),
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding: EdgeInsets.only(left: 35, right: 35),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 15),
                              backgroundColor: Color(0xFF49329A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: (paymentLoading) ? () {} : openCheckout,
                            child: Text(
                              'Pay now',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins Regular',
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
