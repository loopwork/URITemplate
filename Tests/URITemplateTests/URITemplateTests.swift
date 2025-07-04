import Testing

@testable import URITemplate

@Suite("RFC 6570 Level 1: Simple String Expansion")
struct Level1Tests {

    @Test("Simple variable expansion")
    func simpleVariableExpansion() throws {
        let template = try URITemplate("{var}")
        let result = template.expand(with: ["var": "value"])
        #expect(result == "value")
    }

    @Test("Simple expansion with percent encoding")
    func simpleExpansionWithPercentEncoding() throws {
        let template = try URITemplate("{var}")
        let result = template.expand(with: ["var": "hello world"])
        #expect(result == "hello%20world")
    }

    @Test("Simple expansion with special characters")
    func simpleExpansionWithSpecialChars() throws {
        let template = try URITemplate("{var}")
        let result = template.expand(with: ["var": "foo/bar"])
        #expect(result == "foo%2Fbar")
    }

    @Test("Simple expansion with unicode")
    func simpleExpansionWithUnicode() throws {
        let template = try URITemplate("{var}")
        let result = template.expand(with: ["var": "café"])
        #expect(result == "caf%C3%A9")
    }

    @Test("Simple expansion with emoji")
    func simpleExpansionWithEmoji() throws {
        let template = try URITemplate("{var}")
        let result = template.expand(with: ["var": "hello 👋"])
        #expect(result == "hello%20%F0%9F%91%8B")
    }

    @Test("Simple expansion with already encoded characters")
    func simpleExpansionWithAlreadyEncodedChars() throws {
        let template = try URITemplate("{var}")
        let result = template.expand(with: ["var": "hello%20world"])
        #expect(result == "hello%2520world")
    }

    @Test("Simple expansion with undefined variable")
    func simpleExpansionWithUndefinedVariable() throws {
        let template = try URITemplate("{var}")
        let result = template.expand(with: [:])
        #expect(result == "")
    }

    @Test("Simple expansion with empty string")
    func simpleExpansionWithEmptyString() throws {
        let template = try URITemplate("{var}")
        let result = template.expand(with: ["var": ""])
        #expect(result == "")
    }

    @Test("Mixed literal and variable")
    func mixedLiteralAndVariable() throws {
        let template = try URITemplate("hello/{var}")
        let result = template.expand(with: ["var": "world"])
        #expect(result == "hello/world")
    }

    @Test("Multiple separate expressions")
    func multipleSeparateExpressions() throws {
        let template = try URITemplate("{x}/{y}")
        let result = template.expand(with: ["x": "foo", "y": "bar"])
        #expect(result == "foo/bar")
    }
}

// MARK: -

@Suite("RFC 6570 Level 2: Reserved & Fragment Expansion")
struct Level2Tests {

    // Reserved String Expansion {+var}
    @Test("Reserved expansion basic")
    func reservedExpansionBasic() throws {
        let template = try URITemplate("{+var}")
        let result = template.expand(with: ["var": "value"])
        #expect(result == "value")
    }

    @Test("Reserved expansion with path")
    func reservedExpansionWithPath() throws {
        let template = try URITemplate("{+path}/here")
        let result = template.expand(with: ["path": "/foo/bar"])
        #expect(result == "/foo/bar/here")
    }

    @Test("Reserved expansion preserves reserved characters")
    func reservedExpansionPreservesReservedChars() throws {
        let template = try URITemplate("{+var}")
        let result = template.expand(with: ["var": "foo/bar"])
        #expect(result == "foo/bar")
    }

    @Test("Reserved expansion with unicode")
    func reservedExpansionWithUnicode() throws {
        let template = try URITemplate("{+var}")
        let result = template.expand(with: ["var": "café/bar"])
        #expect(result == "caf%C3%A9/bar")
    }

    @Test("Reserved expansion with emoji")
    func reservedExpansionWithEmoji() throws {
        let template = try URITemplate("{+var}")
        let result = template.expand(with: ["var": "hello 👋/world"])
        #expect(result == "hello%20%F0%9F%91%8B/world")
    }

    @Test("Reserved expansion with empty value")
    func reservedExpansionWithEmptyValue() throws {
        let template = try URITemplate("{+var}")
        let result = template.expand(with: ["var": ""])
        #expect(result == "")
    }

