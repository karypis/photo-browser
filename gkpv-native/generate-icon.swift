#!/usr/bin/env swift
import AppKit

let size = 1024
let img = NSImage(size: NSSize(width: size, height: size))

img.lockFocus()
guard let ctx = NSGraphicsContext.current?.cgContext else { fatalError("No context") }

let s = CGFloat(size)

// --- Rounded square (macOS squircle approximation) ---
let iconRect = CGRect(x: 0, y: 0, width: s, height: s)
let cornerRadius: CGFloat = s * 0.22
let iconPath = NSBezierPath(roundedRect: iconRect, xRadius: cornerRadius, yRadius: cornerRadius)
iconPath.addClip()

// --- Background gradient: deep blue to dark ---
let bgColors = [
    NSColor(red: 0.10, green: 0.12, blue: 0.22, alpha: 1.0).cgColor,
    NSColor(red: 0.15, green: 0.25, blue: 0.45, alpha: 1.0).cgColor,
    NSColor(red: 0.25, green: 0.50, blue: 0.75, alpha: 1.0).cgColor,
]
let bgGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                             colors: bgColors as CFArray,
                             locations: [0.0, 0.5, 1.0])!
ctx.drawLinearGradient(bgGradient,
                       start: CGPoint(x: s/2, y: 0),
                       end: CGPoint(x: s/2, y: s),
                       options: [])

// --- Sun glow ---
let sunCenter = CGPoint(x: s * 0.65, y: s * 0.65)
let sunRadius: CGFloat = s * 0.12
let glowColors = [
    NSColor(red: 1.0, green: 0.85, blue: 0.4, alpha: 0.8).cgColor,
    NSColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 0.3).cgColor,
    NSColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.0).cgColor,
]
let glowGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                               colors: glowColors as CFArray,
                               locations: [0.0, 0.4, 1.0])!
ctx.drawRadialGradient(glowGradient,
                       startCenter: sunCenter, startRadius: 0,
                       endCenter: sunCenter, endRadius: sunRadius * 3,
                       options: [])

// --- Sun disc ---
ctx.setFillColor(NSColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 1.0).cgColor)
ctx.fillEllipse(in: CGRect(x: sunCenter.x - sunRadius, y: sunCenter.y - sunRadius,
                            width: sunRadius * 2, height: sunRadius * 2))

// --- Mountains ---
// Back mountain (lighter)
ctx.setFillColor(NSColor(red: 0.15, green: 0.25, blue: 0.40, alpha: 1.0).cgColor)
ctx.beginPath()
ctx.move(to: CGPoint(x: 0, y: 0))
ctx.addLine(to: CGPoint(x: s * 0.15, y: 0))
ctx.addLine(to: CGPoint(x: s * 0.40, y: s * 0.40))
ctx.addLine(to: CGPoint(x: s * 0.55, y: s * 0.30))
ctx.addLine(to: CGPoint(x: s * 0.85, y: s * 0.50))
ctx.addLine(to: CGPoint(x: s, y: s * 0.42))
ctx.addLine(to: CGPoint(x: s, y: 0))
ctx.closePath()
ctx.fillPath()

// Front mountain (darker)
ctx.setFillColor(NSColor(red: 0.10, green: 0.18, blue: 0.30, alpha: 1.0).cgColor)
ctx.beginPath()
ctx.move(to: CGPoint(x: 0, y: 0))
ctx.addLine(to: CGPoint(x: 0, y: s * 0.22))
ctx.addLine(to: CGPoint(x: s * 0.30, y: s * 0.38))
ctx.addLine(to: CGPoint(x: s * 0.42, y: s * 0.30))
ctx.addLine(to: CGPoint(x: s * 0.70, y: s * 0.45))
ctx.addLine(to: CGPoint(x: s, y: s * 0.25))
ctx.addLine(to: CGPoint(x: s, y: 0))
ctx.closePath()
ctx.fillPath()

// --- Photo frame border (subtle white inset) ---
let frameInset: CGFloat = s * 0.06
let frameRect = iconRect.insetBy(dx: frameInset, dy: frameInset)
let frameRadius = cornerRadius - frameInset * 0.8
let framePath = NSBezierPath(roundedRect: frameRect, xRadius: frameRadius, yRadius: frameRadius)
NSColor(white: 1.0, alpha: 0.15).setStroke()
framePath.lineWidth = s * 0.012
framePath.stroke()

// --- "my PV" text at bottom ---
let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: s * 0.09, weight: .bold),
    .foregroundColor: NSColor(white: 1.0, alpha: 0.9),
]
let text = NSAttributedString(string: "my PV", attributes: attrs)
let textSize = text.size()
let textPoint = NSPoint(x: (s - textSize.width) / 2, y: s * 0.08)
text.draw(at: textPoint)

img.unlockFocus()

// --- Save as 1024x1024 PNG ---
guard let tiff = img.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let pngData = rep.representation(using: .png, properties: [:]) else {
    fatalError("Failed to create PNG")
}

let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
let pngPath = "\(outputDir)/AppIcon_1024.png"
try! pngData.write(to: URL(fileURLWithPath: pngPath))
print("Saved \(pngPath)")

// --- Create iconset with all sizes ---
let iconsetPath = "\(outputDir)/AppIcon.iconset"
try? FileManager.default.removeItem(atPath: iconsetPath)
try! FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

let sizes: [(String, Int)] = [
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

for (name, px) in sizes {
    let resized = NSImage(size: NSSize(width: px, height: px))
    resized.lockFocus()
    img.draw(in: NSRect(x: 0, y: 0, width: px, height: px),
             from: NSRect(origin: .zero, size: img.size),
             operation: .sourceOver, fraction: 1.0)
    resized.unlockFocus()

    guard let t = resized.tiffRepresentation,
          let r = NSBitmapImageRep(data: t),
          let d = r.representation(using: .png, properties: [:]) else { continue }
    try! d.write(to: URL(fileURLWithPath: "\(iconsetPath)/\(name)"))
}

print("Created iconset at \(iconsetPath)")
