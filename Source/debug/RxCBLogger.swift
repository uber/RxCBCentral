//
//  Copyright (c) 2019 Uber Technologies, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import RxSwift

protocol RxCBLogging {
    func log(_ message: String,
             function: String,
             file: String,
             line: UInt)
    
    func log(prefix: String,
             data: Data?,
             function: String,
             file: String,
             line: UInt)
}

public protocol RxCBLogStream {
    func read() -> Observable<RxCBLog>
}

/// A singleton logger that exposes RxCBCentral state changes as a sequence of logs that a consumer can subscribe to to receive updates.
public class RxCBLogger: RxCBLogging, RxCBLogStream {
    
    public static let sharedInstance = RxCBLogger()
    
    private init() { }
    
    /// Base logging func.
    func log(_ message: String,
             function: String = #function,
             file: String = #file,
             line: UInt = #line) {
        
        _logSubject.onNext((message: message,
                            function: function,
                            file: file,
                            line: line))
    }
    
    /// A helper function to log Data in readable hex string form.
    func log(prefix: String = "RxCBentral - Data: ",
             data: Data?,
             function: String = #function,
             file: String = #file,
             line: UInt = #line) {
        
        let dataString = data?.hexEncodedString() ?? "none"
        log(prefix + dataString, function: function, file: file, line: line)
    }
    
    public func read() -> Observable<RxCBLog> {
        return _logSubject.asObservable()
    }
    
    private let _logSubject = ReplaySubject<RxCBLog>.create(bufferSize: 1)
}

extension Data {
    func hexEncodedString() -> String {
        return "0x" + map { String(format: "%02hhx", $0) }.joined()
    }
}

extension RxCBLogging {
    func log(_ message: String,
             function: String = #function,
             file: String = #file,
             line: UInt = #line) {}
    
    func log(prefix: String,
             data: Data?,
             function: String = #function,
             file: String = #file,
             line: UInt = #line) {}
}

public typealias RxCBLog = (message: String, function: String, file: String, line: UInt)
