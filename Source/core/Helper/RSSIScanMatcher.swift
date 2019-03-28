//
//  Copyright © Uber Technologies, Inc. All rights reserved.
//

import CoreBluetooth
import RxSwift

// A ScanMatcher that matches us with the peripheral that is closest in proximity
class RSSIScanMatcher: ScanMatching {
    
    // If we haven't discovered any new peripherals in `discoverInterval` seconds, return best matching peripheral
    static let defaultDiscoverInterval: RxTimeInterval = 5
    
    init() {}
    
    func accept(_ scanData: ScanData) -> Observable<CBPeripheral> {
        // add newly discovered peripheral to dictionary
        peripherals[scanData.peripheral] = scanData.RSSI.doubleValue
        peripheralsSubject.onNext(peripherals)
        
        return
            peripheralsSubject
                .asObservable()
                // TODO: test this in test harnass once complete
                // if Apple's didDiscoverPeripheral func re-emits the same peripherals with new RSSIs over time,
                // we need to change this distinctUntilChanged to only check CBPeripherals and not their RSSI values
                .distinctUntilChanged()
                .flatMapLatest { _ -> Observable<Int> in
                    // resets the timer every time new peripherals are discovered
                    return Observable<Int>.timer(RSSIScanMatcher.defaultDiscoverInterval, scheduler: ConcurrentDispatchQueueScheduler(qos: .default))
                }
                .take(1)
                .flatMapLatest { _ -> Observable<CBPeripheral> in
                    // after no new peripherals are discovered for a few seconds, return the closest one
                    return self.getMinRSSIPeripheral()
        }
    }
    
    // A helper function that returns the peripheral that is closest in proximity, if one exists.
    private func getMinRSSIPeripheral() -> Observable<CBPeripheral> {
        return
            Observable.create { observer in
                // note: the closer RSSI is to 0, the closer in proximity a device is. That is why we use absolute value in our min calculation.
                let minRSSIPeripheralData = self.peripherals.min { pair1, pair2 in abs(pair1.value) < abs(pair2.value) }
                
                if let minRSSIPeripheralData = minRSSIPeripheralData {
                    observer.onNext(minRSSIPeripheralData.key)
                    observer.onCompleted()
                }
                
                return Disposables.create()
        }
    }
    
    private typealias RSSI = Double
    private var peripherals = [CBPeripheral: RSSI]()
    private let peripheralsSubject = ReplaySubject<[CBPeripheral: RSSI]>.create(bufferSize: 1)
}

