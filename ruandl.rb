require 'httparty'
require 'dotenv'
require 'date'
require 'twitter'
require 'highline/import'

load 'calculations.rb'
Dotenv.load

#TODO decide what to do (anything?) with command-line args
unless ARGV.empty?
  puts "do something with the args"
  exit
end

class Quandl
  include HTTParty

  base_uri "https://www.quandl.com/api/v3/datasets/WIKI"
  default_params :api_key => ENV['QUANDL_API_KEY']

  attr_accessor :stock, :start_date, :end_date

  def initialize(stock, start_date, end_date)
    self.stock = stock
    self.start_date = start_date
    self.end_date = end_date
  end

  #TODO add error handling (incl. refresh)
  def self.find_oldest_available_date stock
    response = get("/#{ stock }/metadata.json")
    if response.success?
      response["dataset"]["oldest_available_date"]
    else
      puts "That stock wasn't in Quandl's databse. Try your search again."
      exit
    end
  end

  #TODO add error handling (incl. refresh)
  def self.find_newest_available_date stock
    response = get("/#{ stock }/metadata.json")
    if response.success?
      response["dataset"]["newest_available_date"]
    else
      puts "That stock wasn't in Quandl's databse. Try your search again."
      exit
    end
  end

  #TODO add error handling (incl. refresh)
  def self.get_prices stock, start_date
    response = get("/#{ stock }.json?column_index=4&start_date=#{ start_date }")
    if response.success?
      prices = Array.new
      response["dataset"]["data"].reverse_each do |r|
        prices.push(r[1])
      end
      prices
    else
      puts "That stock wasn't in Quandl's databse. Try your search again."
    end
  end

end

cli = HighLine.new

say "\nI can look up data on any stock in the Quandl database.\nIf the dates you're searching for aren't in the database, I'll only give you what I can find."

#TODO add validation for stock symbol
stock = cli.ask("\nPlease enter the ticker symbol (e.g. 'AAPL') of a stock you'd like to check.\n", String) {
  |q| q.validate = /^(?!_)[a-zA-Z_]{1,5}(?<!_)$/;
  q.responses[:not_valid] = "\nThat doesn't look like a valid stock symbol. You can download the full
  list from Quandl: https://www.quandl.com/api/v3/databases/wiki/codes"
}
stock.upcase!

input_date = cli.ask("\nFrom what date would you like to start getting data?", Date)

def set_end_date stock
  newest_available_date = Date.parse(Quandl.find_newest_available_date stock)
  today = DateTime.now
  today > newest_available_date ? end_date = newest_available_date : end_date = today
  end_date = end_date.strftime("%-d %B %Y")
  end_date
end

def set_start_date stock, input_date
  oldest_available_date = Date.parse(Quandl.find_oldest_available_date stock)
  input_date < oldest_available_date ? start_date = oldest_available_date : start_date = input_date
  start_date = start_date.strftime("%-d %B %Y")
  start_date
end

#TODO encapsulate
prices = Quandl.get_prices stock, input_date
total_return = calc_total_return prices
max_dd = calc_max_dd prices
end_date = set_end_date stock
start_date = set_start_date stock, input_date
status = "From #{start_date} to #{end_date}, $#{stock} generated a return of #{total_return}%, with a maximum drawdown of #{max_dd}%."

#connect with Twitter
client = Twitter::REST::Client.new do |config|
  config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
  config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
  config.access_token        = ENV["TWITTER_ACCESS_TOKEN"]
  config.access_token_secret = ENV["TWITTER_ACCESS_TOKEN_SECRET"]
end

#and tweet the status
client.update(status)

#finally, print a link to the tweet
last_tweet = client.user_timeline("quandlbot").first.uri
say "I think I've found the data you're looking for: #{last_tweet}"
