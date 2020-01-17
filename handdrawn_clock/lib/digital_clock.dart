// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_suncalc/flutter_suncalc.dart';

/// Clock Utilty Class
/// Currently defaults to London in absence of real data

class DigitalClockUtils {
  // Data For London. Absence of access to locaiton data in example API.
  static var longitude = -0.1;
  static var latitude = 51.5;
  static var lastTZ = "";

  /// Util to recalc locaiton for time/sun calcs
  /// Currently an emulation base don timezones.
  /// Should be replaced with geo-location or ref table of long+lat
  static reCalcLocationCoords() {
    var date = DateTime.now();
    if (lastTZ == date.timeZoneName) {
      return; // Don't recalc.
    }

    // --- Calculate longitude based upon timezone (UTC Diff)
    // just for emulation tests
    // cannot calculate latitude, so hard coded to London.
    // (ideally would be replaced with GPS)

    int timeZNDiff = date.timeZoneOffset.inHours;
    lastTZ = date.timeZoneName;

    if ((lastTZ.toUpperCase() == "BST" ||
            lastTZ.toUpperCase() == "BDT" ||
            lastTZ.toUpperCase() == "BST") &&
        timeZNDiff < 2) // Must be UK DST
    {
      timeZNDiff =
          -1; //Adjust because location has not changed just articial time zone.

    }

    longitude = (timeZNDiff * 15).ceilToDouble();
  }

  ///Generates a text description of the next sun event.
  static String getNextSunEventText(bool is24hr) {
    var date = DateTime.now();
    reCalcLocationCoords();
    // get today's sunlight times for London
    var times = SunCalc.getTimes(date, latitude, longitude);

    if (times["sunrise"].compareTo(date) < 0) //Sunrise has gone
    {
      if (times["sunset"].compareTo(date) < 0) //Sunset has gone
      {
        var timesTom = SunCalc.getTimes(
            date.add(new Duration(days: 1)), latitude, longitude);
        return "Sunrise @ " +
            DateFormat(is24hr ? 'HH' : 'hh').format(timesTom["sunrise"]) +
            ":" +
            DateFormat("mm").format(timesTom["sunrise"]);
      } else {
        return "Sunset @ " +
            DateFormat(is24hr ? 'HH' : 'hh').format(times["sunset"]) +
            ":" +
            DateFormat("mm").format(times["sunset"]);
      }
    } else {
      return "Sunrise @ " +
          DateFormat(is24hr ? 'HH' : 'hh').format(times["sunrise"]) +
          ":" +
          DateFormat("mm").format(times["sunrise"]);
    }
  }

  /// Generates a flag indicating the next sun event
  /// -1 = Sunrise today
  /// 0 = Sunset today
  /// 1 = Sunrise tomorrow.
  static int getNextSunEvent() {
    var date = DateTime.now();
    reCalcLocationCoords();

    // get today's sunlight times for London
    var times = SunCalc.getTimes(date, latitude, longitude);

    if (times["sunrise"].compareTo(date) < 0) //Sunrise has gone
    {
      if (times["sunset"].compareTo(date) < 0) //Sunset has gone
      {
        return 1;
      } else {
        return 0;
      }
    } else {
      return -1;
    }
  }
}

/// Theme Management Classes
///
/// Creates and array of themes. Should be easier to extend late if needed
class DigitalClockThemes {
  List<DigitalClockTheme> theme = [];

  DigitalClockThemes() {
    theme.add(new DigitalClockTheme(Brightness.light));
    theme.add(new DigitalClockTheme(Brightness.dark));
  }

  DigitalClockTheme getTheme(Brightness pBrightness) {
    for (DigitalClockTheme pTheme in theme) {
      if (pTheme.brightness == pBrightness) {
        return pTheme;
      }
    }
    return theme[0]; // Fall back return default.
  }
}

