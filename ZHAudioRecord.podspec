#
#  Be sure to run `pod spec lint ZHAudioRecord,podspec.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "ZHAudioRecord"
  s.version      = "0.0.2"
  s.summary      = "Simple audio recording with audio spectrum, similar to WeChat"
  s.homepage     = "https://github.com/SixtyTwoPlus/ZHAudioRecord.git"
  s.license      = "MIT"
  s.author       = { "zhl" => "z779215878@gmail.com" }
  s.platform     = :ios
  s.ios.deployment_target = "9.0"

  s.source       = { :git => "https://github.com/SixtyTwoPlus/ZHAudioRecord.git", :tag => "v#{s.version}" }

  s.source_files = 'ZHAudioRecord/*'
  s.frameworks   = 'Foundation', 'UIKit' , 'AVFoundation'
  s.requires_arc = true
  s.dependency	'Masonry'
end
