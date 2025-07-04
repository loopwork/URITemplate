# URITemplate

A Swift implementation of URI Templates
that supports all four levels of the 
[RFC 6570 specification][rfc6570]:

<table>
    <tr>
        <th>Level 1: Simple String Expansion</th>
        <td>
            <ul>
                <li>Basic variable substitution: <code>{var}</code></li>
            </ul>
        </td>
    </tr>
    <tr>
        <th>Level 2: Reserved String Expansion</th>
        <td>
            <ul>
                <li>Reserved character expansion: <code>{+var}</code></li>
                <li>Fragment expansion: <code>{#var}</code></li>
            </ul>
        </td>
    </tr>
    <tr>
        <th>Level 3: Multiple Variable Expansion</th>
        <td>
            <ul>
                <li>Label expansion with dot-prefix: <code>{.var}</code></li>
                <li>Path segment expansion: <code>{/var}</code></li>
                <li>Path-style parameter expansion: <code>{;var}</code></li>
                <li>Query component expansion: <code>{?var}</code></li>
                <li>Query continuation: <code>{&var}</code></li>
            </ul>
        </td>
    </tr>
    <tr>
        <th>Level 4: Value Modifiers</th>
        <td>
            <ul>
                <li>String prefix: <code>{var:3}</code></li>
                <li>Variable explosion: <code>{var*}</code></li>
            </ul>
        </td>
    </tr>
</table>

## Requirements

* Swift 6+

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/loopwork/URITemplate.git", from: "1.0.0")
]
```

## Usage

### Basic Template Expansion

```swift
import URITemplate

// Simple variable expansion
let template = try URITemplate("https://api.example.com/users/{id}")
let result = template.expand(with: ["id": "123"])
// Result: "https://api.example.com/users/123"
```

### Expression Operators

```swift
// Reserved character expansion
let template = try URITemplate("https://example.com/{+path}")
let result = template.expand(with: ["path": "foo/bar"])
// Result: "https://example.com/foo/bar"

// Query parameters
let template = try URITemplate("https://example.com/search{?q,limit}")
let result = template.expand(with: ["q": "swift", "limit": "10"])
// Result: "https://example.com/search?q=swift&limit=10"

// Fragment expansion
let template = try URITemplate("https://example.com/page{#section}")
let result = template.expand(with: ["section": "introduction"])
// Result: "https://example.com/page#introduction"
```

### Variable Types

```swift
// String values
let variables: [String: VariableValue] = ["name": "Johnny Appleseed"]

// List values
let variables: [String: VariableValue] = ["tags": ["macOS", "iOS"]]

// Associative array values
let variables: [String: VariableValue] = [
    "params": [("key1", "value1"), ("key2", "value2")]
]
```

### Variable Modifiers

```swift
// Prefix modifier - truncate to specified length
let template = try URITemplate("/users/{name:3}")
let result = template.expand(with: ["name": "Jonathan"])
// Result: "/users/Jon"

// Explode modifier - expand list/associative array elements
let template = try URITemplate("/search{?tags*}")
let result = template.expand(with: ["tags": ["clean", "robust"]])
// Result: "/search?tags=clean&tags=robust"
```

### Template Introspection

```swift
// Get all variable names from a template
let template = try URITemplate("https://api.example.com/users/{id}/posts{?limit,offset}")
let variables = template.variables
// Result: ["id", "limit", "offset"]

// Works with all operators and modifiers
let template = try URITemplate("{name:3}{+path}{?query*}")
let variables = template.variables
// Result: ["name", "path", "query"]
```

### Error Handling

```swift
do {
    let template = try URITemplate("{unclosed")
} catch URITemplateError.malformedExpression(let message) {
    print("Template error: \(message)")
} catch URITemplateError.invalidVariableName(let name) {
    print("Invalid variable name: \(name)")
} catch URITemplateError.invalidModifier(let modifier) {
    print("Invalid modifier: \(modifier)")
}
```

## License

Apache License, Version 2.0. See [LICENSE](LICENSE) for details.

[rfc6570]: https://datatracker.ietf.org/doc/html/rfc6570