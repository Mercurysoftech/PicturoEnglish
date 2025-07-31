import 'package:flutter/material.dart';
import '../../cubits/referal_cubit/referal_cubit.dart';
import '../../utils/common_app_bar.dart';

// class WalletReferralPage extends StatefulWidget {
//   @override
//   _WalletReferralPageState createState() => _WalletReferralPageState();
// }
//
// class _WalletReferralPageState extends State<WalletReferralPage> {
//   bool showBalance = true;
//   final double balance = 0.0;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: CommonAppBar(title: "My Wallet", isBackbutton: true),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Container(
//           decoration: BoxDecoration(
//             color: Color(0xFFEDEAFF), // Light purple background
//             borderRadius: BorderRadius.circular(20),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black12,
//                 blurRadius: 10,
//                 offset: Offset(0, 4),
//               ),
//             ],
//           ),
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             children: [
//               // Wallet and Referral Row
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Wallet Card
//                   Expanded(
//                     child: Container(
//                       decoration: BoxDecoration(
//                         color: Color(0xFF49329A),
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       padding: const EdgeInsets.all(16),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             "Wallet Balance",
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Colors.white70,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                           SizedBox(height: 8),
//                           Text(
//                             showBalance
//                                 ? "\$${balance.toStringAsFixed(2)}"
//                                 : "****",
//                             style: TextStyle(
//                               fontSize: 24,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                           ),
//                           SizedBox(height: 8),
//                           TextButton.icon(
//                             onPressed: () {
//                               setState(() => showBalance = !showBalance);
//                             },
//                             icon: Icon(
//                               showBalance
//                                   ? Icons.visibility_off
//                                   : Icons.visibility,
//                               color: Colors.white,
//                               size: 18,
//                             ),
//                             label: Text(
//                               showBalance ? "Hide" : "Show",
//                               style: TextStyle(color: Colors.white),
//                             ),
//                             style: TextButton.styleFrom(
//                               foregroundColor: Colors.white,
//                               padding: EdgeInsets.zero,
//                             ),
//                           )
//                         ],
//                       ),
//                     ),
//                   ),
//
//                   SizedBox(width: 16),
//
//                   // Referral Count
//                   Column(
//                     children: [
//                       Icon(Icons.group, color: Color(0xFF49329A)),
//                       SizedBox(height: 8),
//                       Text(
//                         "Referrals",
//                         style: TextStyle(
//                           fontWeight: FontWeight.w500,
//                           fontSize: 14,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       SizedBox(height: 4),
//                       Text(
//                         "0",
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xFF49329A),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WalletReferralPage extends StatefulWidget {
  @override
  _WalletReferralPageState createState() => _WalletReferralPageState();
}

class _WalletReferralPageState extends State<WalletReferralPage> {
  bool showBalance = true;

  @override
  void initState() {
    super.initState();
    context.read<ReferralCubit>().fetchReferralEarnings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Wallet"),
        backgroundColor: const Color(0xFF49329A),
      ),
      body: BlocBuilder<ReferralCubit, ReferralState>(
        builder: (context, state) {
          if (state is ReferralLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ReferralLoaded) {
            final data = state.earnings;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEAFF),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Wallet Balance
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF49329A),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Wallet Balance",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  showBalance
                                      ? "\$${data.totalEarned.toStringAsFixed(2)}"
                                      : "****",
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () => setState(() => showBalance = !showBalance),
                                  icon: Icon(
                                    showBalance ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  label: Text(
                                    showBalance ? "Hide" : "Show",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Referrals Count
                        Column(
                          children: [
                            const Icon(Icons.group, color: Color(0xFF49329A)),
                            const SizedBox(height: 8),
                            const Text(
                              "Referrals",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${data.totalReferrals}",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF49329A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          } else if (state is ReferralError) {
            return Center(child: Text("Error: ${state.message}"));
          }
          return const SizedBox();
        },
      ),
    );
  }
}
