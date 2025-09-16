Pod::Spec.new do |s|
  s.name         = "react-native-audio-interruption-listener"
  s.version      = "0.1.0"
  s.summary      = "Lightweight audio interruption listener for React Native (Old Arch)"
  s.license      = "MIT"
  s.authors      = { "you" => "you@example.com" }
  s.platforms    = { :ios => "11.0" }
  s.source       = { :path => "." }
  s.source_files = "ios/**/*.{h,m,mm}"
  s.dependency "React-Core"
end
