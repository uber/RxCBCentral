/**
 *  Copyright (c) 2019 Uber Technologies, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation
import RxSwift

protocol Logger {
    func log(_ message: String)
    func log(_ data: Data)
}

public protocol LoggingStream {
    func read() -> Observable<String>
}


/// A logger that exposes RxCBCentral state changes as a sequence of logs that a consumer can subscribe to to receive updates.
public class RxCBLogger: Logger, LoggingStream {
    
    public static let sharedInstance = RxCBLogger()
    
    private init() { }
    
    func log(_ message: String) {
        _logSubject.onNext(message)
    }
    
    func log(_ data: Data) {
        log("Data: \(data.hexEncodedString())")
    }
    
    public func read() -> Observable<String> {
        return _logSubject.asObservable()
    }
    
    private let _logSubject = ReplaySubject<String>.create(bufferSize: 1)
}

extension Data {
    func hexEncodedString() -> String {
        return "0x" + map { String(format: "%02hhx", $0) }.joined()
    }
}
