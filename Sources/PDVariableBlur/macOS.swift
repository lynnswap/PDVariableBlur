//
//  macOS.swift
//  PDVariableBlur
//
//  Created by lynnswap on 2025/05/18.
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        VariableBlurContainer(blurRadius: 20, padding: 0) {
            // ここに “ぼかしたい” SwiftUI コンテンツを書く
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
/// ぼかしたい SwiftUI コンテンツを中に入れるコンテナ
public struct VariableBlurContainer<Content: View>: NSViewRepresentable {

    var blurRadius: CGFloat = 20
    var padding:    CGFloat = 0
    @ViewBuilder var content: () -> Content

    // －－ NSViewRepresentable －－
    public func makeNSView(context: Context) -> FilterView {
        let filterView = FilterView()
        filterView.blurRadius = blurRadius
        filterView.padding    = padding

        // 中身（SwiftUI）を NSHostingView で挿入
        let hosting = NSHostingView(rootView: content())
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
        view.blurRadius = blurRadius
        view.padding    = padding
    }
}

public class FilterView: NSView {
    
    public var blurRadius: CGFloat = 50 {
        didSet { needsDisplay = true }      // 値が変わったら再描画
    }
    public var padding: CGFloat = 0 {
        didSet { needsDisplay = true }
    }
    
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
        guard let ctx = CGContext(data: nil,
                                  width: Int(round(size.width)),
                                  height: Int(round(size.height)),
                                  bitsPerComponent: 8,
                                  bytesPerRow: 0,
                                  space: CGColorSpaceCreateDeviceGray(),
                                  bitmapInfo: CGImageAlphaInfo.none.rawValue)
        else { return nil }
        
        /*
         The effect range seems to depend on the bounds of the window, even if the size of the NSView is changed.
         */
        
        let colors: [NSColor] = [
            .black,
            .black,
            .black,
            .white,
        ]
        let cgcolors = colors.map { $0.cgColor } as CFArray
        
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceGray(),
                                        colors: cgcolors,
                                        locations: nil)
        else { return nil }
        
        ctx.drawLinearGradient(gradient,
                               start: CGPoint(x: 0, y: -padding),
                               end: CGPoint(x: 0, y: size.height + padding),
                               options: []) //[.drawsBeforeStartLocation, .drawsAfterEndLocation])
        
        guard let image = ctx.makeImage()
        else { return nil }
        
        return CIImage(cgImage: image)
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
