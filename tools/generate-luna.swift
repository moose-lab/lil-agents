#!/usr/bin/env swift
// Luna v7 - flat shoes, tiny hands, matching Bruce/Jazz proportions exactly
import AVFoundation
import CoreGraphics
import Foundation

let W = 1080, H = 1920, fps: Int32 = 24, totalFrames = 240
let cx = CGFloat(W) / 2.0

let skin   = CGColor(srgbRed: 1.0,  green: 0.85, blue: 0.78, alpha: 1.0)
let hair   = CGColor(srgbRed: 0.48, green: 0.28, blue: 0.68, alpha: 1.0)
let hairL  = CGColor(srgbRed: 0.58, green: 0.38, blue: 0.78, alpha: 0.25)
let coat   = CGColor(srgbRed: 0.60, green: 0.42, blue: 0.80, alpha: 1.0)
let coatDk = CGColor(srgbRed: 0.48, green: 0.30, blue: 0.68, alpha: 1.0)
let shirtC = CGColor(srgbRed: 0.95, green: 0.92, blue: 0.97, alpha: 1.0)
let legC   = CGColor(srgbRed: 0.93, green: 0.88, blue: 0.96, alpha: 1.0)
let shoeC  = CGColor(srgbRed: 0.30, green: 0.16, blue: 0.48, alpha: 1.0)
let soleWh = CGColor(srgbRed: 0.95, green: 0.93, blue: 0.91, alpha: 1.0)
let laceC  = CGColor(srgbRed: 1.0,  green: 0.40, blue: 0.52, alpha: 1.0)
let eyeC   = CGColor(srgbRed: 0.25, green: 0.15, blue: 0.40, alpha: 1.0)
let mouthC = CGColor(srgbRed: 0.80, green: 0.45, blue: 0.50, alpha: 1.0)
let blushC = CGColor(srgbRed: 1.0,  green: 0.55, blue: 0.60, alpha: 0.28)
let bowPk  = CGColor(srgbRed: 1.0,  green: 0.38, blue: 0.52, alpha: 1.0)
let bowDk  = CGColor(srgbRed: 0.80, green: 0.25, blue: 0.40, alpha: 1.0)
let strapC = CGColor(srgbRed: 0.82, green: 0.28, blue: 0.42, alpha: 1.0)
let bagC   = CGColor(srgbRed: 0.70, green: 0.50, blue: 0.80, alpha: 1.0)
let bagDk  = CGColor(srgbRed: 0.52, green: 0.35, blue: 0.62, alpha: 1.0)

// Layout matching Bruce: head ~y200, shoes bottom ~y1750
// Shoes are FLAT and wide, not tall blocks
let headR: CGFloat = 108
let headCY: CGFloat = 310      // head center
let bodyTop: CGFloat = 400     // coat shoulders
let bodyBot: CGFloat = 1060    // coat bottom
let bodyHW: CGFloat = 310      // half width
let legTop: CGFloat = 1020     // legs overlap coat
let legBot: CGFloat = 1530     // leg bottom
let shoeY: CGFloat = 1510      // shoe top (overlaps leg)
let groundY: CGFloat = 1680    // shoe bottom

func spd(_ t: Double) -> Double {
    if t < 3.0 || t >= 8.25 { return 0 }
    if t < 3.75 { return (t - 3.0) / 0.75 }
    if t < 7.5 { return 1.0 }
    return 1.0 - (t - 7.5) / 0.75
}
func cv(_ c: CGContext, _ a: CGPoint, _ b: CGPoint, _ e: CGPoint) {
    c.addCurve(to: e, control1: a, control2: b)
}

