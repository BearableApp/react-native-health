//
//  RCTAppleHealthKit+Helpers.swift
//  RCTAppleHealthKit
//
//  Created by Work on 06/09/2024.
//  Copyright © 2024 Greg Wilson. All rights reserved.
//

import Foundation
import HealthKit

@available(iOS 11.0, *)
func dateFromOptions(options: NSDictionary, key: String) -> Date? {
    if let dateString = options[key] as? String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = isoFormatter.date(from: dateString)
        return date
    }
    return nil
}

func intervalFromOptions(options: NSDictionary, key: String) -> DateComponents {
    if let intervalString = options[key] as? String {
        // switch string to DateComponents
        switch intervalString {
        case "day":
            return DateComponents(day: 1)
        case "month":
            return DateComponents(month: 1)
        default:
            return DateComponents(day: 1)
        }
    }
    return DateComponents(day: 1)
}

func createPredicate(from: Date?, to: Date?) -> NSPredicate? {
    if from != nil || to != nil {
        return HKQuery.predicateForSamples(withStart: from, end: to, options: [.strictEndDate, .strictStartDate])
    } else {
        return nil
    }
}

func formatDateKey(date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMdd" 
    return dateFormatter.string(from: date)
}

func formatDoubleAsString(value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 2

    return formatter.string(from: NSNumber(value: value)) ?? "0"
}

func formatRecord(date: Date, type: String, value: Double) -> NSDictionary {
    let dateKey = formatDateKey(date: date)
    let stringValue = formatDoubleAsString(value: value)

    return [
        "dateKey": dateKey,
        "entry": [
            "type": type,
            "value": stringValue,
            "family": RECORDS_FAMILY,
        ]
    ]
}
