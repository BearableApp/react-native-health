<img style="float: left;" src="https://i.imgur.com/q5PS8gU.png">

# React Native Health

A React Native package to interact with Apple HealthKit for iOS. Originally maintained with ❤️ by [AE Studio](https://ae.studio) but it has been heavily adapted for [Bearable](https://github.com/BearableApp/client-bearable).

This package allows access to health & fitness data exposed by Apple Healthkit and returns data in the specific format to Bearable's need.

## Getting Started

### Automatic Installation

1. Install the react-native-health package from the [github repo](https://github.com/BearableApp/react-native-health).

```
yarn add https://github.com/BearableApp/react-native-health
```

2. If you are using [CocoaPods](https://cocoapods.org/) you can run the following
   from the `ios/` folder of your app

```
pod install
```

Or, if you need to manually link it, run

```
react-native link react-native-health
```

3. Update the `ios/<Project Name>/info.plist` file in your project

```
<key>NSHealthShareUsageDescription</key>
<string>Read and understand health data.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>Share workout data with other apps.</string>
<!-- Below is only required if requesting clinical health data -->
<key>NSHealthClinicalHealthRecordsShareUsageDescription</key>
<string>Read and understand clinical health data.</string>
```

To add Healthkit support to your application's `Capabilities`

- Open the `ios/` folder of your project in Xcode
- Select the project name in the left sidebar
- In the main view select '+ Capability' and double click 'HealthKit'

To enable access to clinical data types, check the `Clinical Health Records` box.

## Usage

### Permissions

In order to start collecting or saving data to HealthKit, you need to request
the user's permissions for the given data types. It can be done in the following
way

```typescript
import AppleHealthKit, {
  HealthValue,
  HealthKitPermissions,
} from 'react-native-health'

/* Permission options */
const permissions = {
  permissions: {
    read: [AppleHealthKit.Constants.Permissions.HeartRate],
    write: [AppleHealthKit.Constants.Permissions.Steps],
  },
} as HealthKitPermissions

AppleHealthKit.initHealthKit(permissions, (error: string) => {
  /* Called after we receive a response from the system */

  if (error) {
    console.log('[ERROR] Cannot grant permissions!')
  }

  /* Can now read from HealthKit */
})
```

Due to Apple's privacy model, if a user has previously denied a
specific permission they will not be prompted again for that permission.
The user will need to go into the Apple Health app and grant the
permission to your app.

For any data written to Healthkit, an authorization error can be caught. If
an authorization error occurs, you can prompt the user to set the
specific permission or add the permission to the options object when
initializing the library.

If extra read or write permissions are added to the options object, the
app will request the user's permission when the library is
initialized again.

### Reading Data

#### `readBucketedQuantity`

This function reads data for a record type and buckets it into intervals from the start date provided.

```typescript
import AppleHealthKit, { BucketedReadOptions } from 'react-native-health'

const options: BucketedReadOptions = {
  startTime: '2024-01-01 00:00:00.000', // Local time
  endTime: '2024-02-01 00:00:00.000', // Local time
  bucketPeriod: 'day',
  unit: 'pound',
}

const records = await AppleHealthKit.readBucketedQuantity('WEIGHT', options)

// Expected record format
const expectedRecords = [
  {
    dateKey: '20240101',
    entry: {
      type: 'WEIGHT',
      value: '134', // See table below for expected value format and units
      family: 'HEALTH',
    },
  },
]
```

The start and end times should be local times and the bucket period will cover the period from the start time. For example if your start date was at 12 noon with an bucket period of a day it would cover the interval between 12 noon of the first date and 12 noon on the next day. Bucket periods can be `day`, `month` or `year`. Units provided are specific to their record type, see the table below for the available record type, its value format and their units.

| Record Type            | Value Format                       | Units (default first)     |
| ---------------------- | ---------------------------------- | ------------------------- |
| STEPS                  | `'{total}'`                        | `count`                   |
| WEIGHT                 | `'{latest}'`                       | `kg` or `pound`           |
| HEART                  | `'{min}/{avg}/{max}'`              | `bpm`                     |
| PRESSURE               | `'{systolic_avg}/{diastolic_avg}'` | `mmhg`                    |
| RESTING_HEART_RATE     | `'{avg}'`                          | `bpm`                     |
| BODY_TEMPERATURE       | `'{avg}'`                          | `celsius` or `fahrenheit` |
| HEART_RATE_VARIABILITY | `'{avg}'`                          | `ms`                      |

#### `readBucketedSleep`

This function reads data for a sleep samples and buckets it into intervals from the start date provided. Since sleep is health kit [category type](https://developer.apple.com/documentation/healthkit/hkcategorytype) it has been handled as a different function.

```typescript
import AppleHealthKit, { BucketedReadOptions } from 'react-native-health'

const options: BucketedReadOptions = {
  startTime: '2024-01-01 00:00:00.000', // Local time
  endTime: '2024-02-01 00:00:00.000', // Local time
}

const records = await AppleHealthKit.readBucketedSleep(options)

// Expected record format
const expectedRecords = [
  {
    dateKey: '20240101',
    entry: {
      type: 'SLEEP',
      value: '7:30', // h:mm
      family: 'HEALTH',
      timesInBed: {
        inBedAt: '2023-12-31 23:55:00.000',
        outOfBedAt: '2024-01-01 09:30:00.000',
      },
      sleepTimes: {
        fellAsleepAt: '2024-01-01 00:30:00.000',
        wokeUpAt: '2024-01-01 08:00:00.000',
      },
    },
  },
]
```

The start and end times should be local times and the bucket period will cover the period from the start time. Bucket periods can only be `day`. The value is the hours and minutes asleep.

## Contributing

### Adding a New Record Type

The `readBucketedQuantity` can be extended easily to add new record types. These record types need to be a health kit [quantity type](https://developer.apple.com/documentation/healthkit/hkquantitytype).

1. Update the `RecordType` with the new health type in _index.d.ts_
2. Update the `RecordType` enum with the the new health type in _Constants.swift_
3. Create a new bucketed class called `Bucketed{HealthType}.swfit`. Make sure it extends the _BucketedQueryType.swift_ class and has the required functions.
   1. `quantityType` - this should return the health kit defined quantity type
   2. `queryOptions` - this should return a list of [statistics options](https://developer.apple.com/documentation/healthkit/hkstatisticsoptions) such as `.discreteAverage`
   3. `statisticsUnit` - this should return the heath kit [unit](https://developer.apple.com/documentation/healthkit/hkunit) based on any units that are passed in via the options
   4. `statisticsValue` - this should return the string value for the record type
4. Update the `queryTypeFromRecordType` in _Helpers.swift_. Add a new case for the new record type and return a list with the new bucketed class created in step 3. It's possible to use multiple types which returns a value with the values from each class separated by a `/`, See the blood pressure record type as an example.

If your record type is not a quantity type then you will likely need to create a new bucketed function to handle it. Sleep is a category type and has very specific data values hence why it's been done separately. This function could be extended in the future to become more generic for other category types similarly to the structure of quantity types.

## References

- [Apple Healthkit Documentation](https://developer.apple.com/documentation/healthkit)

## Acknowledgement

> _This package is a fork of [brandonballinger/react-native-health](https://github.com/brandonballinger/react-native-health)_ which is a fork of [agencyenterprise/react-native-health](https://github.com/agencyenterprise/react-native-health) which is a fork of [rn-apple-healthkit](https://github.com/terrillo/rn-apple-healthkit)\_

> _This package also inherits additional features from [Nutrisense](https://www.nutrisense.io/) fork_
