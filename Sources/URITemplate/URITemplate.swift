import Foundation

/// A URI Template implementation following RFC 6570
public struct URITemplate: Sendable {
    private let template: String
    private let components: [Component]

    /// Initialize a URI Template from a template string
    public init(_ template: String) throws {
        self.template = template
        self.components = try Self.parseTemplate(template)
    }

    /// Expand the template with the provided variables
    public func expand(with variables: [String: VariableValue]) -> String {
        components.map { component in
            switch component {
            case .literal(let text):
                return text
            case .expression(let expr):
                return expr.expand(with: variables)
            }
        }.joined()
    }
}

// MARK: - Component Types

private enum Component: Sendable {
    case literal(String)
    case expression(Expression)
}

private struct Expression: Sendable {
    let `operator`: Operator
    let variables: [VariableSpec]

    func expand(with variables: [String: VariableValue]) -> String {
        let expandedValues: [String] = self.variables.compactMap { spec in
            guard let value = variables[spec.name] else { return nil }
            return spec.expandValue(value, with: `operator`)
        }

        guard !expandedValues.isEmpty else { return "" }

        return `operator`.formatExpansion(expandedValues)
    }
}

private struct VariableSpec: Sendable {
    let name: String
    let modifier: Modifier?

    func expandValue(_ value: VariableValue, with operator: Operator) -> String? {
        switch value {
        case .string(let str):
            return expandString(str, with: `operator`)
        case .list(let items):
            return expandList(items, with: `operator`)
        case .associativeArray(let pairs):
            return expandAssociativeArray(pairs, with: `operator`)
        }
    }

    private func expandString(_ string: String, with operator: Operator) -> String? {
        // For path expansion, empty strings should still contribute a path segment
        if string.isEmpty {
            switch `operator` {
            case .path:
                return ""
            case .simple, .reserved, .fragment, .label:
                return ""
            case .pathStyle, .query, .queryContinuation:
                // Empty strings should still be included for these operators
                let encoded = `operator`.encodeValue(string)
                return `operator`.formatVariable(name: name, value: encoded)
            }
        }

        let encoded = `operator`.encodeValue(string)
        let truncated = applyModifier(encoded)

        return `operator`.formatVariable(name: name, value: truncated)
    }

    private func expandList(_ items: [String], with operator: Operator) -> String? {
        guard !items.isEmpty else { return nil }

        let encodedItems = items.map { `operator`.encodeValue($0) }

        if let modifier = modifier, case .explode = modifier {
            let formatted = encodedItems.map { `operator`.formatVariable(name: name, value: $0) }
            return formatted.joined(separator: `operator`.separator)
        } else {
            let joined = encodedItems.joined(separator: ",")
            return `operator`.formatVariable(name: name, value: joined)
        }
    }

    private func expandAssociativeArray(_ pairs: [(String, String)], with operator: Operator)
        -> String?
    {
        guard !pairs.isEmpty else { return nil }

        if let modifier = modifier, case .explode = modifier {
            let formatted = pairs.map { key, value in
                let encodedKey = `operator`.encodeValue(key)
                let encodedValue = `operator`.encodeValue(value)
                return `operator`.formatKeyValue(key: encodedKey, value: encodedValue)
            }
            return formatted.joined(separator: `operator`.separator)
        } else {
            let joined = pairs.map { key, value in
                let encodedKey = `operator`.encodeValue(key)
                let encodedValue = `operator`.encodeValue(value)
                return "\(encodedKey),\(encodedValue)"
            }.joined(separator: ",")
            return `operator`.formatVariable(name: name, value: joined)
        }
    }

    private func applyModifier(_ value: String) -> String {
        guard let modifier = modifier else { return value }
        switch modifier {
        case .prefix(let maxLength):
            return String(value.prefix(maxLength))
        case .explode:
            return value
        }
    }
}

private enum Modifier: Sendable {
    case prefix(Int)
    case explode
}

// MARK: - Operators

private enum Operator: Sendable {
    case simple
    case reserved
    case fragment
    case label
    case path
    case pathStyle
    case query
    case queryContinuation

    var includesEmpty: Bool {
        switch self {
        case .pathStyle, .query, .queryContinuation:
            return true
        default:
            return false
        }
    }

    var separator: String {
        switch self {
        case .simple, .reserved, .fragment:
            return ","
        case .label:
            return "."
        case .path:
            return "/"
        case .pathStyle:
            return ";"
        case .query, .queryContinuation:
            return "&"
        }
    }

    var prefix: String {
        switch self {
        case .simple:
            return ""
        case .reserved:
            return ""
        case .fragment:
            return "#"
        case .label:
            return "."
        case .path:
            return "/"
        case .pathStyle:
            return ";"
        case .query:
            return "?"
        case .queryContinuation:
            return "&"
        }
    }

