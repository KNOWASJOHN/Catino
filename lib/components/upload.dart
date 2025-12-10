import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';

class Upload extends StatelessWidget {
  const Upload({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 100, 0, 0),
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: 300,
        height: 120,
        child: DottedBorder(
          color: Colors.black45,
          strokeWidth: 1,
          dashPattern: [7, 7],
          borderType: BorderType.RRect,
          radius: Radius.circular(12),

          child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.upload_file,
                    size: 30,
                    color: Colors.limeAccent.shade700,

                  ),
                  SizedBox(height: 4),
                  Text(
                    'Upload Your Document',
                    style: TextStyle(
                      fontFamily: 'Unbounded',
                      fontWeight: FontWeight.w300,
                      fontSize: 8,
                      color: Colors.black.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}
