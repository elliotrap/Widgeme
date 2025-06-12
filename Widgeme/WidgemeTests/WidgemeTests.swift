//
//  WidgemeTests.swift
//  WidgemeTests
//
//  Created by Elliot Rapp on 6/11/25.
//

import XCTest
@testable import Widgeme

final class WidgemeTests: XCTestCase {

    func testDaysLeftInYearCalculation() {
        // Use a fixed date to get a predictable result
        var dateComponents = DateComponents()
        dateComponents.year = 2025
        dateComponents.month = 6
        dateComponents.day = 15
        let calendar = Calendar.current
        let testDate = calendar.date(from: dateComponents)!

        let daysLeft = testDate.daysLeftInYear()

        // There are 199 days left in 2025 after June 15th
        XCTAssertEqual(daysLeft, 199)
    }

}
