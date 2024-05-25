import 'package:flutter/material.dart';

class GetStartedButton extends StatefulWidget {
  final Function onTap;
  final Function onAnimatinoEnd;
  final double elementsOpacity;
  final String TEXT;
  const GetStartedButton(
      {super.key,
      required this.onTap,
      required this.onAnimatinoEnd,
      required this.TEXT,
      required this.elementsOpacity});

  @override
  State<GetStartedButton> createState() => _GetStartedButtonState();
}

class _GetStartedButtonState extends State<GetStartedButton> {
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300),
      tween: Tween(begin: 1, end: widget.elementsOpacity),
      onEnd: () async {
        widget.onAnimatinoEnd();
      },
      builder: (_, value, __) => GestureDetector(
        onTap: () {
          widget.onTap();
        },
        child: Opacity(
          opacity: value,
          child: Container(
            width: 230,
            height: 75,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10), color: Colors.white),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.TEXT,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontSize: 19),
                ),
                SizedBox(width: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
