//
//  BucketedRestingHeartRate.swift
//  RCTAppleHealthKit
//
//  Copyright © 2024 Bearable. All rights reserved.
//

import Foundation

@available(iOS 11.0, *)
class BucketedRestingHeartRate: BucketedQueryType {
    var recordType: RecordType = .restingHeart
    
    func quantityType() -> HKQuantityType? {
        return HKObjectType.quantityType(forIdentifier: .restingHeartRate)
    }
    
    func queryOptions() -> HKStatisticsOptions {
        return .discreteAverage
    }
    
    func statisticsUnit(unitString: String?) -> HKUnit {
        // Beats per minute
        return .count().unitDivided(by: HKUnit.minute())
    }
    
    func statisticsValue(statistic: HKStatistics, unit: HKUnit) -> String? {
        if let quantity = statistic.averageQuantity() {
            let value = quantity.doubleValue(for: unit)
            return formatDoubleAsString(value: value)
        }
        return nil
    }
}
