import 'package:flutter/material.dart';
class NavigationManger {


  //push named
  static  Future<dynamic> navigateTo(BuildContext context, String routeName,{Object? arguments}) {
    return Navigator.pushNamed(context, routeName,arguments: arguments);
  }


  //pushReplacementNamed
  static  Future<dynamic> navigateAndReplace(BuildContext context, String routeName,{Object? arguments}) {
    return Navigator.pushReplacementNamed(context, routeName,arguments: arguments);
  }

  //pushNamedAndRemoveUntil
  static  Future<dynamic> pushNamedAndRemoveUntil(BuildContext context, String routeName,{Object? arguments}) {
    return Navigator.pushNamedAndRemoveUntil(context, routeName,(route) => false,arguments: arguments);
  }



  //pushNamedAndRemoveUntil
  static  void popUntil(BuildContext context, String routeUntil) {
    Navigator.popUntil(context,(route) => route.settings.name == routeUntil);
  }


  //popAndPush
  static  void popAndPush(BuildContext context, String route,{Object? arguments}) {
    Navigator.popAndPushNamed(context, route,arguments: arguments);
  }

  //pop
  static pop<T extends Object>(BuildContext context,[T? result]) {
    Navigator.pop(context,result);
  }





}




