import 'package:flutter/material.dart';
import 'package:picturo_app/screens/premiumscreenpage.dart';





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
      appBar: AppBar(
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
      body: ListView.builder(
        itemCount: plans.length,
        padding: EdgeInsets.all(12),
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
          onPressed:_selectedIndex != null? _onPurchase:null ,
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
