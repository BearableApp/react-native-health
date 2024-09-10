//
//  RCTAppleHealthKit.swift
//  RCTAppleHealthKit
//
//  Copyright © 2024 Bearable. All rights reserved.
//

import Foundation
import HealthKit
import CoreLocation

@objc extension RCTAppleHealthKit {
    @available(iOS 11.0, *)
    @objc(readBucketedSteps:resolve:reject:)
    func readBucketedSteps(
    options: NSDictionary,
    resolve: @escaping RCTPromiseResolveBlock,
    reject: @escaping RCTPromiseRejectBlock
    ) {
    guard let healthStore = healthStore else {
        reject(INIT_ERROR, INIT_ERROR_MESSAGE, nil)
        return
    }

    // Setup query parameters
    guard let quantityType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
        reject(UNEXPECTED_ERROR, "Unable to create a step count type", nil)
        return
    }
    guard let start = dateFromOptions(options: options, key: "startTime") else {
        reject(INVALID_OPTIONS_ERROR, "Start date must be provided", nil)
        return
    }
    let end = dateFromOptions(options: options, key: "endTime")
    let interval = intervalFromOptions(options: options, key: "bucketPeriod")
      
    let predicate = createPredicate(from: start, to: end)

    let query = HKStatisticsCollectionQuery(quantityType: quantityType,
                                 quantitySamplePredicate: predicate,
                                                 options: .cumulativeSum,
                                              anchorDate: start,
                                      intervalComponents: interval)
      
    // Handle query results
    query.initialResultsHandler = {
        query, results, error in

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
            reject(UNEXPECTED_ERROR, "An error occurred fetching the user's step count.", nil)
            return
        }

        let records: NSMutableArray = []
        // Loop over all the statistics objects
        for statistics in statsCollection.statistics() {
            if let quantity = statistics.sumQuantity() {
                let date = statistics.startDate
                let value = quantity.doubleValue(for: .count())

                let record = formatRecord(date: date, type: STEPS_RECORD_TYPE, value: value)
                records.add(record)
            }
        }
        
        DispatchQueue.main.async {
            resolve(records)
        }
    }
      
    healthStore.execute(query)
    }
}
