import 'package:flutter/material.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:provider/provider.dart';

import '../providers/profileprovider.dart';

class BlockedUsersScreen extends StatefulWidget {
  BlockedUsersScreen({super.key, required this.user});

  final ProfileProvider user;

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  late ApiService _apiService;
  bool _isLoading = true;

  List blockedUsers = [];
  List filteredUsers = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    _initializeApiService();
    super.initState();
  }

  Future<void> _initializeApiService() async {
    try {
      _apiService = await ApiService.create();
      await getBlockedUsers();
    } catch (e) {
      print("Error initializing API service: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> getBlockedUsers() async {
    if (widget.user.userId != null) {
      blockedUsers = await _apiService.getBlockedUsers(widget.user.userId!);
      filteredUsers = blockedUsers;
    }
  }

  void _filterUsers(String query) {
    setState(() {
      filteredUsers = blockedUsers.where((user) {
        final username = user['username']?.toLowerCase() ?? '';
        return username.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE0F7FF),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Color(0xFF49329A),
          leading: Padding(
            padding: const EdgeInsets.only(top: 15.0, left: 24.0),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 26),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 15.0),
            child: Row(
              children: [
                Text(
                  'Blocked users',
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F7FF), Color(0xFFEAE4FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24, 15, 24, 15),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Color(0xFF49329A),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterUsers,
                  decoration: InputDecoration(
                    icon: Icon(Icons.search, color: Color(0xFF49329A)),
                    hintText: 'Search',
                    hintStyle:
                    TextStyle(fontFamily: 'Poppins Regular'),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            filteredUsers.isEmpty
                ? Expanded(
              child: Center(
                child: Text("No Blocked Users Found"),
              ),
            )
                : Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 24, right: 24),
                child: ListView.separated(
                  separatorBuilder: (context, index) =>
                      SizedBox(height: 10),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                          AssetImage('assets/avatar_1.png'),
                          radius: 25,
                        ),
                        title: Text(
                          user["username"],
                          style: TextStyle(
                              fontFamily: 'Poppins Regular'),
                        ),
                        subtitle: Text(
                          'Blocked',
                          style: TextStyle(
                              fontFamily: 'Poppins Regular'),
                        ),
                        trailing: TextButton(
                          onPressed: () async {
                            setState(() {
                              _isLoading = true;
                            });
                            await _apiService.unblockUser(
                                user["user_id"]);
                            _searchController.clear();
                            blockedUsers.clear();
                            filteredUsers.clear();
                            // await getBlockedUsers();
                            await _initializeApiService();

                            setState(() {
                              _isLoading = false;
                            });
                          },
                          child: Text(
                            'Unblock',
                            style: TextStyle(
                              fontFamily: 'Poppins Regular',
                              color: Color(0xFF464646),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
