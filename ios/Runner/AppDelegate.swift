import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    self.window.secureApp()
    GMSServices.provideAPIKey("AIzaSyDwfxo5NPOPD_JED1tiZfoHbIUBgcHX8j4")
    GeneratedPluginRegistrant.register(with: self)
    // BackgroundLocationTrackerPlugin.setPluginRegistrantCallback { registry in
    //     GeneratedPluginRegistrant.register(with: registry)
    // }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

extension UIWindow {
func secureApp() {
    let field = UITextField()
    field.isSecureTextEntry = true
    self.addSubview(field)
    field.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    field.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
    self.layer.superlayer?.addSublayer(field.layer)
    field.layer.sublayers?.first?.addSublayer(self.layer)
  }
}
