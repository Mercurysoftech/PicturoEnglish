import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/premium_cubit/premium_plans_cubit.dart';
import '../models/current_premieum_model.dart';
import '../models/premium_plan_model.dart';
import 'premiumscreenpage.dart';

class PremiumPlansScreen extends StatefulWidget {
  final String? userName;
  final bool isChatBot;
  final bool isCall;
  const PremiumPlansScreen(
      {super.key,
      this.userName,
      required this.isChatBot,
      required this.isCall});

  @override
  _PremiumPlansScreenState createState() => _PremiumPlansScreenState();
}

class _PremiumPlansScreenState extends State<PremiumPlansScreen> {
  int? _selectedIndex;
  bool _showAllPlans = false;
  List<PlanModel> _filteredPlans = [];

  @override
  void initState() {
    super.initState();
    context.read<PlanCubit>().fetchPlansAndCurrent();
  }

  void onPurchase(PlanModel plan, int index) {
    if (index != 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PremiumScreen(
            userName: widget.userName ?? '',
            selectedPlan: plan,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
          "Please select a valid plan",
          style: TextStyle(
            fontFamily: 'Poppins Regular',
          ),
        )),
      );
    }
  }

  List<PlanModel> _filterPlans(List<PlanModel> allPlans) {
    if (_showAllPlans) {
      return allPlans.where((plan) => plan.name != "refferal_amount").toList();
    }

    if (widget.isChatBot) {
      return allPlans.where((plan) {
        return plan.name != "refferal_amount" &&
            plan.type == "chatbot";
      }).toList();
    } else if (widget.isCall) {
      return allPlans.where((plan) {
        return plan.name != "refferal_amount" &&
            plan.type == "voice_call";
      }).toList();
    } else {
      return allPlans.where((plan) => plan.name != "refferal_amount").toList();
    }
  }

  // Helper methods to identify specific plans
  bool _isFreePlan(PlanModel plan) {
    return plan.price == "0.00" || plan.price == "0";
  }

  bool _is300RsPlan(PlanModel plan) {
    return plan.price == "300.00" && plan.type == "voice_call";
  }

  bool _is15RsCallPlan(PlanModel plan) {
    return plan.price == "15.00" && plan.type == "voice_call" && plan.isUnlimitedCall == 1;
  }

  bool _is15RsBotPlan(PlanModel plan) {
    return plan.price == "15.00" && plan.type == "chatbot" && plan.chatbotPromptLimit == "33";
  }

  bool _is250RsBotPlan(PlanModel plan) {
    return plan.price == "250.00" && plan.type == "chatbot" && plan.isUnlimitedChat == 1;
  }

  // Parse description which is a JSON string
  List<String> _parseDescription(PlanModel plan) {
    try {
      if (plan.description?.isNotEmpty == true && plan.description!.startsWith('[')) {
        final List<dynamic> descList = json.decode(plan.description!);
        return descList.map((e) => e.toString()).toList();
      }
    } catch (e) {
      print("Error parsing description: $e");
    }
    return [];
  }

  bool _hasMorePlans(List<PlanModel> allPlans) {
    final filteredCount = _filterPlans(allPlans).length;
    final allCount = allPlans.where((plan) => plan.name != "refferal_amount").length;
    return filteredCount < allCount;
  }

  List<Color> cardColors = [
    Colors.orange.shade100,
    Colors.blue.shade100,
    Colors.pink.shade100,
    Colors.green.shade100,
    Colors.purple.shade100,
    Colors.teal.shade100,
  ];
  final List<List<Color>> cardGradients = [
    [Color(0xFF1F1C2C), Color(0xFF928DAB)],
    [Color(0xFF0F2027), Color(0xFF2C5364)],
    [Color(0xFF232526), Color(0xFF414345)],
    [Color(0xFF141E30), Color(0xFF243B55)],
    [Color(0xFF3C1053), Color(0xFFAD5389)],
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Premium Plans',
            style: TextStyle(
              color: Colors.black87,
              fontFamily: 'Poppins Medium',
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: BlocBuilder<PlanCubit, PlanState>(
        builder: (context, state) {
          if (state is PlanLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is PlanLoaded) {
            final activePlans = state.currentPlan?.data
                    ?.where((plan) => plan.status == "active")
                    .toList() ??
                [];

            final filteredPlans = _filterPlans(state.plans);
            final hasMorePlans = _hasMorePlans(state.plans);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader("Current Plan"),
                  const SizedBox(height: 12),

                  if (activePlans.isNotEmpty)
                    ...activePlans.map((plan) => _buildCurrentPlanCard(plan)).toList()
                  else
                    _buildFreePlanCard(),

                  // Choose Plan Header
                  _sectionHeader("Choose Plan"),
                  const SizedBox(height: 12),

                  if (filteredPlans.isEmpty)
                    _buildNoPlansMessage()
                  else
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: filteredPlans.length +
                          (hasMorePlans && !_showAllPlans ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (hasMorePlans && !_showAllPlans && index == filteredPlans.length) {
                          return _buildViewMoreButton();
                        }

                        final plan = filteredPlans[index];
                        final isSelected = _selectedIndex == index;
                        final gradientColors = cardGradients[index % cardGradients.length];
                        final descriptionItems = _parseDescription(plan);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                            });
                            onPurchase(plan, index);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: gradientColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.deepPurpleAccent
                                    : Colors.transparent,
                                width: isSelected ? 2 : 0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Plan header with name and price
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          plan.name ?? '',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'Poppins Regular',
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      // Text(
                                      //   '${plan.priceIcon ?? '💰'} ₹${plan.price}',
                                      //   style: const TextStyle(
                                      //     fontSize: 16,
                                      //     fontWeight: FontWeight.w600,
                                      //     fontFamily: 'Poppins Regular',
                                      //     color: Colors.tealAccent,
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  // Validity
                                  Text(
                                    plan.priceAndValid ?? '${plan.validityDays} days',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.8),
                                      fontFamily: 'Poppins Regular',
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Description items
                                  if (descriptionItems.isNotEmpty)
                                    ...descriptionItems.map((item) => 
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('• ', style: TextStyle(color: Colors.white)),
                                            Expanded(
                                              child: Text(
                                                item,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white.withOpacity(0.9),
                                                  fontFamily: 'Poppins Regular',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ).toList()
                                  else
                                    _buildDefaultPlanDetails(plan),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          } else if (state is PlanError) {
            return Center(
                child: Text(
              state.message,
              style: TextStyle(
                fontFamily: 'Poppins Medium',
              ),
            ));
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildDefaultPlanDetails(PlanModel plan) {
    final List<Widget> details = [];

    if (plan.type == "voice_call") {
      if (plan.isUnlimitedCall == 1) {
        details.add(_buildDetailRow('✅ Unlimited Live Conversation Practice'));
      } else if (plan.callLimitPerDay != null && plan.callLimitPerDay! > 0) {
        details.add(_buildDetailRow('✅ Daily Live Conversation Practice: ${plan.callLimitPerDay} minutes/day'));
      }
    } else if (plan.type == "chatbot") {
      if (plan.isUnlimitedChat == 1) {
        details.add(_buildDetailRow('✅ Unlimited Chat Access'));
      } else if (plan.chatbotPromptLimit != null && plan.chatbotPromptLimit!.isNotEmpty) {
        details.add(_buildDetailRow('✅ ${plan.chatbotPromptLimit} Chat Prompts'));
      }
    }

    details.addAll([
      _buildDetailRow('✅ All Learning Modules: ${_isFreePlan(plan) ? 'Limited access' : 'Fully accessible'}'),
      _buildDetailRow('✅ Games: ${_isFreePlan(plan) ? 'Limited access' : 'Fully accessible'}'),
      _buildDetailRow('✅ Chat with Co-learners: Fully accessible'),
    ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: details,
    );
  }

  Widget _buildDetailRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
                fontFamily: 'Poppins Regular',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreePlanCard() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: [Color(0xFF616161), Color(0xFF9E9E9E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium, color: Colors.amber),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Free Plan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Poppins Regular',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              '💰 ₹0.00 / Lifetime',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                fontFamily: 'Poppins Regular',
              ),
            ),
            SizedBox(height: 12),
            _buildFreeFeatureRow(
                '✅ Daily Live Conversation Practice: 10 minutes/day'),
            _buildFreeFeatureRow('✅ All Learning Modules: Limited access'),
            _buildFreeFeatureRow('✅ Games: Limited access'),
            _buildFreeFeatureRow('✅ Chat with Co-learners: Fully accessible'),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
                fontFamily: 'Poppins Regular',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPlansMessage() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            widget.isChatBot
                ? "No chatbot plans available"
                : "No call plans available",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              fontFamily: 'Poppins Regular',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          _buildViewMoreButton(),
        ],
      ),
    );
  }

  Widget _buildViewMoreButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _showAllPlans = true;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 2,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "View All Plans",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins Regular',
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 6, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.only(
            topRight: Radius.circular(10), topLeft: Radius.circular(10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Poppins Regular',
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1.2,
              color: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Handles multi-line
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(
                  color: Colors.white, fontFamily: 'Poppins Regular'),
              overflow: TextOverflow.fade, // Avoids overflow
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFamily: 'Poppins Regular'),
              overflow: TextOverflow.visible, // Allows wrapping
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPlanCard(Data? plan) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFFFF9800), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFFF9800),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium,
                    color: Colors.white, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    plan?.planName ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins Regular',
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  "₹${plan?.price ?? '0'}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins Regular',
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Details section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildFeatureRow(
                    "Validity Days", plan?.validityDays?.toString() ?? "-"),
                // Only show call limit if it's not null and greater than 0
                if (plan?.callLimitPerDay != null && plan!.callLimitPerDay! > 0)
                  _buildFeatureRow("Call Limit/Day",
                      '${plan.callLimitPerDay.toString()} Minutes'),
                // Only show unlimited call if it's "Yes"
                if (plan?.isUnlimitedCall == true)
                  _buildFeatureRow("Unlimited Call", "Yes"),
                // Only show unlimited chat if it's "Yes"
                if (plan?.isUnlimitedChat == true)
                  _buildFeatureRow("Unlimited Chat", "Yes"),
                _buildFeatureRow("Start Date", plan?.startDate ?? "-"),
                _buildFeatureRow("End Date", plan?.endDate ?? "-"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _noPlanCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent),
      ),
      child: const Center(
        child: Text(
          "No Current Plan Available",
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                color: Colors.black54,
                fontFamily: 'Poppins Regular',
              )),
          Text(value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins Regular',
              )),
        ],
      ),
    );
  }
}
