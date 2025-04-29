//
//  BucketedSleep.swift
//  RCTAppleHealthKit
//
//  Copyright © 2024 Bearable. All rights reserved.
//

import Foundation

struct SimpleSleepSample {
    var startDate: Date
    var endDate: Date
    var type: SleepType
}

struct SleepValue {
    var duration: Double
    var inBed: Date?
    var outOfBed: Date?
    var fellAsleep: Date?
    var wokeUp: Date?
}

@available(iOS 10.0, *)
class BucketedSleep {
    var recordType = "SLEEP"

    func categoryType() -> HKCategoryType? {
        return HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
    }
    
    func calculateSleepValue(samplesForDate: [SleepType: [SimpleSleepSample]]) -> SleepValue? {
        var record = SleepValue(duration: 0, inBed: nil, outOfBed: nil, fellAsleep: nil, wokeUp: nil)

        for (value, samples) in samplesForDate {
            for sample in samples {
                switch value {
                case .inBed:
                    // Update inBed and outBed times with earliest and latest
                    record.inBed = record.inBed.map { min($0, sample.startDate) } ?? sample.startDate
                    record.outOfBed = record.outOfBed.map { max($0, sample.endDate) } ?? sample.endDate
                    
                case .asleep:
                    // Update fellAsleep and wokeUp times with earliest and latest, increase duration
                    record.fellAsleep = record.fellAsleep.map { min($0, sample.startDate) } ?? sample.startDate
                    record.wokeUp = record.wokeUp.map { max($0, sample.endDate) } ?? sample.endDate
                    record.duration += sample.endDate.timeIntervalSince(sample.startDate)
                default: break
                }
            }
        }
        
        return record
    }
}
