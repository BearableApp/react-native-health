//
//  BucketedHealthType.swift
//  RCTAppleHealthKit
//
//  Copyright © 2024 Bearable. All rights reserved.
//

import Foundation

protocol BucketedQueryType {
    var recordType: RecordType { get }

    func quantityType() -> HKQuantityType?
    func queryOptions() -> HKStatisticsOptions
    func statisticsValue(statistic: HKStatistics) -> String?
}
