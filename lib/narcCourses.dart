import 'package:flutter/material.dart';

import 'APIWrapper.dart';
import 'main.dart';

class NarcCourses extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _NarcCoursesState();
  }
}

class _NarcCoursesState extends State<NarcCourses> {

  @override
  Widget build(BuildContext context) {
    return CanvasItemsBuilder(title:"Courses", getFunction:() {
      return getCourses();
    }, onTapFunction: (id, _) {
      storage.write(key: "currentCourse", value: id.toString());
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NarcModules(id: id)),
      );
    });
  }
}