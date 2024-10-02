//
//  BucketedWeight.swift
//  RCTAppleHealthKit
//
//  Copyright © 2024 Bearable. All rights reserved.
//

import Foundation

class BucketedWeight: BucketedQueryType {
    func quantityType() -> HKQuantityType? {
        return HKObjectType.quantityType(forIdentifier: .bodyMass)
    }
    
    func queryOptions() -> HKStatisticsOptions {
        return .mostRecent
    }
    
    func statisticsUnit(unitString: String?) -> HKUnit {
        switch unitString {
        case "pound":
            return .pound()
        case "kg":
            return HKUnit(from: "kg")
        default:
            return HKUnit(from: "kg")
        }
    }
    
    func statisticsValue(statistic: HKStatistics, unit: HKUnit) -> String? {
        if let quantity = statistic.mostRecentQuantity() {
            let value = quantity.doubleValue(for: unit)
            return formatDoubleAsString(value: value)
        }
        return nil
    }
}
