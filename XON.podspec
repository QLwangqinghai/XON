Pod::Spec.new do |s|
  s.name             = 'XON'
  s.version          = '0.1.0'
  s.summary          = 'XON.'

  s.description      = 'XON.'

  s.homepage         = 'https://github.com/QLwangqinghai/XON'
  s.license  = { :type => 'MIT'}
  s.author           = { '' => '' }
  s.source           = { :git => 'https://github.com/QLwangqinghai/XON.git', :tag => "#{s.version}"}

  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = "12.0"

  s.dependency 'CX'

  s.public_header_files = "Sources/XON/include/*.h"
  s.source_files = "Sources/XON/**/*.{h,c,m,cpp,swift}"

end
