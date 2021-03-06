# frozen_string_literal: true

class Quandl
  include HTTParty

  base_uri 'https://www.quandl.com/api/v3/datasets/WIKI'
  default_params api_key: ENV['QUANDL_API_KEY']

  attr_accessor :stock, :start_date, :end_date

  def initialize(stock, start_date, end_date)
    self.stock = stock
    self.start_date = start_date
    self.end_date = end_date
  end

  def self.check_existence(stock)
    response = get("/#{stock}/metadata.json")
    response.success?
  end

  def self.find_oldest_available_date(stock)
    response = get("/#{stock}/metadata.json")
    raise response.response unless response.success?
    response['dataset']['oldest_available_date']
  end

  def self.find_newest_available_date(stock)
    response = get("/#{stock}/metadata.json")
    raise response.response unless response.success?
    response['dataset']['newest_available_date']
  end

  def self.get_prices(stock, start_date)
    response = get("/#{stock}.json?column_index=4&start_date=#{start_date}")
    raise response.response unless response.success?
    prices = []
    response['dataset']['data'].reverse_each do |r|
      prices.push(r[1])
    end
    prices
  end
end
