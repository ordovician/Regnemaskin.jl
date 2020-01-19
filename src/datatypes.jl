export Scalar, AbstractGrid, Grid, SubGrid, release, retain, cleanup, address
export scalarpool, gridpool

import Base: size, show

scalarpool = Pool(3, 10, 1)
gridpool   = Pool(11, 30, 3*3)

struct Scalar
   offset::Int
   block::MemBlock
end

struct Grid{T<:Scalar} <: AbstractMatrix{T}
   rows::Int64
   cols::Int64
   block::MemBlock
end

Grid(rows::Integer, cols::Integer, block::MemBlock) = Grid{Scalar}(rows, cols, block)

function Grid(rows::Integer, cols::Integer)
    blksize = rows*cols
    if blksize > blocksize(gridpool)
        error("Grid requires block size of at least &blksize but pool has blocks of $(blocksize(gridpool))")
    end
    Grid(rows, cols, MemBlock(gridpool))
end

struct SubGrid{T<:Scalar} <: AbstractMatrix{T}
   parent::AbstractMatrix
   skiprow::Int64
   skipcol::Int64 
end

const AbstractGrid = Union{Grid, SubGrid}

SubGrid(grid::AbstractGrid, skiprow, skipcol) = SubGrid{Scalar}(grid, skiprow, skipcol)

function Scalar(A::Grid, i::Integer, j::Integer)
    offset = index(A, i, j)
    Scalar(offset, A.block)
end

function Scalar()
    Scalar(0, MemBlock(scalarpool))
end

address(x::Scalar) = x.offset + address(x.block)

size(A::Grid) = A.rows, A.cols
size(A::SubGrid) = size(A.parent) .- 1
size(A::AbstractGrid, dim::Integer) = size(A)[dim]

index(A::Grid, i::Integer, j::Integer) = A.rows*(j - 1) + i

row(A::SubGrid, i::Integer) = i < A.skiprow ? i : i + 1
col(A::SubGrid, j::Integer) = j < A.skipcol ? j : j + 1

"Indicate that we are going to do some calculations where we need this  Scalar"
function retain(x::Union{Scalar, Grid})
    @assert x.ref >= 0
    retain(x.block)
    x
end

"Indicate that we are done with using this memory cell"
function release(x::Union{Scalar, Grid})
   release(x.block)
   x 
end

function cleanup(x::Union{Scalar, Grid})
   cleanup(x.block)
end

function retain(grid::SubGrid)
   retain(grid.parent)
end

function release(grid::SubGrid)
   retain(grid.parent)
end

