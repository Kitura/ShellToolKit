import XCTest
@testable import SwiftShellUtilities

final class DirUtilityTests: XCTestCase {
    let fileThatShouldExist = URL(fileURLWithPath: "/bin/sh")
    let fileThatShouldNotExist = URL(fileURLWithPath: "/_This_filE_sHoulD_NoT-Exist!")
    let directoryThatShouldExist = URL(fileURLWithPath: "/bin")

    func testThat_File_Exists() throws {
        XCTAssertTrue( DirUtility.shared.fileExists(url: fileThatShouldExist) )
    }

    func testThat_File_DoesNotExist() throws {
        XCTAssertFalse( DirUtility.shared.fileExists(url: fileThatShouldNotExist) )
    }


    func testThat_RegularFile_IsDetected() throws {
        let isFile = DirUtility.shared.isFile(url: fileThatShouldExist)

        XCTAssertTrue(isFile, "Most systems should have a /bin/sh !")
    }

    func testThat_RegularFile_IsNotADirectory() throws {
        let isDirectory = DirUtility.shared.isDirectory(url: fileThatShouldExist)

        XCTAssertFalse(isDirectory, "/bin/sh should be a regular file!")
    }

    func testThat_Directory_IsDetected() throws {
        let isDirectory = DirUtility.shared.isDirectory(url: directoryThatShouldExist)
        XCTAssertTrue(isDirectory, "Most systems should have a /bin !")
    }

    func testThat_Directory_IsNotAFile() throws {
        let isFile = DirUtility.shared.isFile(url: directoryThatShouldExist)
        XCTAssertFalse(isFile, "/bin should be a directory!")
    }

}