func draw(_ c: CGContext, _ f: Int) {
    let t = Double(f) / Double(fps)
    let sp = spd(t)
    let ph = sp > 0 ? sin(t * 7.0) * sp : 0.0
    let bob = CGFloat(abs(ph)) * 8
    let br: CGFloat = sp == 0 ? CGFloat(sin(t * 2.5)) * 3 : 0
    let dy = -bob + br

    let legSp: CGFloat = 75      // legs close together
    let stride = CGFloat(ph) * 50 // forward/back walk

    // Draw order: back hair, back shoe, back leg, body, front leg, front shoe, arms, bag, neck, head

    // === HAIR BEHIND ===
    c.setFillColor(hair)
    for s: CGFloat in [-1, 1] {
        c.beginPath()
        c.move(to: CGPoint(x: cx + s * (headR + 2), y: headCY - 8 + dy))
        cv(c, CGPoint(x: cx + s * (headR + 48), y: headCY + 80 + dy),
             CGPoint(x: cx + s * (headR + 30), y: bodyTop + 160 + dy),
             CGPoint(x: cx + s * (headR - 20), y: bodyBot - 120 + dy + CGFloat(ph * Double(s)) * 12))
        c.addLine(to: CGPoint(x: cx + s * 40, y: bodyTop + 50 + dy))
        c.closePath(); c.fillPath()
    }

    // Determine front/back legs
    let backSide: CGFloat = ph >= 0 ? -1 : 1
    let frontSide: CGFloat = -backSide
    let backStride = -stride
    let frontStride = stride

    // === BACK SHOE (flat, wide, like Bruce) ===
    // Side-profile shoe (like Bruce's chunky sneakers)
    let shoeLen: CGFloat = 220   // shoe length (horizontal)
    let shoeH: CGFloat = 110     // shoe upper height
    let soleH: CGFloat = 35      // sole thickness
    func drawShoe(_ sx: CGFloat) {
        let soleBot = groundY + dy
        let soleTop = soleBot - soleH
        let upperBot = soleTop + 8   // sits on sole
        let upperTop = upperBot - shoeH

        // The shoe extends more to the front (toe) than back (heel)
        let heelX = sx - shoeLen * 0.35
        let toeX = sx + shoeLen * 0.65

        // White sole (thick, extends past upper, like Bruce)
        c.setFillColor(soleWh)
        c.beginPath()
        c.move(to: CGPoint(x: heelX - 15, y: soleBot))
        cv(c, CGPoint(x: heelX - 20, y: soleTop - 5),
             CGPoint(x: heelX - 10, y: soleTop),
             CGPoint(x: heelX, y: soleTop))
        c.addLine(to: CGPoint(x: toeX, y: soleTop))
        cv(c, CGPoint(x: toeX + 15, y: soleTop),
             CGPoint(x: toeX + 20, y: soleTop + 5),
             CGPoint(x: toeX + 15, y: soleBot))
        c.closePath(); c.fillPath()

        // Shoe upper (side profile: rounded toe, ankle opening at top)
        c.setFillColor(shoeC)
        c.beginPath()
        // Start at heel top (ankle)
        c.move(to: CGPoint(x: heelX + 10, y: upperTop))
        // Heel back curve
        cv(c, CGPoint(x: heelX - 15, y: upperTop + 20),
             CGPoint(x: heelX - 10, y: upperBot - 10),
             CGPoint(x: heelX, y: upperBot))
        // Bottom of shoe
        c.addLine(to: CGPoint(x: toeX - 20, y: upperBot))
        // Toe curve (rounded front)
        cv(c, CGPoint(x: toeX + 10, y: upperBot),
             CGPoint(x: toeX + 15, y: upperBot - shoeH * 0.4),
             CGPoint(x: toeX - 10, y: upperBot - shoeH * 0.6))
        // Top of shoe back to ankle
        cv(c, CGPoint(x: toeX - 40, y: upperTop + 5),
             CGPoint(x: sx, y: upperTop - 5),
             CGPoint(x: heelX + 10, y: upperTop))
        c.closePath(); c.fillPath()

        // Pink lace accent
        c.setFillColor(laceC)
        c.fillEllipse(in: CGRect(x: sx - 5, y: upperTop + 12, width: 12, height: 8))
        c.fillEllipse(in: CGRect(x: sx - 3, y: upperTop + 28, width: 8, height: 6))
    }
    drawShoe(cx + backSide * legSp + backStride)

    // === BACK LEG ===
    c.setFillColor(legC)
    let legW: CGFloat = 72
    func drawLeg(_ side: CGFloat, _ sw: CGFloat) {
        let topX = cx + side * legSp
        let botX = topX + sw
        c.beginPath()
        c.move(to: CGPoint(x: topX - legW, y: legTop + dy))
        cv(c, CGPoint(x: topX - legW - 3, y: legTop + 100 + dy),
             CGPoint(x: botX - legW + 3, y: legBot - 30 + dy),
             CGPoint(x: botX - legW + 5, y: legBot + dy))
        c.addLine(to: CGPoint(x: botX + legW - 5, y: legBot + dy))
        cv(c, CGPoint(x: botX + legW - 3, y: legBot - 30 + dy),
             CGPoint(x: topX + legW + 3, y: legTop + 100 + dy),
             CGPoint(x: topX + legW, y: legTop + dy))
        c.closePath(); c.fillPath()
    }
    drawLeg(backSide, backStride)

    // === BODY (rounded blob like Bruce's jacket) ===
    c.setFillColor(coat)
    c.beginPath()
    c.move(to: CGPoint(x: cx - bodyHW + 80, y: bodyTop + dy))
    cv(c, CGPoint(x: cx - bodyHW - 35, y: bodyTop + bodyHW * 0.5 + dy),
         CGPoint(x: cx - bodyHW - 25, y: bodyBot - 80 + dy),
         CGPoint(x: cx - bodyHW + 15, y: bodyBot + dy))
    cv(c, CGPoint(x: cx - bodyHW + 80, y: bodyBot + 15 + dy),
         CGPoint(x: cx + bodyHW - 80, y: bodyBot + 15 + dy),
         CGPoint(x: cx + bodyHW - 15, y: bodyBot + dy))
    cv(c, CGPoint(x: cx + bodyHW + 25, y: bodyBot - 80 + dy),
         CGPoint(x: cx + bodyHW + 35, y: bodyTop + bodyHW * 0.5 + dy),
         CGPoint(x: cx + bodyHW - 80, y: bodyTop + dy))
    cv(c, CGPoint(x: cx + bodyHW - 120, y: bodyTop - 8 + dy),
         CGPoint(x: cx - bodyHW + 120, y: bodyTop - 8 + dy),
         CGPoint(x: cx - bodyHW + 80, y: bodyTop + dy))
    c.fillPath()

    // Shirt opening
    c.setFillColor(shirtC)
    let sv: CGFloat = 72
    c.beginPath()
    c.move(to: CGPoint(x: cx - sv, y: bodyTop + 12 + dy))
    cv(c, CGPoint(x: cx - sv - 5, y: bodyTop + 300 + dy),
         CGPoint(x: cx - sv + 15, y: bodyBot - 15 + dy),
         CGPoint(x: cx - sv + 28, y: bodyBot + 8 + dy))
    c.addLine(to: CGPoint(x: cx + sv - 28, y: bodyBot + 8 + dy))
    cv(c, CGPoint(x: cx + sv - 15, y: bodyBot - 15 + dy),
         CGPoint(x: cx + sv + 5, y: bodyTop + 300 + dy),
         CGPoint(x: cx + sv, y: bodyTop + 12 + dy))
    c.closePath(); c.fillPath()

    // Collar
    c.setFillColor(coatDk)
    c.beginPath(); c.move(to: CGPoint(x: cx - 95, y: bodyTop - 2 + dy))
    cv(c, CGPoint(x: cx - 38, y: bodyTop + 42 + dy),
         CGPoint(x: cx + 38, y: bodyTop + 42 + dy),
         CGPoint(x: cx + 95, y: bodyTop - 2 + dy))
    cv(c, CGPoint(x: cx + 28, y: bodyTop + 22 + dy),
         CGPoint(x: cx - 28, y: bodyTop + 22 + dy),
         CGPoint(x: cx - 95, y: bodyTop - 2 + dy))
    c.fillPath()

    // Coat hem accent
    c.setFillColor(coatDk)
    c.beginPath()
    let hemY = bodyBot - 45 + dy
    c.move(to: CGPoint(x: cx - bodyHW + 25, y: hemY))
    cv(c, CGPoint(x: cx - bodyHW + 80, y: bodyBot + 12 + dy),
         CGPoint(x: cx + bodyHW - 80, y: bodyBot + 12 + dy),
         CGPoint(x: cx + bodyHW - 25, y: hemY))
    c.addLine(to: CGPoint(x: cx + bodyHW - 15, y: bodyBot + dy))
    cv(c, CGPoint(x: cx + bodyHW - 80, y: bodyBot + 15 + dy),
         CGPoint(x: cx - bodyHW + 80, y: bodyBot + 15 + dy),
         CGPoint(x: cx - bodyHW + 15, y: bodyBot + dy))
    c.closePath(); c.fillPath()

    // Pockets (rounded)
    c.setFillColor(coatDk)
    for s: CGFloat in [-1, 1] {
        c.addPath(CGPath(roundedRect: CGRect(x: cx + s * (bodyHW - 105) - 38, y: bodyTop + 200 + dy, width: 76, height: 55),
                         cornerWidth: 10, cornerHeight: 10, transform: nil))
        c.fillPath()
    }

    // === FRONT LEG ===
    drawLeg(frontSide, frontStride)

    // === FRONT SHOE ===
    drawShoe(cx + frontSide * legSp + frontStride)

    // === ARMS (from within body, small hands peeking from sleeves) ===
    let armLen: CGFloat = 380
    for side: CGFloat in [-1, 1] {
        let armSwing = CGFloat(ph * Double(-side)) * 0.2
        let armX = cx + side * (bodyHW - 40)  // within body silhouette
        let armTopY = bodyTop + 50 + dy

        c.saveGState()
        c.translateBy(x: armX, y: armTopY)
        c.rotate(by: armSwing)

        // Sleeve (tapers naturally)
        c.setFillColor(coat)
        let aw: CGFloat = 75
        c.beginPath()
        c.move(to: CGPoint(x: -aw/2, y: 0))
        cv(c, CGPoint(x: -aw/2 - 12, y: armLen * 0.35),
             CGPoint(x: -aw/2 + 8, y: armLen * 0.8),
             CGPoint(x: -15, y: armLen))
        cv(c, CGPoint(x: 0, y: armLen + 8),
             CGPoint(x: 0, y: armLen + 8),
             CGPoint(x: 15, y: armLen))
        cv(c, CGPoint(x: aw/2 - 8, y: armLen * 0.8),
             CGPoint(x: aw/2 + 12, y: armLen * 0.35),
             CGPoint(x: aw/2, y: 0))
        c.closePath(); c.fillPath()

        // Small hand peeking from sleeve (TINY, like Bruce)
        c.setFillColor(skin)
        c.fillEllipse(in: CGRect(x: -16, y: armLen - 22, width: 32, height: 32))

        c.restoreGState()
    }

    // === BAG ===
    c.setStrokeColor(strapC); c.setLineWidth(8); c.setLineCap(.round)
    c.beginPath()
    c.move(to: CGPoint(x: cx + bodyHW - 70, y: bodyTop + 15 + dy))
    c.addLine(to: CGPoint(x: cx - bodyHW + 55, y: bodyBot - 90 + dy))
    c.strokePath()
    let bx = cx - bodyHW + 25, by2 = bodyBot - 135 + dy
    c.setFillColor(bagC)
    c.fillEllipse(in: CGRect(x: bx - 35, y: by2, width: 85, height: 72))
    c.setFillColor(bagDk)
    c.fillEllipse(in: CGRect(x: bx - 25, y: by2 + 5, width: 65, height: 30))
    c.setFillColor(laceC)
    c.fillEllipse(in: CGRect(x: bx, y: by2 + 25, width: 12, height: 12))

    // === NECK (minimal) ===
    c.setFillColor(skin)
    c.fillEllipse(in: CGRect(x: cx - 32, y: bodyTop - 15 + dy, width: 64, height: 32))

    // === HEAD ===
    c.setFillColor(skin)
    c.fillEllipse(in: CGRect(x: cx - headR, y: headCY - headR + dy, width: headR * 2, height: headR * 2))

    // Hair cap
    c.setFillColor(hair)
    c.beginPath()
    c.move(to: CGPoint(x: cx - headR - 3, y: headCY + 12 + dy))
    cv(c, CGPoint(x: cx - headR, y: headCY - headR - 25 + dy),
         CGPoint(x: cx + headR, y: headCY - headR - 25 + dy),
         CGPoint(x: cx + headR + 3, y: headCY + 12 + dy))
    cv(c, CGPoint(x: cx + headR - 6, y: headCY - headR + 28 + dy),
         CGPoint(x: cx - headR + 6, y: headCY - headR + 28 + dy),
         CGPoint(x: cx - headR - 3, y: headCY + 12 + dy))
    c.fillPath()

    // Bangs
    c.beginPath()
    c.move(to: CGPoint(x: cx - headR + 3, y: headCY - headR + 42 + dy))
    cv(c, CGPoint(x: cx - 18, y: headCY - headR + 2 + dy),
         CGPoint(x: cx + 18, y: headCY - headR + 6 + dy),
         CGPoint(x: cx + 45, y: headCY - 6 + dy))
    c.addLine(to: CGPoint(x: cx - 3, y: headCY - 2 + dy))
    c.addLine(to: CGPoint(x: cx - headR + 8, y: headCY - 14 + dy))
    c.closePath(); c.fillPath()

    // Hair highlight
    c.setFillColor(hairL)
    c.beginPath()
    c.move(to: CGPoint(x: cx - 28, y: headCY - headR + 32 + dy))
    cv(c, CGPoint(x: cx - 8, y: headCY - headR + 1 + dy),
         CGPoint(x: cx + 10, y: headCY - headR + 6 + dy),
         CGPoint(x: cx + 18, y: headCY - 8 + dy))
    c.addLine(to: CGPoint(x: cx + 2, y: headCY - 4 + dy))
    c.addLine(to: CGPoint(x: cx - 18, y: headCY - 8 + dy))
    c.closePath(); c.fillPath()

    // Bow
    let bwx = cx + headR - 12, bwy = headCY - headR + 42 + dy
    c.setFillColor(bowPk)
    c.fillEllipse(in: CGRect(x: bwx - 28, y: bwy - 9, width: 26, height: 20))
    c.fillEllipse(in: CGRect(x: bwx + 2, y: bwy - 9, width: 26, height: 20))
    c.setFillColor(bowDk)
    c.fillEllipse(in: CGRect(x: bwx - 5, y: bwy - 5, width: 10, height: 10))

    // Eyes (small like Bruce)
    c.setFillColor(eyeC)
    c.fillEllipse(in: CGRect(x: cx - 36, y: headCY - 2 + dy, width: 16, height: 18))
    c.fillEllipse(in: CGRect(x: cx + 20, y: headCY - 2 + dy, width: 16, height: 18))
    c.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.75))
    c.fillEllipse(in: CGRect(x: cx - 32, y: headCY + 1 + dy, width: 5, height: 5))
    c.fillEllipse(in: CGRect(x: cx + 24, y: headCY + 1 + dy, width: 5, height: 5))

    // Blush
    c.setFillColor(blushC)
    c.fillEllipse(in: CGRect(x: cx - 50, y: headCY + 16 + dy, width: 26, height: 14))
    c.fillEllipse(in: CGRect(x: cx + 24, y: headCY + 16 + dy, width: 26, height: 14))

    // Mouth
    c.setStrokeColor(mouthC); c.setLineWidth(3.0); c.setLineCap(.round)
    c.beginPath(); c.move(to: CGPoint(x: cx - 12, y: headCY + 30 + dy))
    cv(c, CGPoint(x: cx - 4, y: headCY + 40 + dy),
         CGPoint(x: cx + 4, y: headCY + 40 + dy),
         CGPoint(x: cx + 12, y: headCY + 30 + dy))
    c.strokePath()
}

