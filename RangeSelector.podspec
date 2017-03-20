Pod::Spec.new do |s|

  s.name         = "RangeSelector"
  s.version      = "0.1.0"
  s.summary      = "A simple range selector for iOS."

  s.description  = <<-DESC
                    A smple range selector for iOS. This description need to be increased.
                   DESC

  s.homepage     = "https://github.com/scrobby/RangeSelector"
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"

  s.license      = "MIT"

  s.author             = { "Carl Goldsmith" => "me@carlgoldsmith.com" }
  s.social_media_url   = "http://twitter.com/scrobby"

  s.platform     = :ios

  s.source       = { :git => "https://github.com/scrobby/RangeSelector.git", :tag => "#{s.version}" }

  s.source_files  = "RangeSelector/*.{swift,h}"

  s.resource  = "RangeSelector/Media.xcassets"

  s.framework  = "UIKit"

end
