puts "Start"
begin
  fail "Broken"
rescue Exception => ex
  puts "Got Exception: #{ex}"
end
puts "DONE"
