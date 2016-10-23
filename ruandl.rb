api_key = ENV["QUANDL_API_KEY"]

puts "Please enter a stock symbol (e.g. AAPL)."
stock_symbol = gets.chomp
puts "When should I start checking this stock? (Date format: YYYY-MM-DD)"
start_date = gets.chomp.to_i
puts "Checking #{stock_symbol}'s performance from #{start_date} until today."

url =
