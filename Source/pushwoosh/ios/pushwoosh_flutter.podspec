#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'pushwoosh_flutter'
  s.version          = '2.3.25'
  s.summary          = 'Pushwoosh Flutter plugin'
  s.homepage         = 'https://pushwoosh.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Pushwoosh' => 'support@pushwoosh.com' }
  s.source           = { :path => '.' }
  s.source_files = 'pushwoosh_flutter/Sources/pushwoosh_flutter/**/*'
  s.public_header_files = 'pushwoosh_flutter/Sources/pushwoosh_flutter/include/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'PushwooshXCFramework', '7.2.8'
  s.dependency 'PushwooshXCFramework/PushwooshLiveActivities'
  s.dependency 'PushwooshXCFramework/PushwooshInApp'
  s.static_framework = true


  s.ios.deployment_target = '15.0'
end
