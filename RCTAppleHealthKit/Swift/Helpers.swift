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

@available(iOS 10.0, *)
func findSleepType(value: HKCategoryValueSleepAnalysis.RawValue) -> SleepType {
    switch value {
    case HKCategoryValueSleepAnalysis.inBed.rawValue:
        return .inBed
    case HKCategoryValueSleepAnalysis.awake.rawValue:
        return .awake
    // .asleepCore, .asleepREM, .asleepDeep, .asleepUnspecified
    default:
        return .asleep
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

func unitFromOptions(options: NSDictionary, key: String) -> String? {
    if let unitString = options[key] as? String {
        return unitString
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

@available(iOS 11.0, *)
func queryTypeFromRecordType(recordType: String) -> [BucketedQueryType]? {
    guard let recordTypeEnum = RecordType(rawValue: recordType.uppercased()) else {
        return nil
    }

    switch recordTypeEnum {
    case RecordType.steps:
        return [BucketedSteps()]
    case RecordType.heart:
        return [BucketedHeartRate()]
    case RecordType.weight:
        return [BucketedWeight()]
    case RecordType.hrv:
        return [BucketedHeartRateVariability()]
    case RecordType.bodyTemperature:
        return [BucketedBodyTemperature()]
    case RecordType.restingHeart:
        return [BucketedRestingHeartRate()]
    case RecordType.bloodPressure:
        return [BucketedSystolicBloodPressure(), BucketedDiastolicBloodPressure()]
    }
}

// ----- Format Helpers ----- //

func formatDateKey(date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMdd" 
    return dateFormatter.string(from: date)
}

func formatSleepDateKey(date: Date, cutoff: Int) -> String {
    var finalDate = date

    let sampleHour = Calendar.current.component(.hour, from: date)
    if sampleHour > cutoff {
        // If past the cutoff then we want to get the date key for the next day
        finalDate = Calendar.current.date(byAdding: .day, value: 1, to: date)!
    }
    
    return formatDateKey(date: finalDate)
}

// Format to YYYY-MM-DD HH:mm:ss.SSS as local time
func formatLocalString(date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    formatter.timeZone = .current
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter.string(from: date)
}

func formatDoubleAsString(value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 2

    return formatter.string(from: NSNumber(value: value)) ?? "0"
}

func formatDuration(seconds: Double) -> String {
    let hours = Int(seconds) / 3600
    let secondsAfterHours = Int(seconds) % 3600
    let minutes = secondsAfterHours / 60

   return String(format: "%02d:%02d", hours, minutes)
}

func formatRecord(date: String, type: String, value: String) -> NSDictionary {
    return [
        "dateKey": date,
        "entry": [
            "type": type,
            "value": value,
            "family": RECORDS_FAMILY,
        ]
    ]
}

func formatSleepRecord(date: String, type: String, sleepValue: SleepValue) -> NSDictionary {
    
    let value = formatDuration(seconds: sleepValue.duration)

    var entry: [String: Any] = [
        "type": type,
        "value": value,
        "family": RECORDS_FAMILY,
    ]
    var timesInBed: [String: String] = [:]
    var sleepTimes: [String: String] = [:]
    
    if let inBedAt = sleepValue.inBed {
        timesInBed["inBedAt"] = formatLocalString(date: inBedAt)
    }
    if let outOfBedAt = sleepValue.outOfBed {
        timesInBed["outOfBedAt"] = formatLocalString(date: outOfBedAt)
    }
    if let fellAsleepAt = sleepValue.fellAsleep {
        sleepTimes["fellAsleepAt"] = formatLocalString(date: fellAsleepAt)
    }
    if let wokeUpAt = sleepValue.wokeUp {
        sleepTimes["wokeUpAt"] = formatLocalString(date: wokeUpAt)
    }
    
    if !timesInBed.isEmpty {
        entry["timesInBed"] = timesInBed
    }
    if !sleepTimes.isEmpty {
        entry["sleepTimes"] = sleepTimes
    }
    
    return [
        "dateKey": date,
        "entry": entry
    ]
}
