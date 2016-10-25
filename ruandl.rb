require 'httparty'
require 'dotenv'
require 'date'
require 'twitter'

load 'calculations.rb'
Dotenv.load

#check for 2 inputs
#if there are 2 inputs
  #check input date format
    #if invalid, return
    #if valid, check if input stock is in db
      #if not in db, return
      #if in db, return earliest_date and call drawdown_and_return

#checks that input date is in the past
#TODO fix: check isn't necessary, since API responds to dates outside range
#TODO check if date is within allowable range (i.e., after oldest_available_date)
# def check_date_range
#   start_date = Date.parse ARGV[1]
#   if start_date >= Date.today
#     puts "We can't see into the future...yet.\nPlease enter a date before today."
#   else
#     start_date
#   end
# end

def input_check
  if ARGV[0] && ARGV[1]
    get_stock
  else
    puts "I can look up returns and maximum drawdowns of any stock in the Quandl database. To start, run this program with a stock symbol (e.g., AAPL) and a date (e.g. 1990-12-20) as arguments."
  end
end

#checks if stock input is in the right format
#TODO check if stock input matches a Quandl dataset code
def get_stock
  stock = ARGV[0].upcase
  if stock.match(/^(?!_)[a-zA-Z_]{1,5}(?<!_)$/) == nil
    puts "That's the wrong format for a stock dataset. You can download the full
    list from Quandl: https://www.quandl.com/api/v3/databases/wiki/codes"
    return false
  else
    get_date
    stock
  end
end

#checks if input date is in required format (YYYY-MM-DD)
def get_date
  y, m, d = ARGV[1].split "-"
  if Date.valid_date? y.to_i, m.to_i, d.to_i
    start_date = Date.parse ARGV[1]
    start_date
  else
    puts "#{y}-#{m}-#{d} is not a valid date.\nPlease make sure you're using the
    format YYYY-MM-DD."
    return false
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

  #checks the metadata for a stock input
  def self.check_metadata stock
    response = get("/#{ stock }/metadata.json")
    if response.success?
      response["dataset"]["oldest_available_date"]
    else
      puts "Stock not found in Quandl db."
    end
  end

  #TODO fix whatever is making this break without the print line
  #or maybe not necessary since api call works w/o end date
  # def self.end_date
  #   end_date = Time.now.strftime("%m-%d-%Y")
  #   puts "hi"
  # end

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

# #TODO error handling
# #TODO replace get_date with oldest_available_date; replace today conditionally with newest_available_date
if get_stock && get_date
  prices = Quandl.get_prices get_stock, get_date
  total_return = calc_total_return prices
  max_dd = calc_max_dd prices
  status = "From #{get_date} to today, #{get_stock} generated a return of #{total_return}%, with a maximum drawdown of #{max_dd}%."
  status
end

#not necessary, since API call automatically only goes back as far as there are records
def date_check stock
  earliest_date = Date.parse(Quandl.check_metadata stock)
  input_date = Date.parse ARGV[1]
  if input_date < earliest_date
    puts "Records for #{ stock } don't start until #{earliest_date}."
  else
    puts "Records should be available"
  end
end

client = Twitter::REST::Client.new do |config|
  config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
  config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
  config.access_token        = ENV["TWITTER_ACCESS_TOKEN"]
  config.access_token_secret = ENV["TWITTER_ACCESS_TOKEN_SECRET"]
end

client.update(status)

last_tweet = client.user_timeline("quandlbot").first.uri
puts "I've found the data you're looking for: #{last_tweet}"

input_check

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
