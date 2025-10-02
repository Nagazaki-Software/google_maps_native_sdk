Pod::Spec.new do |s|
  s.name             = 'google_maps_native_sdk'
  s.version          = '0.6.5'
  s.summary          = 'Native Google Maps plugin for Flutter'
  s.description      = <<-DESC
    Flutter plugin bridging Google Maps SDK with markers, polylines, caching and events.
  DESC
  s.homepage         = 'https://example.com'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Author' => 'author@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.platform         = :ios, '12.0'
  s.frameworks       = 'UIKit', 'CoreLocation'
  # Optional CarPlay helpers (host app must add CarPlay extension)
  s.frameworks      += ['CarPlay']
  s.dependency 'Flutter'
  s.dependency 'GoogleMaps'
  s.dependency 'Google-Maps-iOS-Utils'
  s.static_framework = true
  s.swift_version    = '5.0'
end
