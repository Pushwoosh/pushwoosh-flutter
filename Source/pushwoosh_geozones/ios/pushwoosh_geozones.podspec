#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'pushwoosh_geozones'
  s.version          = '2.3.25'
  s.summary          = 'Pushwoosh Geozones Flutter plugin'
  s.homepage         = 'http://pushwoosh.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Pushwoosh' => 'support@pushwoosh.com' }
  s.source           = { :path => '.' }
  s.source_files = 'pushwoosh_geozones/Sources/pushwoosh_geozones/**/*'
  s.public_header_files = 'pushwoosh_geozones/Sources/pushwoosh_geozones/include/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'PushwooshXCFramework/Geozones'
  s.static_framework = true

  s.ios.deployment_target = '15.0'
end

