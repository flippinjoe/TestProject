Pod::Spec.new do |s|
  s.name         = "MercuryCore"
  s.version      = "0.0.3"
  s.platform     = :ios
  s.summary      = "A package of M3 api for ios.."
  s.homepage     = "https://github.com/MercuryIntermedia/MercuryCoreLib-iOS"
  s.author       = { "Brandon Titus" => "btitus@mercury.io", "Joe Ridenour" => "jridenour@mercury.io" }
  s.source       = { :git => "https://github.com/MercuryIntermedia/MercuryCoreLib-iOS.git", :tag => "v#{s.version}" }
  s.ios.deployment_target = '5.0'
  s.source_files = 'MercuryCore/Classes/**/*{.h,.m}'
  s.license = { :type => 'Custom', :text => 'Copyright (C) 2013 Mercury Intermedia. All Rights Reserved.' }
  
  s.exclude_files = 'MercuryCore/Excludes/**/*'
  s.exclude_files = 'MercuryCore/External/**/*'
  s.resources = 'MercuryCore/Classes/**/*.{xcdatamodeld,xcdatamodel}'

  s.requires_arc = true
  s.libraries = 'xml2', 'z'
  s.frameworks = 'CoreData', 'CoreLocation', 'Security'
  s.xcconfig = { 'OTHER_LDFLAGS' => '-lxml2 -ObjC', 'HEADER_SEARCH_PATHS'=>'$(SDKROOT)/usr/include/libxml2'}
    
  s.dependency 'TouchJSON'
  s.dependency 'TouchXML'
  s.dependency 'SFHFKeychainUtils'
end