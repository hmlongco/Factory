Pod::Spec.new do |s|
  s.name         = "Factory"
  s.version      = "2.3.2"
  s.summary      = "A Modern Dependency Injection / Service Locator framework for Swift on iOS."
  s.homepage     = "https://github.com/hmlongco/Factory"
  s.license      = "MIT"
  s.author       = "Michael Long"
  s.source       = { :git => "https://github.com/hmlongco/Factory.git", :tag => "#{s.version}" }
  s.source_files  = "Sources/**/*.swift"
  s.resource_bundles = { "Factory" => "Sources/**/*.xcprivacy" }
  s.swift_version = '5.9'

  s.ios.deployment_target = "12.0"
  s.ios.framework  = 'UIKit'

  s.tvos.deployment_target = "13.0"
  s.tvos.framework  = 'UIKit'

  s.watchos.deployment_target = "8.2"
  s.watchos.framework  = 'SwiftUI'

  s.osx.deployment_target = "10.14"
  s.osx.framework  = 'AppKit'
end
