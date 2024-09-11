//
//  Steps.swift
//  RCTAppleHealthKit
//
//  Copyright © 2024 Bearable. All rights reserved.
//

import Foundation

class BucketedSteps: BucketedQueryType {
    var recordType: RecordType = .steps
    
    func quantityType() -> HKQuantityType? {
        return HKObjectType.quantityType(forIdentifier: .stepCount)
    }
    
    func queryOptions() -> HKStatisticsOptions {
        return .cumulativeSum
    }
    
    func statisticsValue(statistic: HKStatistics) -> String? {
        if let quantity = statistic.sumQuantity() {
            let value = quantity.doubleValue(for: .count())
            return formatDoubleAsString(value: value)
        }
        return nil
    }
}
