import XCTest
@testable import SwiftShellUtilities

final class SystemActionTests: XCTestCase {

    func testThat_Real_CanExecuteCommand() throws {
        let action = SystemActionReal()

        try action.runAndPrint(command: "date")
    }

    func testThat_Real_WillThrow_GivenInvalidCommand() throws {
        let action = SystemActionReal()

        XCTAssertThrowsError(try action.runAndPrint(command: "_this_command-does_not_exist"))
    }

    func testThat_Composite_CanExecuteCommand() throws {
        let action = SystemActionComposite( [SystemActionPrint(), SystemActionReal()] )

        try action.runAndPrint(command: "date")
    }

    func testThat_Composite_WillThrow_GivenInvalidCommand() throws {
        let action = SystemActionComposite( [SystemActionPrint(), SystemActionReal()] )

        XCTAssertThrowsError(try action.runAndPrint(command: "_this_command-does_not_exist"))
    }

    func testThat_StdinString_CanBeSent() throws {
        let inputValue = "Hello World!"
        let expectedValue = inputValue
        
        let action = SystemActionComposite( [SystemActionPrint(), SystemActionReal()] )
        
        let output = action.run(command: ["cat"], stdin: inputValue)
        
        XCTAssertEqual(expectedValue, output.stdout)
    }
}
