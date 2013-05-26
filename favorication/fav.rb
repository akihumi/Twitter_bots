# -*- coding: utf-8 -*-

require 'rubygems'
require 'twitter'
require 'net/https'
require 'oauth'
require 'json'
require 'pp'
require 'yaml'

# 適当なものを定義すること。
config = YAML.load_file("config.yaml")
CONSUMER_KEY = config["consumer_key"]
CONSUMER_SECRET = config["consumer_secret"]
ACCESS_TOKEN = config["access_token"]
ACCESS_TOKEN_SECRET = config["access_token_secret"]

@client = Twitter::Client.new(
  :consumer_key => CONSUMER_KEY,
  :consumer_secret => CONSUMER_SECRET,
  :oauth_token => ACCESS_TOKEN,
  :oauth_token_secret => ACCESS_TOKEN_SECRET
)

consumer = OAuth::Consumer.new(
  CONSUMER_KEY,
  CONSUMER_SECRET,
  :site => 'http://twitter.com'
)

access_token = OAuth::AccessToken.new(
  consumer,
  ACCESS_TOKEN,
  ACCESS_TOKEN_SECRET
)

uri = URI.parse('https://userstream.twitter.com/2/user.json')

https = Net::HTTP.new(uri.host, uri.port)
https.use_ssl = true
https.ca_file = '/etc/ssl/certs/ca-certificates.crt' #とりあえず
https.verify_mode = OpenSSL::SSL::VERIFY_PEER
https.verify_depth = 5

# 相手のツイートの先頭5件をとってきてふぁぼる
# すでにふぁぼっていたらさかのぼって5件とってきてふぁぼる
def counttweet(count, user)
  tweet = @client.user_timeline(user, :count => count)
  favo = true
  puts count
  unless tweet.length == 0 then
    tweet.each do |t|
      if t['favorited'] then
        favo = true
      else
        begin
          @client.favorite(t['id']) unless t['favorited']
        rescue Twitter::Error::Forbidden
          puts "already favo"
        end
        favo = false
      end
    end
  else
    favo = false
  end
  counttweet(count + 5, user) if favo
end

https.start do |https|
  request = Net::HTTP::Get.new(uri.request_uri)
  request.oauth!(https, consumer, access_token) # OAuthで認証
  buf = ""
  begin
    https.request(request) do |response|
      response.read_body do |chunk|
        buf << chunk
        while (line = buf[/.+?(\r\n)+/m]) != nil # 改行コードで区切って一行ずつ読み込み
          begin
            buf.sub!(line,"") # 読み込み済みの行を削除
            line.strip!
            status = JSON.parse(line)
          rescue
            break # parseに失敗したら、次のループでchunkをもう1個読み込む
          end
          user = status['source']
          if (status['event'] == "favorite") && !(user['screen_name'] == "akihumi2") then
            puts "#{user['screen_name']} is favorited My tweet."
            counttweet(5, user['screen_name']) unless @client.block?(user['id'])
          end
        end
      end
    end
  rescue Timeout::Error, EOFError
    puts "hoge"
    retry
  end
end

puts "end"
