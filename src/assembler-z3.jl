export Cell, retain, release, emit, asm, index, minors, cofactors!, transpose!, determinant, div!

import Base: +, -, *, /, getindex, setindex!, size, show, inv, transpose

@enum Reg r1 r2

struct Cell
    num::Int  # number of memory cell
    ref::Int  # reference count. 0 available for use. > 0 in use.
    Cell(num = -1) = new(num, 1)  # Using -1 to indicate not allocated
end

global available_regs = Cell[]
global null = Cell()

abstract type AbstractGrid end

struct Grid <: AbstractGrid
   offset::Int64
   rows::Int64
   cols::Int64
end

struct SubGrid <: AbstractGrid
   parent::AbstractGrid
   skiprow::Int64
   skiprow::Int64 
end

size(A::Grid) = A.rows, A.cols
size(A::SubGrid) = size(A.parent) .- 1
size(A::AbstractGrid, dim::Integer) = size(A)[dim]

index(A::Grid, i::Integer, j::Integer) = A.rows*(j - 1) + i

function getindex(A::Grid, i::Integer, j::Integer)
   Cell(index(A, i, j))
end

function setindex!(A::Grid, x::Cell, i::Integer, j::Integer)
   y = Cell(index(A, i, j))
   load(r1, x)
   store(r1, y)
   y
end

row(A::SubGrid, i::Integer) = i < A.skiprow ? i : i + 1
col(A::SubGrid, j::Integer) = j < A.skipcol ? j : j + 1

getindex(A::SubGrid, i::Integer, j::Integer) = A.parent[row(A, i), col(A, j)]

function setindex!(A::SubMatrix, x, i::Integer, j::Integer)
    A.parent[row(A, i), col(A, j)] = x
end

#################

"Indicate that we are going to do some calculations where we need this memory cell"
function retain(x::Cell)
    @assert x.ref >= 0
    x.ref += 1
    x
end

"Indicate that we are done with using this memory cell"
function release(x::Cell)
   @assert x.ref > 0
   x.ref -= 1
   x 
end

function asm(x::Cell)
   if x.num == -1
       x.num = pop!(available_regs)
   end
   string(x.num)
end


#################

function emit(operation::AbstractString, xs...)
    println(operation, "(", join(xs, ", "), ")")
end

load(r::Reg, x::Cell) = emit("load", r, asm(x))
store(r::Reg, x::Cell) = emit("store", r, asm(x))
mul() = emit("mul")
div() = emit("div")
add() = emit("add")
sub() = emit("sub")

function +(x::Cell, y::Cell)
   load(r1, x)
   load(r2, y)
   add()
   z = Cell()
   store(r1, z)
   z
end

function -(x::Cell, y::Cell)
   load(r1, x)
   load(r2, y)
   sub()
   z = Cell()
   store(r1, z)
   z
end

function *(x::Cell, y::Cell)
   load(r1, x)
   load(r2, y)
   mul()
   z = Cell()
   store(r1, z)
   z
end

function /(x::Cell, y::Cell)
   load(r1, x)
   load(r2, y)
   div()
   z = Cell()
   store(r1, z)
   z
end


####### Matrix operations ##########
function determinant(A::AbstractGrid)
    a, c, b, d = A
    a*d - b*c 
end

function minors(A::Grid)
   C = Grid(size(A)...)  # TODO: Offer some kind of memory allocation
   for i in size(A, 1)
      for j in size(A, 2)
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
   for i in size(A, 1)
      for j in size(A, 2)
         load(r1, A[i, j])
         load(r2, A[j, i])
         store(r1, A[j, i])
         store(r2, A[i, j])
      end
   end   
end

function div!(A::Grid, denom::Cell)
   load(r2, denom)
   for i in size(A, 1)
      for j in size(A, 2)
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