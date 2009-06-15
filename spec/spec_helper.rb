require 'rubygems'
require 'spec'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rakismet'

Spec::Runner.configure do |config|
  config.before(:each) { FakeWeb.clean_registry }  
end
