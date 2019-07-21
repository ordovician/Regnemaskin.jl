# If you want to multiply two numbers A and B. Then you store A in `input`. In
# the counter array you store the digits of B from least significant digits to
# most significant digits.
function multiply(input::Integer, counter::Vector{T}) where T <: Integer
	 accumulator = zero(typeof(input))
	 for count in counter
		 for i in 1:count
			 accumulator += input
		 end
		 input *= 10
	 end
	 return accumulator
 end