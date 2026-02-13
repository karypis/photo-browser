import SwiftUI
import AppKit

struct LightboxImageView: NSViewRepresentable {
    let image: NSImage
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    var rotation: Int  // 0, 90, 180, 270
    var onZoomChanged: () -> Void

    func makeNSView(context: Context) -> LightboxNSView {
        let view = LightboxNSView()
        view.delegate = context.coordinator
        view.displayImage = image
        view.rotationDegrees = rotation
        return view
    }

    func updateNSView(_ nsView: LightboxNSView, context: Context) {
        var needsRedraw = false

        if nsView.displayImage !== image {
            nsView.displayImage = image
            nsView.scale = 1.0
            nsView.translateX = 0
            nsView.translateY = 0
            needsRedraw = true
        }

        if nsView.rotationDegrees != rotation {
            nsView.rotationDegrees = rotation
            needsRedraw = true
        }

        // Sync from SwiftUI state
        if abs(nsView.scale - scale) > 0.001 && !nsView.isUserInteracting {
            nsView.scale = scale
            nsView.translateX = offset.width
            nsView.translateY = offset.height
            nsView.constrainPan()
            needsRedraw = true
        }

        if needsRedraw { nsView.needsDisplay = true }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator {
        var parent: LightboxImageView
        init(_ parent: LightboxImageView) { self.parent = parent }

        func didChangeZoom(scale: CGFloat, tx: CGFloat, ty: CGFloat) {
            parent.scale = scale
            parent.offset = CGSize(width: tx, height: ty)
            parent.onZoomChanged()
        }
    }
}

class LightboxNSView: NSView {
    var displayImage: NSImage?
    var scale: CGFloat = 1.0
    var translateX: CGFloat = 0
    var translateY: CGFloat = 0
    var rotationDegrees: Int = 0
    weak var delegate: LightboxImageView.Coordinator?
    var isUserInteracting = false

    private var isDragging = false
    private var didDrag = false
    private var dragStartPoint: NSPoint = .zero
    private var dragStartTx: CGFloat = 0
    private var dragStartTy: CGFloat = 0

    private let minScale: CGFloat = 0.5
    private let maxScale: CGFloat = 20.0
    private let zoomStep: CGFloat = 1.15

    override var acceptsFirstResponder: Bool { false }
    override var isFlipped: Bool { true }

    /// Image dimensions after rotation (swapped at 90/270)
    private var rotatedImageSize: NSSize {
        guard let image = displayImage else { return .zero }
        let isRotated90 = (rotationDegrees == 90 || rotationDegrees == 270)
        if isRotated90 {
            return NSSize(width: image.size.height, height: image.size.width)
        }
        return image.size
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let image = displayImage, let ctx = NSGraphicsContext.current?.cgContext else { return }

        NSColor.clear.setFill()
        dirtyRect.fill()

        let viewW = bounds.width
        let viewH = bounds.height
        let rSize = rotatedImageSize

        // Fit rotated image to view
        let fitScale = min(viewW / rSize.width, viewH / rSize.height, 1.0)

        let cx = viewW / 2 + translateX
        let cy = viewH / 2 + translateY

        ctx.saveGState()

        // Move origin to center of where the image should be
        ctx.translateBy(x: cx, y: cy)

        // Apply rotation (negative because CG is counterclockwise)
        let radians = -CGFloat(rotationDegrees) * .pi / 180
        ctx.rotate(by: radians)

        // Draw image centered at origin (pre-rotation dimensions)
        let origFittedW = image.size.width * fitScale * scale
        let origFittedH = image.size.height * fitScale * scale
        let destRect = NSRect(
            x: -origFittedW / 2,
            y: -origFittedH / 2,
            width: origFittedW,
            height: origFittedH
        )

        // Need to flip for the image since we're drawing in a flipped context
        ctx.translateBy(x: 0, y: 0)
        ctx.scaleBy(x: 1, y: -1)

        image.draw(
            in: NSRect(x: destRect.origin.x, y: -destRect.origin.y - destRect.height, width: destRect.width, height: destRect.height),
            from: NSRect(origin: .zero, size: image.size),
            operation: .sourceOver,
            fraction: 1.0
        )

        ctx.restoreGState()
    }

