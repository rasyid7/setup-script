import AppKit
import QuartzCore

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

class EdgeLightningDelegate: NSObject, NSApplicationDelegate {
    var windows: [NSWindow] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        for screen in NSScreen.screens {
            setupEdgeLightning(on: screen)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            self.fadeOutAndClose()
        }
    }

    func fadeOutAndClose() {
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.6
            self.windows.forEach { $0.animator().alphaValue = 0 }
        }, completionHandler: {
            NSApp.terminate(nil)
        })
    }

    // cw=true  → right half (bottom-center → bottom-right → top-right corner)
    // cw=false → left half  (bottom-center → bottom-left → top-left → across top → top-right corner)
    // Both paths converge at (x1 - r, y1): the top-right corner, where Mac notifications appear.
    func halfEdgePath(rect: CGRect, r: CGFloat, clockwise cw: Bool) -> CGPath {
        let p = CGMutablePath()
        let mx = rect.midX
        let x0 = rect.minX, x1 = rect.maxX
        let y0 = rect.minY, y1 = rect.maxY
        if cw {
            p.move(to: CGPoint(x: mx, y: y0))
            p.addLine(to: CGPoint(x: x1 - r, y: y0))
            p.addArc(center: CGPoint(x: x1 - r, y: y0 + r), radius: r,
                     startAngle: -.pi / 2, endAngle: 0, clockwise: false)
            p.addLine(to: CGPoint(x: x1, y: y1 - r))
            p.addArc(center: CGPoint(x: x1 - r, y: y1 - r), radius: r,
                     startAngle: 0, endAngle: .pi / 2, clockwise: false)
            // Ends at (x1-r, y1) — top-right corner
        } else {
            p.move(to: CGPoint(x: mx, y: y0))
            p.addLine(to: CGPoint(x: x0 + r, y: y0))
            p.addArc(center: CGPoint(x: x0 + r, y: y0 + r), radius: r,
                     startAngle: -.pi / 2, endAngle: .pi, clockwise: true)
            p.addLine(to: CGPoint(x: x0, y: y1 - r))
            p.addArc(center: CGPoint(x: x0 + r, y: y1 - r), radius: r,
                     startAngle: .pi, endAngle: .pi / 2, clockwise: true)
            p.addLine(to: CGPoint(x: x1 - r, y: y1))
            // Ends at (x1-r, y1) — top-right corner
        }
        return p
    }

    func strokeAnim(keyPath: String, from: CGFloat, to: CGFloat, duration: Double) -> CABasicAnimation {
        let a = CABasicAnimation(keyPath: keyPath)
        a.fromValue = from; a.toValue = to; a.duration = duration
        a.timingFunction = CAMediaTimingFunction(name: .easeIn)
        a.fillMode = .forwards; a.isRemovedOnCompletion = false
        return a
    }

    func setupEdgeLightning(on screen: NSScreen) {
        let frame = screen.frame
        let win = NSWindow(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: screen
        )
        win.level = .screenSaver
        win.isOpaque = false
        win.backgroundColor = .clear
        win.ignoresMouseEvents = true
        win.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        win.isReleasedWhenClosed = false
        win.alphaValue = 0

        let view = NSView(frame: CGRect(origin: .zero, size: frame.size))
        view.wantsLayer = true
        win.contentView = view

        let thick: CGFloat = 7
        let r: CGFloat = 16
        let inset: CGFloat = 8
        let rect = CGRect(x: inset, y: inset, width: frame.width - inset * 2, height: frame.height - inset * 2)
        let dur = 1.4

        let sides: [(cw: Bool, color: CGColor)] = [
            (true,  CGColor(red: 0.0,  green: 0.55, blue: 1.0,  alpha: 1)),  // electric blue
            (false, CGColor(red: 0.75, green: 0.1,  blue: 1.0,  alpha: 1)),  // electric purple
        ]

        var coreLayers: [CAShapeLayer] = []
        var glowLayers: [CAShapeLayer] = []

        for side in sides {
            let path = halfEdgePath(rect: rect, r: r, clockwise: side.cw)

            // Wide soft outer glow — no shadow, wide stroke IS the glow
            let glow = CAShapeLayer()
            glow.path = path; glow.fillColor = nil
            glow.strokeColor = side.color.copy(alpha: 0.3)
            glow.lineWidth = thick * 6; glow.lineCap = .round; glow.strokeEnd = 0

            // Crisp core line
            let core = CAShapeLayer()
            core.path = path; core.fillColor = nil
            core.strokeColor = side.color
            core.lineWidth = thick; core.lineCap = .round; core.strokeEnd = 0

            // Bright white leading tip
            let tip = CAShapeLayer()
            tip.path = path; tip.fillColor = nil
            tip.strokeColor = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
            tip.lineWidth = thick + 2; tip.lineCap = .round
            tip.strokeStart = 0; tip.strokeEnd = 0.05

            view.layer!.addSublayer(glow)
            view.layer!.addSublayer(core)
            view.layer!.addSublayer(tip)

            // Trail draws in as spark travels
            glow.add(strokeAnim(keyPath: "strokeEnd", from: 0, to: 1, duration: dur), forKey: "trail")
            core.add(strokeAnim(keyPath: "strokeEnd", from: 0, to: 1, duration: dur), forKey: "trail")

            // Tip rides ahead of the trail
            let tipGroup = CAAnimationGroup()
            tipGroup.animations = [
                strokeAnim(keyPath: "strokeStart", from: 0.00, to: 0.95, duration: dur),
                strokeAnim(keyPath: "strokeEnd",   from: 0.05, to: 1.00, duration: dur),
            ]
            tipGroup.duration = dur
            tipGroup.fillMode = .forwards; tipGroup.isRemovedOnCompletion = false
            tip.add(tipGroup, forKey: "tipMove")

            coreLayers.append(core)
            glowLayers.append(glow)
        }

        // Flash burst where the two arcs meet (top-right corner)
        let flashSize: CGFloat = 40
        let flash = CALayer()
        flash.frame = CGRect(x: rect.maxX - r - flashSize / 2, y: rect.maxY - flashSize / 2,
                             width: flashSize, height: flashSize)
        flash.cornerRadius = flashSize / 2
        flash.backgroundColor = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
        flash.shadowColor = CGColor(red: 0.7, green: 0.85, blue: 1, alpha: 1)
        flash.shadowRadius = 25; flash.shadowOpacity = 1.0; flash.shadowOffset = .zero
        flash.opacity = 0
        view.layer!.addSublayer(flash)

        DispatchQueue.main.asyncAfter(deadline: .now() + dur) {
            let flashGroup = CAAnimationGroup()
            let scaleAnim = CABasicAnimation(keyPath: "transform.scale")
            scaleAnim.fromValue = 0.3; scaleAnim.toValue = 3.5
            let opacAnim = CABasicAnimation(keyPath: "opacity")
            opacAnim.fromValue = 1.0; opacAnim.toValue = 0.0
            flashGroup.animations = [scaleAnim, opacAnim]
            flashGroup.duration = 0.45
            flashGroup.fillMode = .forwards; flashGroup.isRemovedOnCompletion = false
            flash.add(flashGroup, forKey: "flash")

            // Trails pulse after meeting
            let pulse = CABasicAnimation(keyPath: "opacity")
            pulse.fromValue = 1.0; pulse.toValue = 0.35
            pulse.duration = 0.4; pulse.autoreverses = true; pulse.repeatCount = 3
            coreLayers.forEach { $0.add(pulse, forKey: "pulse") }
            glowLayers.forEach { $0.add(pulse, forKey: "pulse") }
        }

        win.makeKeyAndOrderFront(nil)
        windows.append(win)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            win.animator().alphaValue = 1.0
        }
    }
}

let delegate = EdgeLightningDelegate()
app.delegate = delegate
app.run()
