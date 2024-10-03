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
        if #available(iOS 13.0, *) {
            return .mostRecent
        } else {
            return .discreteAverage
        }
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
        var quantity: HKQuantity?
        if #available(iOS 13.0, *) {
            quantity = statistic.mostRecentQuantity()
        } else {
            quantity = statistic.averageQuantity()
        }
        
        if let unwrappedQuantity = quantity {
            let value = unwrappedQuantity.doubleValue(for: unit)
            return formatDoubleAsString(value: value)
        }

        return nil
    }
}
