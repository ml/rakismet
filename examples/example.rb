require 'rubygems'
require 'sinatra'

require File.join(File.dirname(__FILE__), '..', 'lib', 'rakismet.rb')


get '/' do
  %{<html><head><title>Rakismet</title></head><body>
  <form action="/posts" method="post">
    <label for="comment_author">author</author>
    <input type="text" name="author" id="comment_author" />
    <br />
    <label for="comment_email">email</label>
    <input type="text" name="email" id="comment_email" />
    <br />
    <label for="comment_url">url</author>
    <input type="text" name="url" id="comment_url" />
    <br />
    <label for="comment_content">content</author>
    <input type="text" name="content" id="content" />
    <br />
    
    <input type="submit" value="submit" />
  </form>
  </body></html>}
end

post '/posts' do
  if request.env["rack-middleware.rakismet.spam"]
    "spammer!!"
  else
    "<html><head><title>Rakismet</title></head><body>OHAI!</body></html>"
  end
end

form_mapping = { "author" => :comment_author,
                 "email" => :comment_author_email,
                 "url" => :comment_author_url,
                 "content" => :comment_content }
                 
predicate = lambda do |path, method, form_data|
  path =~ /posts/ && method == "POST"
end

# replace yourkey and yourblog with real credentials or use fakeweb
use Rack::Rakismet, "yourkey", "http://yourblog.wordpress.com", form_mapping, predicate
