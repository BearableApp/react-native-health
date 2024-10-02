//
//  BucketedDiastolicBloodPressure.swift
//  RCTAppleHealthKit
//
//  Copyright © 2024 Bearable. All rights reserved.
//

import Foundation

class BucketedDiastolicBloodPressure: BucketedQueryType {
    func quantityType() -> HKQuantityType? {
        return HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)
    }
    
    func queryOptions() -> HKStatisticsOptions {
        return .discreteAverage
    }
    
    func statisticsUnit(unitString: String?) -> HKUnit {
        return HKUnit(from: "mmHg")
    }
    
    func statisticsValue(statistic: HKStatistics, unit: HKUnit) -> String? {
        if let quantity = statistic.averageQuantity() {
            let value = quantity.doubleValue(for: unit)
            return formatDoubleAsString(value: value)
        }
        return nil
    }
}
