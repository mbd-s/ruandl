def total_return_calculator
  prices = [ 500000, 750000, 400000, 600000, 350000, 800000 ]
  initial_val = prices.first.to_f
  final_val = prices.last.to_f
  total_return = ((final_val - initial_val) / initial_val) * 100
  puts "The total return was #{total_return}%."
end

def max_dd_calculator
  max_drawdown = 0
  peak = 0
  i = 0
  drawdown = Array.new
  prices = [ 50, 75, 40, 60, 35, 80 ]
  prices.each do |x|
    peak = x if x > peak
    drawdown[i] = peak - x
    max_drawdown = drawdown[i] if drawdown[i] > max_drawdown
    i += 1
  end
  puts "The maximum drawdown was $#{max_drawdown}."
end


def max_dd_calculator_with_pctg
  peak = 0
  i = 0
  drawdown = Array.new
  prices = [ 50, 75, 40, 60, 35, 80 ]
  prices.each do |x|
    peak = x if x > peak
    drawdown[i] = (x.to_f - peak.to_f) / peak.to_f
    i += 1
  end
  max_drawdown_pct = (drawdown.min * 100).round(2)
  puts "The maximum drawdown was #{max_drawdown_pct}%."
end


total_return_calculator
max_dd_calculator
max_dd_calculator_with_pctg
