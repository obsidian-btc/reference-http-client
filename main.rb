require 'vertx'
require 'openssl'
require 'base64'

access_key = '1uujt/6iFcNdgCKPbz8nkQ=='
secret = 'iTpnsfRp7TWJuBwUkVKPQw=='

timestamp = Time.now.to_i

host = 'localhost'
ssl = false
request_string = "http://0.0.0.0:8081"
request = '/orders'
port = 8081
body = ''

p composed_request = "#{timestamp}#{request_string}#{request}#{body}"
encoded_request = Base64.encode64(composed_request).chomp

digest = OpenSSL::Digest::Digest.new('sha256')
p signature = OpenSSL::HMAC.hexdigest(digest, secret, encoded_request)

client = Vertx::HttpClient.new
client.host = host
client.ssl = ssl
client.port = port
# client.trust_store_path = './obsidiankeystore.jks'
# client.trust_store_password = 'superpassword'

request = client.get(request) do |resp|
  puts "got response #{resp.status_code}"

  resp.body_handler do |body|
    puts "The total body received was #{body.length} bytes"
    puts body
    puts "Exiting"
    Vertx.exit
  end
end

request.put_header('X-Obsidian-Access-Key', access_key)
request.put_header("X-Obsidian-Timestamp", timestamp)
request.put_header('X-Obsidian-Signature', signature)
request.put_header('Accept', 'application/vnd.eventstore.atom+json')
request.put_header('Content-Length', body.length)
request.put_header('Content-Type', 'application/json')

request.exception_handler { |e| raise e }

request.write_str(body)

request.end

# curl -H "X-Obsidian-Access-Key: 1uujt/6iFcNdgCKPbz8nkQ==" -H "X-Obsidian-Timestamp: 1234567"  -H "X-Obsidian-Signature: 8800f8f5a95a7f04d3b477dc480f36a3f5511214b8eca043893eaf13d5a847fd"  "api.obsidianexchange.com:/v1/orders"
