//
//  Copyright © Uber Technologies, Inc. All rights reserved.
//

import CoreBluetooth
import RxSwift

// A ScanMatcher that matches us with the peripheral that is closest in proximity
public final class RSSIScanMatcher: ScanMatching {
    
    // If we haven't discovered any new peripherals in `discoverInterval` seconds, return best matching peripheral
    static let defaultDiscoverInterval: RxTimeInterval = 5
    
    public init(scheduler: SchedulerType = ConcurrentDispatchQueueScheduler(qos: .default)) {
        self.scheduler = scheduler
    }
    
    public func accept(_ scanData: ScanData) -> Observable<CBPeripheral> {
        // add newly discovered peripheral to dictionary
        peripheralsDict[scanData.peripheral] = scanData.RSSI.doubleValue
        peripheralsSubject.onNext(scanData.peripheral)
        
        return
            peripheralsSubject
                .asObservable()
                // TODO: test this in test harnass once complete
                // we ignore peripherals that may be rediscovered with changing RSSIs for now, and only take the first calculated RSSI
                .distinctUntilChanged()
                .flatMapLatest { _ -> Observable<Int> in
                    // resets the timer every time new peripherals are discovered
                    return Observable<Int>.timer(RSSIScanMatcher.defaultDiscoverInterval, scheduler: self.scheduler)
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
                let minRSSIPeripheralData = self.peripheralsDict.min { pair1, pair2 in abs(pair1.value) < abs(pair2.value) }
                
                if let minRSSIPeripheralData = minRSSIPeripheralData {
                    observer.onNext(minRSSIPeripheralData.key)
                    observer.onCompleted()
                }
                
                return Disposables.create()
            }
    }
    
    private typealias RSSI = Double
    private var peripheralsDict = [CBPeripheral: RSSI]()
    private let peripheralsSubject = ReplaySubject<CBPeripheral>.create(bufferSize: 1)
    private let scheduler: SchedulerType
}

