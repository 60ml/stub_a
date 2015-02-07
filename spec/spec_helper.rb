require 'rspec'
require 'stub_a'

Dir.glob(File.join(File.dirname(__FILE__), 'support', '**', '*.rb')) do |f|
  require f
end

RSpec.configure do |config|
end

