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
    
    func statisticsUnit(unitString: String?) -> HKUnit {
        // Beats per minute
        return .count().unitDivided(by: HKUnit.minute())
    }
    
    func statisticsValue(statistic: HKStatistics, unit: HKUnit) -> String? {
        guard let average = statistic.averageQuantity() else {
            return nil
        }
        guard let maximum = statistic.maximumQuantity() else {
            return nil
        }
        guard let minimum = statistic.minimumQuantity() else {
            return nil
        }
        
        let averageValue = average.doubleValue(for: unit)
        let maximumValue = maximum.doubleValue(for: unit)
        let minimumValue = minimum.doubleValue(for: unit)
        
        let averageString = formatDoubleAsString(value: averageValue)
        let maximumString = formatDoubleAsString(value: maximumValue)
        let minimumString = formatDoubleAsString(value: minimumValue)

        return "\(minimumString)/\(averageString)/\(maximumString)"
    }
}