    // Fragment Expansion {#var}
    @Test("Fragment expansion basic")
    func fragmentExpansionBasic() throws {
        let template = try URITemplate("{#var}")
        let result = template.expand(with: ["var": "value"])
        #expect(result == "#value")
    }

    @Test("Fragment expansion with undefined variable")
    func fragmentExpansionWithUndefinedVariable() throws {
        let template = try URITemplate("{#undef}")
        let result = template.expand(with: [:])
        #expect(result == "")
    }

    @Test("Fragment expansion with empty value")
    func fragmentExpansionWithEmptyValue() throws {
        let template = try URITemplate("{#var}")
        let result = template.expand(with: ["var": ""])
        #expect(result == "#")
    }

    @Test("Fragment expansion with reserved characters")
    func fragmentExpansionWithReservedChars() throws {
        let template = try URITemplate("{#var}")
        let result = template.expand(with: ["var": "foo/bar"])
        #expect(result == "#foo/bar")
    }
}

// MARK: -

@Suite("RFC 6570 Level 3: Multiple Variables & Complex Operators")
struct Level3Tests {

    // Multiple Variables (default operator)
    @Test("Multiple variables basic")
    func multipleVariablesBasic() throws {
        let template = try URITemplate("{x,y}")
        let result = template.expand(with: ["x": "1024", "y": "768"])
        #expect(result == "1024,768")
    }

    @Test("Multiple variables with undefined")
    func multipleVariablesWithUndefined() throws {
        let template = try URITemplate("{x,y}")
        let result = template.expand(with: ["x": "1024"])
        #expect(result == "1024")
    }

    @Test("Multiple variables reserved expansion")
    func multipleVariablesReservedExpansion() throws {
        let template = try URITemplate("{+path,x}/here")
        let result = template.expand(with: ["path": "/foo/bar", "x": "1024"])
        #expect(result == "/foo/bar,1024/here")
    }

    @Test("Multiple variables fragment expansion")
    func multipleVariablesFragmentExpansion() throws {
        let template = try URITemplate("{#path,x}/here")
        let result = template.expand(with: ["path": "/foo/bar", "x": "1024"])
        #expect(result == "#/foo/bar,1024/here")
    }

    @Test("Multiple variables with empty values")
    func multipleVariablesWithEmptyValues() throws {
        let template = try URITemplate("{+path,empty}")
        let result = template.expand(with: ["path": "/foo/bar", "empty": ""])
        #expect(result == "/foo/bar,")
    }

    // Label Expansion {.var}
    @Test("Label expansion basic")
    func labelExpansionBasic() throws {
        let template = try URITemplate("X{.var}")
        let result = template.expand(with: ["var": "value"])
        #expect(result == "X.value")
    }

    @Test("Label expansion multiple variables")
    func labelExpansionMultipleVariables() throws {
        let template = try URITemplate("X{.x,y}")
        let result = template.expand(with: ["x": "1024", "y": "768"])
        #expect(result == "X.1024.768")
    }

    @Test("Label expansion with empty value")
    func labelExpansionWithEmptyValue() throws {
        let template = try URITemplate("X{.empty}")
        let result = template.expand(with: ["empty": ""])
        #expect(result == "X.")
    }

    @Test("Label expansion with undefined variable")
    func labelExpansionWithUndefinedVariable() throws {
        let template = try URITemplate("X{.undef}")
        let result = template.expand(with: [:])
        #expect(result == "X")
    }

    // Path Segment Expansion {/var}
    @Test("Path expansion basic")
    func pathExpansionBasic() throws {
        let template = try URITemplate("{/var}")
        let result = template.expand(with: ["var": "value"])
        #expect(result == "/value")
    }

    @Test("Path expansion multiple variables")
    func pathExpansionMultipleVariables() throws {
        let template = try URITemplate("{/var,x}/here")
        let result = template.expand(with: ["var": "value", "x": "1024"])
        #expect(result == "/value/1024/here")
    }

    @Test("Path expansion with empty value")
    func pathExpansionWithEmptyValue() throws {
        let template = try URITemplate("{/var,empty}")
        let result = template.expand(with: ["var": "value", "empty": ""])
        #expect(result == "/value/")
    }

    @Test("Path expansion with undefined variable")
    func pathExpansionWithUndefinedVariable() throws {
        let template = try URITemplate("{/var,undef}")
        let result = template.expand(with: ["var": "value"])
        #expect(result == "/value")
    }

