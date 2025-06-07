# PDVariableBlur

PDVariableBlur provides a variable blur effect for SwiftUI views on iOS and macOS.

You can find a simple preview setup in `Sources/PDVariableBlur/Example.swift`. Open the **Examples** scheme in Xcode to view the preview.

## Usage

`variableBlur` can be used on any `View`:

```swift
ZStack {
    Color.black
    Rectangle()
        .fill(.white)
        .frame(width: 20)
}
.variableBlur(
    edge: .bottom,
    length: 150
)
.ignoresSafeArea()
```

### Parameters

The following values can be specified with `variableBlur`:

- `radius`: radius that controls the strength of the blur. Default is `20`.
- `edge`: a `VariableBlurEdge` indicating from which side the blur begins.
- `length`: length of the blurred region.
- `offset`: start position of the gradient, from `0` to `1`.
- `tint`: color overlay applied to the blurred area.
- `tintOpacity`: explicit opacity value for `tint`.
- `isEnabled`: toggles the overlay on and off. Default is `true`.

### VariableBlurView and VariableBlurViewRepresentable

`VariableBlurView` implements the variable blur using `UIVisualEffectView` or `NSView`.
`VariableBlurViewRepresentable` exposes this view to SwiftUI, and the `variableBlur` modifier uses it internally.

Install via Swift Package Manager and import `PDVariableBlur` in your project.

## Apps Using

<p float="left">
    <a href="https://apps.apple.com/jp/app/tweetpd/id1671411031"><img src="https://i.imgur.com/AC6eGdx.png" height="65"></a>
</p>

## License

PDVariableBlur is released under the MIT License. See [LICENSE](LICENSE) for details.
