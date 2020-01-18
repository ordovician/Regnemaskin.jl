# To solve equations with multiple unknowns. Matrix operations where usually
# used in early computers.
#
# Let us take an example equation to solve. I've already decided the answer
# should be x = 3 and y = 4. Then I construct some simple equations from that:
#   4x -  y = 8
#    x + 3y = 15
# 
# We can express this as a matrix equation like this:
# A = [4 -1; 1 3]
# 2×2 Array{Int64,2}:
# 4  -1
# 1   3
#
# Meaning each equation becomes a row in the matrix.
# B = [8, 15]
# The results are a column vector
# 
# X = [x, y]
# Then we can express the equation as:
#   AX = B
# To find X we take multiply by the inverse on both sides:
#   A⁻¹AX = A⁻¹B
#   IX = A⁻¹B
#   X = A⁻¹B
# So in Julia code we get:
#   inv(A) * B
# Look this up at: https://www.mathsisfun.com/algebra/matrix-inverse.html
#
# This means the trick is to find the inverse matrix. A method which is
# straight forward in the sense that no if-statements needs to be computed is
# the Inverse Matrix using Minors, Cofactors and Adjugate method:
# https://www.mathsisfun.com/algebra/matrix-inverse-minors-cofactors-adjugate.html
#
#
import Base: getindex, setindex!, size

export SubMatrix, determinant

using Regnemaskin.Allocator

"""
Represents a subset of another Matrix 
"""
struct SubMatrix{T} <: AbstractMatrix{T}
    parent::Matrix{T}
    skiprow::Int64   # skip this row in parent matrix
    skipcol::Int64   # skip this column in parent matrix
end

row(M::SubMatrix, i::Integer) = i < M.skiprow ? i : i + 1
col(M::SubMatrix, j::Integer) = j < M.skipcol ? j : j + 1

getindex(M::SubMatrix, i::Integer, j::Integer) = M.parent[row(M, i), col(M, j)]

function setindex!(M::SubMatrix, x, i::Integer, j::Integer)
    M.parent[row(M, i), col(M, j)] = x
end

function size(M::SubMatrix)
   w, h = size(M.parent)
   w - 1, h - 1 
end

function determinant(A::AbstractMatrix{<:Number}) 
    a, c, b, d = A
    a*d - b*c 
end

function matrix_of_minors(A::AbstractMatrix{<:Number})
    determinant(A[2:end, 2:end]) 
end