import AppKit
import Foundation

final class MenuIconView: NSView {
  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    // macOS treats input-source menu icons as monochrome template masks. Keep
    // the page transparent; use a stroked frame so it cannot collapse into a
    // solid block after the system applies its menu-bar tint.
    let frameRect = NSRect(x: 1, y: 0.75, width: 20, height: 14.5)
    let frame = NSBezierPath(roundedRect: frameRect, xRadius: 3, yRadius: 3)
    frame.lineWidth = 1.25
    NSColor.black.setStroke()
    frame.stroke()

    let text = "万" as NSString
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let attributes: [NSAttributedString.Key: Any] = [
      .font: NSFont(name: "PingFangSC-Semibold", size: 12.5)
        ?? NSFont.systemFont(ofSize: 12.5, weight: .bold),
      .foregroundColor: NSColor.black,
      .paragraphStyle: paragraph,
    ]
    let textSize = text.size(withAttributes: attributes)
    let textRect = NSRect(
      x: bounds.midX - textSize.width / 2,
      y: bounds.midY - textSize.height / 2 + 0.25,
      width: textSize.width,
      height: textSize.height
    )
    text.draw(in: textRect, withAttributes: attributes)
  }
}

guard CommandLine.arguments.count == 2 else {
  fputs("usage: make_menu_icon output.pdf\n", stderr)
  exit(2)
}

let view = MenuIconView(frame: NSRect(x: 0, y: 0, width: 22, height: 16))
let data = view.dataWithPDF(inside: view.bounds)
try data.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
