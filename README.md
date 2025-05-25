# PDVariableBlur

PDVariableBlur provides a variable blur effect for SwiftUI views on iOS and macOS.

## Usage

### iOS

```swift
// You can use either `UIColor` or SwiftUI's `Color`
VariableBlurView(edge: .top,
                 tintColor: .black.opacity(0.3))
    .frame(height: 200)
```

### macOS

```swift
VariableBlurContainer(blurRadius: 20,
                      blurLength: 100,
                      edge: .bottom,
                      padding: 0) {
    // content
}
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
