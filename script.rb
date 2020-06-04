require 'httparty'
require 'dotenv'
require 'pry-byebug'
require 'csv'
require 'json'
require 'tty-prompt'
require 'date'

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
@hh2_cookie = hh2_login.headers['set-cookie'] if hh2_login.code == 200 && hh2_login.headers

def hh2_headers
  {'Cookie' => @hh2_cookie}
end

puts "HH2 Login: Success!\n"

def full_job_transactions(job_guid:, version: 0 )
  url = "#{@hh2_base_url}/JobCosting/Api/V1/JobTransaction.svc/job/transactions?job=#{job_guid}&version=#{version}"
  puts "fetching job txns: #{url}"
  HTTParty.get(url, headers: hh2_headers).parsed_response
end

guid = ''

list = []
res = full_job_transactions(job_guid: guid)
list << res['ArrayOfJobTransaction']['JobTransaction']
until res["ArrayOfJobTransaction"].nil? do
  version = res['ArrayOfJobTransaction']['JobTransaction'].last['Version']
  puts "version: #{version}"
  res = full_job_transactions(job_guid: guid, version: version)
  break if res["ArrayOfJobTransaction"].nil?
  list << res['ArrayOfJobTransaction']['JobTransaction']
end

# map possible keys
max_keys = {}
list.flatten.map{|x| max_keys[x.keys.size.to_s] = x.keys if !max_keys[x.keys.size] }

# all uniq keys
headers = max_keys.reduce([]){|acc, x| acc << x[1] }.flatten.uniq.sort

# method to clean up nils for 'N/A'
def denilize(h)
  h.each_with_object({}) { |(k,v),g|
    g[k] = (Hash === v) ?  denilize(v) : v.nil? ? 'N/A' : v }
end

# extend data with full key set so CSV is neat
temp = list.flatten.map do |data|
  missing_keys = (headers - data.keys).reduce({}){|missing_hash, key| missing_hash.update(key => 'N/A') }
  data.merge!(missing_keys)
  denilize(data)
  data.sort_by{|key, value| key}.to_h
end

# create CSV
CSV.open("#{hh2_client_identifier}_#{Date.today.strftime}.csv", 'w', headers: true) do |csv|
  csv << headers
  temp.each do |row|
      csv << row.values
  end
end

puts 'transaction script'
rescue => e
  binding.pry
end