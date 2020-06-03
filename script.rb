require 'httparty'
require 'dotenv'
require 'pry-byebug'
require 'csv'
require 'json'
require 'tty-prompt'

# ******** SETUP ***********
Dotenv.load()
prompt = TTY::Prompt.new

# ******** HH2 API ***********
begin
hh2_client_identifier = ENV['HH2_ID']
hh2_username = ENV['HH2_USER']
hh2_password = ENV['HH2_PASSWORD']

@hh2_base_url = "https://#{hh2_client_identifier}.hh2.com"

hh2_headers = {
  "Content-Type" => "text/xml; charset=utf-8",
  "SOAPAction" => "http://asp.net/ApplicationServices/v200/AuthenticationService/Login"
}

hh2_body = <<DOC
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
  <s:Body>
    <Login xmlns="http://asp.net/ApplicationServices/v200">
      <username>#{hh2_username}</username>
      <password>#{hh2_password}</password>
      <customCredential a:nil="true" xmlns:a="http://www.w3.org/2001/XMLSchema-instance"/>
      <isPersistent>true</isPersistent>
    </Login>
  </s:Body>
</s:Envelope>
DOC

# enpoints for hh2
hh2_auth_endpoint = '/WebServices/Authentication.svc'

# log in to hh2
hh2_login = HTTParty.post("#{@hh2_base_url}#{hh2_auth_endpoint}", headers: hh2_headers, body: hh2_body)
if hh2_login.code == 200 && hh2_login.headers
  @hh2_cookie = hh2_login.headers['set-cookie'] 
else
  raise StandardError.new("Error Logging into HH2\n base url: #{@hh2_base_url}|User: #{hh2_username}|pass: #{hh2_password}") if hh2_login.nil?
end
puts "HH2 Login: Success! #{@hh2_cookie}\n"




puts 'transaction script'
rescue => e
  binding.pry
end