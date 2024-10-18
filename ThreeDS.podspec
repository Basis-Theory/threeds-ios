Pod::Spec.new do |s|
  s.name = 'ThreeDS'
  s.ios.deployment_target = '15.6'
  s.version = '0.2.2'
  s.source = { :git => 'https://github.com/Basis-Theory/3ds-ios.git', :tag => '0.2.2' }
  s.authors = 'BasisTheory'
  s.license = 'Apache'
  s.homepage = 'https://github.com/Basis-Theory/3ds-ios'
  s.summary = 'BasisTheory 3DS iOS SDK'
  s.description = 'An SDK to support 3D Secure authentication for iOS applications using the BasisTheory platform.'
  s.source_files = 'ThreeDS/Sources/**/*.swift'
  s.swift_version = '5.5'
  s.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'COCOAPODS=1' }
end