    private static let unreservedCharacters = CharacterSet.alphanumerics.union(
        CharacterSet(charactersIn: "-._~"))
    private static let reservedCharacters = CharacterSet(charactersIn: ":/?#[]@!$&'()*+,;=")

    func encodeValue(_ value: String) -> String {
        switch self {
        case .simple, .label, .path, .pathStyle, .query, .queryContinuation:
            return value.addingPercentEncoding(withAllowedCharacters: Self.unreservedCharacters)
                ?? value
        case .reserved, .fragment:
            // For reserved and fragment, we don't encode reserved characters
            return value.addingPercentEncoding(
                withAllowedCharacters: Self.unreservedCharacters.union(Self.reservedCharacters))
                ?? value
        }
    }

    func formatExpansion(_ values: [String]) -> String {
        guard !values.isEmpty else { return "" }
        return prefix + values.joined(separator: separator)
    }

    func formatVariable(name: String, value: String) -> String {
        switch self {
        case .simple, .reserved, .fragment, .label, .path:
            return value
        case .pathStyle:
            return value.isEmpty ? name : "\(name)=\(value)"
        case .query, .queryContinuation:
            return "\(name)=\(value)"
        }
    }

    func formatKeyValue(key: String, value: String) -> String {
        switch self {
        case .simple, .reserved, .fragment, .label, .path:
            return "\(key)=\(value)"
        case .pathStyle, .query, .queryContinuation:
            return "\(key)=\(value)"
        }
    }
}

// MARK: - Variable Values

/// Represents a variable value that can be expanded in a URI template
public enum VariableValue: Sendable {
    case string(String)
    case list([String])
    case associativeArray([(String, String)])
}

extension VariableValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension VariableValue: ExpressibleByStringInterpolation {
    public init(stringInterpolation value: DefaultStringInterpolation) {
        self = .string(String(stringInterpolation: value))
    }
}

extension VariableValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: String...) {
        self = .list(elements)
    }
}

extension VariableValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, String)...) {
        self = .associativeArray(elements)
    }
}

// MARK: - Parsing

public enum URITemplateError: Error, Sendable {
    case malformedExpression(String)
    case invalidVariableName(String)
    case invalidModifier(String)
    case unexpectedCharacter(Character, position: Int)
}

extension URITemplate {
    private static func parseTemplate(_ template: String) throws -> [Component] {
        var components: [Component] = []
        var currentLiteral = ""
        var index = template.startIndex

        while index < template.endIndex {
            let char = template[index]

            if char == "{" {
                // Check if this is an escaped brace (preceded by backslash)
                let isEscaped = !currentLiteral.isEmpty && currentLiteral.last == "\\"

                if isEscaped {
                    // Treat as literal, don't parse as expression
                    currentLiteral.append(char)
                    index = template.index(after: index)
                } else {
                    if !currentLiteral.isEmpty {
                        components.append(.literal(currentLiteral))
                        currentLiteral = ""
                    }

                    let (expression, nextIndex) = try parseExpression(template, startingAt: index)
                    components.append(.expression(expression))
                    index = nextIndex
                }
            } else if char == "}" {
                // Check if this is an escaped brace (preceded by backslash)
                let isEscaped = !currentLiteral.isEmpty && currentLiteral.last == "\\"

                if isEscaped {
                    // Treat as literal
                    currentLiteral.append(char)
                    index = template.index(after: index)
                } else {
                    // Lone closing brace should throw an error
                    throw URITemplateError.unexpectedCharacter(
                        char, position: template.distance(from: template.startIndex, to: index))
                }
            } else {
                currentLiteral.append(char)
                index = template.index(after: index)
            }
        }

        if !currentLiteral.isEmpty {
            components.append(.literal(currentLiteral))
        }

        return components
    }

    private static func parseExpression(_ template: String, startingAt startIndex: String.Index)
        throws -> (Expression, String.Index)
    {
        guard startIndex < template.endIndex && template[startIndex] == "{" else {
            throw URITemplateError.malformedExpression("Expected '{'")
        }

        var index = template.index(after: startIndex)
        var expressionContent = ""

        while index < template.endIndex {
            let char = template[index]
            if char == "}" {
                break
            }
            expressionContent.append(char)
            index = template.index(after: index)
        }

        guard index < template.endIndex && template[index] == "}" else {
            throw URITemplateError.malformedExpression("Unclosed expression")
        }

        let nextIndex = template.index(after: index)
        let expression = try parseExpressionContent(expressionContent)

        return (expression, nextIndex)
    }

