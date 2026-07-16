#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint capture_helper.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'capture_helper'
  s.version          = '1.1.1'
  s.summary          = 'Cross-platform Flutter plugin for advanced document capture, image enhancement, and PDF compression.'
  s.description      = <<-DESC
Cross-platform Flutter plugin for advanced document capture, image enhancement,
and PDF compression. Uses native VisionKit (iOS) and ML Kit (Android) for optimal results.
                       DESC
  s.homepage         = 'https://alexislouis.xyz'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'alex596' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'capture_helper/Sources/capture_helper/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # This plugin ships a privacy manifest. Built with CocoaPods it is packaged as a
  # resource bundle; built with Swift Package Manager it is declared in Package.swift.
  # See https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  s.resource_bundles = {'capture_helper_privacy' => ['capture_helper/Sources/capture_helper/PrivacyInfo.xcprivacy']}
end
