Pod::Spec.new do |s|
  s.name         = "Factory"
  s.version      = "2.2.0"
  s.summary      = "A Modern Dependency Injection / Service Locator framework for Swift on iOS."
  s.homepage     = "https://github.com/hmlongco/Factory"
  s.license      = "MIT"
  s.author       = "Michael Long"
  s.source       = { :git => "https://github.com/hmlongco/Factory.git", :tag => "#{s.version}" }
  s.source_files  = "Sources/**/*.swift"
  s.swift_version = '5.6'

  s.ios.deployment_target = "11.0"
  s.tvos.deployment_target = "13.0"
  s.watchos.deployment_target = "8.2"
  s.osx.deployment_target = "10.14"
end
