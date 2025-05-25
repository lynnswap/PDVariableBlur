# PDVariableBlur

PDVariableBlur provides a variable blur effect for SwiftUI views on iOS and macOS.

## Usage

### iOS

```swift
VariableBlurView(direction: .top,
                 tintColor: UIColor.black.withAlphaComponent(0.3))
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

### Direction

`VariableBlurDirection` specifies from which edge the blur starts.

```swift
public enum VariableBlurDirection {
    case top      // blur starts at the top edge
    case bottom   // blur starts at the bottom edge
    case trailing // blur starts at the trailing edge
}
```

Install via Swift Package Manager and import `PDVariableBlur` in your project.
