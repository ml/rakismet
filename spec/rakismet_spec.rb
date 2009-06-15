require 'spec_helper'
require 'rack/builder'
require 'rack/mock'
require 'fakeweb'

FakeWeb.allow_net_connect = false

describe Rack do
  describe Rakismet do
    describe "#comment_check" do
      it "should not check comment when predicate does not match" do
         rakismet = create_rakismet(lambda { false })
         rakismet.should_not_receive :comment_check
         rakismet.call({})
      end
  
      it "should check comment if predicate matches" do
         rakismet = create_rakismet(lambda { true })
         rakismet.should_receive :comment_check
         rakismet.call({})
      end
    end
    
    describe "#initialize" do
      it "should throw Rakismet::KeyVerificationError when credentials are invalid" do
        register_akismet_uri "verify-key", "invalid"
      
        lambda { create_rakismet }.should raise_error(Rack::Rakismet::KeyVerificationError)
      end
    
      it "should not throw Rakismet::KeyVerificationError if credentials ar valid" do
        register_akismet_uri "verify-key", "valid"
      
        lambda { create_rakismet }.should_not raise_error(Rack::Rakismet::KeyVerificationError)
      end
    end
  end

  def create_rakismet(predicate = lambda {})
    Rack::Rakismet.new(lambda {}, "key", "http://my.blog.com", {}, predicate)    
  end

  def register_akismet_uri(path, response_text)
    FakeWeb.register_uri :post, "http://rest.akismet.com/1.1/#{path}", :string => response_text, :status => [200, "OK"]
  end
end