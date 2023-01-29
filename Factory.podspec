Pod::Spec.new do |s|
  s.name         = "Factory"
  s.version      = "1.3.6"
  s.summary      = "A Modern Dependency Injection / Service Locator framework for Swift on iOS."
  s.homepage     = "https://github.com/hmlongco/Factory"
  s.license      = "MIT"
  s.author       = "Michael Long"
  s.source       = { :git => "https://github.com/hmlongco/Factory.git", :tag => "#{s.version}" }
  s.source_files  = "Classes", "Sources/Factory/*.swift"
  s.swift_version = '5.1'

  s.ios.deployment_target = "11.0"
  s.tvos.deployment_target = "13.0"
  s.osx.deployment_target = "10.14"
  s.watchos.deployment_target = "6.0"
end
