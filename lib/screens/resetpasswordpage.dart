import 'package:flutter/material.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Color(0xFFFFFFFF),
        centerTitle: true,
        title: const Text('Change password',style: TextStyle(fontFamily: 'Poppins Regular', color: Color(0xFF49329A),fontWeight: FontWeight.bold)),
        toolbarHeight: 100,
      ),
      body: 
      Column(
        children: [
          SizedBox(height: 30,),
          Padding(
              padding: const EdgeInsets.only(left: 24, right: 24),
              child: TextFormField(
                decoration: InputDecoration(
                   enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Color(0xFFC3C3C3),width: 1)
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Color(0xFF49329A),width: 1.2)
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(
                        left: 20,
                        top: 5,
                        bottom: 5,
                        right: 10), // Adjust spacing
                    child: Image.asset(
                      'assets/solar_lock-linear.png',
                      width: 22, // Set width & height
                      height: 22,
                    ),
                  ),
                  hintText: "Current password",
                   hintStyle: TextStyle(fontFamily: 'Poppins Regular', color: Color(0xFF464646), fontSize: 15),
                  suffixIcon: IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.visibility)),
                ),
              )),
          SizedBox(
            height: 20,
          ),
          Padding(
              padding: const EdgeInsets.only(left: 24, right: 24),
              child: TextFormField(
                decoration: InputDecoration(
                   enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Color(0xFFC3C3C3),width: 1)
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Color(0xFF49329A),width: 1.2)
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(
                        left: 20,
                        top: 5,
                        bottom: 5,
                        right: 10), // Adjust spacing
                    child: Image.asset(
                      'assets/solar_lock-linear.png',
                      width: 22, // Set width & height
                      height: 22,
                    ),
                  ),
                  hintText: "New password",
                   hintStyle: TextStyle(fontFamily: 'Poppins Regular', color: Color(0xFF464646), fontSize: 15),
                  suffixIcon: IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.visibility)),

                ),
              )),
          SizedBox(
            height: 20,
          ),
          Padding(
              padding: const EdgeInsets.only(left: 24, right: 24),
              child: TextFormField(
                decoration: InputDecoration(
                   enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Color(0xFFC3C3C3),width: 1)
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Color(0xFF49329A),width: 1.2)
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(
                        left: 20,
                        top: 5,
                        bottom: 5,
                        right: 10), // Adjust spacing
                    child: Image.asset(
                      'assets/solar_lock-linear.png',
                      width: 22, // Set width & height
                      height: 22,
                    ),
                  ),
                  hintText: "Confirm password",
                  hintStyle: TextStyle(fontFamily: 'Poppins Regular', color: Color(0xFF464646), fontSize: 15),
                  suffixIcon: IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.visibility)),
                ),
              )),
              SizedBox(height: 05,),
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Align(
              alignment: AlignmentDirectional.bottomEnd,
              child:
             TextButton(
                onPressed: () {},
                child: Text(
                  "Forget password?",
                  style: TextStyle(color: Color(0xFF727272),fontFamily: 'Poppins Regular',fontSize: 14),
                )),),
           
          ),
          SizedBox(height: 30),
           Padding(
            padding: const EdgeInsets.only(left: 24, right: 24),
         child: SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF49329A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    )),
                onPressed: () {},
                child: Text(
                  "Change",
                  style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 17,fontFamily: 'Poppins Regular',fontWeight: FontWeight.bold),
                ),
              ))
           ),
        ],
      ),
    );
  }
}
