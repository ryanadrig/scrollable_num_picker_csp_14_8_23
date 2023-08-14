import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

late Size ss;

// day max state provider
final dmsp = StateProvider<int>((ref) {
  return 31;
});

// selected day state provider
final sdsp = StateProvider<DateTime>((ref) {
  return DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
});

// year scroll physics state provider
final yspsp = StateProvider<ScrollPhysics>((ref) {
  return const PageScrollPhysics();
});

// year scroll physics lock (revert back to pagephysics after delay and avoid infinite loop)
final ysplock = StateProvider<bool>((ref) {
  return false;
});

class YearScrollPhysics extends PageScrollPhysics {
  static final SpringDescription customSpring =
  SpringDescription.withDampingRatio(mass: 10, stiffness: 1);

  @override
  YearScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return YearScrollPhysics();
  }

  @override
  SpringDescription get spring => customSpring;
}

YearScrollPhysics yearScrollPhysics = YearScrollPhysics();

class DatePickScrollRow extends ConsumerWidget {
  DatePickScrollRow({
    Key? key,
  }) : super(key: key);

  final DateTime now = DateTime.now();

  final CarouselController dcc = CarouselController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    ss = MediaQuery.of(context).size;

    DateTime sd = ref.watch(sdsp);
    int dayMax = ref.watch(dmsp);

    //callback set from page e.g. 0-11 datetime set 1-12
    daySetCB(int day) {
      // print("day change ~ " + day.toString());
      ref.read(sdsp.notifier).state = DateTime(sd.year, sd.month, day + 1);
    }

    //callback set from page e.g. 0-11 datetime set 1-12
    monthSetCB(int month) {
      // print("month change ~ " + month.toString());
      ref.read(sdsp.notifier).state = DateTime(sd.year, month + 1, sd.day);
      // change max days for selected month / year
      DateTime lastDayOfMonth = DateTime(sd.year, month + 2, 0);
      if (dayMax > lastDayOfMonth.day || dayMax < lastDayOfMonth.day) {
        ref.read(dmsp.notifier).state = lastDayOfMonth.day;
      }
    }

    //callback set from page e.g. 0-11 datetime set 1-12
    yearSetCB(int year) {
      // print("yearchange ~ " + year.toString());
      // print("new year ~ " + (1900 + year).toString());
      ref.read(sdsp.notifier).state = DateTime(1900 + year, sd.month, sd.day);
      // change max days for selected month / year
      DateTime lastDayOfMonth = DateTime(sd.year, sd.month + 1, 0);
      if (dayMax > lastDayOfMonth.day || dayMax < lastDayOfMonth.day) {
        ref.read(dmsp.notifier).state = lastDayOfMonth.day;
      }
    }

    List<Widget> dayItems = [];
    List<Widget> monthItems = [];
    List<Widget> yearItems = [];

    for (int mi = 1; mi <= 12; mi++) {
      monthItems.add(ScrollTimeItem(
        idx: mi,
        dateItemType: DateItemType.month,
      ));
    }

    for (int di = 1; di <= dayMax; di++) {
      dayItems.add(ScrollTimeItem(idx: di, dateItemType: DateItemType.day));
    }
    for (int dip = 1; dip <= (31 - dayMax); dip++) {
      dayItems.add(ScrollTimeItem(idx: -dip, dateItemType: DateItemType.day));
    }

    for (int yi = 1900; yi <= now.year; yi++) {
      yearItems.add(ScrollTimeItem(idx: yi, dateItemType: DateItemType.year));
    }

    ysp_switcher() {
      print("ysp switcher called");
      Future.delayed(const Duration(milliseconds: 400), () {
        print("reset psp");
        ref
            .read(yspsp.notifier)
            .state = const PageScrollPhysics();
      });
      if (ref.watch(yspsp) is YearScrollPhysics == false &&
          ref.watch(ysplock) == false) {
        print("set ysp");
        ref
            .read(yspsp.notifier)
            .state = yearScrollPhysics;
        ref
            .read(ysplock.notifier)
            .state = true;
        Future.delayed(const Duration(milliseconds: 300), () {
          print("reset lock");
          ref
              .read(ysplock.notifier)
              .state = false;
        });
      }
    }

    return Expanded(child:Container(
          color: Colors.white,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            Expanded(
                child: ThreeRowScrollItem(
                  items: dayItems,
                  setCB: daySetCB,
                )),
            Container(width: ss.width*.01),
            Expanded(
                child: ThreeRowScrollItem(
                  items: monthItems,
                  setCB: monthSetCB,
                )
            ),
            Container(width: ss.width*.01),
            Expanded(
                child: ThreeRowScrollItem(
                  items: yearItems,
                  setCB: yearSetCB,
                  scrollCB:ysp_switcher
                ))
          ]),
        ));
  }
}

class ThreeRowScrollItem extends ConsumerWidget {
   ThreeRowScrollItem({super.key,
    this.scrollCB,
    required this.items,
  required this.setCB,});

  final List<Widget> items;
  final Function setCB;
  Function? scrollCB;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DateTime sd = ref.watch(sdsp);

    return CarouselSlider(
        items: items,
        options: CarouselOptions(
          aspectRatio: .66,
          viewportFraction: 0.2,
          initialPage: sd.year - 1900,
          enableInfiniteScroll: true,
          autoPlay: false,
          enlargeCenterPage: true,
          enlargeFactor: 0.3,
          onPageChanged: (int page, cpcr) {
            setCB(page);
          },
          onScrolled: (s) {
            if (scrollCB!=null) {
              scrollCB!();
            }
          },
          scrollPhysics: ref.watch(yspsp),
          // scrollPhysics: PageScrollPhysics(),
          scrollDirection: Axis.vertical,
        ));
  }
}



enum DateItemType { day, month, year }

class ScrollTimeItem extends ConsumerWidget {
  const ScrollTimeItem(
      {Key? key, required this.idx, required this.dateItemType})
      : super(key: key);

  final int idx;
  final DateItemType dateItemType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color selectedColor = Colors.white;
    Color selectedTextColor = Colors.deepPurple;

    DateTime sd = ref.watch(sdsp);
    DateTime bndt = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    if (sd != bndt) {
      if (dateItemType == DateItemType.day && sd.day == idx) {
        selectedColor = Colors.deepPurple;
        selectedTextColor = Colors.white;
      } else if (dateItemType == DateItemType.year && sd.year == idx) {
        selectedColor = Colors.deepPurple;
        selectedTextColor = Colors.white;
      } else if (dateItemType == DateItemType.month && sd.month == idx) {
        selectedColor = Colors.deepPurple;
        selectedTextColor = Colors.white;
      }
    }

    return Container(
      // width:  .2.sw,
      height: .06 * ss.width,
      color: selectedColor,
      child: idx > 0
          ? Center(
          child: Text(
            idx.toString(),
            style: TextStyle(fontSize: .05 * ss.width, color: selectedTextColor),
          ))
          : const Text(""),
    );
  }
}

