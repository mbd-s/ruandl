# frozen_string_literal: true

class TwitterBot
  include Twitter

  attr_accessor :status, :client
  def initialize(status, client)
    self.status = status
    self.client = client
  end

  @client = Twitter::REST::Client.new do |config|
    config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
    config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
    config.access_token        = ENV['TWITTER_ACCESS_TOKEN']
    config.access_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET']
  end

  def self.tweet(status)
    limiter = 0
    begin
      @client.update status
    rescue Twitter::Error
      say("<%= color('\nThere was a problem connecting with Twitter. Trying again.\n', :alert) %>")
      limiter += 1
      if limiter < 3
        retry
      else
        say("<%= color('\nSorry, there was an error. Please try again.\n', :alert) %>")
        exit
      end
    end
  end

  def self.check_last_tweet
    @client.user_timeline('quandlbot').first.uri
  end
end
