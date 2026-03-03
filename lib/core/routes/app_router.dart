import 'package:flutter/material.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/features/splash/presentation/screens/splash_screen.dart';

class AppRouter {

   Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splashScreen:

        return MaterialPageRoute(builder: (context) => SplashScreen());

      default:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }



}
