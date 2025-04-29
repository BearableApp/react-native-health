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

    @available(iOS 11.0, *)
    @objc(readBucketedSleep:resolve:reject:)
    func readBucketedSleep(
        options: NSDictionary,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        guard let healthStore = healthStore else {
            reject(INIT_ERROR, INIT_ERROR_MESSAGE, nil)
            return
        }
        
        guard let start = dateFromOptions(options: options, key: "startTime") else {
            reject(INVALID_OPTIONS_ERROR, "Start date must be provided", nil)
            return
        }

        if intervalFromOptions(options: options, key: "bucketPeriod") != DateComponents(day: 1) {
            reject(INVALID_OPTIONS_ERROR, "Bucket period is not supported - please use 'day'", nil)
            return
        }
        
        let end = dateFromOptions(options: options, key: "endTime")
        let predicate = createPredicate(from: start, to: end)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let bucketedSleep = BucketedSleep()
        guard let categoryType = bucketedSleep.categoryType() else {
            reject(UNEXPECTED_ERROR, "No matching category type to \(bucketedSleep.recordType)", nil)
            return
        }

        let query = HKSampleQuery(sampleType: categoryType, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: [sortDescriptor]) {
            query, results, error in
            
            guard let sleepSamples = results as? [HKCategorySample] else {
                reject(UNEXPECTED_ERROR, "An error occurred fetching records for sleep", nil)
                return
            }

            var sampleDict: [String: [SleepType: [SimpleSleepSample]]] = [:]
            let cutOffHour = Calendar.current.component(.hour, from: start)
            
            for sleepSample in sleepSamples {
                let dateKey = formatSleepDateKey(date: sleepSample.startDate, cutOff: cutOffHour)
                
                let sleepSampleType = findSleepType(value: sleepSample.value)
                if sleepSampleType == .awake {
                    continue
                }

                var sleepTypeDict = sampleDict[dateKey, default: [:]]
                var samplesForType = sleepTypeDict[sleepSampleType, default: []]
                var newSample = SimpleSleepSample(startDate: sleepSample.startDate, endDate: sleepSample.endDate, type: sleepSampleType)
                
                if let lastSample = samplesForType.last, lastSample.endDate > sleepSample.startDate {
                    if lastSample.endDate >= sleepSample.endDate {
                        // Full overlap - don't include sample
                        continue
                    }
                    
                    // Partial overlap - Remove the last sample and update the new samples start date to use the last samples start date
                    newSample.startDate = lastSample.startDate
                    samplesForType.removeLast()
                }
                
                samplesForType.append(newSample)
                sleepTypeDict[sleepSampleType] = samplesForType
                sampleDict[dateKey] = sleepTypeDict
            }
            
            var records: [Any] = []
            for (dateKey, sleepSamplesForDate) in sampleDict {
                guard let sleepValue = bucketedSleep.calculateSleepValue(samplesForDate: sleepSamplesForDate) else {
                    continue
                }
                if sleepValue.duration.isZero {
                    continue
                }
                
                records.append(formatSleepRecord(date: dateKey, type: bucketedSleep.recordType, sleepValue: sleepValue))
            }

            DispatchQueue.main.async {
                resolve(records)
            }
        }
        
        healthStore.execute(query)
    }
}
