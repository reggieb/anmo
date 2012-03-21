require "stringio"

When /^I execute the following code in a new thread$/ do |code|
  Thread.new do
    eval code
  end
end

When /^I execute the code$/ do |code|
  eval code
end

Then /^I see an anmo server on port (\d+)$/ do |port|
  response = nil

  timeout 5 do
    while response.nil?
      response = HTTParty.get("http://localhost:#{port}") rescue nil
    end
  end

  response.body.should include "Not Found"
end

Given /^an anmo server$/ do
  Thread.new do
    Anmo.launch_server
  end

  timeout 5 do
    response = nil
    while response.nil?
      response = HTTParty.get("http://localhost:8787") rescue nil
    end
    sleep 0.1
  end
end

Then /^I issue a get request to the uri "([^"]*)"$/ do |uri|
  @response = HTTParty.get(uri)
end

When /^I issue a put request to the uri "([^"]*)"$/ do |uri|
  @response = HTTParty.put(uri)
end

When /^I request the uri "([^"]*)"$/ do |uri|
  @requested_uri = uri
  @response = HTTParty.get(uri)
end

When /^I request the uri "([^"]*)" with the headers$/ do |uri, headers|
  headers = JSON.parse(headers)
  @response = HTTParty.get(uri, :headers => headers)
end

Then /^I see the response body "([^"]*)"$/ do |body|
  @response.body.should == body
end

Then /^I see the response code (\d+)$/ do |code|
  @response.code.should == code.to_i
end

Then /^that request should be stored$/ do
  Anmo.requests.last["PATH_INFO"].should == @requested_uri.gsub("http://localhost:8787", "")
end

Then /^there should be no stored requests$/ do
  Anmo.requests.size.should == 0
end

Then /^I should see the value$/ do |code|
  @result.should == eval(code)
end

Then /^I see that the anmo server is not running$/ do
  @result.should == false
end

Then /^I see that the anmo server is running$/ do
  @result.should == true
end

Given /^I save an object to the host "([^"]*)"$/ do |host|
  HTTParty.post("http://localhost:8787/__CREATE_OBJECT__", {
    :body    => {:path => "/lulz", :body => host}.to_json,
    :headers => {"Host" => host}
  })
end

When /^I request the object from the host "([^"]*)"$/ do |host|
  @response = HTTParty.get("http://localhost:8787/lulz", :headers => {"Host" => host})
end

Then /^I see the object saved to the host "([^"]*)"$/ do |host|
  @response.body.should == host
end


Given /^I request the path "([^"]*)" on the host "([^"]*)"$/ do |path, host|
  @response = HTTParty.get("http://localhost:8787#{path}", :headers => {"Host" => host})
end

When /^I list requests on the host "([^"]*)"$/ do |host|
  json = HTTParty.get("http://localhost:8787/__REQUESTS__", :headers => {"Host" => host}).body
  @requests = JSON.parse(json)
end

Then /^I should see the request with the path "([^"]*)"$/ do |path|
  @requests.size.should == 1
  @requests.first["PATH_INFO"].should == path
end
