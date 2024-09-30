//
//  BucketedBodyTemperature.swift
//  RCTAppleHealthKit
//
//  Copyright © 2024 Bearable. All rights reserved.
//

import Foundation

class BucketedBodyTemperature: BucketedQueryType {
    var recordType: RecordType = .bodyTemperature
    
    func quantityType() -> HKQuantityType? {
        return HKObjectType.quantityType(forIdentifier: .bodyTemperature)
    }
    
    func queryOptions() -> HKStatisticsOptions {
        return .discreteAverage
    }
    
    func statisticsUnit(unitString: String?) -> HKUnit {
        switch unitString {
        case "celsius":
            return .degreeCelsius()
        case "fahrenheit":
            return .degreeFahrenheit()
        default:
            return .degreeCelsius()
        }
    }
    
    func statisticsValue(statistic: HKStatistics, unit: HKUnit) -> String? {
        if let quantity = statistic.averageQuantity() {
            let value = quantity.doubleValue(for: unit)
            return formatDoubleAsString(value: value)
        }
        return nil
    }
}
