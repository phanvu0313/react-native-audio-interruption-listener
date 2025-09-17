require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = package['name']
  s.version      = package['version']
  s.summary      = 'Trình lắng nghe gián đoạn âm thanh cho React Native (Old Architecture)'
  s.description  = package['description']
  s.license      = package['license']
  s.homepage     = package['repository']
  s.authors      = { 'Pham Vu' => 'you@example.com' }
  s.platforms    = { :ios => '11.0' }
  s.source       = { :git => 'https://github.com/phanvu0313/react-native-audio-interruption-listener.git',
                     :tag => s.version }
  s.source_files = 'ios/**/*.{h,m,mm}'
  s.requires_arc = true
  s.frameworks   = 'AVFoundation'
  s.dependency   'React-Core'
end
