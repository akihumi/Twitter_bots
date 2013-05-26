#-*- coding:utf-8 -*-
require 'rubygems'
require 'twitter'
require 'time'
require 'yaml'
require 'pp'

config = YAML.load_file("config.yaml")
@client = Twitter::Client.new(
  :consumer_key => config["CONSUMER_KEY"],
  :consumer_secret => config["CONSUMER_SECRET"],
  :oauth_token => config["ACCESS_TOKEN"],
  :oauth_token_secret => config["ACCESS_TOKEN_SECRET"]
)

def tweet count
  message = ""
  birthhour = (Time.now.to_i - Time.mktime(ARGV[0], ARGV[1], ARGV[2], ARGV[3], ARGV[4], ARGV[5]).to_i)/3600
  hour = count/3600
  
  if hour == 0 then
    message << "@#{@user[:screen_name]} Happy birth day to me!!。#birthdaybot"
  else
    message << "#{@user[:name]}さんが生まれてから #{birthhour} 時間経過しました。"
    message << "誕生日まで残り #{hour} 時間です。#birthdaybot"
  end
  @client.update(message)
  pp "twitter post message that #{message}!"
end

@user = @client.user.attrs 
# birthday = Time.mktime(Time.now.year, ARGV[0], ARGV[1], ARGV[2], ARGV[3], ARGV[4])
while true do
  count = ((Time.mktime(Time.now.year, ARGV[1], ARGV[2], ARGV[3], ARGV[4], ARGV[5]).to_i - Time.now.to_i) % (365 * 24 * 3600))-(9*3600)
  span = count / (24 * 3600)
  interval = 0
  case span
  when 0
    interval = (count % 3600)
    # puts "hoge" if interval == 0
    tweet count if interval == 0
  when 1..3
    interval = (count % (2*3600))
    # puts "foo"
    tweet count if interval == 0
  when 4..7
    interval = (count % (4*3600))
    # puts "bar"
    tweet count if interval == 0
  when 8..30
    interval = (count % (8*3600))
    # puts "boo" if interval == 0
    tweet count if interval == 0
  else
    interval = (count % (24*3600))
    # puts "ooo" if interval == 0
    tweet count if interval == 0
  end
  sleep 1
end
