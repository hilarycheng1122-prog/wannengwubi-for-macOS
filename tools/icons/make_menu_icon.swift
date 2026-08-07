import AppKit
import Foundation

final class MenuIconView: NSView {
  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    // macOS treats input-source menu icons as monochrome template masks. A
    // solid background plus a differently coloured glyph therefore collapses
    // into one solid block. Keep the page transparent and draw only the glyph.
    let text = "万" as NSString
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let attributes: [NSAttributedString.Key: Any] = [
      .font: NSFont(name: "PingFangSC-Semibold", size: 14)
        ?? NSFont.systemFont(ofSize: 14, weight: .bold),
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
