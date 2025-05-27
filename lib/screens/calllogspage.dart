import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/call_log_his_cubit/call_log_cubit.dart';
import '../responses/allusers_response.dart';

class CallLogPage extends StatefulWidget {
  const CallLogPage({super.key,required this.allUsers});
  final List<User> allUsers;

  @override
  State<CallLogPage> createState() => _CallLogPageState();
}

class _CallLogPageState extends State<CallLogPage> {

  @override
  void initState() {
    // TODO: implement initState
    context.read<CallLogCubit>().fetchCallLogs(allUsers: widget.allUsers);
    super.initState();
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
            if (state is CallLogLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is CallLogLoaded) {
              return (state.callLogs.isEmpty)?Center(
                child: Text("No Record Found"),
              ):ListView.builder(
                itemCount: state.callLogs.length,
                itemBuilder: (context, index) {
                  final log = state.callLogs[index];
                  print("sdclskcmsd ${log.status}");
                  final isMissed = log.status.toLowerCase() == 'missed';
                  final isVideo = log.callType.toLowerCase() == 'video';

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: isVideo ? Colors.blue.shade100 : Colors.green.shade100,
                        child: Icon(
                          isVideo ? Icons.videocam : Icons.call,
                          color: isVideo ? Colors.blue : Colors.green,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        '${log.callType[0].toUpperCase()}${log.callType.substring(1)} Call',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: Colors.black87,
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
                                  isMissed ? Icons.call_missed : Icons.call_made,
                                  color: isMissed ? Colors.red : Colors.green,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  log.status,
                                  style: TextStyle(
                                    color: isMissed ? Colors.red : Colors.green,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${log.duration}s',
                              style: const TextStyle(color: Colors.grey, fontSize: 12.5),
                            ),
                            Text(
                              log.createdAt,
                              style: const TextStyle(color: Colors.grey, fontSize: 12.5),
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
