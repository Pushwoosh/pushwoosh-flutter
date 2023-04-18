#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'pushwoosh'
  s.version          = '2.2.13'
  s.summary          = 'Pushwoosh Flutter plugin'
  s.homepage         = 'https://pushwoosh.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Pushwoosh' => 'support@pushwoosh.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.static_framework = true

  s.vendored_libraries = 'Library/libPushwoosh_native.a'
  s.libraries = "Pushwoosh_native", 'c++', 'z'

  s.ios.deployment_target = '10.0'
end