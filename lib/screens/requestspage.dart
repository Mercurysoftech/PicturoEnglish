import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:picturo_app/providers/requests_provider.dart';
import 'package:picturo_app/responses/chat_requests_response.dart';
import 'package:picturo_app/screens/chatscreenpage.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:picturo_app/utils/common_file.dart';
import 'package:provider/provider.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  _RequestsPageState createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  List<Requests> allUsers = [];
  List<Requests> friends = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAllUsers();
  }

  Future<void> _fetchAllUsers() async {
    // try {
    final apiService = await ApiService.create();
    final RequestsResponse response = await apiService.fetchRequests();

    final pending = response.received_requests
        .where((user) => user.status != "accepted" && user.status == "pending")
        .toList();

    setState(() {
      allUsers = pending;
      friends = response.received_requests
          .where((user) => user.status == "accepted")
          .toList();
      isLoading = false;
    });
    // } catch (e) {
    //   setState(() {
    //     errorMessage = e.toString();
    //     isLoading = false;
    //   });
    // }

    final requestsProvider =
        Provider.of<RequestsProvider>(context, listen: false);
    requestsProvider.setRequestsCount(pending.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE0F7FF),
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
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
                ? Center(
                    child:
                        Text(errorMessage, style: TextStyle(color: Colors.red)))
                : (allUsers.where((users) => users.status == "pending")).isEmpty
                    ? Center(
                        child: AnimatedOpacity(
                        opacity: 1,
                        duration: const Duration(milliseconds: 300),
                        child: const EmptyRequestsState(),
                      )
                      )
                    : ListView(
                        padding: EdgeInsets.fromLTRB(15, 0, 15, 15),
                        children: [
                          SizedBox(height: 20),
                          ...allUsers
                              .map((user) => _buildUserTile(context, user)),
                        ],
                      ),
      ),
    );
  }

  Widget _buildUserTile(BuildContext context, Requests user) {
    return GestureDetector(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(width: 1, color: Color(0xFFDDDDDD)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage('assets/avatar2.png'),
              radius: 25,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                user.username,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins Regular',
                ),
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _handleDecline(user),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Color(0xFF9A9A9A), width: 1),
                    ),
                    child: Text(
                      'Decline',
                      style: TextStyle(
                        fontFamily: 'Poppins Regular',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9A9A9A),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _handleAccept(user),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFEDE8FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Accept',
                      style: TextStyle(
                        fontFamily: 'Poppins Regular',
                        color: Color(0xFF49329A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleAccept(Requests user) async {
    try {
      final apiService = await ApiService.create();
      final response =
          await apiService.acceptChatRequest(requestId: user.sender_id);

      if (response.containsValue("success")) {
        setState(() {
          allUsers.removeWhere((u) => u.id == user.id);
        });

        final requestsProvider =
            Provider.of<RequestsProvider>(context, listen: false);
        requestsProvider.setRequestsCount(allUsers.length);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Request accepted successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(response["error"] ?? "Failed to accept request")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: ${e.toString()}")),
      );
    }
  }

  void _handleDecline(Requests user) async {
    try {
      final apiService = await ApiService.create();
      final response =
          await apiService.declineChatRequest(requestId: user.sender_id);

      if (response.containsValue("success")) {
        setState(() {
          allUsers.removeWhere((u) => u.id == user.id);
        });

        final requestsProvider =
            Provider.of<RequestsProvider>(context, listen: false);
        requestsProvider.setRequestsCount(allUsers.length);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Request declined successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(response["error"] ?? "Failed to decline request")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: ${e.toString()}")),
      );
    }
  }
}

class EmptyRequestsState extends StatelessWidget {
  const EmptyRequestsState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/lottie/empty_notifications.json',
            width: 230,
            height: 230,
            fit: BoxFit.contain,
            repeat: false,
          ),
          const Text(
            "No friend requests",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: AppConstants.commonFont
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "When someone sends you a request, it will appear here",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontFamily: AppConstants.commonFont
            ),
          ),
        ],
      ),
    );
  }
}
