import 'package:flutter/material.dart';
import 'package:picturo_app/screens/loginscreen.dart';
import 'package:picturo_app/services/api_service.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  _DeleteAccountPageState createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isDeleting = false; // Flag to indicate deletion in progress.
  late ApiService _apiService;


  @override
  void initState() {
    super.initState();
    // Initialize ApiService in initState
    ApiService.create().then((service) {
      _apiService = service;
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Confirm Delete',
              style: TextStyle(fontFamily: 'Poppins Regular')),
          content: Text('Are you sure you want to delete your account?',
              style: TextStyle(fontFamily: 'Poppins Regular')),
          actions: <Widget>[
            TextButton(
              child: Text('No',
                  style: TextStyle(fontFamily: 'Poppins Regular')),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text('Yes',
                  style: TextStyle(fontFamily: 'Poppins Regular')),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _performDelete(); // Call the API function
              },
            ),
          ],
        );
      },
    );
  }

  void _performDelete() async {
    if (!mounted) return; // Check if the widget is still in the tree

    setState(() {
      _isDeleting = true;
    });

    try {
      final response = await _apiService.deleteAccount(); // Call your API function
      if (!mounted) return;
      if (response['success'] == true) {
        // Show success dialog or navigate
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text('Account Deleted',
                  style: TextStyle(fontFamily: 'Poppins Regular')),
              content: Text('Your account has been deleted successfully.',
                  style: TextStyle(fontFamily: 'Poppins Regular')),
              actions: <Widget>[
                TextButton(
                  child: Text('OK',
                      style: TextStyle(fontFamily: 'Poppins Regular')),
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Navigate to login or home.  Important: use pushReplacement
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) =>
                            LoginScreen(), // Replace with your home page
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      } else {
         if (!mounted) return;
        // Show error
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text('Error',
                  style: TextStyle(fontFamily: 'Poppins Regular')),
              content: Text(response['error'] ?? 'Failed to delete account.',
                  style: TextStyle(fontFamily: 'Poppins Regular')),
              actions: <Widget>[
                TextButton(
                  child: Text('OK',
                      style: TextStyle(fontFamily: 'Poppins Regular')),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
       if (!mounted) return;
      // Handle API error
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text('Error',
                style: TextStyle(fontFamily: 'Poppins Regular')),
            content: Text('Failed to delete account. Please try again. $e', //show the error
                style: TextStyle(fontFamily: 'Poppins Regular')),
            actions: <Widget>[
              TextButton(
                child: Text('OK',
                    style: TextStyle(fontFamily: 'Poppins Regular')),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } finally {
       if (!mounted) return;
      setState(() {
        _isDeleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Color(0xFF49329A),
          leading: Padding(
            padding: const EdgeInsets.only(top: 15.0, left: 24.0),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 26),
              onPressed: () {
                Navigator.pop(context); // Navigate back
              },
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 15.0),
            child: Row(
              children: [
                Text(
                  'Delete Account',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Are you sure you want to delete your account?',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins Regular'),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              'Please provide a reason for deleting your account (optional):',
              style: TextStyle(fontSize: 16, fontFamily: 'Poppins Regular'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _reasonController,
              maxLines: 4,
              style: TextStyle(fontFamily: 'Poppins Regular'),
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter your reason here...',
                hintStyle: TextStyle(fontFamily: 'Poppins Regular'),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isDeleting ? null : _deleteAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF49329A),
                foregroundColor: Colors.white,
              ),
              child: _isDeleting
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Delete Account',
                      style: TextStyle(
                        fontFamily: 'Poppins Regular',
                      ),
                    ),
            ),
            SizedBox(height: 20),
            Text(
              "Warning: This action is irreversible. All of your data will be permanently deleted.",
              style: TextStyle(
                  color: Colors.red, fontSize: 12, fontFamily: 'Poppins Regular'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}