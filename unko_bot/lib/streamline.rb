# -*- coding: utf-8 -*-

require 'rubygems'
require 'net/https'
require 'oauth'
require 'json'

class Streamline
  def initialize(con_key, con_sec, acc_tok, acc_tok_sec)
    @status = nil
    @tokens = {
      :consumer_key => con_key,
      :consumer_secret => con_sec,
      :access_token => acc_tok,
      :access_token_secret => acc_tok_sec
    }
  end

  def status
    @status
  end

  def start
    tokens = get_tokens
    uri = URI.parse('https://userstream.twitter.com/2/user.json')
    https = init_https(uri)
    https.start do |https|
      request = Net::HTTP::Get.new(uri.request_uri)
      request.oauth!(https, tokens[:consumer], tokens[:access_token]) # OAuthで認証
      buf = ""
      https_request(https, request) do
        yield
      end
    end
  end

  private
  
  def get_tokens
    consumer = OAuth::Consumer.new(@tokens[:consumer_key], @tokens[:consumer_secret], :site =>'http://twitter.com')
    access_token = OAuth::AccessToken.new(consumer, @tokens[:access_token], @tokens[:access_token_secret])
    tokens = { :consumer => consumer, :access_token => access_token }
    tokens
  end

  def init_https(uri)
    # init connection
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    https.ca_file = '/etc/ssl/certs/ca-certificates.crt' #とりあえず
    https.verify_mode = OpenSSL::SSL::VERIFY_PEER
    https.verify_depth = 5
    https
  end

  def parseline(buf)
    while (line = buf[/.+?(\r\n)+/m]) != nil # 改行コードで区切って一行ずつ読み込み
      begin
        buf.sub!(line,"") # 読み込み済みの行を削除
        line.strip!
        @status = JSON.parse(line)
      rescue
        break # parseに失敗したら、次のループでchunkをもう1個読み込む
      end
      yield
    end
  end

  def https_request(https, request)
    buf = ""
    begin
      https.request(request) do |response|
        response.read_body do |chunk|
          buf << chunk
          parseline(buf) do
            yield
          end
        end
      end
    rescue Timeout::Error, EOFError
      puts "userstream response timeout, retry request."
      retry
    end
  end

end
