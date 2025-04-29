//
//  BucketedHeartRateVariability.swift
//  RCTAppleHealthKit
//
//  Copyright © 2024 Bearable. All rights reserved.
//

import Foundation

@available(iOS 11.0, *)
class BucketedHeartRateVariability: BucketedQueryType {
    func quantityType() -> HKQuantityType? {
        return HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)
    }
    
    func queryOptions() -> HKStatisticsOptions {
        return .discreteAverage
    }
    
    func statisticsUnit(unitString: String?) -> HKUnit {
        return HKUnit(from: "ms")
    }
    
    func statisticsValue(statistic: HKStatistics, unit: HKUnit) -> String? {
        if let quantity = statistic.averageQuantity() {
            let value = quantity.doubleValue(for: unit)
            return formatDoubleAsString(value: value)
        }
        return nil
    }
}
