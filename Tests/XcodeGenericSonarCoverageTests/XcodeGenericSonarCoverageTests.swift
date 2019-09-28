import XCTest
@testable import XcodeGenericSonarCoverage

final class XcodeGenericSonarCoverageTests: XCTestCase {
    func testWorking() {
        let derivedDataPath = "/Users/brendanguegan/Projects/XcodeGenericSonarCoverage/Tests/Resources/TestCoverage-dlcxaavmtcsidsearcolrmcjltsc"
        let derivedDataURL = URL(fileURLWithPath: derivedDataPath)
        var instance: XcodeGenericSonarCoverage!
        XCTAssertNoThrow(instance = try XcodeGenericSonarCoverage(derivedDataURL: derivedDataURL))
        let destFile = URL(fileURLWithPath: NSTemporaryDirectory() + "testCoverage.json")
        XCTAssertNoThrow(try instance.generateCoverageReport(at: destFile))
    }

    static var allTests = [
        ("testWorking", testWorking),
    ]
}
