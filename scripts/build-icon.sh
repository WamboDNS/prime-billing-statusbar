#!/bin/bash
# Rebuilds assets/prime-logo-template.png from Prime Intellect's upstream
# favicon. Useful if the upstream logo changes or you want a different size.
#
# Pipeline:
#   1. Download the 256x256 favicon (sharper than the 48x48 .ico).
#   2. Find the tight bounding box of the dark logo content (it lives inside
#      a square canvas with ~55px of empty padding top/bottom — bad for
#      vertical centering against menu-bar text).
#   3. Crop to that bbox.
#   4. Downscale (Lanczos via CGContext) to TARGET_HEIGHT px tall, preserving
#      aspect.
#   5. Convert to an alpha-only template image (RGB=0, alpha = 1 − luminance).
#      SwiftBar's templateImage parameter recolors based on the menu-bar text
#      color, so only the alpha channel matters.
#   6. Tag the PNG with 144 DPI so macOS renders it at @2x — i.e. half the
#      logical pt size with full pixel sharpness. Without this it renders at
#      pixel == point and looks huge or blurry.
#
# Tweak TARGET_HEIGHT for a bigger or smaller icon (37 ≈ 18.5pt rendered).

set -euo pipefail

TARGET_HEIGHT="${TARGET_HEIGHT:-37}"
SOURCE_URL="${SOURCE_URL:-https://app.primeintellect.ai/favicon-256x256.png}"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${REPO_DIR}/assets/prime-logo-template.png"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "→ downloading $SOURCE_URL"
curl -sLfo "${TMP}/source.png" "$SOURCE_URL"

echo "→ rendering ${TARGET_HEIGHT}px-tall template"
/usr/bin/swift - "${TMP}/source.png" "$OUT" "$TARGET_HEIGHT" <<'SWIFT'
import AppKit
import CoreGraphics

let inPath = CommandLine.arguments[1]
let outPath = CommandLine.arguments[2]
let targetH = Int(CommandLine.arguments[3])!

let data = try Data(contentsOf: URL(fileURLWithPath: inPath))
let src = NSBitmapImageRep(data: data)!
let cgSrc = src.cgImage!

// 1. Find the dark-content bounding box on the source canvas.
let cs0 = CGColorSpaceCreateDeviceRGB()
let probe = CGContext(data: nil, width: cgSrc.width, height: cgSrc.height,
                      bitsPerComponent: 8, bytesPerRow: 0, space: cs0,
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
probe.draw(cgSrc, in: CGRect(x: 0, y: 0, width: cgSrc.width, height: cgSrc.height))
let pbuf = probe.data!.bindMemory(to: UInt8.self, capacity: cgSrc.width * cgSrc.height * 4)
let pbpr = probe.bytesPerRow
var minX = cgSrc.width, minY = cgSrc.height, maxX = 0, maxY = 0
for y in 0..<cgSrc.height {
    for x in 0..<cgSrc.width {
        let i = y * pbpr + x * 4
        let lum = (299 * Int(pbuf[i]) + 587 * Int(pbuf[i+1]) + 114 * Int(pbuf[i+2])) / 1000
        if lum < 200 {
            if x < minX { minX = x }
            if y < minY { minY = y }
            if x > maxX { maxX = x }
            if y > maxY { maxY = y }
        }
    }
}
let bboxW = maxX - minX + 1
let bboxH = maxY - minY + 1
// CG origin is bottom-left
let bbox = CGRect(x: minX, y: cgSrc.height - 1 - maxY,
                  width: bboxW, height: bboxH)
let cropped = cgSrc.cropping(to: bbox)!

// 2. Resize to targetH preserving aspect.
let targetW = Int((Double(cropped.width) / Double(cropped.height)) * Double(targetH))
let cs = CGColorSpaceCreateDeviceRGB()
let ctx = CGContext(data: nil, width: targetW, height: targetH,
                    bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.interpolationQuality = .high
ctx.draw(cropped, in: CGRect(x: 0, y: 0, width: targetW, height: targetH))

// 3. Alpha-from-luminance.
let buf = ctx.data!.bindMemory(to: UInt8.self, capacity: targetW * targetH * 4)
let bpr = ctx.bytesPerRow
for y in 0..<targetH {
    for x in 0..<targetW {
        let i = y * bpr + x * 4
        let lum = 0.299 * Double(buf[i]) / 255.0
                + 0.587 * Double(buf[i+1]) / 255.0
                + 0.114 * Double(buf[i+2]) / 255.0
        buf[i] = 0; buf[i+1] = 0; buf[i+2] = 0
        buf[i+3] = UInt8(max(0, min(255, (1.0 - lum) * 255.0)))
    }
}

let pngData = NSBitmapImageRep(cgImage: ctx.makeImage()!)
    .representation(using: .png, properties: [:])!
try pngData.write(to: URL(fileURLWithPath: outPath))
print("  wrote \(targetW)x\(targetH)  \(pngData.count) bytes")
SWIFT

echo "→ tagging 144 DPI (= @2x on Retina)"
sips -s dpiHeight 144 -s dpiWidth 144 "$OUT" >/dev/null
chmod 644 "$OUT"

echo "✓ ${OUT}"
sips -g pixelWidth -g pixelHeight -g dpiWidth -g dpiHeight "$OUT" \
  | grep -E 'pixel|dpi'
