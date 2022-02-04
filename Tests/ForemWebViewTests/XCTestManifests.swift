import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(ForemWebViewTests.allTests),
        testCase(URL_ForemUtilitiesTests.allTests),
    ]
}
#endif
