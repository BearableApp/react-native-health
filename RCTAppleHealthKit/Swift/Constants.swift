//
//  Constants.swift
//  RCTAppleHealthKit
//
//  Copyright © 2024 Bearable. All rights reserved.
//

import Foundation

let RECORDS_FAMILY = "HEALTH"

enum RecordType: String {
    case steps = "STEPS"
    case heart = "HEART"
    case weight = "WEIGHT"
    case hrv = "HEART_RATE_VARIABILITY"
    case bodyTemperature = "BODY_TEMPERATURE"
    case restingHeart = "RESTING_HEART_RATE"
    case bloodPressure = "PRESSURE"
}

enum SleepType {
    case asleep
    case inBed
    case awake
}
