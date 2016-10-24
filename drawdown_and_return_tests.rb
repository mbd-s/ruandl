def total_return_calculator
  prices = [ 500000, 750000, 400000, 600000, 350000, 800000 ]
  initial_val = prices.first.to_f
  final_val = prices.last.to_f
  total_return = (final_val - initial_val) / initial_val
  puts "The total return was #{total_return}%."
end

#TODO figure out how to capture relative peaks and troughs so pctg calc works
def max_drawdown_calculator
  max_drawdown = 0
  peak = 0
  i = 0
  drawdown = Array.new
  prices = [ 500000, 750000, 400000, 600000, 350000, 800000 ]

  prices.each do |x|
    peak = x if x > peak
    drawdown[i] = peak - x
    max_drawdown = drawdown[i] if drawdown[i] > max_drawdown
    i += 1
  end
  puts "The maximum drawdown was $#{max_drawdown}."
end

total_return_calculator
max_drawdown_calculator
