require 'httparty'
require 'dotenv'
require 'date'
load 'drawdown_and_return.rb'

Dotenv.load

#check input stock format
  #if invalid, return
  #if valid, check if input stock is in db
    #if not in db, return
    #if in db, return earliest_date
      #if requested date is before earliest_date, return
      #if requested date is on or after earliest date, call drawdown_and_return

#checks that input date is in the past
#TODO check if date is within allowable range (i.e., after oldest_available_date)
def check_date_range
  date_to_check = Date.parse ARGV[1]
  if date_to_check >= Date.today
    puts "We can't see into the future...yet.\nPlease enter a date before today."
  else
    @start_date = date_to_check
    print_url
  end
end

#checks if input date is in required format (YYYY-MM-DD)
def check_date_format
  y, m, d = ARGV[1].split "-"
  if Date.valid_date? y.to_i, m.to_i, d.to_i
    check_date_range
  else
    puts "#{y}-#{m}-#{d} is not a valid date.\nPlease make sure you're using the
    format YYYY-MM-DD."
  end
end

#checks if stock input is in the right format
#TODO check if stock input matches a Quandl dataset code
def check_stock_format
  stock_input = ARGV[0].upcase
  if stock_input.match(/^(?!_)[a-zA-Z_]{1,5}(?<!_)$/) == nil
    puts "That's the wrong format for a stock dataset. You can download the full
    list from Quandl: https://www.quandl.com/api/v3/databases/wiki/codes"
  else
    @stock_input = stock_input
  end
end

def print_url
  date_today = DateTime.now.strftime '%F'
  puts "Checking data for #{ @stock_symbol } from #{ @start_date } to today (#{ date_today })."
  @url = "https://www.quandl.com/api/v3/datasets/WIKI/#{ @stock_symbol }.json?start_date=#{ @start_date }&end_date=#{ date_today }&api_key=#{ ENV['QUANDL_API_KEY'] }"
  puts @url
end

def input_check
  if ARGV[0]
    check_stock_format
  else
    puts "I can look up returns and maximum drawdowns of any stock in the Quandl database. To start, run this program with a stock symbol (e.g., AAPL) and a date (e.g. 1990-12-20) as arguments."
  end
end
# input_check

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

  def self.get_prices stock, start_date, end_date
    response = get("/#{ stock }.json?column_index=4&start_date=#{ start_date }&end_date=#{ end_date }")
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

  def base_path
    "/.json?#{ api_key }"
  end


end

prices = Quandl.get_prices "FB", "2016-01-05", "2016-01-10"
total_return_calculator prices
max_dd_calculator prices


def date_check stock
  earliest_date = Date.parse(Quandl.check_metadata stock)
  input_date = Date.parse ARGV[1]
  if input_date < earliest_date
    puts "Records for #{ stock } don't start until #{earliest_date}."
  else
    puts "Records should be available"
  end
end

# check_stock_format
#
# if @stock_input
#   date_check @stock_input
# end

#


# prices_test_arr = [ 500000, 750000, 400000, 600000, 350000, 800000 ]
# total_return_calculator prices_test_arr
# max_dd_calculator prices_test_arr

#TODO reset at end(?)


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
