require 'vertx'
require 'openssl'
require 'base64'

access_key = '1uujt/6iFcNdgCKPbz8nkQ=='
secret     = 'iTpnsfRp7TWJuBwUkVKPQw=='

timestamp = Time.now.to_i

host = 'localhost'
ssl = false
request_string = "http://0.0.0.0:8081"
request = '/balances'
port = 8081
body = ''

%w{/balances /orders?state=matching}.each do |request|
  p composed_request = "#{timestamp}#{request_string}#{request}#{body}"
  encoded_request = Base64.encode64(composed_request).chomp

  digest = OpenSSL::Digest::Digest.new('sha256')
  p signature = OpenSSL::HMAC.hexdigest(digest, secret, encoded_request)

  client = Vertx::HttpClient.new
  client.host = host
  client.ssl  = ssl
  client.port = port

  request = client.get(request) do |resp|
    puts "got response #{resp.status_code}"

    resp.body_handler do |body|
      puts body
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
end