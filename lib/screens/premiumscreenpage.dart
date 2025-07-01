import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:picturo_app/classes/svgfiles.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

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
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Payment Successful"),
        content: Text("Payment ID: ${response.paymentId}"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
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
  bool paymentLoading=false;
  void openCheckout() async {
setState(() {
  paymentLoading=true;
});
    try {
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
      body: jsonEncode({
        "amount": 200
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final orderData = json.decode(response.body);
      print("Order created successfully: ${orderData['id']}");
    } else {
      print("Failed to create order. Status: ${response.statusCode}");
      print("Body: ${response.body}");
    }

      if (response.statusCode == 200) {
        final orderData = json.decode(response.body);

        if (orderData['id'] != null && orderData['amount'] != null) {
          var options = {
            'key': 'rzp_live_DmO2qslBG6Nr8v', // Replace with your real Razorpay Key ID
            'amount': orderData['amount'], // Amount in paise
            'currency': 'INR',
            'name': 'Picturo Premium',
            'description': 'One-Time Premium Purchase',
            'order_id': orderData['id'], // Use Razorpay Order ID from backend
            'prefill': {
              'contact': '9344587208',
              'email': 'user@example.com',
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
      paymentLoading=false;
    });
    } catch (e) {
      debugPrint('Error: $e');
      _showErrorDialog("Something went wrong. Please try again.");
      setState(() {
        paymentLoading=false;
      });
    }
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
            padding: const EdgeInsets.only(top: 15.0, left: 24.0), // Adjust top padding
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
                  'Unlock Premium',
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
          gradient: LinearGradient(colors: [
            Color(0xFFE0F7FF),
            Color(0xFFEAE4FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,  
          ),
        ),
        child: 
      Padding(
        padding: const EdgeInsets.fromLTRB(25, 0, 25, 35),
        child: Center(
          child: Container(
            padding: EdgeInsets.fromLTRB(25, 30, 25, 35),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
        colors: [Color(0xFFEEEFFF), Color(0xFFFFF0D3),Color(0xFFE7F8FF),Color(0xFFEEEFFF)], // Set your gradient colors here
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
  mainAxisSize: MainAxisSize.min, // Add this to minimize extra space
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
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
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
    SizedBox(width: 30), // Reduce spacing between 'Picturo' and 'Premium'
    Text(
      'Premium',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins',
        color: Color(0XFF49329A)
      ),
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
                            'One-Time Purchase for',
                            style: TextStyle(
                              color: Color(0xFF464646),
                              fontFamily: 'Poppins Regular',
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '₹200',
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
                  child:Row(
                    children: [
                      SvgPicture.string(
                Svgfiles.diamondSvg,
                width: 22,
                height: 22,
              ),
              SizedBox(width: 10,),
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
Row(
  children: [
    SvgPicture.string(
                Svgfiles.starSvg,
                width: 18,
                height: 18,
              ),
    SizedBox(width: 12),
    Expanded( // Use Expanded to allow the text to wrap
      child: Text(
        'Exclusive Content – Access special features, more games & more quotations.',
        style: TextStyle(
          fontSize: 13,
          fontFamily: 'Poppins Regular',
        ),
        overflow: TextOverflow.ellipsis, // Add ellipsis if text overflows
        maxLines: 2, // Limit to 2 lines (adjust as needed)
      ),
    ),
  ],
),
SizedBox(height: 15),
Row(
  children: [
    SvgPicture.string(
                Svgfiles.starSvg,
                width: 18,
                height: 18,
              ),
    SizedBox(width: 12),
    Expanded( // Use Expanded to allow the text to wrap
      child: Text(
        'One-Time Payment – Pay once, enjoy forever.',
        style: TextStyle(
          fontSize: 13,
          fontFamily: 'Poppins Regular',
        ),
        overflow: TextOverflow.ellipsis, // Add ellipsis if text overflows
        maxLines: 2, // Limit to 2 lines (adjust as needed)
      ),
    ),
  ],
),
SizedBox(height: 15,),
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
      border: InputBorder.none, // Remove default TextField border
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
                    child: Padding(padding: EdgeInsets.only(left: 35,right:35),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Color(0xFF49329A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed:(paymentLoading)?(){}:  openCheckout,
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
    );
  }
}