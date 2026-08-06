import AppKit
import Foundation

final class MenuIconView: NSView {
  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    let iconRect = NSRect(x: 4, y: 1, width: 14, height: 14)
    let background = NSBezierPath(roundedRect: iconRect, xRadius: 3, yRadius: 3)
    NSColor(calibratedRed: 0.82, green: 0.06, blue: 0.035, alpha: 1).setFill()
    background.fill()

    let text = "万" as NSString
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let attributes: [NSAttributedString.Key: Any] = [
      .font: NSFont.systemFont(ofSize: 11, weight: .semibold),
      .foregroundColor: NSColor.black,
      .paragraphStyle: paragraph,
    ]
    let textSize = text.size(withAttributes: attributes)
    let textRect = NSRect(
      x: iconRect.midX - textSize.width / 2,
      y: iconRect.midY - textSize.height / 2 + 0.5,
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
