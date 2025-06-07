# PDVariableBlur

PDVariableBlur provides a variable blur effect for SwiftUI views on iOS and macOS.

You can find a simple preview setup in `Sources/PDVariableBlur/Example.swift`.
Open the **Examples** scheme in Xcode to view the preview.

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
    radius: 60,
    edge: .top,
    length: 200,
    tint: .indigo
)
.variableBlur(
    edge: .bottom,
    length: 150,
    tint: .blue
)
.ignoresSafeArea()
```

### Edge

`VariableBlurEdge` specifies from which edge the blur starts.

```swift
public enum VariableBlurEdge {
    case top      // blur starts at the top edge
    case bottom   // blur starts at the bottom edge
    case trailing // blur starts at the trailing edge
    case leading  // blur starts at the leading edge
}
```

Install via Swift Package Manager and import `PDVariableBlur` in your project.

## License

PDVariableBlur is released under the MIT License. See [LICENSE](LICENSE) for details.
