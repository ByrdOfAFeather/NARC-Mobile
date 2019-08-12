import 'package:flutter/material.dart';

import 'APIWrapper.dart';
import 'canvasItemBuilders.dart';
import 'main.dart';

class NarcMainMenu extends StatefulWidget {
  int initalIndex = 0;
  NarcMainMenu({Key key, this.initalIndex}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _NarcMainMenuState();
  }
}

class _NarcMainMenuState extends State<NarcMainMenu> {

  @override
  Widget build(BuildContext context) {
    return MainMenuBuilder(title:"Courses", getFunction:() {
      return getCourses();
    }, onTapFunction: (id, _) {
      storage.write(key: "currentCourse", value: id.toString());
      Navigator.push(
        context,
        CustomRoute(builder: (context) => NarcModules(id: id)),
      );
    }, initGlobalNavigationIndex: widget.initalIndex,);
  }
}