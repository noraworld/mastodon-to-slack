# frozen_string_literal: true

require 'bundler/setup'
require 'net/https'

Bundler.require
Dotenv.load

MASTODON_API_VERSION = 'v1'
MASTODON_TIMELINE    = 'public:local'
MASTODON_ENDPOINT    = "wss://#{ENV['MASTODON_INSTANCE_HOST']}"        \
                       "/api/#{MASTODON_API_VERSION}/streaming"        \
                       "?access_token=#{ENV['MASTODON_ACCESS_TOKEN']}" \
                       "&stream=#{MASTODON_TIMELINE}"
SLACK_WEBHOOK_URI    = URI.parse(ENV['SLACK_WEBHOOK_URI'])

request      = Net::HTTP::Post.new(SLACK_WEBHOOK_URI.request_uri)
http         = Net::HTTP.new(SLACK_WEBHOOK_URI.host, SLACK_WEBHOOK_URI.port)
http.use_ssl = true

EM.run do
  ws = Faye::WebSocket::Client.new(MASTODON_ENDPOINT)

  ws.on :open do |_|
    puts 'Connection starts'
  end

  ws.on :error do |_|
    puts 'Error occured'
  end

  ws.on :close do |_|
    puts 'Connection closed'
  end

  ws.on :message do |message|
    response = JSON.parse(message.data)

    if response.dig('event') == 'update'
      payload = JSON.parse(response.dig('payload'))

      if payload.dig('account', 'acct') == ENV['MASTODON_USERNAME']
        mastodon_status_uri = payload.dig('url')

        request.body = {
          text: mastodon_status_uri,
          unfurl_links: true
        }.to_json

        http.start do |h|
          h.request(request)
        end
      end
    end
  end
end
