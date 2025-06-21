import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../cubits/games_cubits/quest_game/quest_game_qtn_list_cubit.dart';
import '../cubits/get_coins_cubit/coins_cubit.dart';
import '../utils/common_app_bar.dart';
import '../utils/common_file.dart';
class GrammarQuestScreen extends StatefulWidget {
  final String? title;
  final int questId;
  final int level;
  final int index;
  final List<GrammarQuestion> questions;
  const GrammarQuestScreen({super.key, this.title,required this.questId,required  this.level,required this.index,required this.questions});

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
  bool loading=false;

  late AudioPlayer _bgPlayer;
  bool showCountdown = true;
  int countdown = 3;

@override
  void initState() {
    // TODO: implement initState
  context.read<CoinCubit>().useCoin(1);
  _bgPlayer = AudioPlayer();
  _startCountdown();
  super.initState();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      if (countdown > 1) {
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          countdown--;
        });
        return true;
      } else {
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          showCountdown = false;
        });
        _playBackgroundMusic();
        return false;
      }
    });
  }
  void _playBackgroundMusic() async {
  if(!pauseMusic){
    await _bgPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgPlayer.play(AssetSource('audio/quest_gm_bg.mp3'));
  }

  }
  void _stopAllSounds() {
    _bgPlayer.stop();

  }
  @override
  void dispose() {
    // TODO: implement dispose
    _stopAllSounds();
    super.dispose();
  }
  bool pauseMusic=false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEEEFFF),
      appBar: CommonAppBar(title:"Picture Grammar Quest" ,isBackbutton: true,  actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: InkWell(
              onTap: (){
                if(pauseMusic==false){
                  _bgPlayer.pause();
                }else{
                  _bgPlayer.play(AssetSource('audio/quest_gm_bg.mp3'));

                }
                setState(() {
                  pauseMusic=!pauseMusic;
                });

              },
              child: Icon((!pauseMusic)?Icons.volume_up_outlined:Icons.volume_off,color: Colors.white,)),
        )
      ],),
      body: Stack(
        children: [
          SingleChildScrollView(
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
                      "${widget.title}",
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
                        child:(loading)?SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 0.8,color: Colors.white,),
                        ): Text(
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
          if (showCountdown)
            Positioned(
              child: Container(
                height: double.infinity,
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Text(
                    "$countdown",
                    style: TextStyle(
                      fontSize: 100,
                      color: Colors.white,
                      fontFamily: AppConstants.commonFont,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
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

  void _showCongratulationsPopup() {

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Congratulations!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF5E3FA0)), textAlign: TextAlign.center),
          content: const Text("You matched all correctly.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if((widget.questions.length==widget.level)){

                }else{
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GrammarQuestScreen(questions: widget.questions,index: widget.index+1,level:widget.level+1,questId: widget.questId+1,title: widget.questions[widget.index+1].gameQus),
                    ),
                  );
                }

              },
              child:(widget.questions.length==widget.level)? const Text("Finish", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)): const Text("Next Level", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
  void checkValues() async {
    setState(() {
      loading=true;
    });

    final url = Uri.parse("http://picturoenglish.com/api/sentancecheck.php");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Replace with actual token
      },
      body: jsonEncode({
        "sentence_id":widget.questId,
        "verb": word1Controller.text.trim(),
        "adverb": word2Controller.text.trim(),
        "adjective": word3Controller.text.trim(),
      }),
    );


    if (response.statusCode == 200) {

      final data = json.decode(response.body);
      final result = data['result'];

      setState(() {
        word1Color = result['verb'] == 'Correct' ? Color(0xFF00C02D) : Color(0xFFC01515);
        word2Color = result['adverb'] == 'Correct' ? Color(0xFF00C02D) : Color(0xFFC01515);
        word3Color = result['adjective'] == 'Correct' ? Color(0xFF00C02D) : Color(0xFFC01515);
        if( result['verb'] == 'Correct'&&result['adverb'] == 'Correct'&&result['adjective'] == 'Correct'){
          context.read<GrammarQuestCubit>().fetchGrammarQuestions(levelFrom:widget.level+1);
          _showCongratulationsPopup();
        }

        word1TextColor = result['verb'] == 'Correct' ? Colors.white : Colors.black;
        word2TextColor = result['adverb'] == 'Correct' ? Colors.white : Colors.black;
        word3TextColor = result['adjective'] == 'Correct' ? Colors.white : Colors.black;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking sentence.')),
      );
    }
    setState(() {
      loading=false;
    });
  }
}