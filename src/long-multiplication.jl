# Simulation of long multiplication as done on paper. Numbers are input
# in A and B as individual digits in an array in reverse order (least 
# significant digits first).
# Output is stored in the C array (also reverse order).
function multiply(A::Vector{T}, B::Vector{T}) where T <: Integer
    # Make a large enough vector to hold result, initialized to zero
    C = zeros(T, length(A) + length(B))

    for i in 1:length(A)
        for j in 1:length(B)
            c = A[i] * B[j]      # product of single digits

            k = i + j          
            carry =  c ÷ 10     # integer division
            remainder = c % 10  # remainder of division by 10

            C[k] += carry
            C[k-1] += remainder
        end
    end
    return C
end
