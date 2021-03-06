# frozen_string_literal: true

class Calculations
  def self.calc_total_return(prices)
    initial_val = prices.first.to_f
    final_val = prices.last.to_f
    total_return = (((final_val - initial_val) / initial_val) * 100).round(2)
    total_return
  end

  def self.calc_max_dd(prices)
    peak = 0
    i = 0
    drawdown = []
    prices.each do |x|
      peak = x if x > peak
      drawdown[i] = (x.to_f - peak.to_f) / peak.to_f
      i += 1
    end
    max_drawdown = (drawdown.min * 100).round(2)
    max_drawdown
  end
end