    // MARK: - Computed

    var fittedSize: NSSize {
        let rSize = rotatedImageSize
        guard rSize.width > 0, rSize.height > 0 else { return .zero }
        let fitScale = min(bounds.width / rSize.width, bounds.height / rSize.height, 1.0)
        return NSSize(width: rSize.width * fitScale, height: rSize.height * fitScale)
    }

    private var hundredPercentScale: CGFloat {
        let rSize = rotatedImageSize
        let fitted = fittedSize
        guard fitted.width > 0 else { return 1 }
        return rSize.width / fitted.width
    }

    // MARK: - Constraint

    func constrainPan() {
        let fitted = fittedSize
        let scaledW = fitted.width * scale
        let scaledH = fitted.height * scale
        let maxTx = max(0, (scaledW - bounds.width) / 2)
        let maxTy = max(0, (scaledH - bounds.height) / 2)
        translateX = max(-maxTx, min(maxTx, translateX))
        translateY = max(-maxTy, min(maxTy, translateY))
    }

    // MARK: - Zoom toward point

    private func zoomTo(_ newScale: CGFloat, centerX cx: CGFloat, centerY cy: CGFloat) {
        let clamped = max(minScale, min(maxScale, newScale))
        let ratio = clamped / scale
        translateX = cx * (1 - ratio) + translateX * ratio
        translateY = cy * (1 - ratio) + translateY * ratio
        scale = clamped
        constrainPan()
        needsDisplay = true
        notifyDelegate()
    }

    private func notifyDelegate() {
        delegate?.didChangeZoom(scale: scale, tx: translateX, ty: translateY)
    }

    // MARK: - Scroll wheel zoom

    override func scrollWheel(with event: NSEvent) {
        isUserInteracting = true
        defer { isUserInteracting = false }

        let location = convert(event.locationInWindow, from: nil)
        let cx = location.x - bounds.midX
        let cy = location.y - bounds.midY
        let factor = event.scrollingDeltaY > 0 ? zoomStep : 1 / zoomStep
        zoomTo(scale * factor, centerX: cx, centerY: cy)
    }

    // MARK: - Trackpad pinch zoom

    override func magnify(with event: NSEvent) {
        isUserInteracting = true
        defer { isUserInteracting = false }

        let location = convert(event.locationInWindow, from: nil)
        let cx = location.x - bounds.midX
        let cy = location.y - bounds.midY
        zoomTo(scale * (1 + event.magnification), centerX: cx, centerY: cy)
    }

    // MARK: - Click: toggle fit / 100%

    override func mouseUp(with event: NSEvent) {
        isUserInteracting = true
        defer { isUserInteracting = false }

        if isDragging {
            isDragging = false
            if didDrag { return }
        }

        let s100 = hundredPercentScale
        if abs(scale - 1.0) < 0.01 && s100 > 1.05 {
            // Zoom to 100%
            let location = convert(event.locationInWindow, from: nil)
            let cx = location.x - bounds.midX
            let cy = location.y - bounds.midY
            zoomTo(s100, centerX: cx, centerY: cy)
        } else {
            // Reset to fit
            scale = 1.0
            translateX = 0
            translateY = 0
            constrainPan()
            needsDisplay = true
            notifyDelegate()
        }
    }

    // MARK: - Mouse drag pan

    override func mouseDown(with event: NSEvent) {
        guard scale > 1.01 else { return }
        isDragging = true
        didDrag = false
        dragStartPoint = convert(event.locationInWindow, from: nil)
        dragStartTx = translateX
        dragStartTy = translateY
    }

    override func mouseDragged(with event: NSEvent) {
        guard isDragging else { return }
        isUserInteracting = true

        let current = convert(event.locationInWindow, from: nil)
        let dx = current.x - dragStartPoint.x
        let dy = current.y - dragStartPoint.y
        if abs(dx) > 3 || abs(dy) > 3 { didDrag = true }

        translateX = dragStartTx + dx
        translateY = dragStartTy + dy
        constrainPan()
        needsDisplay = true
        notifyDelegate()

        isUserInteracting = false
    }
}
