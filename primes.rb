require 'prime'

100000.times do |x|
  s = (x+1).to_s.chars.map(&:to_i).inject(:+) # convert each number to string and back to array of digits, calculate sum in place
  puts s if Prime.prime?(s) # printf the sum is a prime
end