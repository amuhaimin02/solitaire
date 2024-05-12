import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Debug: Make window always on top
    self.level = .floating

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
