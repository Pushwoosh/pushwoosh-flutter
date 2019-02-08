#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'pushwoosh_inbox'
  s.version          = '1.12.1'
  s.summary          = 'Pushwoosh Inbox Flutter plugin'
  s.homepage         = 'http://pushwoosh.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Pushwoosh' => 'support@pushwoosh.com'  }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.static_framework = true

  s.vendored_libraries = 'Library/libPushwooshInboxUI.a'
  s.libraries = "PushwooshInboxUI"
  s.resources = "Library/PushwooshInboxBundle.bundle"
  
  s.ios.deployment_target = '8.0'
end

