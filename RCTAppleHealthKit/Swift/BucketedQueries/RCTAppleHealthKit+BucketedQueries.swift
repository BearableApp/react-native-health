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

        // Make into array
        guard let queryTypes = queryTypeFromRecordType(recordType: recordType) else {
            reject(INVALID_OPTIONS_ERROR, "No matching record type for '\(recordType)'", nil)
            return
        }
        guard let start = dateFromOptions(options: options, key: "startTime") else {
            reject(INVALID_OPTIONS_ERROR, "Start date must be provided", nil)
            return
        }

        let interval = intervalFromOptions(options: options, key: "bucketPeriod")
        let end = dateFromOptions(options: options, key: "endTime")
        let predicate = createPredicate(from: start, to: end)
        
        let dispatchGroup = DispatchGroup()
        var queryTypeError: (message: String, error: Error?)?
        
        var recordsDict: [String: [Int: String]] = [:]

        for (index, queryType) in queryTypes.enumerated() {
            dispatchGroup.enter()

            guard let quantityType = queryType.quantityType() else {
                queryTypeError = (
                    message: "No matching quantity type to \(recordType)",
                    error: nil
                )
                return
            }
            
            let queryOptions = queryType.queryOptions()
            let unit = queryType.statisticsUnit(unitString: unitFromOptions(options: options, key: "unit"))
            
            let query = HKStatisticsCollectionQuery(quantityType: quantityType,
                                         quantitySamplePredicate: predicate,
                                                         options: queryOptions,
                                                      anchorDate: start,
                                              intervalComponents: interval)

            query.initialResultsHandler = { query, results, error in
                if let error = error as? HKError {
                switch (error.code) {
                case .errorDatabaseInaccessible:
                    queryTypeError = (
                        message: "HealthKit couldn't access the database because the device is locked.",
                        error: error
                    )
                    // HealthKit couldn't access the database because the device is locked.
                    return
                default:
                    queryTypeError = (
                        message: "\(error)",
                        error: error
                    )
                    // Handle other HealthKit errors here.
                    return
                }
                }
            
                guard let statsCollection = results else {
                    // You should only hit this case if you have an unhandled error. Check for bugs in your code that creates the query, or explicitly handle the error.
                    queryTypeError = (
                        message: "An error occurred fetching records for \(recordType)",
                        error: nil
                    )
                    return
                }

                // Loop over all the statistics objects
                for statistics in statsCollection.statistics() {
                    // Add value to dictionary and do this in
                    guard let value = queryType.statisticsValue(statistic: statistics, unit: unit) else {
                        continue
                    }
                    
                    let dateKey = formatDateKey(date: statistics.startDate)
                    if recordsDict[dateKey] == nil {
                        recordsDict[dateKey] = [:]
                    }
                    recordsDict[dateKey]?[index] = value
                }
                
                dispatchGroup.leave()
            }
            
            healthStore.execute(query)
        
        }
        
        dispatchGroup.notify(queue: .main) {
            if let error = queryTypeError {
                reject(UNEXPECTED_ERROR, error.message, error.error)
                return
            }
            
            let records: NSMutableArray = []
            for (dateKey, values) in recordsDict {
                if (values.count != queryTypes.count) {
                    continue
                }

                var value = ""
                for (index, _) in queryTypes.enumerated() {
                    if let queryString = values[index] {
                        if !value.isEmpty {
                            value += "/"
                        }
                        value += "\(queryString)"
                    }
                }

                let record = formatRecord(date: dateKey, type: recordType, value: value)
                records.add(record)
                
            }

            resolve(records)
        }
    }
}
