require 'net/http'
require 'uri'


module Rack
  class Request
    def spam?
      env["rack-middleware.rakismet.spam"]
    end
  end
  
  class Rakismet
    class KeyVerificationError < RuntimeError; end

    class << self
      def extend_hash!
        Hash.class_eval do # stolen from Extlib

          def to_params
             params = self.map { |k,v| normalize_param(k,v) }.join
             params.chop!
             params
           end

          def normalize_param(key, value)
            param = ''
            stack = []

            if value.is_a?(Array)
              param << value.map { |element| normalize_param("#{key}[]", element) }.join
            elsif value.is_a?(Hash)
              stack << [key,value]
            else
              param << "#{key}=#{value}&"
            end

            stack.each do |parent, hash|
              hash.each do |k, v|
                if v.is_a?(Hash)
                  stack << ["#{parent}[#{k}]", v]
                else
                  param << normalize_param("#{parent}[#{k}]", v)
                end
              end
            end

            param
          end
          
        end # class_eval
      end # extend_hash!
    end # class << self
    
    VERIFY_KEY_PATH = "/1.1/verify-key"
    COMMENT_CHECK_PATH = "/1.1/comment-check"
    AKISMET_ADDRESS = "rest.akismet.com"
    
    def initialize(app, api_key, blog, form_mapping, predicate)
      Rakismet.extend_hash! unless Hash.methods.include?("to_params")
      
      @app = app
      @api_key = api_key
      @blog = blog
      @form_mapping = form_mapping
      @predicate = predicate
      api_key_valid? or raise KeyVerificationError
    end

    def call(env)
      env["rack-middleware.rakismet.spam"] = 
        @predicate.call(env["REQUEST_PATH"], env["REQUEST_METHOD"],  env["rack.request.form_hash"]) &&
        comment_check(env)
      @app.call(env)
    end

    protected

    def api_key_valid?
      response, data = Net::HTTP.new(AKISMET_ADDRESS).post(VERIFY_KEY_PATH, { :key => @api_key, :blog => @blog }.to_params)
      data == "valid"
    end
    
    def comment_check(env)
      comment = { :blog => @blog, 
                  :user_ip => env["REMOTE_ADDR"], 
                  :referrer => env["HTTP_REFERER"],
                  :user_agent => env["HTTP_USER_AGENT"] }
      form_data = env["rack.request.form_hash"]
      
      @form_mapping.each do |k, v|
        comment[v] = form_data[k]
      end
      
      response, data = Net::HTTP.new("#{@api_key}.#{AKISMET_ADDRESS}").post(COMMENT_CHECK_PATH, comment.to_params)
      data == "true"
    end
  end
end
