require 'httparty'
require 'dotenv'
require 'date'
require 'twitter'
require 'highline/import'

load 'calculations.rb'
Dotenv.load

if ARGV.length = 2
  puts "do something with the args"
  exit
end

cli = HighLine.new
say "\nI can look up returns and maximum drawdowns of any stock in the Quandl database."

stock = cli.ask("\nPlease enter the ticker symbol (e.g. 'AAPL') of a stock you'd like to check.", String) {
  |q| q.validate = /^(?!_)[a-zA-Z_]{1,5}(?<!_)$/;
  q.responses[:not_valid] = "That doesn't look like a valid stock symbol. You can download the full
  list from Quandl: https://www.quandl.com/api/v3/databases/wiki/codes"
}
stock.upcase!
puts stock

start_date = cli.ask("From what date would you like to start getting data?", Date)

#check for 2 inputs
#if there are 2 inputs
  #check input date format
    #if invalid, return
    #if valid, check if input stock is in db
      #if not in db, return
      #if in db, return earliest_date and call drawdown_and_return

# def validation_for_input stock date
#   case
#   when (stock.nil? or stock.empty?) then "Please enter a stock.\nI can look up returns and maximum drawdowns of any stock in the Quandl database. To start, run this program with a stock symbol (e.g., 'AAPL') and a date (e.g. '1990-12-20') as the two arguments."
#   when stock.match(/^(?!_)[a-zA-Z_]{1,5}(?<!_)$/) == nil then "That's the wrong format for a stock dataset. You can download the full list from Quandl: https://www.quandl.com/api/v3/databases/wiki/codes"
#   else nil
#   end
# end
#
# validation_status = validation_for_input ARGV[0] ARGV[1]
# puts validation_status

#checks if stock input is in the right format
#TODO check if stock input matches a Quandl dataset code
def check_stock_input_format
  stock_input = ARGV[0].upcase
  if stock_input.match(/^(?!_)[a-zA-Z_]{1,5}(?<!_)$/) == nil
    puts "That's the wrong format for a stock dataset. You can download the full
    list from Quandl: https://www.quandl.com/api/v3/databases/wiki/codes"
    exit
  else
    stock_input
  end
end

#checks if input date is in required format (YYYY-MM-DD)
def check_date_format
  y, m, d = ARGV[1].split "-"
  if Date.valid_date? y.to_i, m.to_i, d.to_i
    start_date = Date.parse ARGV[1]
    start_date
  else
    puts "#{y}-#{m}-#{d} is not a valid date.\nPlease make sure you're using the
    format YYYY-MM-DD."
    exit
  end
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

  def self.find_oldest_available_date stock
    response = get("/#{ stock }/metadata.json")
    if response.success?
      response["dataset"]["oldest_available_date"]
    else
      puts "Stock not found in Quandl db."
      exit
    end
  end

  def self.find_newest_available_date stock
    response = get("/#{ stock }/metadata.json")
    if response.success?
      response["dataset"]["newest_available_date"]
    else
      puts "Stock not found in Quandl db."
      exit
    end
  end

  def self.get_prices stock, start_date
    response = get("/#{ stock }.json?column_index=4&start_date=#{ start_date }")
    if response.success?
      prices = Array.new
      response["dataset"]["data"].reverse_each do |r|
        prices.push(r[1])
      end
      prices
    else
      puts "err"
    end
  end

end

stock = get_stock
start_date = set_start_date stock

#TODO error handling
#TODO fix `input_date = Date.parse ARGV[1]` (Date.parse ARGV[1] should be validated first)
#no need to validate if in future, bc default is to return today
def set_start_date stock
  oldest_available_date = Date.parse(Quandl.find_oldest_available_date stock)
  input_date = Date.parse ARGV[1]
  input_date < oldest_available_date ? start_date = oldest_available_date : start_date = input_date
  start_date = start_date.strftime("%-d %B %Y")
  puts start_date
end

def set_end_date stock
  newest_available_date = Date.parse(Quandl.find_newest_available_date stock)
  today = DateTime.now
  today > newest_available_date ? end_date = newest_available_date : end_date = today
  end_date = end_date.strftime("%-d %B %Y")
  puts end_date
end

#TODO error handling
#TODO replace get_date with oldest_available_date; replace today conditionally with newest_available_date

  prices = Quandl.get_prices get_stock, get_date
  total_return = calc_total_return prices
  max_dd = calc_max_dd prices
  status = "From #{start_date} to #{end_date}, $#{stock} generated a return of #{total_return}%, with a maximum drawdown of #{max_dd}%."
  puts status


#connect with Twitter API
client = Twitter::REST::Client.new do |config|
  config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
  config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
  config.access_token        = ENV["TWITTER_ACCESS_TOKEN"]
  config.access_token_secret = ENV["TWITTER_ACCESS_TOKEN_SECRET"]
end
#
# #TODO this should only be invoked if there's a valid status
#tweet
client.update(status)

last_tweet = client.user_timeline("quandlbot").first.uri
puts "I think I've found the data you're looking for: #{last_tweet}"

#prompts user for a date
# def get_date
#   puts "When should I start checking this stock?\n(Use the date format: YYYY-MM-DD)"
#   @start_date = gets.chomp
#   y, m, d = @start_date.split "-"
#   check_date y, m, d
# end
#
# #checks date format
# #TODO check if date is within allowable range (in db range, not in future, not today[?])
# def check_date(y, m, d)
#   if Date.valid_date? y.to_i, m.to_i, d.to_i
#     puts "valid date"
#     puts "#{@start_date}"
#   else
#     puts "Please enter a valid date."
#     get_date
#   end
# end

# #prompt the user for a stock symbol
# #TODO check if symbol is in db
# def get_stock_symbol
#   puts "Please enter a stock symbol (e.g. AAPL)."
#   @stock_symbol = gets.chomp
# end