/// Theme Def Class and utils
class DigitalClockTheme {
  ///Defaults
  static double textOpacity = 0.65;
  static double imageOpacity = 0.65;
  static String cAssetPath = "assets/";
  Color background = Colors.white;
  Color timeText = Colors.black;
  Color dateText = Colors.black;
  Color weatherText = Colors.black;
  Color locationText = Colors.black;
  Color sunText = Colors.black;
  Brightness brightness = Brightness.light;

  String name = "";

  ///Image for Alarm(themed)
  String get alarmImageFileName {
    return cAssetPath + "alarm_" + name + ".png";
  }

  ///Image for Background(themed)
  String get backgroundImageFileName {
    return cAssetPath + "back_" + name + ".png";
  }

  ///Image for Location Icon(themed)
  String get locationImageFileName {
    return cAssetPath + "location_" + name + ".png";
  }

  ///Image for Temperature Icon(themed)
  String get temperatureImageFileName {
    return cAssetPath + "temp_" + name + ".png";
  }

  ///Image for Sun Icon(themed)
  String get sunImageFileName {
    return cAssetPath + "sun_" + name + ".png";
  }

  ///Image for Moon Icon(themed)
  String get moonImageFileName {
    return cAssetPath + "moon_" + name + ".png";
  }

  ///Array mapping sun state throughout day
  /// 0=night, 1 = sun, 2 =day
  var sunMap = [
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1
  ];

  /// 0=night, 1 = sun, 2 =day
  var currHr = -1;

  /// Return the themed image for a specific block if the sun chart based on Sun State
  String getSunBlock(int row, int hour) {
    var date = DateTime.now();
    DigitalClockUtils.reCalcLocationCoords();

    /// --- Rebuild sun map of needed
    if (date.hour != currHr) // Refresh sun Map
    {
      ///find previous and next sun events

      var hrStart =
          date.subtract(new Duration(hours: 11)); // Start 11 hours back
      var times = SunCalc.getTimes(
          date, DigitalClockUtils.latitude, DigitalClockUtils.longitude);

      var event1IsSunrise = true;
      var event1 = times["sunrise"];
      var event2 = times["sunset"];

      if (event1.compareTo(hrStart) < 0) //Sunrise has gone
      {
        event1 = event2;
        event1IsSunrise = false;
        event2 = SunCalc.getTimes(date.add(new Duration(days: 1)),
            DigitalClockUtils.latitude, DigitalClockUtils.longitude)["sunrise"];
      }

      ///Rebuild sun map

      for (var hrStep = 0; hrStep <= 23; hrStep++) {
        var mapHr = hrStart.add(new Duration(hours: hrStep));

        // Estimate daylight
        if (mapHr.compareTo(event1) < 0) //Before first event
        {
          sunMap[hrStep] = (event1IsSunrise ? 0 : 2);
        } else if (mapHr.compareTo(event2) < 0) //Before second event
        {
          sunMap[hrStep] = (event1IsSunrise ? 2 : 0);
        } else if (mapHr.compareTo(event2) > 0) //After second event
        {
          sunMap[hrStep] = (event1IsSunrise ? 0 : 2);
        }

        //Mark Sunrise and Sunset
        if (mapHr.day == event1.day && mapHr.hour == event1.hour) //first event
        {
          sunMap[hrStep] = 1;
        }

        if (mapHr.day == event2.day && mapHr.hour == event2.hour) //second event
        {
          sunMap[hrStep] = 1;
        }
      }
    }

    currHr = date.hour;

    /// --- Select Image based on Sun Map

    var sunState = sunMap[hour - 1];

    if (sunState == 0 && row > 1) sunState = -1; // N/A
    if (sunState == 1 && row == 3) sunState = -1; // N/A

    var image = "block_1";

    if (sunState == -1) image = "block_blank";
    if (sunState == 1) image = "block_2";
    if (sunState == 2) image = "block_3";
    if (hour == 12) image = "block_4";

    if (sunState > -1) image = image + (name == "light" ? "l" : "d");

    image = "assets/" + image + ".png";

    return image;
  }

