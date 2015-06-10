Pod::Spec.new do |s|
  s.name         = "CalqClient-iOS"
  s.version      = "1.0.2"
  s.summary      = "Calq analytics client SDK for iOS."
  s.homepage     = "https://calq.io"
  s.license      = { :type => "Apache2" }
  s.author       = { "Calq" => "support@calq.io" }
  s.source       = { :git => "https://github.com/Calq/Client-iOS.git", :tag => "v#{s.version}" }
  s.platform     = :ios, '6.0'
  s.source_files = 'CalqClient/**/*.{h,m}'
  s.requires_arc = true
  s.library      = 'sqlite3'
end