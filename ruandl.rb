require 'httparty'
require 'dotenv'
require 'date'

Dotenv.load

#checks if input date is in the past
#TODO check if date is within allowable range (after oldest_available_date)
def check_date_range
  date_to_check = Date.parse ARGV[1]
  if date_to_check >= Date.today
    puts "We can't see into the future...yet.\nPlease enter a date before today."
  else
    @start_date = date_to_check
    build_url
  end
end

#checks if input date is in required format (YYYY-MM-DD)
def check_date_format
  y, m, d = ARGV[1].split "-"
  if Date.valid_date? y.to_i, m.to_i, d.to_i
    check_date_range
  else
    puts "#{y}-#{m}-#{d} is not a valid date.\nPlease enter a date in the format YYYY-MM-DD."
  end
end

#checks if stock input is in the right format
#TODO check if stock input matches a Quandl dataset code
def check_stock_format
  stock_input = ARGV[0].upcase
  if stock_input.match(/^(?!_)[a-zA-Z_]{1,5}(?<!_)$/) == nil
    puts "That's the wrong format for a stock dataset. You can download the full list from Quandl: https://www.quandl.com/api/v3/databases/wiki/codes"
  else
    @stock_symbol = stock_input
    check_date_format
  end
end

def build_url
  @end_date = DateTime.now.strftime '%F'
  puts "Checking #{ @stock_symbol } from #{ @start_date } to today (#{ @end_date })."
  puts "https://www.quandl.com/api/v3/datasets/WIKI/#{ @stock_symbol }.json?start_date=#{ @start_date }&end_date=#{ @end_date }&api_key=#{ ENV['QUANDL_API_KEY'] }"
end

check_stock_format


class Quandl
  include HTTParty
  base_uri 'https://www.quandl.com/api/v3/datasets/WIKI'

  def api_key
    ENV['QUANDL_API_KEY']
  end

  def base_path
    "/.json?#{ api_key }"
  end

  def stock
    "#{ stock_symbol }.json?start_date=#{ start_date }&end_date=#{ date_today }&api_key=#{ api_key }"
  end

end

#TODO class(es)? (attr:accessor?)

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
#
# #prompt the user for a stock symbol
# #TODO check if symbol is in db
# def get_stock_symbol
#   puts "Please enter a stock symbol (e.g. AAPL)."
#   @stock_symbol = gets.chomp
# end

#TODO reset at end