  /// Return the weather text (take into account night and day)
  String weatherConditionText(WeatherCondition wc) {
    if (wc == WeatherCondition.sunny) {
      var sunEvent = DigitalClockUtils.getNextSunEvent();
      if (sunEvent == -1) // -1 b4 Sunrise, 0 day,after sunset
      {
        return "Clear morning";
      }
      if (sunEvent == 1) // -1 b4 Sunrise, 0 day,after sunset
      {
        return "Clear night";
      }
      if (sunEvent == 0) // -1 b4 Sunrise, 0 day,after sunset
      {
        return "Sunny day";
      }

      return "Sunny day";
    }
    if (wc == WeatherCondition.cloudy) {
      return "Cloudy";
    }
    if (wc == WeatherCondition.foggy) {
      return "Foggy";
    }
    if (wc == WeatherCondition.rainy) {
      return "Rain";
    }
    if (wc == WeatherCondition.snowy) {
      return "Snow";
    }
    if (wc == WeatherCondition.thunderstorm) {
      return "Thunder";
    }

    if (wc == WeatherCondition.windy) {
      return "Breezy";
    }

    return "Unsettled";
  }

  /// Return the weather themed image (take into account night and day)
  String weatherImageFileName(WeatherCondition wc) {
    String weatherName = wc.toString().replaceAll("WeatherCondition.", "");

    if (wc == WeatherCondition.sunny) {
      var sunEvent = DigitalClockUtils.getNextSunEvent();
      weatherName = "sun";
      if (sunEvent == -1) // -1 b4 Sunrise, 0 day,after sunset
      {
        weatherName = "moon";
      }
      if (sunEvent == 1) // -1 b4 Sunrise, 0 day,after sunset
      {
        weatherName = "moon";
      }
      if (sunEvent == 0) // -1 b4 Sunrise, 0 day,after sunset
      {
        weatherName = "sun";
        ;
      }
    }

    ///Process Weather

    return cAssetPath + weatherName + "_" + name + ".png";
  }

  ///Constructor
  DigitalClockTheme(Brightness pBrightness) {
    brightness = pBrightness;

    if (pBrightness == Brightness.light) {
      background = Colors.white;
      timeText = Colors.black.withOpacity(1);
      dateText = Colors.blueAccent.withOpacity(1);
      locationText = Colors.green.withOpacity(textOpacity);
      sunText = Colors.deepOrange.withOpacity(textOpacity);
      weatherText = Colors.pinkAccent.withOpacity(textOpacity);
      name = "light";
    } else {
      background = Colors.black.withOpacity(1);
      timeText = Colors.white.withOpacity(1);
      dateText = Colors.grey.withOpacity(textOpacity);
      locationText = Colors.grey.withOpacity(textOpacity);
      sunText = Colors.grey.withOpacity(textOpacity);
      weatherText = Colors.grey.withOpacity(textOpacity);
      name = "dark";
    }
  }

  /// --Start-- Standardised Text Styles
  TextStyle dataTextStyle(screenWidth) {
    var fontSize = screenWidth / 24;
    return TextStyle(
      color: dateText,
      fontFamily: '2Dumb',
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
    );
  }

  TextStyle timeTextStyle(screenWidth) {
    var fontSize = screenWidth / 3.5;
    return TextStyle(
      color: timeText,
      fontFamily: '3Dumb',
      fontSize: fontSize,
      //  height: 800,
    );
  }

  TextStyle weatherTextStyle(screenWidth) {
    var fontSize = screenWidth / 24;
    return TextStyle(
      color: weatherText,
      fontFamily: '2Dumb',
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
    );
  }

  TextStyle locationTextStyle(screenWidth) {
    var fontSize = screenWidth / 30;
    return TextStyle(
      color: locationText,
      fontFamily: '2Dumb',
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
    );
  }