    // Path-Style Parameter Expansion {;var}
    @Test("Path-style parameter expansion basic")
    func pathStyleParameterExpansionBasic() throws {
        let template = try URITemplate("{;x,y}")
        let result = template.expand(with: ["x": "1024", "y": "768"])
        #expect(result == ";x=1024;y=768")
    }

    @Test("Path-style parameter expansion with empty value")
    func pathStyleParameterExpansionWithEmptyValue() throws {
        let template = try URITemplate("{;x,y,empty}")
        let result = template.expand(with: ["x": "1024", "y": "768", "empty": ""])
        #expect(result == ";x=1024;y=768;empty")
    }

    @Test("Path-style parameter expansion with undefined variable")
    func pathStyleParameterExpansionWithUndefinedVariable() throws {
        let template = try URITemplate("{;x,y,undef}")
        let result = template.expand(with: ["x": "1024", "y": "768"])
        #expect(result == ";x=1024;y=768")
    }

    // Form-Style Query Expansion {?var}
    @Test("Query parameter expansion basic")
    func queryParameterExpansionBasic() throws {
        let template = try URITemplate("{?x,y}")
        let result = template.expand(with: ["x": "1024", "y": "768"])
        #expect(result == "?x=1024&y=768")
    }

    @Test("Query parameter expansion with empty value")
    func queryParameterExpansionWithEmptyValue() throws {
        let template = try URITemplate("{?x,y,empty}")
        let result = template.expand(with: ["x": "1024", "y": "768", "empty": ""])
        #expect(result == "?x=1024&y=768&empty=")
    }

    @Test("Query parameter expansion with empty string variable")
    func queryParameterExpansionWithEmptyStringVariable() throws {
        let template = try URITemplate("{?var}")
        let result = template.expand(with: ["var": ""])
        #expect(result == "?var=")
    }

    // Form-Style Query Continuation {&var}
    @Test("Query continuation basic")
    func queryContinuationBasic() throws {
        let template = try URITemplate("?fixed=yes{&x}")
        let result = template.expand(with: ["x": "1024"])
        #expect(result == "?fixed=yes&x=1024")
    }

    @Test("Query continuation multiple variables")
    func queryContinuationMultipleVariables() throws {
        let template = try URITemplate("?fixed=yes{&x,y,empty}")
        let result = template.expand(with: ["x": "1024", "y": "768", "empty": ""])
        #expect(result == "?fixed=yes&x=1024&y=768&empty=")
    }

    // Complex mixed operator expressions
    @Test("Complex mixed operators")
    func complexMixedOperators() throws {
        let template = try URITemplate("{+path}{?query}{#fragment}")
        let result = template.expand(with: [
            "path": "/foo/bar",
            "query": "search",
            "fragment": "section1",
        ])
        #expect(result == "/foo/bar?query=search#section1")
    }
}

// MARK: -

@Suite("RFC 6570 Level 4: Value Modifiers")
struct Level4Tests {

    // Prefix Modifier {var:N}
    @Test("Prefix modifier basic")
    func prefixModifierBasic() throws {
        let template = try URITemplate("{var:3}")
        let result = template.expand(with: ["var": "value"])
        #expect(result == "val")
    }

    @Test("Prefix modifier longer than string")
    func prefixModifierLongerThanString() throws {
        let template = try URITemplate("{var:30}")
        let result = template.expand(with: ["var": "value"])
        #expect(result == "value")
    }

    @Test("Prefix modifier with empty string")
    func prefixModifierWithEmptyString() throws {
        let template = try URITemplate("{var:3}")
        let result = template.expand(with: ["var": ""])
        #expect(result == "")
    }

    @Test("Prefix modifier with single character")
    func prefixModifierWithSingleCharacter() throws {
        let template = try URITemplate("{var:1}")
        let result = template.expand(with: ["var": "hello"])
        #expect(result == "h")
    }

    @Test("Prefix modifier with exact length")
    func prefixModifierWithExactLength() throws {
        let template = try URITemplate("{var:5}")
        let result = template.expand(with: ["var": "hello"])
        #expect(result == "hello")
    }

    // Explode Modifier {var*} - Simple Lists
    @Test("List variable explode basic")
    func listVariableExplodeBasic() throws {
        let template = try URITemplate("{var*}")
        let result = template.expand(with: ["var": .list(["one", "two", "three"])])
        #expect(result == "one,two,three")
    }