    private static func parseExpressionContent(_ content: String) throws -> Expression {
        guard !content.isEmpty else {
            throw URITemplateError.malformedExpression("Empty expression")
        }

        let (op, variableList) = try parseOperatorAndVariables(content)
        let variables = try parseVariableList(variableList)

        return Expression(operator: op, variables: variables)
    }

    private static func parseOperatorAndVariables(_ content: String) throws -> (Operator, String) {
        let firstChar = content.first!

        switch firstChar {
        case "+":
            let remaining = String(content.dropFirst())
            // Check for invalid double operators like ++
            if remaining.first == "+" {
                throw URITemplateError.malformedExpression("Invalid operator sequence: ++")
            }
            return (.reserved, remaining)
        case "#":
            return (.fragment, String(content.dropFirst()))
        case ".":
            return (.label, String(content.dropFirst()))
        case "/":
            return (.path, String(content.dropFirst()))
        case ";":
            return (.pathStyle, String(content.dropFirst()))
        case "?":
            return (.query, String(content.dropFirst()))
        case "&":
            return (.queryContinuation, String(content.dropFirst()))
        case "@":
            // @ is not a valid operator in RFC 6570
            throw URITemplateError.malformedExpression("Invalid operator: @")
        default:
            return (.simple, content)
        }
    }

    private static func parseVariableList(_ variableList: String) throws -> [VariableSpec] {
        // Disallow empty variable list
        if variableList.trimmingCharacters(in: .whitespaces).isEmpty {
            throw URITemplateError.malformedExpression("Empty variable list")
        }
        let variables = variableList.split(separator: ",", omittingEmptySubsequences: false).map(
            String.init)
        // Disallow any empty variable names
        if variables.contains(where: { $0.trimmingCharacters(in: .whitespaces).isEmpty }) {
            throw URITemplateError.malformedExpression("Empty variable name")
        }
        return try variables.map { try parseVariableSpec($0) }
    }

    private static func parseVariableSpec(_ spec: String) throws -> VariableSpec {
        let trimmed = spec.trimmingCharacters(in: .whitespaces)

        if trimmed.hasSuffix("*") {
            let name = String(trimmed.dropLast())
            guard isValidVariableName(name) else {
                throw URITemplateError.invalidVariableName(name)
            }
            return VariableSpec(name: name, modifier: .explode)
        } else if let colonIndex = trimmed.lastIndex(of: ":") {
            let name = String(trimmed[..<colonIndex])
            let maxLengthStr = String(trimmed[trimmed.index(after: colonIndex)...])

            guard isValidVariableName(name) else {
                throw URITemplateError.invalidVariableName(name)
            }

            guard let maxLength = Int(maxLengthStr), maxLength > 0 else {
                throw URITemplateError.invalidModifier(maxLengthStr)
            }

            return VariableSpec(name: name, modifier: .prefix(maxLength))
        } else {
            guard isValidVariableName(trimmed) else {
                throw URITemplateError.invalidVariableName(trimmed)
            }
            return VariableSpec(name: trimmed, modifier: nil)
        }
    }

    private static func isValidVariableName(_ name: String) -> Bool {
        guard !name.isEmpty else { return false }

        // Check for valid percent encoding if present
        if name.contains("%") {
            return isValidPercentEncoded(name)
        }

        // RFC 6570 allows: ALPHA / DIGIT / "_" / pct-encoded
        // Also allow Unicode characters for internationalization, but exclude problematic characters
        return name.allSatisfy { char in
            char.isLetter || char.isNumber || char == "_" || char == "." || char == "%"
                || (char.unicodeScalars.count == 1 && char.unicodeScalars.first!.value > 127)  // Allow Unicode above ASCII
        }
    }

    private static func isValidPercentEncoded(_ name: String) -> Bool {
        var index = name.startIndex

        while index < name.endIndex {
            let char = name[index]

            if char == "%" {
                // Need exactly 2 more characters for hex encoding
                let nextIndex = name.index(index, offsetBy: 1, limitedBy: name.endIndex)
                guard let nextIndex = nextIndex else { return false }

                let afterHexIndex = name.index(index, offsetBy: 3, limitedBy: name.endIndex)
                guard let afterHexIndex = afterHexIndex else { return false }

                let hexString = String(name[nextIndex..<afterHexIndex])

                // Check if it's valid hex (exactly 2 characters)
                guard hexString.count == 2 && hexString.allSatisfy({ $0.isHexDigit }) else {
                    return false
                }

                // Move to the character after the percent sequence
                index = afterHexIndex
            } else {
                // Regular character validation - allow more characters for RFC 6570
                guard char.isLetter || char.isNumber || char == "_" || char == "." else {
                    return false
                }
                index = name.index(after: index)
            }
        }

        return true
    }
}