// === VIDEO ===
let out = URL(fileURLWithPath: CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : FileManager.default.currentDirectoryPath + "/LilAgents/walk-luna-01.mov")
try? FileManager.default.removeItem(at: out)
print("Generating → \(out.path)")
let wr = try! AVAssetWriter(outputURL: out, fileType: .mov)
let st: [String: Any] = [AVVideoCodecKey: AVVideoCodecType.hevcWithAlpha,
    AVVideoWidthKey: W, AVVideoHeightKey: H,
    AVVideoCompressionPropertiesKey: [AVVideoQualityKey: 0.85] as [String: Any]]
let inp = AVAssetWriterInput(mediaType: .video, outputSettings: st)
inp.expectsMediaDataInRealTime = false
let pa: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
    kCVPixelBufferWidthKey as String: W, kCVPixelBufferHeightKey as String: H]
let ad = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: inp, sourcePixelBufferAttributes: pa)
wr.add(inp); wr.startWriting(); wr.startSession(atSourceTime: .zero)
for i in 0..<totalFrames {
    while !inp.isReadyForMoreMediaData { Thread.sleep(forTimeInterval: 0.005) }
    var pb: CVPixelBuffer?
    CVPixelBufferCreate(kCFAllocatorDefault, W, H, kCVPixelFormatType_32BGRA, pa as CFDictionary, &pb)
    guard let b = pb else { continue }
    CVPixelBufferLockBaseAddress(b, [])
    let ctx = CGContext(data: CVPixelBufferGetBaseAddress(b)!, width: W, height: H,
        bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(b),
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)!
    ctx.clear(CGRect(x: 0, y: 0, width: W, height: H))
    ctx.translateBy(x: 0, y: CGFloat(H)); ctx.scaleBy(x: 1, y: -1)
    draw(ctx, i)
    CVPixelBufferUnlockBaseAddress(b, [])
    ad.append(b, withPresentationTime: CMTime(value: CMTimeValue(i), timescale: fps))
}
inp.markAsFinished()
let s = DispatchSemaphore(value: 0)
wr.finishWriting {
    let sz = (try? FileManager.default.attributesOfItem(atPath: out.path)[.size] as? Int) ?? 0
    print(wr.status == .completed ? "Done! \(sz/1024)KB" : "Err: \(wr.error?.localizedDescription ?? "?")")
    s.signal()
}
s.wait()
