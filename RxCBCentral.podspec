Pod::Spec.new do |s|
  s.name             = 'RxCBCentral'
  s.version          = '0.1.0'
  s.summary          = 'A reactive, interface-driven central role Bluetooth LE library for iOS'
  s.description      = 'A reactive, interface-driven central role Bluetooth LE library for iOS'

  s.homepage         = 'https://github.com/uber/RxCBCentral'
  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE.txt' }
  s.author           = { 'jpsoultanis' => 'jsoultanis@uber.com' }
  s.source           = { :git => 'https://github.com/uber/RxCBCentral.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = 'Sources/**/*.swift'

  s.frameworks = 'UIKit', 'Foundation', 'CoreBluetooth'
  s.dependency 'ReactiveX/RxSwift', '~> 4.5.0'
  s.dependency 'RxSwiftCommunity/RxOptional', '~> 3.1.3'
end