    @Test("List variable without explode")
    func listVariableWithoutExplode() throws {
        let template = try URITemplate("{var}")
        let result = template.expand(with: ["var": .list(["one", "two", "three"])])
        #expect(result == "one,two,three")
    }

    @Test("List variable with empty items")
    func listVariableWithEmptyItems() throws {
        let template = try URITemplate("{var*}")
        let result = template.expand(with: ["var": .list(["one", "", "three"])])
        #expect(result == "one,,three")
    }

    // Explode Modifier {var*} - Path Segments
    @Test("List variable path explode")
    func listVariablePathExplode() throws {
        let template = try URITemplate("{/var*}")
        let result = template.expand(with: ["var": .list(["one", "two", "three"])])
        #expect(result == "/one/two/three")
    }

    @Test("List variable path explode with empty items")
    func listVariablePathExplodeWithEmptyItems() throws {
        let template = try URITemplate("{/var*}")
        let result = template.expand(with: ["var": .list(["one", "", "three"])])
        #expect(result == "/one//three")
    }

    // Explode Modifier {var*} - Query Parameters
    @Test("List variable query explode")
    func listVariableQueryExplode() throws {
        let template = try URITemplate("{?var*}")
        let result = template.expand(with: ["var": .list(["one", "two", "three"])])
        #expect(result == "?var=one&var=two&var=three")
    }

    @Test("List variable query explode with empty items")
    func listVariableQueryExplodeWithEmptyItems() throws {
        let template = try URITemplate("{?var*}")
        let result = template.expand(with: ["var": .list(["one", "", "three"])])
        #expect(result == "?var=one&var=&var=three")
    }

    @Test("List variable query continuation explode")
    func listVariableQueryContinuationExplode() throws {
        let template = try URITemplate("?fixed=yes{&var*}")
        let result = template.expand(with: ["var": .list(["one", "two", "three"])])
        #expect(result == "?fixed=yes&var=one&var=two&var=three")
    }

    // Explode Modifier {var*} - Associative Arrays
    @Test("Associative array basic")
    func associativeArrayBasic() throws {
        let template = try URITemplate("{var}")
        let result = template.expand(with: [
            "var": .associativeArray([("semi", ";"), ("dot", "."), ("comma", ",")])
        ])
        #expect(result == "semi,%3B,dot,.,comma,%2C")
    }

    @Test("Associative array explode")
    func associativeArrayExplode() throws {
        let template = try URITemplate("{var*}")
        let result = template.expand(with: [
            "var": .associativeArray([("semi", ";"), ("dot", "."), ("comma", ",")])
        ])
        #expect(result == "semi=%3B,dot=.,comma=%2C")
    }

    @Test("Associative array query explode")
    func associativeArrayQueryExplode() throws {
        let template = try URITemplate("{?var*}")
        let result = template.expand(with: [
            "var": .associativeArray([("semi", ";"), ("dot", "."), ("comma", ",")])
        ])
        #expect(result == "?semi=%3B&dot=.&comma=%2C")
    }

    @Test("Associative array query continuation explode")
    func associativeArrayQueryContinuationExplode() throws {
        let template = try URITemplate("?fixed=yes{&var*}")
        let result = template.expand(with: [
            "var": .associativeArray([("key1", "value1"), ("key2", "value2")])
        ])
        #expect(result == "?fixed=yes&key1=value1&key2=value2")
    }

    @Test("Associative array with empty keys and values")
    func associativeArrayWithEmptyKeysAndValues() throws {
        let template = try URITemplate("{var*}")
        let result = template.expand(with: [
            "var": .associativeArray([("", "value1"), ("key2", "")])
        ])
        #expect(result == "=value1,key2=")
    }

    @Test("Associative array query explode with empty keys and values")
    func associativeArrayQueryExplodeWithEmptyKeysAndValues() throws {
        let template = try URITemplate("{?var*}")
        let result = template.expand(with: [
            "var": .associativeArray([("", "value1"), ("key2", "")])
        ])
        #expect(result == "?=value1&key2=")
    }

    @Test("Complex query with lists and prefix")
    func complexQueryWithListsAndPrefix() throws {
        let template = try URITemplate("{?list}")
        let result = template.expand(with: ["list": .list(["one", "two", "three"])])
        #expect(result == "?list=one,two,three")
    }

