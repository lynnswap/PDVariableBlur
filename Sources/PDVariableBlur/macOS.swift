//
//  macOS.swift
//  PDVariableBlur
//
//  Created by lynnswap on 2025/05/18.
//

import SwiftUI
#if os(macOS)
struct ContentView: View {
    
    var body: some View {
        VariableBlurContainer(
            blurRadius: 20,
            blurLength: 100,
            edge:.bottom,
            padding: 0
        ) {
            List(0..<50, id: \.self) { i in
                Text("Row \(i)")
                    .frame(maxWidth:.infinity,alignment: .center)
            }
            .listStyle(.sidebar)
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
/// ぼかしたい SwiftUI コンテンツを中に入れるコンテナ
public struct VariableBlurContainer<Content: View>: NSViewRepresentable {
    
    var blurRadius: CGFloat = 20
    var blurLength:  CGFloat
    var edge:BlurEdge
    var padding:    CGFloat = 0
    @ViewBuilder var content: () -> Content
    
    public init(
        blurRadius: CGFloat,
        blurLength:  CGFloat = 120,
        edge:BlurEdge,
        padding: CGFloat,
        content: @escaping () -> Content
    ) {
        self.blurRadius = blurRadius
        self.blurLength = blurLength
        self.edge = edge
        self.padding = padding
        self.content = content
    }
    
    public func makeNSView(context: Context) -> FilterView {
        let filterView = FilterView()
        filterView.blurRadius = blurRadius
        filterView.blurLength = blurLength
        filterView.edge       = edge
        filterView.padding    = padding
        
        // AnyView にラップすると型の制約を気にせず差し替えられる
        let hosting = NSHostingView(rootView: AnyView(content()))
        context.coordinator.hosting = hosting      // ← 保持
        
        hosting.translatesAutoresizingMaskIntoConstraints = false
        filterView.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.leadingAnchor .constraint(equalTo: filterView.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: filterView.trailingAnchor),
            hosting.topAnchor     .constraint(equalTo: filterView.topAnchor),
            hosting.bottomAnchor  .constraint(equalTo: filterView.bottomAnchor)
        ])
        return filterView
    }
    
    public func updateNSView(_ view: FilterView, context: Context) {
//        view.blurRadius = blurRadius
//        view.blurLength = blurLength
//        view.edge       = edge
//        view.padding    = padding
//        
        // ここで差し替えるだけで SwiftUI 側の最新状態を反映
        context.coordinator.hosting?.rootView = AnyView(content())
    }
    public class Coordinator {
        var hosting: NSHostingView<AnyView>?   // ← 参照を握る
    }
    public func makeCoordinator() -> Coordinator { Coordinator() }
}

public class FilterView: NSView {
    
    public var blurRadius: CGFloat = 50  { didSet { needsDisplay = true } }
    public var blurLength: CGFloat = 120 { didSet { needsDisplay = true } }
    public var edge: BlurEdge     = .top { didSet { needsDisplay = true } }
    public var padding: CGFloat   = 0    { didSet { needsDisplay = true } }
    
    // MARK: - layer 更新モードを宣言
    /// draw(_:) ではなく updateLayer() を呼ばせる
    public override var wantsUpdateLayer: Bool { true }
    
    func prepare() {
        wantsLayer = true
        layerUsesCoreImageFilters = true
        layerContentsRedrawPolicy = .onSetNeedsDisplay
        layer?.backgroundColor = NSColor.clear.cgColor
        
        setVariableBlur(blurRadius)
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
        setVariableBlur(blurRadius)
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
