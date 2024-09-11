//
//  RCTAppleHealthKit+BucketedQueries.swift
//  RCTAppleHealthKit
//
//  Copyright © 2024 Bearable. All rights reserved.
//

import Foundation

import HealthKit

@objc extension RCTAppleHealthKit {
    @available(iOS 11.0, *)
    @objc(readBucketedQuantity:options:resolve:reject:)
    func readBucketedQuantity(
        recordType: String,
        options: NSDictionary,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        guard let healthStore = healthStore else {
            reject(INIT_ERROR, INIT_ERROR_MESSAGE, nil)
            return
        }

        guard let queryType = queryTypeFromRecordType(recordType: recordType) else {
            reject(INVALID_OPTIONS_ERROR, "No matching record type for '\(recordType)'", nil)
            return
        }
        guard let start = dateFromOptions(options: options, key: "startTime") else {
            reject(INVALID_OPTIONS_ERROR, "Start date must be provided", nil)
            return
        }
        guard let quantityType = queryType.quantityType() else {
            reject(UNEXPECTED_ERROR, "No matching quantity type to \(recordType)", nil)
            return
        }

        let queryOptions = queryType.queryOptions()
        let interval = intervalFromOptions(options: options, key: "bucketPeriod")
        let end = dateFromOptions(options: options, key: "endTime")
        let predicate = createPredicate(from: start, to: end)

        let query = HKStatisticsCollectionQuery(quantityType: quantityType,
                                     quantitySamplePredicate: predicate,
                                                     options: queryOptions,
                                                  anchorDate: start,
                                          intervalComponents: interval)
        
        // Handle query results
        query.initialResultsHandler = { query, results, error in
            // Handle errors here.
            if let error = error as? HKError {
            switch (error.code) {
            case .errorDatabaseInaccessible:
                reject(UNEXPECTED_ERROR, "HealthKit couldn't access the database because the device is locked.", error)
                // HealthKit couldn't access the database because the device is locked.
                return
            default:
                reject(UNEXPECTED_ERROR, "\(error)", error)
                // Handle other HealthKit errors here.
                return
            }
            }
        
            guard let statsCollection = results else {
                // You should only hit this case if you have an unhandled error. Check for bugs in your code that creates the query, or explicitly handle the error.
                reject(UNEXPECTED_ERROR, "An error occurred fetching records for \(recordType)", nil)
                return
            }

            let records: NSMutableArray = []
            // Loop over all the statistics objects
            for statistics in statsCollection.statistics() {
                guard let value = queryType.statisticsValue(statistic: statistics) else {
                    continue
                }

                let record = formatRecord(date: statistics.startDate, type: queryType.recordType, value: value)
                records.add(record)
            }
            
            DispatchQueue.main.async {
                resolve(records)
            }
        }
        
        healthStore.execute(query)
    }
}