    @Test("Complex query with associative arrays")
    func complexQueryWithAssociativeArrays() throws {
        let template = try URITemplate("{?map}")
        let result = template.expand(with: [
            "map": .associativeArray([("key1", "value1"), ("key2", "value2")])
        ])
        #expect(result == "?map=key1,value1,key2,value2")
    }

    @Test("Complex query with exploded associative arrays")
    func complexQueryWithExplodedAssociativeArrays() throws {
        let template = try URITemplate("{?map*}")
        let result = template.expand(with: [
            "map": .associativeArray([("key1", "value1"), ("key2", "value2")])
        ])
        #expect(result == "?key1=value1&key2=value2")
    }
}

// MARK: -

@Suite("Error Handling Tests")
struct ErrorHandlingTests {
    @Test("Malformed expression unclosed")
    func malformedExpressionUnclosed() {
        #expect(throws: URITemplateError.self) {
            try URITemplate("{var")
        }
    }

    @Test("Malformed expression empty")
    func malformedExpressionEmpty() {
        #expect(throws: URITemplateError.self) {
            try URITemplate("{}")
        }
    }

    @Test("Invalid variable name with space")
    func invalidVariableNameWithSpace() {
        #expect(throws: URITemplateError.self) {
            try URITemplate("{var name}")
        }
    }

    @Test("Invalid variable name with special characters")
    func invalidVariableNameWithSpecialCharacters() {
        #expect(throws: URITemplateError.self) {
            try URITemplate("{var-name}")
        }
        #expect(throws: URITemplateError.self) {
            try URITemplate("{var@name}")
        }
    }

    @Test("Invalid prefix modifier zero")
    func invalidPrefixModifierZero() {
        #expect(throws: URITemplateError.self) {
            try URITemplate("{var:0}")
        }
    }

    @Test("Invalid prefix modifier negative")
    func invalidPrefixModifierNegative() {
        #expect(throws: URITemplateError.self) {
            try URITemplate("{var:-1}")
        }
    }

    @Test("Invalid prefix modifier non-numeric")
    func invalidPrefixModifierNonNumeric() {
        #expect(throws: URITemplateError.self) {
            try URITemplate("{var:abc}")
        }
    }

    @Test("Invalid operator")
    func invalidOperator() {
        #expect(throws: URITemplateError.self) {
            try URITemplate("{@var}")
        }
    }

    @Test("Multiple operators")
    func multipleOperators() {
        #expect(throws: URITemplateError.self) {
            try URITemplate("{++var}")
        }
    }

    @Test("Template with only operators")
    func templateWithOnlyOperators() {
        #expect(throws: URITemplateError.self) {
            try URITemplate("{+}")
        }
    }

    @Test("Template with nested braces")
    func templateWithNestedBraces() {
        #expect(throws: URITemplateError.self) {
            try URITemplate("{{var}}")
        }
    }

    @Test("Invalid asterisk placement")
    func invalidAsteriskPlacement() {
        #expect(throws: URITemplateError.self) {
            try URITemplate("{var*name}")
        }
    }

    @Test("Multiple asterisks")
    func multipleAsterisks() {
        #expect(throws: URITemplateError.self) {
            try URITemplate("{var**}")
        }
    }

    @Test("Prefix modifier with decimal")
    func prefixModifierWithDecimal() {
        #expect(throws: URITemplateError.self) {
            try URITemplate("{var:3.14}")
        }
    }

    @Test("Prefix modifier with very large number")
    func prefixModifierWithVeryLargeNumber() {
        #expect(throws: URITemplateError.self) {
            try URITemplate("{var:999999999999999999999999999999}")
        }
    }

    @Test("Empty variable name")
    func emptyVariableName() {
        #expect(throws: URITemplateError.self) {
            try URITemplate("{,var}")
        }
    }

    @Test("Variable name with invalid percent encoding")
    func variableNameWithInvalidPercentEncoding() {
        #expect(throws: URITemplateError.self) {
            try URITemplate("{var%}")
        }
    }

    @Test("Variable name with incomplete percent encoding")
    func variableNameWithIncompletePercentEncoding() {
        #expect(throws: URITemplateError.self) {
            try URITemplate("{var%2}")
        }
    }
}

// MARK: -

