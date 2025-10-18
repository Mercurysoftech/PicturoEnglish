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

  // Filter plans based on isChatBot or isCall
  List<PlanModel> _filterPlans(List<PlanModel> allPlans) {
    if (_showAllPlans) {
      return allPlans.where((plan) => plan.name != "refferal_amount").toList();
    }

    if (widget.isChatBot) {
      // Show only chatbot-related plans (plans with chatbot features)
      return allPlans.where((plan) {
        return plan.name != "refferal_amount" &&
            (plan.chatbotPromptLimit != null &&
                int.tryParse(plan.chatbotPromptLimit ?? '0') != null &&
                int.parse(plan.chatbotPromptLimit ?? '0') > 0);
      }).toList();
    } else if (widget.isCall) {
      // Show only call-related plans (plans with call features)
      return allPlans.where((plan) {
        return plan.name != "refferal_amount" &&
            ((plan.callLimitPerDay ?? 0) > 0 || plan.isUnlimitedCall == 1);
      }).toList();
    } else {
      // Show all plans except referral_amount
      return allPlans.where((plan) => plan.name != "refferal_amount").toList();
    }
  }

  bool _is300RsPlan(PlanModel plan) {
    return plan.price?.contains('300') == true ||
        plan.price?.contains('₹300') == true ||
        plan.price?.contains('300') == true;
  }

  bool _is250RsPlan(PlanModel plan) {
    return plan.price?.contains('250') == true ||
        plan.price?.contains('₹250') == true ||
        plan.price?.contains('250') == true;
  }

  bool _is15RsBotPlan(PlanModel plan) {
    final price = plan.price?.toLowerCase() ?? '';
    final type = plan.type?.toLowerCase() ?? '';
    final name = plan.name?.toLowerCase() ?? '';

    final is15Rs = price.contains('15') ||
        price.contains('₹15') ||
        price.contains('15') ||
        (plan.price != null &&
            double.tryParse(plan.price!.replaceAll('₹', '').trim()) == 15);

    final isBotPlan = type.contains('chatbot') ||
        type.contains('chat') ||
        name.contains('chatbot') ||
        name.contains('chat') ||
        (plan.chatbotPromptLimit != null &&
            plan.chatbotPromptLimit!.isNotEmpty) ||
        plan.isUnlimitedChat == 1;

    return is15Rs && isBotPlan;
  }

  bool _is15RsCallPlan(PlanModel plan) {
    final price = plan.price?.toLowerCase() ?? '';
    final type = plan.type?.toLowerCase() ?? '';
    final name = plan.name?.toLowerCase() ?? '';

    final is15Rs = price.contains('15') ||
        price.contains('₹15') ||
        price.contains('15') ||
        (plan.price != null &&
            double.tryParse(plan.price!.replaceAll('₹', '').trim()) == 15);

    final isCallPlan = type.contains('voice_call') ||
        type.contains('call') ||
        name.contains('call') ||
        (plan.callLimitPerDay != null && plan.callLimitPerDay! > 0) ||
        plan.isUnlimitedCall == 1;

    return is15Rs && isCallPlan;
  }

  bool _hasMorePlans(List<PlanModel> allPlans) {
    final filteredCount = _filterPlans(allPlans).length;
    final allCount =
        allPlans.where((plan) => plan.name != "refferal_amount").length;
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
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: activePlans.length,
                      itemBuilder: (context, index) {
                        return _buildCurrentPlanCard(activePlans[index]);
                      },
                    )
                  else
                    // _noPlanCard(),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.grey.shade700,
                      ),
                      margin: EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: const Text(
                                                  '💎 Free Call Plan',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                    fontFamily:
                                                        'Poppins Regular',
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            '💰 ₹0.00 / Lifetime',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontFamily: 'Poppins Regular',
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '✅ Daily Live Conversation Practice: 10 minutes/day',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontFamily: 'Poppins Regular',
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '✅ All Learning Modules: Fully accessible',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontFamily: 'Poppins Regular',
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '✅ Games: Fully accessible',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontFamily: 'Poppins Regular',
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '✅ Chat with Co-learners: Fully accessible',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontFamily: 'Poppins Regular',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                          ],
                        ),
                      ),
                    ),

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
                        // Check if this is the View More button
                        if (hasMorePlans &&
                            !_showAllPlans &&
                            index == filteredPlans.length) {
                          return _buildViewMoreButton();
                        }

                        final plan = filteredPlans[index];
                        final isSelected = _selectedIndex == index;
                        final is300RsPlan = _is300RsPlan(plan);
                        final is250RsBotPlan = _is250RsPlan(plan);
                        final is15RsBotPlan = _is15RsBotPlan(plan);
                        final is15RsCallPlan = _is15RsCallPlan(plan);

                        // Pick gradient based on index
                        final gradientColors =
                            cardGradients[index % cardGradients.length];

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
                                  // Row(
                                  //   children: [
                                  //     Icon(
                                  //       Icons.workspace_premium,
                                  //       color: isSelected
                                  //           ? Colors.amber
                                  //           : Colors.white,
                                  //     ),
                                  //     const SizedBox(width: 8),
                                  //     Text(
                                  //       plan.name ?? '',
                                  //       style: const TextStyle(
                                  //         fontSize: 18,
                                  //         fontWeight: FontWeight.w700,
                                  //         fontFamily: 'Poppins Regular',
                                  //         color: Colors.white,
                                  //       ),
                                  //     ),
                                  //     // if (is300RsPlan) ...[
                                  //     //   const SizedBox(width: 8),
                                  //     //   Container(
                                  //     //     padding: const EdgeInsets.symmetric(
                                  //     //         horizontal: 8, vertical: 2),
                                  //     //     decoration: BoxDecoration(
                                  //     //       color: Colors.amber,
                                  //     //       borderRadius:
                                  //     //           BorderRadius.circular(12),
                                  //     //     ),
                                  //     //     child: const Text(
                                  //     //       'Popular',
                                  //     //       style: TextStyle(
                                  //     //         fontSize: 12,
                                  //     //         fontWeight: FontWeight.bold,
                                  //     //         color: Colors.black,
                                  //     //         fontFamily: 'Poppins Regular',
                                  //     //       ),
                                  //     //     ),
                                  //     //   ),
                                  //     // ],
                                  //   ],
                                  // ),
                                  // const SizedBox(height: 6),
                                  // Text(
                                  //   "${plan.price} ${(plan.validityDays?.isEmpty ?? false) ? "" : "(${plan.validityDays} Days)"}",
                                  //   style: const TextStyle(
                                  //     fontSize: 16,
                                  //     fontFamily: 'Poppins Regular',
                                  //     fontWeight: FontWeight.w600,
                                  //     color: Colors.tealAccent,
                                  //   ),
                                  // ),
                                  if (is15RsCallPlan) ...[
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: const Text(
                                                  '🚀 Extra Live Conversation Practice (1 Day)',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.amber,
                                                    fontFamily:
                                                        'Poppins Regular',
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            '💰 ₹15.00 / 1 Day',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontFamily: 'Poppins Regular',
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '✅ Unlimited Live Conversation Practice: Unlocked for 24 hours',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontFamily: 'Poppins Regular',
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '✅ All Learning Modules: Limited access',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontFamily: 'Poppins Regular',
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '✅ Games: Limited access',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontFamily: 'Poppins Regular',
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '✅ Chat with Co-learners: Fully accessible',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontFamily: 'Poppins Regular',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (!is300RsPlan && !is250RsBotPlan && !is15RsBotPlan && !is15RsCallPlan) ...[
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: const Text(
                                                  '💎 Free Call Plan',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.amber,
                                                    fontFamily:
                                                        'Poppins Regular',
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            '💰 ₹0.00 / Lifetime',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontFamily: 'Poppins Regular',
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '✅ Daily Live Conversation Practice: 10 minutes/day',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontFamily: 'Poppins Regular',
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '✅ All Learning Modules: Fully accessible',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontFamily: 'Poppins Regular',
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '✅ Games: Fully accessible',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontFamily: 'Poppins Regular',
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '✅ Chat with Co-learners: Fully accessible',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontFamily: 'Poppins Regular',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (is300RsPlan) ...[
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: const Text(
                                                  '🌟 Premium Plan: Unlimited Learning Access with Live Conversation Practice (3 Months)',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.amber,
                                                    fontFamily:
                                                        'Poppins Regular',
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            '💰 ₹300 • Valid for 90 Days',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontFamily: 'Poppins Regular',
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '✅ Daily Live Conversation Practice: 1 hour/day',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontFamily: 'Poppins Regular',
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '✅ All Learning Modules: Fully accessible',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontFamily: 'Poppins Regular',
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '✅ Games: Fully accessible',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontFamily: 'Poppins Regular',
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '✅ Chat with Co-learners: Fully accessible',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontFamily: 'Poppins Regular',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (is250RsBotPlan) ...[
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: const Text(
                                                  'Chatbot (Monthly Pack)',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.amber,
                                                    fontFamily:
                                                        'Poppins Regular',
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            '💰 ₹250.00 / 1 Month',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontFamily: 'Poppins Regular',
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '🔓 Unlimited Chat Access',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontFamily: 'Poppins Regular',
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '🤖 24/7 Chatbot Availability',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontFamily: 'Poppins Regular',
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '🎯 Your Perfect English Partner',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontFamily: 'Poppins Regular',
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '🕒 Valid for 30 days',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontFamily: 'Poppins Regular',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (is15RsBotPlan) ...[
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: const Text(
                                                  'Chatbot (Day Pack)',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.amber,
                                                    fontFamily:
                                                        'Poppins Regular',
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            '💰 ₹15.00 / 1 Day',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontFamily: 'Poppins Regular',
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '🔢 33 Chat Tokens Available',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontFamily: 'Poppins Regular',
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '🤖 24/7 Chatbot Access',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontFamily: 'Poppins Regular',
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '🎯 Your Perfect English Partner',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontFamily: 'Poppins Regular',
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '🕒 Valid for 24 hours',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontFamily: 'Poppins Regular',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  // const Divider(
                                  //     height: 20, color: Colors.white24),
                                  // if (plan.callLimitPerDay != null &&
                                  //     plan.callLimitPerDay! > 0)
                                  //   _buildInfoRow(
                                  //       "Call limit per day",
                                  //       "${plan.callLimitPerDay.toString()} Mins",
                                  //       Colors.white70),
                                  // if (plan.chatbotPromptLimit != null &&
                                  //     plan.chatbotPromptLimit != '0' &&
                                  //     plan.chatbotPromptLimit != '')
                                  //   _buildInfoRow(
                                  //       "Chatbot prompt limit",
                                  //       '${plan.chatbotPromptLimit} Prompts' ??
                                  //           '',
                                  //       Colors.white70),
                                  // // Only show unlimited call if it's "Yes"
                                  // if (plan.isUnlimitedCall == 1)
                                  //   _buildInfoRow("Unlimited Call", "Yes",
                                  //       Colors.white70),
                                  // // Only show unlimited chat if it's "Yes"
                                  // if (plan.isUnlimitedChat == 1)
                                  //   _buildInfoRow("Unlimited Chat", "Yes",
                                  //       Colors.white70),
                                  // _buildInfoRow("Created at",
                                  //     plan.createdAt ?? '', Colors.white54),
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
                  _buildFeatureRow(
                      "Call Limit/Day", plan.callLimitPerDay.toString()),
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
