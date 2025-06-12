import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SplashView extends StatefulWidget {
  final AnimationController animationController;

  const SplashView({super.key, required this.animationController});

  @override
  _SplashViewState createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  Widget build(BuildContext context) {
    final size=MediaQuery.of(context).size;
    final introductionanimation =
        Tween<Offset>(begin: Offset(0, 0), end: Offset(0.0, -1.0))
            .animate(CurvedAnimation(
      parent: widget.animationController,
      curve: Interval(
        0.0,
        0.2,
        curve: Curves.fastOutSlowIn,
      ),
    ));
    return Container(
      color: Colors.white,
      child: SlideTransition(
        position: introductionanimation,
        child: ListView(
          children: [
            SizedBox(
              height: 158,
            ),
            SizedBox(
              width:size.width,
              height: 300,
              child: SvgPicture.asset(
                'assets/svgs/study.svg',
                fit: BoxFit.fill,
              ),
            ),
            // Spacer(),

            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Center(
                child: Text(
                  "Welcome to Picturo",
                  style: TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 64, right: 64),
              child: Text(
                "Learn grammar rules through engaging visuals and examples. Make learning easier, faster, and more memorable. Visual stories turn complex rules into simple understanding.",
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              height: 48,
            ),
            Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                  left: 56,
                  right:56,
              ),
              child: InkWell(
                onTap: () {
                  widget.animationController.animateTo(0.2);
                },
                child: SizedBox(
                  height: 58,
                  child: Container(
                    clipBehavior: Clip.hardEdge,
                    constraints: BoxConstraints(
                      maxWidth: 200
                    ),
                    height: 58,
                    // width: size.width*.5,
                    // padding: EdgeInsets.symmetric(horizontal: 50),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(38.0),
                      color: Color(0xff132137),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Let's begin",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 48,
            ),
          ],
        ),
      ),
    );
  }
}
