import UIKit
import Flutter
import GoogleMaps
import background_location_tracker

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyDwfxo5NPOPD_JED1tiZfoHbIUBgcHX8j4")
    GeneratedPluginRegistrant.register(with: self)
    BackgroundLocationTrackerPlugin.setPluginRegistrantCallback { registry in
        GeneratedPluginRegistrant.register(with: registry)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
