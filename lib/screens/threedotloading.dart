// import 'package:flutter/material.dart';

// class ThreeDotLoading extends StatefulWidget {
//   final Color color;
  
//   const ThreeDotLoading({
//     super.key,
//     this.color = Colors.grey,
//   });

//   @override
//   State<ThreeDotLoading> createState() => _ThreeDotLoadingState();
// }

// class _ThreeDotLoadingState extends State<ThreeDotLoading> 
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late List<Animation<double>> _animations;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 800),
//     )..repeat();
    
//     _animations = List.generate(3, (index) {
//       final start = index * 0.2;
//       return Tween<double>(begin: 0.4, end: 1.0).animate(
//         CurvedAnimation(
//           parent: _controller,
//           curve: Interval(start, start + 0.6, curve: Curves.easeInOut),
//         ),
//       );
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: List.generate(3, (index) {
//         return AnimatedBuilder(
//           animation: _animations[index],
//           builder: (context, child) {
//             return Opacity(
//               opacity: _animations[index].value,
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 4),
//                 child: Container(
//                   width: 12,
//                   height: 12,
//                   decoration: BoxDecoration(
//                     color: widget.color,
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//               ),
//             );
//           },
//         );
//       }),
//     );
//   }
// }