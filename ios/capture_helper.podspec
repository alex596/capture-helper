#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint capture_helper.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'capture_helper'
  s.version          = '1.2.0'
  s.summary          = 'Document scanning and compression for Flutter, powered by VisionKit.'
  s.description      = <<-DESC
Cross-platform Flutter plugin for document capture, image enhancement and PDF compression.
Uses the native VisionKit document camera on iOS.
                       DESC
  s.homepage         = 'https://github.com/alex596/capture-helper'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Alexis Louis' => 'support@alexislouis.xyz' }
  s.source           = { :path => '.' }
  s.source_files = 'capture_helper/Sources/capture_helper/**/*.swift'
  s.resource_bundles = {'capture_helper_privacy' => ['capture_helper/Sources/capture_helper/PrivacyInfo.xcprivacy']}
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