@Suite("Edge Cases Tests")
struct EdgeCasesTests {
    @Test("Empty template")
    func emptyTemplate() throws {
        let template = try URITemplate("")
        let result = template.expand(with: [:])
        #expect(result == "")
    }

    @Test("Literal only template")
    func literalOnlyTemplate() throws {
        let template = try URITemplate("hello/world")
        let result = template.expand(with: [:])
        #expect(result == "hello/world")
    }

    @Test("Expression with whitespace")
    func expressionWithWhitespace() throws {
        let template = try URITemplate("{ var }")
        let result = template.expand(with: ["var": "value"])
        #expect(result == "value")
    }

    @Test("Multiple expressions with whitespace")
    func multipleExpressionsWithWhitespace() throws {
        let template = try URITemplate("{ x , y }")
        let result = template.expand(with: ["x": "foo", "y": "bar"])
        #expect(result == "foo,bar")
    }

    @Test("Variable name with underscore")
    func variableNameWithUnderscore() throws {
        let template = try URITemplate("{user_name}")
        let result = template.expand(with: ["user_name": "johnny_appleseed"])
        #expect(result == "johnny_appleseed")
    }

    @Test("Variable name with dot")
    func variableNameWithDot() throws {
        let template = try URITemplate("{user.name}")
        let result = template.expand(with: ["user.name": "johnny.appleseed"])
        #expect(result == "johnny.appleseed")
    }

    @Test("Variable name with percent encoded characters")
    func variableNameWithPercentEncodedChars() throws {
        let template = try URITemplate("{user%20name}")
        let result = template.expand(with: ["user%20name": "johnny appleseed"])
        #expect(result == "johnny%20appleseed")
    }

    @Test("Variable name with leading number")
    func variableNameWithLeadingNumber() throws {
        let template = try URITemplate("{1var}")
        let result = template.expand(with: ["1var": "value"])
        #expect(result == "value")
    }

    @Test("Variable name with only numbers")
    func variableNameWithOnlyNumbers() throws {
        let template = try URITemplate("{123}")
        let result = template.expand(with: ["123": "value"])
        #expect(result == "value")
    }

    @Test("Variable name with mixed case")
    func variableNameWithMixedCase() throws {
        let template = try URITemplate("{VarName}")
        let result = template.expand(with: ["VarName": "value"])
        #expect(result == "value")
    }

    @Test("Variable name with unicode characters")
    func variableNameWithUnicodeCharacters() throws {
        let template = try URITemplate("{café}")
        let result = template.expand(with: ["café": "value"])
        #expect(result == "value")
    }

    @Test("Variable name with emoji")
    func variableNameWithEmoji() throws {
        let template = try URITemplate("{👋}")
        let result = template.expand(with: ["👋": "hello"])
        #expect(result == "hello")
    }

    @Test("Nested expressions in literal")
    func nestedExpressionsInLiteral() throws {
        let template = try URITemplate("{var}{var}")
        let result = template.expand(with: ["var": "test"])
        #expect(result == "testtest")
    }
}

// MARK: -

@Suite("Complex Real-World Examples")
struct ComplexRealWorldExamplesTests {

    @Test("API endpoint with multiple path segments")
    func apiEndpointWithMultiplePathSegments() throws {
        let template = try URITemplate("https://api.example.com/v1{/resource*}{?filter,sort,page}")
        let result = template.expand(with: [
            "resource": .list(["users", "123", "posts"]),
            "filter": "active",
            "sort": "date",
            "page": "1",
        ])
        #expect(
            result == "https://api.example.com/v1/users/123/posts?filter=active&sort=date&page=1")
    }

    @Test("Search API with complex parameters")
    func searchAPIWithComplexParameters() throws {
        let template = try URITemplate("https://search.example.com/search{?q,lang,params*}")
        let result = template.expand(with: [
            "q": "swift programming",
            "lang": "en",
            "params": .associativeArray([
                ("category", "development"),
                ("type", "tutorial"),
                ("level", "beginner"),
            ]),
        ])
        #expect(
            result
                == "https://search.example.com/search?q=swift%20programming&lang=en&category=development&type=tutorial&level=beginner"
        )
    }

    @Test("File download URL with authentication")
    func fileDownloadURLWithAuthentication() throws {
        let template = try URITemplate("https://files.example.com{/path*}{?token,expires}")
        let result = template.expand(with: [
            "path": .list(["downloads", "documents", "report.pdf"]),
            "token": "abc123def456",
            "expires": "2024-12-31",
        ])
        #expect(
            result
                == "https://files.example.com/downloads/documents/report.pdf?token=abc123def456&expires=2024-12-31"
        )
    }

    @Test("WebSocket URL with query parameters")
    func webSocketURLWithQueryParameters() throws {
        let template = try URITemplate("wss://chat.example.com{/room}{?user,channel,params*}")
        let result = template.expand(with: [
            "room": "general",
            "user": "johnny_appleseed",
            "channel": "main",
            "params": .associativeArray([
                ("theme", "dark"),
                ("notifications", "enabled"),
            ]),
        ])
        #expect(
            result
                == "wss://chat.example.com/general?user=johnny_appleseed&channel=main&theme=dark&notifications=enabled"
        )
    }
}

