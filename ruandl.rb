require 'httparty'
require 'dotenv'
require 'chronic'
require 'twitter'
require 'highline/import'

load 'calculations.rb'
Dotenv.load

#methods to access the Quandl db
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

  def self.check_existence stock
    response = get("/#{ stock }/metadata.json")
    response.success?
  end

  def self.find_oldest_available_date stock
    response = get("/#{ stock }/metadata.json")
    if response.success?
      response["dataset"]["oldest_available_date"]
    else
      raise response.response
    end
  end

  def self.find_newest_available_date stock
    response = get("/#{ stock }/metadata.json")
    if response.success?
      response["dataset"]["newest_available_date"]
    else
      raise response.response
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
      raise response.response
    end
  end

end

#if the stock matches the general Quandl format, ping the db to see if it's there
def stock_check stock
  if stock.match(/^(?!_)[a-zA-Z_]{1,5}(?<!_)$/)
    Quandl.check_existence stock
  end
end

# a little fiddly because Chronic outputs Time objects
def date_check date
  if date.to_i >= 0 && Chronic.parse(date)
    input_date = Chronic.parse(date)
    yesterday = Time.now - (3600 * 24)
    input_date <= yesterday
  end
end

#using highline to style the CLI and help validate inputs
cli = HighLine.new

ft = HighLine::ColorScheme.new do |cs|
         cs[:output]          = [ :bold, :blue ]
         cs[:alert]           = [ :bold, :red ]
       end
HighLine.color_scheme = ft
say("<%= color('\nHi! I can help you look up the rate of return and maximum drawdown
of any stock in the Quandl database within a particular time frame.\n', :output) %>")

stock = cli.ask('<%= color("To start, please enter the ticker symbol (e.g., \"AAPL\")
of the stock you\'d like to check.\\n", :output) %>') {
  |q| q.validate = lambda { |s| stock_check s };
  q.responses[:not_valid] = '<%= color("\\nThat doesn\'t seem to be in Quandl\'s database.
  \\nYou can download the full list of available ticker symbols here\\: https\\:\\/\\/www\\.quandl\\.com\\/api\\/v3\\/databases\\/wiki\\/codes\\n", :alert) %>'
}
stock.upcase!

input_date = cli.ask('<%= color("\\nHow far back do you want to look?\\n\\n(If the date you enter is outside the range found in Quandl\'s records, the results will start from the first available date.)\\n", :output) %>', String) {
  |q| q.validate = lambda { |d| date_check d };
  q.responses[:not_valid] = '<%= color("\\nPlease enter a valid date (e.g. \\"1983-10-27\\", \\"oct 27 1983\\", or \\"33 years ago\\") before today.\\n", :alert) %>'
}

#turning the (valid but not formatted) date input into a Time obj, then Date obj
p_d = Chronic.parse(input_date).strftime('%Y-%m-%d')
parsed_date = Date.parse(p_d)
say("<%= color('\nOK, checking $#{stock} starting from #{parsed_date.strftime("%-d %B %Y")}.\n', :output) %>")

#if records stop before today, find the most recent records and only search until then
def set_end_date stock
  newest_available_date = Date.parse(Quandl.find_newest_available_date stock)
  today = DateTime.now
  today > newest_available_date ? end_date = newest_available_date : end_date = today
  end_date = end_date.strftime("%-d %B %Y")
  end_date
end

#only search as far back as the oldest records
def set_start_date stock, parsed_date
  oldest_available_date = Date.parse(Quandl.find_oldest_available_date stock)
  parsed_date < oldest_available_date ? start_date = oldest_available_date : start_date = parsed_date
  start_date = start_date.strftime("%-d %B %Y")
  start_date
end

#set up the Twitter bot
class QuandlBot
  include Twitter

  attr_accessor :status, :client
  def initialize(status, client)
    self.status = status
    self.client = client
  end

  @client = Twitter::REST::Client.new do |config|
    config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
    config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
    config.access_token        = ENV["TWITTER_ACCESS_TOKEN"]
    config.access_token_secret = ENV["TWITTER_ACCESS_TOKEN_SECRET"]
  end

  def self.tweet status
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
    @client.user_timeline("quandlbot").first.uri
  end

end

#do the math and build the data response
prices = Quandl.get_prices stock, parsed_date
total_return = calc_total_return prices
max_dd = calc_max_dd prices
end_date = set_end_date stock
start_date = set_start_date stock, parsed_date
status = "From #{start_date} to #{end_date}, $#{stock} generated a return of #{total_return}%, with a maximum drawdown of #{max_dd}%."

#tweet!
QuandlBot.tweet status

#and print a link to the tweet
last_tweet = QuandlBot.check_last_tweet
say("<%= color('I think I\\'ve found the data you\\'re looking for: #{last_tweet}', :output) %>")
exit
