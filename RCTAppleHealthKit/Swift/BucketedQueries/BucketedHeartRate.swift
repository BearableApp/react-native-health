//
//  BucketedHeartRate.swift
//  RCTAppleHealthKit
//
//  Copyright © 2024 Bearable. All rights reserved.
//

import Foundation

class BucketedHeartRate: BucketedQueryType {
    var recordType: RecordType = .heart
    
    func quantityType() -> HKQuantityType? {
        return HKObjectType.quantityType(forIdentifier: .heartRate)
    }
    
    func queryOptions() -> HKStatisticsOptions {
        return [.discreteAverage, .discreteMax, .discreteMin]
    }
    
    func statisticsValue(statistic: HKStatistics) -> String? {
        guard let average = statistic.averageQuantity() else {
            return nil
        }
        guard let maximum = statistic.maximumQuantity() else {
            return nil
        }
        guard let minimum = statistic.minimumQuantity() else {
            return nil
        }
        
        let beatsPerMinuteUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
        let averageValue = average.doubleValue(for: beatsPerMinuteUnit)
        let maximumValue = maximum.doubleValue(for: beatsPerMinuteUnit)
        let minimumValue = minimum.doubleValue(for: beatsPerMinuteUnit)
        
        let averageString = formatDoubleAsString(value: averageValue)
        let maximumString = formatDoubleAsString(value: maximumValue)
        let minimumString = formatDoubleAsString(value: minimumValue)

        return "\(minimumString)/\(averageString)/\(maximumString)"
    }
}
