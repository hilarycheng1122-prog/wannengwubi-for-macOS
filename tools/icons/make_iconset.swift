import AppKit
import Foundation

guard CommandLine.arguments.count == 3 else {
  fputs("usage: make_iconset source.png output.iconset\n", stderr)
  exit(2)
}

let sourcePath = CommandLine.arguments[1]
let outputPath = CommandLine.arguments[2]

guard let source = NSImage(contentsOfFile: sourcePath) else {
  fputs("unable to load source image\n", stderr)
  exit(1)
}

let variants: [(String, Int)] = [
  ("icon_16x16.png", 16),
  ("icon_16x16@2x.png", 32),
  ("icon_32x32.png", 32),
  ("icon_32x32@2x.png", 64),
  ("icon_128x128.png", 128),
  ("icon_128x128@2x.png", 256),
  ("icon_256x256.png", 256),
  ("icon_256x256@2x.png", 512),
  ("icon_512x512.png", 512),
  ("icon_512x512@2x.png", 1024),
]

try FileManager.default.createDirectory(
  atPath: outputPath,
  withIntermediateDirectories: true
)

for (filename, pixels) in variants {
  guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: pixels,
    pixelsHigh: pixels,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bitmapFormat: [],
    bytesPerRow: 0,
    bitsPerPixel: 0
  ) else {
    fputs("unable to allocate \(pixels)x\(pixels) bitmap\n", stderr)
    exit(1)
  }

  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
  NSGraphicsContext.current?.imageInterpolation = .high
  NSColor.clear.setFill()
  NSRect(x: 0, y: 0, width: pixels, height: pixels).fill()
  source.draw(
    in: NSRect(x: 0, y: 0, width: pixels, height: pixels),
    from: .zero,
    operation: .sourceOver,
    fraction: 1
  )
  NSGraphicsContext.restoreGraphicsState()

  guard let data = bitmap.representation(using: .png, properties: [:]) else {
    fputs("unable to encode \(filename)\n", stderr)
    exit(1)
  }
  try data.write(to: URL(fileURLWithPath: outputPath).appendingPathComponent(filename))
}