  TextStyle sunTextStyle(screenWidth) {
    var fontSize = screenWidth / 24;
    return TextStyle(
      color: sunText,
      fontFamily: '2Dumb',
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
    );
  }

  /// --End-- Standardised Text Styles
}

/// Clock Class
class DigitalClock extends StatefulWidget {
  const DigitalClock(this.model);

  final ClockModel model;

  @override
  _DigitalClockState createState() => _DigitalClockState();
}

/// Clock State and visuals Manager

class _DigitalClockState extends State<DigitalClock> {
  DigitalClockThemes themes = new DigitalClockThemes();
  DateTime _dateTime = DateTime.now();
  Timer _timer;

  /// Init
  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    _updateTime();
    _updateModel();
  }

  /// Event
  @override
  void didUpdateWidget(DigitalClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  ///CleanUp
  @override
  void dispose() {
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    widget.model.dispose();
    super.dispose();
  }

  /// Update
  void _updateModel() {
    setState(() {
      // Cause the clock to rebuild when the model changes.
    });
  }

  /// Timer Update
  void _updateTime() {
    setState(() {
      _dateTime = DateTime.now();
      // Update once per minute. If you want to update every second, use the
      // following code.
      _timer = Timer(
        Duration(minutes: 1) -
            Duration(seconds: _dateTime.second) -
            Duration(milliseconds: _dateTime.millisecond),
        _updateTime,
      );
      // Update once per second, but make sure to do it at the beginning of each
      // new second, so that the clock is accurate.
      // _timer = Timer(
      //   Duration(seconds: 1) - Duration(milliseconds: _dateTime.millisecond),
      //   _updateTime,
      // );
    });
  }

  /// Build Display
  @override
  Widget build(BuildContext context) {
    //clock.weatherCondition = WeatherCondition.
    // ----------- Themes and Globals ---------------------
    //Theme based on brightness
    final DigitalClockTheme theme =
        themes.getTheme(Theme.of(context).brightness);
    final scaleFactor = MediaQuery.of(context).size.width /
        800; //Display on Lenovo Clock @100% (800px wide)
    final screenWidth = MediaQuery.of(context).size.width;
    // ----------- Time ---------------------
    // Create Time String
    final hour =
        DateFormat(widget.model.is24HourFormat ? 'HH' : 'hh').format(_dateTime);
    final minute = DateFormat('mm').format(_dateTime);
    final time = hour + ":" + minute;

    // ----------- Date ---------------------
    final date = DateFormat('EEE, dd MMM').format(_dateTime);

    // ----------- Build Display Object ------------
    return AspectRatio(
      aspectRatio: 5 / 3,
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(theme.backgroundImageFileName),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
            child: Stack(
          // -----------  Time ---------------
          children: <Widget>[
            Positioned(
              child: Container(
                width: MediaQuery.of(context).size.width - 80,
                //child: Center(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    new Text(
                      time,
                      style: theme.timeTextStyle(screenWidth),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              top: 65 * scaleFactor,
              left: 0,
            ),
            // -----------  Alarm Marker ---------------
            /*  Positioned(
                      child: new Image.asset(theme.alarmImageFileName,
                        width: 40*scaleFactor,
                        height: 40*scaleFactor,
                      ),
                      top: 20*scaleFactor,
                      right : 20*scaleFactor,

                    ),*/

            // -----------  Sun Times ---------------
            /*Positioned(
              child: new Text(
                DigitalClockUtils.getNextSunEventText(
                    widget.model.is24HourFormat),
                style: theme.sunTextStyle(screenWidth),
                textAlign: TextAlign.left,
              ),
              top: 20 * scaleFactor,
              left: 20 * scaleFactor,
            ),*/

            // -----------  Weather/Temp ---------------
            Positioned(
              child: Container(
                width: MediaQuery.of(context).size.width - 80,
                //child: Center(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    new Image.asset(
                      theme.weatherImageFileName(widget.model.weatherCondition),
                      width: 80 * scaleFactor,
                      height: 60 * scaleFactor,
                    ),
                    /*  new Text(
                        theme.weatherConditionText(
                                widget.model.weatherCondition) +
                            " ",
                        style: theme.weatherTextStyle(screenWidth),
                        textAlign: TextAlign.left,
                      ),*/
                    /* new Image.asset(
                        theme.temperatureImageFileName,
                        width: 30 * scaleFactor,
                        height: 60 * scaleFactor,
                      ),*/
                    new Text(
                      widget.model.temperatureString,
                      style: theme.weatherTextStyle(screenWidth),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
              //),
              top: 10 * scaleFactor,
              left: 0,
            ),
            // -----------  Date ---------------
            Positioned(
              child:
                  /*Container(
                        width: MediaQuery.of(context).size.width-80,
                        child: Center(
                          child:Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>
                            [*/
                  new Text(
                date,
                style: theme.dataTextStyle(screenWidth),
                textAlign: TextAlign.center,
              ),

              /* ],
                          ),
                        ),
                      ),*/
              top: 20 * scaleFactor,
              right: 20 * scaleFactor,
            ),
            // -----------  Location ---------------
            Positioned(
              child: Container(
                width: MediaQuery.of(context).size.width - 80,
                child: Center(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      new Image.asset(
                        theme.locationImageFileName,
                        width: 30 * scaleFactor,
                        height: 30 * scaleFactor,
                      ),
                      new Text(
                        widget.model.location,
                        style: theme.locationTextStyle(screenWidth),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ),
              top: 370 * scaleFactor,
              left: 0,
            ),
            // -----------  BlockView  row 3 ---------------
            Positioned(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  new Image.asset(
                    theme.sunImageFileName,
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(3, 1),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(3, 2),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(3, 3),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(3, 4),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(3, 5),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(3, 6),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(3, 7),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(3, 8),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(3, 9),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(3, 10),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(3, 11),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(3, 12),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(3, 13),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(3, 14),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(3, 15),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(3, 16),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(3, 17),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(3, 18),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(3, 19),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(3, 20),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(3, 21),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(3, 22),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(3, 23),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(3, 24),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                ],
              ),
              top: 280 * scaleFactor,
              left: 35 * scaleFactor,
            ),
            // -----------  BlockView  row 2 ---------------
            Positioned(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  new Image.asset(
                    "assets/block_blank.png",
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(2, 1),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(2, 2),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(2, 3),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(2, 4),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(2, 5),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(2, 6),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(2, 7),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(2, 8),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(2, 9),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(2, 10),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(2, 11),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(2, 12),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(2, 13),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(2, 14),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(2, 15),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(2, 16),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(2, 17),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(2, 18),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(2, 19),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(2, 20),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(2, 21),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(2, 22),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(2, 23),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(2, 24),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                ],
              ),
              top: 305 * scaleFactor,
              left: 35 * scaleFactor,
            ),
            // -----------  BlockView  row 1 ---------------
            Positioned(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  new Image.asset(
                    theme.moonImageFileName,
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(1, 1),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(1, 2),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(1, 3),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(1, 4),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(1, 5),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(1, 6),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(1, 7),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(1, 8),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(1, 9),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(1, 10),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(1, 11),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(1, 12),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(1, 13),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(1, 14),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(1, 15),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(1, 16),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(1, 17),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(1, 18),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(1, 19),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(1, 20),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(1, 21),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(1, 22),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(1, 23),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                  new Image.asset(
                    theme.getSunBlock(1, 24),
                    width: 25 * scaleFactor,
                    height: 25 * scaleFactor,
                  ),
                ],
              ),
              top: 330 * scaleFactor,
              left: 35 * scaleFactor,
            ),
          ],
        )),
      ),
    );
  }
}
