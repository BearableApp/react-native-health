//
//  BucketedHealthType.swift
//  RCTAppleHealthKit
//
//  Copyright © 2024 Bearable. All rights reserved.
//

import Foundation

protocol BucketedQueryType {
    func quantityType() -> HKQuantityType?
    func queryOptions() -> HKStatisticsOptions
    func statisticsUnit(unitString: String?) -> HKUnit
    func statisticsValue(statistic: HKStatistics, unit: HKUnit) -> String?
}
