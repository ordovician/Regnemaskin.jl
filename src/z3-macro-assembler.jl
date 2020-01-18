export emit, asm, index, minors, cofactors!, transpose!, determinant, div!
export Reg, r1, r2, null

import Base: +, -, *, /, getindex, setindex!, size, show, inv, transpose

using Regnemaskin.Allocator

@enum Reg r1 r2

global null = Scalar()

function getindex(A::Grid, i::Integer, j::Integer)
    Scalar(A, i, j)
end

function setindex!(A::Grid, x::Scalar, i::Integer, j::Integer)
   y = Scalar(A, i, j)
   load(r1, x)
   store(r1, y)
   y
end

row(A::SubGrid, i::Integer) = i < A.skiprow ? i : i + 1
col(A::SubGrid, j::Integer) = j < A.skipcol ? j : j + 1

getindex(A::SubGrid, i::Integer, j::Integer) = A.parent[row(A, i), col(A, j)]

function setindex!(A::SubGrid, x, i::Integer, j::Integer)
    A.parent[row(A, i), col(A, j)] = x
end

#################

function asm(x::Scalar)
   string(address(x))  # TODO: Allocate somehow?
end


#################

function emit(operation::AbstractString, xs...)
    println(operation, "(", join(xs, ", "), ")")
end

load(r::Reg, x::Scalar) = emit("load", r, asm(x))
store(r::Reg, x::Scalar) = emit("store", r, asm(x))
mul() = emit("mul")
div() = emit("div")
add() = emit("add")
sub() = emit("sub")

function +(x::Scalar, y::Scalar)
   load(r1, x)
   load(r2, y)
   add()
   z = Scalar()
   store(r1, z)
   z
end

function -(x::Scalar, y::Scalar)
   load(r1, x)
   load(r2, y)
   sub()
   z = Scalar()
   store(r1, z)
   z
end

function *(x::Scalar, y::Scalar)
   load(r1, x)
   load(r2, y)
   mul()
   z = Scalar()
   store(r1, z)
   z
end

function /(x::Scalar, y::Scalar)
   load(r1, x)
   load(r2, y)
   div()
   z = Scalar()
   store(r1, z)
   z
end


####### Matrix operations ##########
function determinant(A::AbstractGrid)
    a, c, b, d = A
    a*d - b*c 
end

function minors(A::Grid)
   C = Grid(size(A)...)
   for i in 1:size(A, 1)
      for j in 1:size(A, 2)
         B = SubGrid(A, i, j)
         C[i, j] = determinant(B)
      end
   end
   C
end

function cofactors!(A::Grid)
   for i in 1:2:length(A)
      A[i] = null - A[i] # TODO: should be some nicer way of doing this
   end
   A
end

function transpose!(A::Grid)
   for i in 1:size(A, 1)
      for j in 1:size(A, 2)
         load(r1, A[i, j])
         load(r2, A[j, i])
         store(r1, A[j, i])
         store(r2, A[i, j])
      end
   end   
end

function div!(A::Grid, denom::Scalar)
   load(r2, denom)
   for i in 1:size(A, 1)
      for j in 1:size(A, 2)
         load(r1, A[i, j])
         div()
         store(r1, A[i, j])
      end
   end     
end

function inv(A::Grid)
   C = minors(A)
   cofactors!(C)
   transpose!(C)
   d = determinant(A)
   div!(C, d)
   C
end