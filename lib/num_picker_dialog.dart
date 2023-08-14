import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'num_pick_widget.dart';

class DatePickerDialogContent extends ConsumerStatefulWidget {
  const DatePickerDialogContent({super.key, required this.setDateCB});
  final Function setDateCB;
  @override
  DatePickerDialogContentState createState() => DatePickerDialogContentState();
}

class DatePickerDialogContentState
    extends ConsumerState<DatePickerDialogContent> {
  @override
  Widget build(BuildContext context) {
    return
    Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children:[
      ListView(
      shrinkWrap: true,
        children: [
        const SizedBox(height: 25),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DatePickScrollRow()
          ],
        ),
        MaterialButton(
            onPressed: () {
              widget.setDateCB(ref.watch(sdsp));
              Navigator.pop(context);
            },
            color: Colors.deepPurple,
            child: Text(
              "Ok",
              style: TextStyle(color: Colors.white),
            )),
      ],
    )]);
  }
}