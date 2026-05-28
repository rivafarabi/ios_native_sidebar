#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint ios_native_sidebar.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'ios_native_sidebar'
  s.version          = '0.0.1'
  s.summary          = 'Native iPadOS/iOS sidebar with UISplitViewController and iOS 26 liquid glass.'
  s.description      = <<-DESC
  A Flutter plugin that renders a native iPadOS sidebar using UISplitViewController,
  with iOS 26 liquid glass aesthetics and adaptive iPhone support.
                       DESC
  s.homepage         = 'https://github.com/example/ios_native_sidebar'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '16.0'
  s.swift_version = '5.9'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
