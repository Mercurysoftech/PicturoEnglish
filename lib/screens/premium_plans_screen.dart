import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/premium_cubit/premium_plans_cubit.dart';
import '../models/current_premieum_model.dart';
import '../models/premium_plan_model.dart';
import 'premiumscreenpage.dart';

class PremiumPlansScreen extends StatefulWidget {
  final String? userName;
  const PremiumPlansScreen({super.key, this.userName});

  @override
  _PremiumPlansScreenState createState() => _PremiumPlansScreenState();
}

class _PremiumPlansScreenState extends State<PremiumPlansScreen> {
  int? _selectedIndex;

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
        const SnackBar(content: Text("Please select a valid plan")),
      );
    }
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
    [Color(0xFF1F1C2C), Color(0xFF928DAB)], // dark purple to grey
    [Color(0xFF0F2027), Color(0xFF2C5364)], // dark teal to blue
    [Color(0xFF232526), Color(0xFF414345)], // dark grey to light grey
    [Color(0xFF141E30), Color(0xFF243B55)], // navy to steel blue
    [Color(0xFF3C1053), Color(0xFFAD5389)], // deep purple to pink
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
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Plan Header
                  _sectionHeader("Current Plan"),
                  const SizedBox(height: 12),

                  if (state.currentPlan != null && (state.currentPlan?.data?.isNotEmpty ??false))
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: state.currentPlan?.data?.length ?? 0,
                      itemBuilder: (context, index) {
                        return _buildCurrentPlanCard(state.currentPlan?.data?[index]);
                      },
                    )
                  else
                    // _noPlanCard(),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.grey,
                      ),
                      margin: EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.workspace_premium,
                                  color:  Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  state.plans.first.name ?? '',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "${state.plans.first.price} ${(state.plans.first.validityDays?.isEmpty ?? false) ? "" : "(${state.plans.first.validityDays} Days)"}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),

                            const Divider(height: 20, color: Colors.white24),
                            _buildInfoRow("Call limit per day", state.plans.first.callLimitPerDay.toString(), Colors.white70),
                            _buildInfoRow("Chatbot prompt limit", state.plans.first.chatbotPromptLimit ?? '0', Colors.white70),
                            _buildInfoRow("Unlimited Call", state.plans.first.isUnlimitedCall == 1 ? "Yes" : "No",  Colors.white70),
                            _buildInfoRow("Unlimited Chat", state.plans.first.isUnlimitedChat == 1 ? "Yes" : "No", Colors.white70),
                            _buildInfoRow("Created at", state.plans.first.createdAt ?? '', Colors.white54),
                          ],
                        ),
                      ),
                    ),

                  // Choose Plan Header
                  _sectionHeader("Choose Plan"),
                  const SizedBox(height: 12),


                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: state.plans.length,
                    itemBuilder: (context, index) {
                      final plan = state.plans[index];
                      final isSelected = _selectedIndex == index;
                      if (plan.name == "refferal_amount") return const SizedBox();

                      // Pick gradient based on index
                      final gradientColors = cardGradients[index % cardGradients.length];

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
                              color: isSelected ? Colors.deepPurpleAccent : Colors.transparent,
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
                                Row(
                                  children: [
                                    Icon(
                                      Icons.workspace_premium,
                                      color: isSelected ? Colors.amber : Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      plan.name ?? '',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "${plan.price} ${(plan.validityDays?.isEmpty ?? false) ? "" : "(${plan.validityDays} Days)"}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.tealAccent,
                                  ),
                                ),

                                const Divider(height: 20, color: Colors.white24),
                                _buildInfoRow("Call limit per day", plan.callLimitPerDay.toString(), Colors.white70),
                                _buildInfoRow("Chatbot prompt limit", plan.chatbotPromptLimit ?? '', Colors.white70),
                                _buildInfoRow("Unlimited Call", plan.isUnlimitedCall == 1 ? "Yes" : "No",  Colors.white70),
                                _buildInfoRow("Unlimited Chat", plan.isUnlimitedChat == 1 ? "Yes" : "No", Colors.white70),
                                _buildInfoRow("Created at", plan.createdAt ?? '', Colors.white54),
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
            return Center(child: Text(state.message));
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 6,horizontal: 18),
decoration: BoxDecoration(
  color: Colors.blue,
  borderRadius: BorderRadius.only(topRight: Radius.circular(10),topLeft:Radius.circular(10) ),

),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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

  Widget _buildInfoRow(String title, String value,Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Handles multi-line
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis, // Avoids overflow
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600,color: Colors.white),
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
        border: Border.all(color: Color(0xFFFF9800),width: 2),
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium, color: Colors.white, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    plan?.planName ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  "₹${plan?.price ?? '0'}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
                _buildFeatureRow("Validity Days", plan?.validityDays?.toString() ?? "-"),
                _buildFeatureRow("Call Limit/Day", plan?.callLimitPerDay?.toString() ?? "-"),
                _buildFeatureRow("Unlimited Call", plan?.isUnlimitedCall == true ? "Yes" : "No"),
                _buildFeatureRow("Unlimited Chat", plan?.isUnlimitedChat == true ? "Yes" : "No"),
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
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red),
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
          Text(title, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