// MARK: -

@Suite("Performance Tests")
struct PerformanceTests {
    @Test("Large number of variables")
    func largeNumberOfVariables() throws {
        var variables: [String: VariableValue] = [:]
        for i in 1...100 {
            variables["var\(i)"] = .string("value\(i)")
        }

        let template = try URITemplate("{var1,var50,var100}")
        let result = template.expand(with: variables)
        #expect(result == "value1,value50,value100")
    }

    @Test("Large list expansion")
    func largeListExpansion() throws {
        let largeList = (1...1000).map { "item\($0)" }
        let template = try URITemplate("{var*}")
        let result = template.expand(with: ["var": .list(largeList)])
        #expect(result.contains("item1"))
        #expect(result.contains("item1000"))
        #expect(result.components(separatedBy: ",").count == 1000)
    }

    @Test("Large associative array expansion")
    func largeAssociativeArrayExpansion() throws {
        let largeArray = (1...100).map { ("key\($0)", "value\($0)") }
        let template = try URITemplate("{var*}")
        let result = template.expand(with: ["var": .associativeArray(largeArray)])
        #expect(result.contains("key1=value1"))
        #expect(result.contains("key100=value100"))
        #expect(result.components(separatedBy: ",").count == 100)
    }
}

// MARK: -

@Suite("Template Introspection Tests")
struct TemplateIntrospectionTests {

    @Test("Simple variable extraction")
    func simpleVariableExtraction() throws {
        let template = try URITemplate("{var}")
        let variables = template.variables
        #expect(variables == ["var"])
    }

    @Test("Multiple variables extraction")
    func multipleVariablesExtraction() throws {
        let template = try URITemplate("{x,y,z}")
        let variables = template.variables
        #expect(variables == ["x", "y", "z"])
    }

    @Test("Variables with different operators")
    func variablesWithDifferentOperators() throws {
        let template = try URITemplate(
            "{var}{+reserved}{#fragment}{.label}{/path}{;pathStyle}{?query}{&continuation}")
        let variables = template.variables
        #expect(
            variables == [
                "var", "reserved", "fragment", "label", "path", "pathStyle", "query",
                "continuation",
            ])
    }

    @Test("Variables with prefix modifiers")
    func variablesWithPrefixModifiers() throws {
        let template = try URITemplate("{var:3}{name:10}")
        let variables = template.variables
        #expect(variables == ["var", "name"])
    }

    @Test("Variables with explode modifier")
    func variablesWithExplodeModifier() throws {
        let template = try URITemplate("{var*}{list*}")
        let variables = template.variables
        #expect(variables == ["var", "list"])
    }

    @Test("Complex template with mixed operators and modifiers")
    func complexTemplateWithMixedOperatorsAndModifiers() throws {
        let template = try URITemplate("https://api.example.com{/path*}{?query,limit:10,exploded*}")
        let variables = template.variables
        #expect(variables == ["path", "query", "limit", "exploded"])
    }

    @Test("Template with literals only")
    func templateWithLiteralsOnly() throws {
        let template = try URITemplate("https://api.example.com/static/path")
        let variables = template.variables
        #expect(variables.isEmpty)
    }

    @Test("Template with duplicated variable names")
    func templateWithDuplicatedVariableNames() throws {
        let template = try URITemplate("{var}/{var}")
        let variables = template.variables
        #expect(variables == ["var", "var"])
    }

    @Test("Empty template")
    func emptyTemplate() throws {
        let template = try URITemplate("")
        let variables = template.variables
        #expect(variables.isEmpty)
    }
}
