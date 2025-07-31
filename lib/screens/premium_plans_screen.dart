import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:picturo_app/screens/premiumscreenpage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/current_premieum_model.dart';





class Plan {
  final String name;
  final String price;
  final String per;
  final List<String> features;
  final Color color;

  Plan({required this.name, required this.price, required this.features, required this.color,required this.per});
}

class PremiumPlansScreen extends StatefulWidget {
  final String? userName;
  const PremiumPlansScreen({super.key, this.userName});

  @override
  _PremiumPlansScreenState createState() => _PremiumPlansScreenState();
}

class _PremiumPlansScreenState extends State<PremiumPlansScreen> {
  int? _selectedIndex;

  final List<Plan> plans = [
    Plan(
      name: "Free Plan",
      price: "₹0",
      per: 'for One-Time Purchase',
      features: [
        "✅ Voice Call: 10 mins/day",
        "✅ Unlimited messaging",
        "✅ Access to 10% of content & games"
      ],
      color: Colors.green,
    ),
    Plan(
      name: "Premium Plan",
      price: "₹300 ",
      per: "for 3 months",
      features: [
        "✅ Voice Call: 1 hour/day",
        "✅ Unlimited messaging",
        "✅ Full access to all lessons, activities & games"
      ],
      color: Colors.blue,
    ),
    Plan(
      name: "Chatbot Plan",
      price: "₹250",
      per: "for per month",
      features: [
        "✅ Unlimited prompts with AI chatbot for English learning"
      ],
      color: Colors.amber[800]!,
    ),
    Plan(
      name: "Extra Voice Call Add-On",
      price: "₹15",
      per: "for per day",
      features: [
        "✅ Unlimited voice calls for the day"
      ],
      color: Colors.deepOrange,
    ),
  ];
  PremiumResponse? currentPremieumModel;

  @override
  void initState() {
    currentPlan();
    super.initState();
  }
  Future<void> currentPlan()async{
    currentPremieumModel=await fetchPremiumData();
    setState(() {

    });
  }


  Future<PremiumResponse?> fetchPremiumData() async {
    final url = Uri.parse("https://picturoenglish.com/api/premium.php");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");

    // try {
      final response = await http.get(url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        return PremiumResponse.fromJson(jsonData);
      } else {
        print("Failed to load data: ${response.statusCode}");
        return null;
      }
    // } catch (e) {
    //   print("Error: $e");
    //   return null;
    // }
  }
  void _onPurchase() {
    if (_selectedIndex != null) {
      final selectedPlan = plans[_selectedIndex!];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PremiumScreen(
            userName: widget.userName ?? '',
            selectedPlan: selectedPlan,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a plan first")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  Color(0xFFE0F7FF).withValues(alpha: 6),
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
                  'Choose Plan',
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 18,),
            Divider(),
            const SizedBox(height: 2,),
            Text("Current Plan",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600,color: Color(0xFF49329A)),),
            const SizedBox(height: 2,),
            Divider(),
            (currentPremieumModel==null)?Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(),
              ),
            ):(currentPremieumModel?.membership.isNotEmpty??false)?
            GestureDetector(
              onTap: () {

              },
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 8,horizontal: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFEEEFFF).withValues(alpha: .5), Color(0xFFFFF0D3).withValues(alpha: .5),Color(0xFFE7F8FF).withValues(alpha: .5),Color(0xFFEEEFFF).withValues(alpha: .5)], // Set your gradient colors here
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:  Colors.grey.shade300,
                    width: 1,
                  ),
                  // boxShadow: [
                  //   // if (isSelected)
                  //     BoxShadow(
                  //       color: plan.color.withValues(alpha: 0.3),
                  //       blurRadius: 6,
                  //       offset: Offset(0, 3),
                  //     ),
                  // ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(backgroundColor: Colors.orange, radius: 6),
                          SizedBox(width: 8),
                          Text(
                            "${currentPremieumModel?.membership.first.membership.toUpperCase()} Plan",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        "₹ ${
                            (currentPremieumModel?.membership.first.membership.toLowerCase().contains("free")??false)?
                            "0":
                            (currentPremieumModel?.membership.first.membership.toLowerCase().contains("Premium")??false)?
                            "300":(currentPremieumModel?.membership.first.membership.toLowerCase().contains("chatbot")??false)?
                            "250":(currentPremieumModel?.membership.first.membership.toLowerCase().contains("extra voice call")??false)?
                            "15":"30"
                        }",
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "${currentPremieumModel?.membership.first.planVoiceCall}",
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 6),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("${currentPremieumModel?.membership.first.planStartTime}"),
                          Text("${currentPremieumModel?.membership.first.planStartTime}"),
                        ],
                      ),
                      SizedBox(height: 8),
                      ...plans[
                        (currentPremieumModel?.membership.first.membership.toLowerCase().contains("free")??false)?
                      0:
                      (currentPremieumModel?.membership.first.membership.toLowerCase().contains("Premium")??false)?
                      1:(currentPremieumModel?.membership.first.membership.toLowerCase().contains("chatbot")??false)?
                      2:(currentPremieumModel?.membership.first.membership.toLowerCase().contains("extra voice call")??false)?
                      3:4].features.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(f),
                      )),
                    ],
                  ),
                ),
              ),
            ):SizedBox(),
            Divider(),
            const SizedBox(height: 2,),
            Text("Choose Plan",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600),),
            const SizedBox(height: 2,),
            Divider(),
            SizedBox(
              height: 800,
              child: ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                itemCount: plans.length,
                padding: EdgeInsets.symmetric(horizontal: 12,vertical: 8),
                itemBuilder: (context, index) {
                  final plan = plans[index];
                  final isSelected = _selectedIndex == index;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedIndex = index),
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFEEEFFF).withValues(alpha: .5), Color(0xFFFFF0D3).withValues(alpha: .5),Color(0xFFE7F8FF).withValues(alpha: .5),Color(0xFFEEEFFF).withValues(alpha: .5)], // Set your gradient colors here
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? plan.color : Colors.grey.shade300,
                          width: isSelected?2:1,
                        ),
                        // boxShadow: [
                        //   // if (isSelected)
                        //     BoxShadow(
                        //       color: plan.color.withValues(alpha: 0.3),
                        //       blurRadius: 6,
                        //       offset: Offset(0, 3),
                        //     ),
                        // ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(backgroundColor: plan.color, radius: 6),
                                SizedBox(width: 8),
                                Text(
                                  plan.name,
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              plan.price,
                              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                            ),
                            SizedBox(height: 10),
                            ...plan.features.map((f) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(f),
                            )),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0,horizontal: 20),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 15),
            backgroundColor: Color(0xFF49329A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed:(_selectedIndex != null&&_selectedIndex!=0)? _onPurchase:null ,
          child: Text(
            'Purchase',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins Regular',
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
