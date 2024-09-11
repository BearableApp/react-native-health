//
//  RCTAppleHealthKit+Helpers.swift
//  RCTAppleHealthKit
//
//  Copyright © 2024 Bearable. All rights reserved.
//

import Foundation
import HealthKit

func createPredicate(from: Date?, to: Date?) -> NSPredicate? {
    if from != nil || to != nil {
        return HKQuery.predicateForSamples(withStart: from, end: to, options: [.strictEndDate, .strictStartDate])
    } else {
        return nil
    }
}

// ----- Request Option Extraction Helpers ----- //

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

func queryTypeFromRecordType(recordType: String) -> BucketedQueryType? {
    guard let recordTypeEnum = RecordType(rawValue: recordType.uppercased()) else {
        return nil
    }

    // switch string to DateComponents
    switch recordTypeEnum {
    case RecordType.steps:
        return BucketedSteps()
    case RecordType.heart:
        return BucketedHeartRate()
    }
}

// ----- Format Helpers ----- //

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

func formatRecord(date: Date, type: RecordType, value: String) -> NSDictionary {
    let dateKey = formatDateKey(date: date)
    return [
        "dateKey": dateKey,
        "entry": [
            "type": type.rawValue,
            "value": value,
            "family": RECORDS_FAMILY,
        ]
    ]
}
