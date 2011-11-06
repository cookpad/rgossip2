Gem::Specification.new do |spec|
  spec.name              = 'rgossip2'
  spec.version           = '0.1.2'
  spec.summary           = 'Basic implementation of a gossip protocol. This is a porting of Java implementation. see http://code.google.com/p/gossip-protocol-java/'
  spec.require_paths     = %w(lib)
  spec.files             = %w(README) + Dir.glob('bin/**/*') + Dir.glob('lib/**/*')
  spec.author            = 'winebarrel'
  spec.email             = 'sgwr_dts@yahoo.co.jp'
  spec.homepage          = 'https://bitbucket.org/winebarrel/rgossip2'
  spec.executables << 'gossip'
  spec.add_dependency('msgpack')
end
