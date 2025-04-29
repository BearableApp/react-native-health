//
//  Steps.swift
//  RCTAppleHealthKit
//
//  Copyright © 2024 Bearable. All rights reserved.
//

import Foundation

class BucketedSteps: BucketedQueryType {
    func quantityType() -> HKQuantityType? {
        return HKObjectType.quantityType(forIdentifier: .stepCount)
    }
    
    func queryOptions() -> HKStatisticsOptions {
        return .cumulativeSum
    }
    
    func statisticsUnit(unitString: String?) -> HKUnit {
        return .count()
    }
    
    func statisticsValue(statistic: HKStatistics, unit: HKUnit) -> String? {
        if let quantity = statistic.sumQuantity() {
            let value = quantity.doubleValue(for: unit)
            return formatDoubleAsString(value: value)
        }
        return nil
    }
}
