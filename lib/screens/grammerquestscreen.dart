import 'package:flutter/material.dart';

class GrammarQuestScreen extends StatefulWidget {
  final String? title;
  const GrammarQuestScreen({super.key, this.title});

  @override
  _GrammarQuestScreenState createState() => _GrammarQuestScreenState();
}

class _GrammarQuestScreenState extends State<GrammarQuestScreen> {
  TextEditingController verbController = TextEditingController(text: "Verb");
  TextEditingController adverbController = TextEditingController(text: 'Adverb');
  TextEditingController adjectiveController = TextEditingController(text: 'Adjective');

  TextEditingController word1Controller = TextEditingController();
  TextEditingController word2Controller = TextEditingController();
  TextEditingController word3Controller = TextEditingController();

  Color word1Color = Colors.white;
  Color word2Color = Colors.white;
  Color word3Color = Colors.white;

  Color word1TextColor = Colors.black; // Default text color
  Color word2TextColor = Colors.black; // Default text color
  Color word3TextColor = Colors.black; // Default text color

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEEEFFF),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80), // Increased app bar height
        child: AppBar(
          backgroundColor: Color(0xFF49329A),
          leading: Padding(
            padding: const EdgeInsets.only(top: 15.0, left: 24.0), // Adjust top padding
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 26),
              onPressed: () {},
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 15.0), // Adjust top padding
            child: Row(
              children: [
                Text(
                  'Picture Grammar Quest',
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
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEEEFFF), Color(0xFFFFF0D3), Color(0xFFE7F8FF), Color(0xFFEEEFFF)], // Set your gradient colors here
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    "https://encrypted-tbn1.gstatic.com/images?q=tbn:ANd9GcQi0s-XNjBDXwkLqd6wZJsHXQHi70I-C6swaM8Bix5Gs_ZVcEXB",
                    height: MediaQuery.of(context).size.width * 0.65, // Responsive height
                    width: MediaQuery.of(context).size.width * 0.65, // Responsive width
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: 30),
                Text(
                  "He ran quickly through the dark alley.",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins Regular'),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                Column(
                  children: [
                    buildTextFieldRow(
                        "Verb", verbController, word1Controller, "ran", word1Color, word1TextColor),
                    SizedBox(height: 10),
                    buildTextFieldRow("Adverb", adverbController, word2Controller,
                        "quickly", word2Color, word2TextColor),
                    SizedBox(height: 10),
                    buildTextFieldRow("Adjective", adjectiveController,
                        word3Controller, "Alley", word3Color, word3TextColor),
                  ],
                ),
                SizedBox(height: 50),
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        checkValues();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF49329A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                    ),
                    child: Text(
                      "Submit",
                      style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Poppins Regular', fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextFieldRow(
      String label,
      TextEditingController leftController,
      TextEditingController rightController,
      String correctValue,
      Color fillColor,
      Color textColor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              readOnly: leftController == verbController ||
                  leftController == adverbController ||
                  leftController == adjectiveController,
              controller: leftController,
              decoration: InputDecoration(
                hintText: label,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8), // Border radius for the focused state
                  borderSide: BorderSide(color: Color(0xFF49329A)), // Border color
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8), // Border radius for the enabled state
                  borderSide: BorderSide(color: Color(0xFF49329A)), // Border color when enabled
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8), // Border radius for the focused state
                  borderSide: BorderSide(color: Color(0xFF49329A)), // Border color when focused
                ),
                filled: true,
                fillColor: Color(0xFFE3F1FF),
              ),
              style: TextStyle(fontFamily: 'Poppins Regular', color: Color(0xFF49329A), fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 10),
          Text("→",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins Regular')),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: rightController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8), // Border radius for the focused state
                  borderSide: BorderSide(color: Color(0xFFC1C1C1)), // Border color
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8), // Border radius for the enabled state
                  borderSide: BorderSide(color: Color(0xFFC1C1C1)), // Border color when enabled
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8), // Border radius for the focused state
                  borderSide: BorderSide(color: Color(0xFFC1C1C1)), // Border color when focused
                ),
                filled: true,
                fillColor: fillColor,
              ),
              style: TextStyle(fontFamily: 'Poppins Regular', color: textColor), // Dynamic text color
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void checkValues() {
    setState(() {
      if (word1Controller.text == "ran" &&
          word2Controller.text == "quickly" &&
          word3Controller.text == "Alley") {
        word1Color = Colors.green[200]!;
        word2Color = Colors.green[200]!;
        word3Color = Colors.green[200]!;
        word1TextColor = Colors.white; // Change text color to white
        word2TextColor = Colors.white; // Change text color to white
        word3TextColor = Colors.white; // Change text color to white
      } else {
        word1Color = word1Controller.text == "ran"
            ? Color(0xFF00C02D)
            : Color(0xFFC01515);
        word2Color = word2Controller.text == "quickly"
            ? Color(0xFF00C02D)
            : Color(0xFFC01515);
        word3Color = word3Controller.text == "Alley"
            ? Color(0xFF00C02D)
            : Color(0xFFC01515);
        word1TextColor = word1Controller.text == "ran" ? Colors.white : Colors.black; // Change text color dynamically
        word2TextColor = word2Controller.text == "quickly" ? Colors.white : Colors.black; // Change text color dynamically
        word3TextColor = word3Controller.text == "Alley" ? Colors.white : Colors.black; // Change text color dynamically
      }
    });
  }
}