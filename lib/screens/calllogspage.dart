import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/call_log_his_cubit/call_log_cubit.dart';
import '../responses/allusers_response.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CallLogPage extends StatefulWidget {
  const CallLogPage({super.key, required this.allUsers});
  final List<User> allUsers;

  @override
  State<CallLogPage> createState() => _CallLogPageState();
}

class _CallLogPageState extends State<CallLogPage> {
  int? currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
  }

  Future<void> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
   String? userId = prefs.getString("user_id");
    setState(() {
      currentUserId = int.parse(userId ?? '0');
    });
    context.read<CallLogCubit>().fetchCallLogs(allUsers: widget.allUsers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: BlocBuilder<CallLogCubit, CallLogState>(
          builder: (context, state) {
            if (currentUserId == null) {
              return Center(child: CircularProgressIndicator());
            }
            
            if (state is CallLogLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is CallLogLoaded) {
              return (state.callLogs.isEmpty)
                  ? Center(
                      child: Text("No Record Found"),
                    )
                  : ListView.builder(
                      itemCount: state.callLogs.length,
                      itemBuilder: (context, index) {
                        final log = state.callLogs[index];
                        final isOutgoing = log.callerId == currentUserId;
                        final isMissed = log.status.toLowerCase() == 'missed';
                        final isVideo = log.callType.toLowerCase() == 'video';
                        final isIncoming = !isOutgoing;

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                          color: isOutgoing
                              ? Colors.white 
                              : Colors.white,
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            leading: CircleAvatar(
                              radius: 22,
                              backgroundColor: isOutgoing
                                  ? Colors.green[100] 
                                  : Colors.red[100],
                              child: Icon(
                                isVideo ? Icons.videocam : Icons.call,
                                color: isOutgoing ? Colors.green : Colors.red,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              isOutgoing ? 'Outgoing Call' : 'Incoming Call',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                fontFamily: 'Poppins Regular',
                                color: isOutgoing ? Colors.green[800] : Colors.red[800],
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        isOutgoing
                                            ? Icons.call_made
                                            : (isMissed ? Icons.call_missed : Icons.call_received),
                                        color: isOutgoing
                                            ? Colors.green
                                            : (isMissed ? Colors.red : Colors.blue),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isOutgoing
                                            ? 'Outgoing'
                                            : (isMissed ? 'Missed' : 'Received'),
                                        style: TextStyle(
                                          color: isOutgoing
                                              ? Colors.green
                                              : (isMissed ? Colors.red : Colors.blue),
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Poppins Regular',
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${log.duration}s',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12.5,fontFamily: 'Poppins Regular',),
                                  ),
                                  Text(
                                    log.createdAt,
                                    style: const TextStyle(color: Colors.grey, fontSize: 12.5,fontFamily: 'Poppins Regular',),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
            } else if (state is CallLogError) {
              return Center(child: Text(state.message));
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }
}