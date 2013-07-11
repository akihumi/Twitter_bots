# -*- coding: utf-8 -*-

require 'rubygems'
require 'twitter'
require 'pp'
require 'yaml'
require './lib/streamline'

# get "itcollege" list members
@listmembers = []
config = YAML.load_file("oauth.yaml")
@client = Twitter::Client.new(
  :consumer_key => config["consumer_key"],
  :consumer_secret => config["consumer_secret"],
  :oauth_token => config["oauth_token"],
  :oauth_token_secret => config["oauth_token_secret"]
)
# カタカナをひらがなに変換する
def kata2hira(str)
  trans = lambda{|s| s.tr("ァ-ン","ぁ-ん") }
  trans.call(str)
end

# userが@listmembersに含まれているか
def search_user(user)
  unless user.nil? then
    if @listmembers.include?(user['screen_name'])
      yield if block_given?
      puts user['screen_name']
    end
  end
end

# keywordをつぶやいているか
def search_unko(text)
  keyword = ["うんこ","うんち","うん○","う○こ","○んこ","う○ち","○んち","うんo","oんこ","うoこ","うoち","うoち","うんx","うxこ","xんこ","うxち","xんち","糞","う◯こ","う◯ち","◯んこ","◯んち","うん◯","うん●","う●こ","う●ち","●んこ","●んち", "うんk","・・ー ・ー・ー・ ーーーー","uんこ"]
  keyword.each do |w|
    if text.include?(w) || text.reverse.include?(w) then
      yield if block_given?
      puts "text included #{w}"
    end
  end
end

@client.list_members("akihumi2", "itcollege").each do |list|
  @listmembers.push list.attrs[:screen_name] unless list.nil?
end

# @listmembers.push "_humin"
https = Streamline.new(config["consumer_key"], config["consumer_secret"], config["oauth_token"], config["oauth_token_secret"])
https.start do
  user = https.status['user']
  # itcollegeリストに入ってる人のつぶやきに反応
  search_user(user) do
    text =  kata2hira(https.status['text']).gsub(/(\s|　|\.|\/|,|、|。|;|\[|\]|\{|\}|'|\_|\?|\"|\!|\*|\-|\|-|ー|・|\w|「|」)+/, '').downcase
    text = text.split(//).uniq.join("")
    search_unko(text) do
      begin
        @client.favorite(https.status['id']) unless https.status['favorited']
        # typosonのつぶやきだったらリツイート
        if user['screen_name'] == "typosone" then
          @client.retweet(https.status['id']) unless https.status['retweeted']
        end
      rescue Twitter::Error::Unauthorized
        puts "supplied user credentials are not valid."
      end
    end
  end  
end
