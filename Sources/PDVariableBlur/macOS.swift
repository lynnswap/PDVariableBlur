//
//  macOS.swift
//  PDVariableBlur
//
//  Created by lynnswap on 2025/05/18.
//

import SwiftUI
#if os(macOS)
struct ContentView: View {
    @State private var isEnabled:Bool = true
    var body: some View {
        VariableBlurContainer(
            blurRadius: 20,
            blurLength: 100,
            edge:.bottom,
            padding: 0,
            isEnabled:isEnabled
        ) {
            List(0..<50, id: \.self) { i in
                Text("Row \(i)")
                    .frame(maxWidth:.infinity,alignment: .center)
            }
            .listStyle(.sidebar)
            .toolbar{
                ToolbarItem(placement:.primaryAction){
                    Toggle(isOn:$isEnabled){
                        Text(String("enabled"))
                    }
                }
            }
        }
    }
}
#Preview{
    ContentView()
}
public enum BlurEdge {
    case top      // ビュー上端側をぼかす
    case bottom   // ビュー下端側をぼかす
}

public struct VariableBlurContainer<Content: View>: NSViewRepresentable {
    
    
    var blurRadius:  CGFloat
    var blurLength:  CGFloat
    var edge: BlurEdge
    var padding: CGFloat = 0
    var isEnabled: Bool = true
    @ViewBuilder var content: () -> Content
    public init(
        blurRadius: CGFloat,
        blurLength:  CGFloat = 120,
        edge:BlurEdge,
        padding: CGFloat,
        isEnabled:Bool = true,
        content: @escaping () -> Content
    ) {
        self.blurRadius = blurRadius
        self.blurLength = blurLength
        self.edge = edge
        self.padding = padding
        self.isEnabled = isEnabled
        self.content = content
    }
    // Coordinator がオーバーレイへの参照を保持
    public class Coordinator {
        weak var overlay: FilterOverlayView?
        weak var hosting: NSHostingView<Content>?
    }
    public func makeCoordinator() -> Coordinator { Coordinator() }
    public func makeNSView(context: Context) -> NSView {
        
        let root = NSView()
        root.wantsLayer = true
        
        // (1) コンテンツ
        let host = NSHostingView(rootView: content())
        host.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(host)
        NSLayoutConstraint.activate([
            host.leadingAnchor .constraint(equalTo: root.leadingAnchor),
            host.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            host.topAnchor     .constraint(equalTo: root.topAnchor),
            host.bottomAnchor  .constraint(equalTo: root.bottomAnchor)
        ])
        let overlay = FilterOverlayView()
        // (2) オーバーレイ
        overlay.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(overlay)
        
        // ＝＝＝ blurLength を直接使用 ＝＝＝＝
        switch edge {
        case .top:
            NSLayoutConstraint.activate([
                overlay.leadingAnchor .constraint(equalTo: root.leadingAnchor),
                overlay.trailingAnchor.constraint(equalTo: root.trailingAnchor),
                overlay.topAnchor     .constraint(equalTo: root.topAnchor),
                overlay.heightAnchor  .constraint(equalToConstant: blurLength)
            ])
        case .bottom:
            NSLayoutConstraint.activate([
                overlay.leadingAnchor .constraint(equalTo: root.leadingAnchor),
                overlay.trailingAnchor.constraint(equalTo: root.trailingAnchor),
                overlay.bottomAnchor  .constraint(equalTo: root.bottomAnchor),
                overlay.heightAnchor  .constraint(equalToConstant: blurLength)
            ])
        }
        overlay.blurRadius = blurRadius
        overlay.blurLength = blurLength
        overlay.edge       = edge
        overlay.padding    = padding
        overlay.isHidden   = !isEnabled
        
        context.coordinator.hosting = host
        context.coordinator.overlay = overlay
        return root
    }
    
    public func updateNSView(_ root: NSView, context: Context) {
        context.coordinator.hosting?.rootView = content()
        if let overlay = context.coordinator.overlay {
            overlay.isHidden = !isEnabled
        }
    }
}
public final class FilterOverlayView: NSView {

    var blurRadius: CGFloat = 20   { didSet { updateFilter() } }
    var blurLength: CGFloat = 120  { didSet { updateFilter() } }
    var edge: BlurEdge = .bottom   { didSet { updateFilter() } }
    var padding: CGFloat = 0       { didSet { updateFilter() } }

    public override var wantsUpdateLayer: Bool { true }
    public override func updateLayer() { updateFilter() }

