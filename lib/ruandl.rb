# frozen_string_literal: true

require 'httparty'
require 'dotenv'
require 'chronic'
require 'twitter'
require 'highline/import'

Dotenv.load

require_relative 'ruandl/calculations'
require_relative 'ruandl/quandl'
require_relative 'ruandl/twitter'
require_relative 'ruandl/highline'

# if the stock matches the general Quandl format, ping the db to see if it's there
def stock_check(stock)
  Quandl.check_existence stock if /^(?!_)[a-zA-Z_]{1,5}(?<!_)$/.match?(stock)
end

# a little fiddly because Chronic outputs Time objects
def date_check(date)
  if date.to_i >= 0 && Chronic.parse(date)
    input_date = Chronic.parse(date)
    yesterday = Time.now - (3600 * 24)
    input_date <= yesterday
  end
end

# highline styles the CLI and helps validate inputs

cli = HighLine.new

ft = HighLine::ColorScheme.new do |cs|
  cs[:output] = %i[bold blue]
  cs[:alert] = %i[bold red]
end

HighLine.color_scheme = ft
say("<%= color('\nHi! I can help you look up the rate of return and maximum drawdown
of any stock in the Quandl database within a particular time frame.\n', :output) %>")

stock = cli.ask('<%= color("To start, please enter the ticker symbol (e.g., \"AAPL\")
of the stock you\'d like to check.\\n", :output) %>') do |q|
  q.validate = ->(s) { stock_check s }
  q.responses[:not_valid] = '<%= color("\\nThat doesn\'t seem to be in Quandl\'s database.
  \\nYou can download the full list of available ticker symbols here\\: https\\:\\/\\/www\\.quandl\\.com\\/api\\/v3\\/databases\\/wiki\\/codes\\n", :alert) %>'
end
stock.upcase!

input_date = cli.ask('<%= color("\\nHow far back do you want to look?\\n\\n(If the date you enter is outside the range found in Quandl\'s records, the results will start from the first available date.)\\n", :output) %>', String) do |q|
  q.validate = ->(d) { date_check d }
  q.responses[:not_valid] = '<%= color("\\nPlease enter a valid date (e.g., \\"1983-10-27\\", \\"oct 27 1983\\", or \\"33 years ago\\") before today.\\n", :alert) %>'
end

# turning the (valid but not formatted) date input into a Time obj, then Date obj
p_d = Chronic.parse(input_date).strftime('%Y-%m-%d')
parsed_date = Date.parse(p_d)

# if records stop before today, find the most recent records and only search until then
def set_end_date(stock)
  newest_available_date = Date.parse(Quandl.find_newest_available_date(stock))
  today = DateTime.now
  today > newest_available_date ? end_date = newest_available_date : end_date = today
  end_date = end_date.strftime('%-d %B %Y')
  end_date
end

# only search as far back as the oldest records
def set_start_date(stock, parsed_date)
  oldest_available_date = Date.parse(Quandl.find_oldest_available_date(stock))
  parsed_date < oldest_available_date ? start_date = oldest_available_date : start_date = parsed_date
  start_date = start_date.strftime('%-d %B %Y')
  start_date
end

# do the math and build the data response
prices = Quandl.get_prices stock, parsed_date
total_return = Calculations.calc_total_return prices
max_dd = Calculations.calc_max_dd prices
end_date = set_end_date stock
start_date = set_start_date stock, parsed_date
say("<%= color('\nOK, checking $#{stock} starting from #{start_date}.\n', :output) %>")
status = "From #{start_date} to #{end_date}, $#{stock} generated a return of #{total_return}%, with a maximum drawdown of #{max_dd}%."

# tweet!
TwitterBot.tweet status
# and print a link to the tweet
last_tweet = TwitterBot.check_last_tweet
say("<%= color('I think I\\'ve found the data you\\'re looking for: #{last_tweet}', :output) %>")
exit
