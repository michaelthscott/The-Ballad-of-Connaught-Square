//
//  DurationTests.swift
//  ConnaughtSquareTests
//
//  Created by Michael Scott on 22/09/2026.
//

import Foundation
import Testing
@testable import ConnaughtSquare

struct DurationTests {

    @Test func testWholeSeconds() {
        #expect(Duration.seconds(13).seconds == 13)
        #expect(Duration.zero.seconds == 0)
    }

    /// The whole seconds are taken from the duration's components, which truncate towards zero.
    @Test func testFractionalSecondsAreTruncated() {
        #expect(Duration.seconds(1.75).seconds == 1)
        #expect(Duration.milliseconds(999).seconds == 0)
        #expect(Duration.seconds(-1.5).seconds == -1)
    }

    @Test func testSecondsOfASumOfDurations() {
        let duration = Duration.seconds(13) + Duration.seconds(1) + Duration.milliseconds(500)
        #expect(duration.seconds == 14)
    }
}
