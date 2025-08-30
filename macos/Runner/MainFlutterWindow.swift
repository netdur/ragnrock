import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
    override func awakeFromNib() {
        let initialWidth:  CGFloat = 1280
        let initialHeight: CGFloat = 800
        let minWidth:      CGFloat = 1024
        let minHeight:     CGFloat = 640

        let flutterViewController = FlutterViewController()
        self.contentViewController = flutterViewController

        // Default size + minimum size
        self.contentMinSize = NSSize(width: minWidth, height: minHeight)
        if let screen = self.screen ?? NSScreen.main {
          let rect = NSRect(
            x: screen.frame.midX - initialWidth/2,
            y: screen.frame.midY - initialHeight/2,
            width: initialWidth,
            height: initialHeight
          )
          self.setFrame(rect, display: true)
        } else {
          self.setContentSize(NSSize(width: initialWidth, height: initialHeight))
        }

        // Auto-remember size on next launch (optional)
        self.setFrameAutosaveName("MainWindow")

        self.makeKeyAndOrderFront(nil)
        RegisterGeneratedPlugins(registry: flutterViewController)
        super.awakeFromNib()
      }
}

