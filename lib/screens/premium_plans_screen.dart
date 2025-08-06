import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:picturo_app/screens/premiumscreenpage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../cubits/premium_cubit/premium_plans_cubit.dart';
import '../models/current_premieum_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/premium_plan_model.dart';






// class PremiumPlansScreen extends StatefulWidget {
//   final String? userName;
//   const PremiumPlansScreen({super.key, this.userName});
//
//   @override
//   _PremiumPlansScreenState createState() => _PremiumPlansScreenState();
// }
//
// class _PremiumPlansScreenState extends State<PremiumPlansScreen> {
//   int? _selectedIndex;
//
//   // final List<PlanModel> plans = [
//   //   PlanModel(
//   //     name: "Free Plan",
//   //     price: "₹0",
//   //     per: 'for One-Time Purchase',
//   //     features: [
//   //       "✅ Voice Call: 10 mins/day",
//   //       "✅ Unlimited messaging",
//   //       "✅ Access to 10% of content & games"
//   //     ],
//   //     color: Colors.green,
//   //   ),
//   //   Plan(
//   //     name: "Premium Plan",
//   //     price: "₹300 ",
//   //     per: "for 3 months",
//   //     features: [
//   //       "✅ Voice Call: 1 hour/day",
//   //       "✅ Unlimited messaging",
//   //       "✅ Full access to all lessons, activities & games"
//   //     ],
//   //     color: Colors.blue,
//   //   ),
//   //   Plan(
//   //     name: "Chatbot Plan",
//   //     price: "₹250",
//   //     per: "for per month",
//   //     features: [
//   //       "✅ Unlimited prompts with AI chatbot for English learning"
//   //     ],
//   //     color: Colors.amber[800]!,
//   //   ),
//   //   Plan(
//   //     name: "Extra Voice Call Add-On",
//   //     price: "₹15",
//   //     per: "for per day",
//   //     features: [
//   //       "✅ Unlimited voice calls for the day"
//   //     ],
//   //     color: Colors.deepOrange,
//   //   ),
//   // ];
//   PremiumResponse? currentPremieumModel;
//
//   @override
//   void initState() {
//     currentPlan();
//     super.initState();
//   }
//   Future<void> currentPlan()async{
//     currentPremieumModel=await fetchPremiumData();
//     setState(() {
//
//     });
//   }
//
//
//   Future<PremiumResponse?> fetchPremiumData() async {
//     final url = Uri.parse("https://picturoenglish.com/api/premium.php");
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString("auth_token");
//
//     // try {
//       final response = await http.get(url,
//         headers: {
//           "Authorization": "Bearer $token",
//           "Content-Type": "application/json"
//         },);
//
//       if (response.statusCode == 200) {
//         final jsonData = json.decode(response.body);
//
//         return PremiumResponse.fromJson(jsonData);
//       } else {
//         print("Failed to load data: ${response.statusCode}");
//         return null;
//       }
//     // } catch (e) {
//     //   print("Error: $e");
//     //   return null;
//     // }
//   }
//   void _onPurchase() {
//     if (_selectedIndex != null) {
//       final selectedPlan = plans[_selectedIndex!];
//
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => PremiumScreen(
//             userName: widget.userName ?? '',
//             selectedPlan: selectedPlan,
//           ),
//         ),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Please select a plan first")),
//       );
//     }
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor:  Color(0xFFE0F7FF).withValues(alpha: 6),
//       appBar: PreferredSize(
//         preferredSize: Size.fromHeight(80), // Increased app bar height
//         child: AppBar(
//           backgroundColor: Color(0xFF49329A),
//           leading: Padding(
//             padding: const EdgeInsets.only(top: 15.0, left: 24.0),
//             // Adjust top padding
//             child: IconButton(
//               icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 26),
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//             ),
//           ),
//           title: Padding(
//             padding: const EdgeInsets.only(top: 15.0), // Adjust top padding
//             child: Row(
//               children: [
//                 Text(
//                   'Choose Plan',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     fontFamily: 'Poppins Regular',
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.only(
//               bottomLeft: Radius.circular(20),
//               bottomRight: Radius.circular(20),
//             ),
//           ),
//         ),
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             const SizedBox(height: 18,),
//             Divider(),
//             const SizedBox(height: 2,),
//             Text("Current Plan",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600,color: Color(0xFF49329A)),),
//             const SizedBox(height: 2,),
//             Divider(),
//             (currentPremieumModel==null)?Center(
//               child: SizedBox(
//                 height: 20,
//                 width: 20,
//                 child: CircularProgressIndicator(),
//               ),
//             ):(currentPremieumModel?.membership.isNotEmpty??false)?
//             GestureDetector(
//               onTap: () {
//
//               },
//               child: Container(
//                 margin: EdgeInsets.symmetric(vertical: 8,horizontal: 10),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [Color(0xFFEEEFFF).withValues(alpha: .5), Color(0xFFFFF0D3).withValues(alpha: .5),Color(0xFFE7F8FF).withValues(alpha: .5),Color(0xFFEEEFFF).withValues(alpha: .5)], // Set your gradient colors here
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(
//                     color:  Colors.grey.shade300,
//                     width: 1,
//                   ),
//                   // boxShadow: [
//                   //   // if (isSelected)
//                   //     BoxShadow(
//                   //       color: plan.color.withValues(alpha: 0.3),
//                   //       blurRadius: 6,
//                   //       offset: Offset(0, 3),
//                   //     ),
//                   // ],
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           CircleAvatar(backgroundColor: Colors.orange, radius: 6),
//                           SizedBox(width: 8),
//                           Text(
//                             "${currentPremieumModel?.membership.first.membership.toUpperCase()} Plan",
//                             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 8),
//                       Text(
//                         "₹ ${
//                             (currentPremieumModel?.membership.first.membership.toLowerCase().contains("free")??false)?
//                             "0":
//                             (currentPremieumModel?.membership.first.membership.toLowerCase().contains("Premium")??false)?
//                             "300":(currentPremieumModel?.membership.first.membership.toLowerCase().contains("chatbot")??false)?
//                             "250":(currentPremieumModel?.membership.first.membership.toLowerCase().contains("extra voice call")??false)?
//                             "15":"30"
//                         }",
//                         style: TextStyle(fontSize: 16, color: Colors.grey[700]),
//                       ),
//                       SizedBox(height: 4),
//                       Text(
//                         "${currentPremieumModel?.membership.first.planVoiceCall}",
//                         style: TextStyle(fontSize: 16, color: Colors.grey[700]),
//                       ),
//                       SizedBox(height: 6),
//                       Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text("${currentPremieumModel?.membership.first.planStartTime}"),
//                           Text("${currentPremieumModel?.membership.first.planStartTime}"),
//                         ],
//                       ),
//                       SizedBox(height: 8),
//                       ...plans[
//                         (currentPremieumModel?.membership.first.membership.toLowerCase().contains("free")??false)?
//                       0:
//                       (currentPremieumModel?.membership.first.membership.toLowerCase().contains("Premium")??false)?
//                       1:(currentPremieumModel?.membership.first.membership.toLowerCase().contains("chatbot")??false)?
//                       2:(currentPremieumModel?.membership.first.membership.toLowerCase().contains("extra voice call")??false)?
//                       3:4].features.map((f) => Padding(
//                         padding: const EdgeInsets.only(bottom: 4),
//                         child: Text(f),
//                       )),
//                     ],
//                   ),
//                 ),
//               ),
//             ):SizedBox(),
//             Divider(),
//             const SizedBox(height: 2,),
//             Text("Choose Plan",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600),),
//             const SizedBox(height: 2,),
//             Divider(),
//             SizedBox(
//               height: 800,
//               child: ListView.builder(
//                 physics: NeverScrollableScrollPhysics(),
//                 itemCount: plans.length,
//                 padding: EdgeInsets.symmetric(horizontal: 12,vertical: 8),
//                 itemBuilder: (context, index) {
//                   final plan = plans[index];
//                   final isSelected = _selectedIndex == index;
//
//                   return GestureDetector(
//                     onTap: () => setState(() => _selectedIndex = index),
//                     child: Container(
//                       margin: EdgeInsets.symmetric(vertical: 8),
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [Color(0xFFEEEFFF).withValues(alpha: .5), Color(0xFFFFF0D3).withValues(alpha: .5),Color(0xFFE7F8FF).withValues(alpha: .5),Color(0xFFEEEFFF).withValues(alpha: .5)], // Set your gradient colors here
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                         ),
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(
//                           color: isSelected ? plan.color : Colors.grey.shade300,
//                           width: isSelected?2:1,
//                         ),
//                         // boxShadow: [
//                         //   // if (isSelected)
//                         //     BoxShadow(
//                         //       color: plan.color.withValues(alpha: 0.3),
//                         //       blurRadius: 6,
//                         //       offset: Offset(0, 3),
//                         //     ),
//                         // ],
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               children: [
//                                 CircleAvatar(backgroundColor: plan.color, radius: 6),
//                                 SizedBox(width: 8),
//                                 Text(
//                                   plan.name,
//                                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                                 ),
//                               ],
//                             ),
//                             SizedBox(height: 8),
//                             Text(
//                               plan.price,
//                               style: TextStyle(fontSize: 16, color: Colors.grey[700]),
//                             ),
//                             SizedBox(height: 10),
//                             ...plan.features.map((f) => Padding(
//                               padding: const EdgeInsets.only(bottom: 4),
//                               child: Text(f),
//                             )),
//                           ],
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 12.0,horizontal: 20),
//         child: ElevatedButton(
//           style: ElevatedButton.styleFrom(
//             padding: EdgeInsets.symmetric(vertical: 15),
//             backgroundColor: Color(0xFF49329A),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//           onPressed:(_selectedIndex != null&&_selectedIndex!=0)? _onPurchase:null ,
//           child: Text(
//             'Purchase',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               fontFamily: 'Poppins Regular',
//               color: Colors.white,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }




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

  void onPurchase(PlanModel plans,int? _selectedIndex) {
    if (_selectedIndex != null&&_selectedIndex!=0) {
      final selectedPlan = plans;
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
      if(_selectedIndex==0){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select valid plan")),
        );
      }else{
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a plan first")),
        );
      }

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: const Color(0xFF49329A),
          leading: Padding(
            padding: const EdgeInsets.only(top: 15.0, left: 24.0),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 26),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: const Padding(
            padding: EdgeInsets.only(top: 15.0),
            child: Text(
              'Choose Plan',
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
      ),
      body: BlocBuilder<PlanCubit, PlanState>(
        builder: (context, state) {
          if (state is PlanLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is PlanLoaded) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: SingleChildScrollView(
                      child: SafeArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 18),
                            const Divider(),
                            const SizedBox(height: 2),
                            const Text(
                              "Current Plans",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF49329A)),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            const Divider(),

                            if (state.currentPlan != null && (state.currentPlan?.data?.isNotEmpty ?? false))
                              ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: state.currentPlan?.data?.length,
                                itemBuilder: (context, index) {
                                  return _buildCurrentPlanCard(state.currentPlan?.data?[index]);
                                },
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFEEEFFF).withOpacity(0.5),
                                      const Color(0xFFFFF0D3).withOpacity(0.5),
                                      const Color(0xFFE7F8FF).withOpacity(0.5),
                                      const Color(0xFFEEEFFF).withOpacity(0.5)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300, width: 1),
                                ),
                                child: const Center(
                                  child: Text(
                                    "No Current Plan Available",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red),
                                  ),
                                ),
                              ),

                            const Divider(),
                            const SizedBox(height: 2),
                            const Text(
                              "Choose Plan",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            const Divider(),

                            ListView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: state.plans.length,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              itemBuilder: (context, index) {
                                final plan = state.plans[index];
                                final isSelected = _selectedIndex == index;
                                if (plan.name == "refferal_amount") return const SizedBox();
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      onPurchase(plan,index);
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFFEEEFFF).withOpacity(0.5),
                                          const Color(0xFFFFF0D3).withOpacity(0.5),
                                          const Color(0xFFE7F8FF).withOpacity(0.5),
                                          const Color(0xFFEEEFFF).withOpacity(0.5),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? Colors.blue : Colors.grey.shade300,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const CircleAvatar(backgroundColor: Colors.blue, radius: 6),
                                              const SizedBox(width: 8),
                                              Text(
                                                plan.name ?? '',
                                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text("${plan.price} ${(plan.validityDays?.isEmpty??false) ? "" : "(${plan.validityDays} Days)"}"),
                                          const SizedBox(height: 10),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _buildInfoRow("Call limit per day", plan.callLimitPerDay.toString()),
                                              _buildInfoRow("Chatbot prompt limit", plan.chatbotPromptLimit??''),
                                              _buildInfoRow("Is unlimited call", plan.isUnlimitedCall == 1 ? "Yes" : "No"),
                                              _buildInfoRow("Is unlimited chat", plan.isUnlimitedChat == 1 ? "Yes" : "No"),
                                              _buildInfoRow("Price", "₹ ${plan.price}"),
                                              _buildInfoRow("Created at", plan.createdAt??''),
                                              _buildInfoRow("Updated at", plan.updatedAt??""),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(
                              height: 80,
                            )

                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );

          } else if (state is PlanError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox();
        },
      ),
    );
  }
  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildCurrentPlanCard(Data? currentPlan) {
    final plan = currentPlan;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEEEFFF).withOpacity(0.5),
            const Color(0xFFFFF0D3).withOpacity(0.5),
            const Color(0xFFE7F8FF).withOpacity(0.5),
            const Color(0xFFEEEFFF).withOpacity(0.5)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(backgroundColor: Colors.orange, radius: 6),
                const SizedBox(width: 8),
                Text(
                  plan?.status ?? '',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            // const SizedBox(height: 8),
            // Text(
            //   "₹ ${plan?.price ?? '0'}",
            //   style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            // ),
            const SizedBox(height: 12),

            // Plan feature details
            _buildFeatureRow("Voice Call", plan?.remainingCallMinutes.toString() ?? "0"),
            // _buildFeatureRow("Messages", plan?.planMessage ?? "0"),
            // _buildFeatureRow("Games", plan?.planGames ?? "0"),
            _buildFeatureRow("Chatbot", plan?.remainingChatbotPrompts.toString() ?? "0"),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Start: ${plan?.startDate ?? ''}",style: TextStyle(fontWeight: FontWeight.bold),),
                Text("End: ${plan?.endDate ?? ''}",style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            // Text("Activated on: ${plan?.activePlanDate ?? ''}"),
          ],
        ),
      ),
    );
  }

// helper for row display
  Widget _buildFeatureRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }


}