    private func updateFilter() {
        guard bounds.width > 0, bounds.height > 0 else { return }

        let f = CIFilter(name: "CIMaskedVariableBlur")!
        f.setDefaults()
        f.setValue(verticalGradient(size: bounds.size), forKey: "inputMask")
        f.setValue(blurRadius, forKey: kCIInputRadiusKey)

        // ▼ 背面だけに効かせる
        layerUsesCoreImageFilters = true
        layer?.backgroundFilters = [f]   // ← ここが change!
    }

    /// マスク生成（縦グラデーション）
    private func verticalGradient(size: CGSize) -> CIImage? {
        
        let total = size.height + padding * 2          // 描画範囲
        let ratio = max(0, min(1, blurLength / total)) // 0‥1 に正規化
        // ratio=0 → ブラー無し / 1 → 全面ブラー
        
        guard let ctx = CGContext(
            data: nil,
            width:  Int(round(size.width)),
            height: Int(round(size.height)),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue)
        else { return nil }
        
        // 3 ストップ： 白 → 黒 → 黒
        let colors: [NSColor] = [
            .black,
            .black,
            .black,
            .white,
        ]
        let locs:   [CGFloat] = [0.0,   ratio, 1.0]
        
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceGray(),
            colors: colors.map(\.cgColor) as CFArray,
            locations: locs)
        else { return nil }
        
        // edge に応じて start / end を反転
        let startY: CGFloat = (edge == .bottom) ? -padding              : size.height + padding
        let endY:   CGFloat = (edge == .bottom) ? size.height + padding : -padding
        
        ctx.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: startY),
            end:   CGPoint(x: 0, y: endY),
            options: [])
        
        guard let cgImage = ctx.makeImage() else { return nil }
        return CIImage(cgImage: cgImage)
    }
}
public class FilterView: NSView {
    
    public var blurRadius: CGFloat = 50  { didSet { needsDisplay = true } }
    public var blurLength: CGFloat = 120 { didSet { needsDisplay = true } }
    public var edge: BlurEdge     = .top { didSet { needsDisplay = true } }
    public var padding: CGFloat   = 0    { didSet { needsDisplay = true } }
    public var isEnabled: Bool = true    { didSet { needsDisplay = true } }
    
    // MARK: - layer 更新モードを宣言
    /// draw(_:) ではなく updateLayer() を呼ばせる
    public override var wantsUpdateLayer: Bool { true }
    
    func prepare() {
        wantsLayer = true
        layerUsesCoreImageFilters = true
        layerContentsRedrawPolicy = .onSetNeedsDisplay
        layer?.backgroundColor = NSColor.clear.cgColor
        
        if isEnabled{
            setVariableBlur(blurRadius)
        }else{
            self.layer?.filters = nil
        }
       
    }
    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        wantsLayer                   = true
        layerUsesCoreImageFilters    = true   // ← これを必ず true に
        layerContentsRedrawPolicy    = .onSetNeedsDisplay
        layer?.isOpaque              = false
        needsDisplay = true
    }
    public override func layout() {
        super.layout()
        needsDisplay = true
    }
    
    public override func updateLayer() {
        super.updateLayer()
        guard bounds.width > 0, bounds.height > 0 else { return }
        if isEnabled{
            setVariableBlur(blurRadius)
        }else{
            self.layer?.filters = nil
        }
    }
    private func verticalGradient(size: CGSize) -> CIImage? {
        
        let total = size.height + padding * 2          // 描画範囲
        let ratio = max(0, min(1, blurLength / total)) // 0‥1 に正規化
        // ratio=0 → ブラー無し / 1 → 全面ブラー
        
        guard let ctx = CGContext(
            data: nil,
            width:  Int(round(size.width)),
            height: Int(round(size.height)),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue)
        else { return nil }
        
        // 3 ストップ： 白 → 黒 → 黒
        let colors: [NSColor] = [
            .black,
            .black,
            .black,
            .white,
        ]
        let locs:   [CGFloat] = [0.0,   ratio, 1.0]
        
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceGray(),
            colors: colors.map(\.cgColor) as CFArray,
            locations: locs)
        else { return nil }
        
        // edge に応じて start / end を反転
        let startY: CGFloat = (edge == .bottom) ? -padding              : size.height + padding
        let endY:   CGFloat = (edge == .bottom) ? size.height + padding : -padding
        
        ctx.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: startY),
            end:   CGPoint(x: 0, y: endY),
            options: [])
        
        guard let cgImage = ctx.makeImage() else { return nil }
        return CIImage(cgImage: cgImage)
    }
    
    private func setVariableBlur(_ radius: CGFloat) {
        if let filter = CIFilter(name: "CIMaskedVariableBlur") {
            filter.setDefaults()
            filter.setValue(verticalGradient(size: bounds.size), forKey: "inputMask")
            filter.setValue(radius, forKey: kCIInputRadiusKey)

            layer?.filters = [filter]
        }
    }
}
#endif
