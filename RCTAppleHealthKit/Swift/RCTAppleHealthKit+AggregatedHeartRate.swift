//
//  RCTAppleHealthKit+AggregatedHeartRate.swift
//  RCTAppleHealthKit
//
//  Created by Gabrielle Earnshaw on 10/09/2024.
//

import Foundation
import HealthKit

@objc extension RCTAppleHealthKit {
    
    @available(iOS 11.0, *)
    @objc(getAggregatedHeartRate:callback:)
    func getAggregatedHearthRate(options: NSDictionary, callback: @escaping RCTResponseSenderBlock) {
        
        guard let healthStore = healthStore else {
            callback(["Error - no healthstore"])
            return
        }
        
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            callback(["Error - didn't get heart rate type"])
            return
        }
        
        guard let start = dateFromOptions(options: options, key: "startTime") else {
            callback(["Error - didn't get start date"])
            return
        }
        let end = dateFromOptions(options: options, key: "endTime")
        let interval = intervalFromOptions(options: options, key: "bucketPeriod")
        guard let anchorDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: start) else {
            callback(["Error - didn't get anchor date"])
            return
        }
        
        let predicate = createPredicate(from: start, to: end)
        let query = HKStatisticsCollectionQuery(quantityType: heartRateType,
                                                quantitySamplePredicate: predicate,
                                                options: .discreteAverage,
                                                anchorDate: anchorDate,
                                                intervalComponents: interval
        )
        
        query.initialResultsHandler = { query, results, error in
                guard let statsCollection = results else { return }

                for statistics in statsCollection.statistics() {
                    guard let quantity = statistics.averageQuantity() else { continue }

                    let beatsPerMinuteUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                    let value = quantity.doubleValue(for: beatsPerMinuteUnit)

                    let df = DateFormatter()
                    df.dateStyle = .medium
                    df.timeStyle = .none
                    print("On \(df.string(from: statistics.startDate)) the average heart rate was \(value) beats per minute")
                    
                    if let min = statistics.minimumQuantity() {
                        print("min was \(min)")
                    } else {
                        print("No min")
                    }
                    
                    if let max = statistics.maximumQuantity() {
                        print("max was \(max)")
                    } else {
                        print("No max")
                    }
                }
            }

            healthStore.execute(query)
                
        
        callback(["Did this work?"])
    }
}
