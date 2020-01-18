export MemBlock, Pool, free, address, blocksize, retain, release, cleanup

import Base: show

abstract type Pool end

mutable struct MemBlock
   ref::Int
   index::Int
   next::Union{MemBlock, Nothing}
   pool::Union{Pool, Nothing}
end

mutable struct MemPool <: Pool
   baseaddress::Int
   blocksize::Int
   blocks::Vector{MemBlock}
   firstfree::MemBlock
end

function MemBlock(index::Integer)
   MemBlock(0, index, nothing, nothing)
end

function MemBlock(pool::Pool)
   block = pool.firstfree
   block.pool = pool
   if block == nothing
      return error("Out of memory")
   end
   pool.firstfree = block.next
   block.next = nothing
   block
end

function address(block::MemBlock)
   pool = block.pool
   if pool == nothing
      error("$block was never allocated from a pool")
   end
   base = pool.baseaddress
   blocksz = pool.blocksize
   base + (block.index - 1) * blocksz
end

blocksize(pool::MemPool) = pool.blocksize

function Pool(address::Integer, size::Integer, blocksize::Integer)
   nblocks = div(size, blocksize)
   blocks = [MemBlock(i) for i in 1:nblocks]
   
   head = blocks[1]
   for block in blocks[2:end]
      block.next = head
      head = block
   end
   
   pool = MemPool(address, blocksize, blocks, head)
end

function free(pool::Pool, block::MemBlock)
   if block.next == nothing
      block.next = pool.firstfree
      pool.firstfree = block
   else
      error("$block was already freed")
   end
   pool
end

function free(::Nothing, block::MemBlock)
   error("$block does not seem to be part of a memory pool")
end

function free(block::MemBlock)
   free(block.pool, block)
end

function retain(block::MemBlock)
    @assert block.ref >= 0
    block.ref += 1
    block
end

function release(block::MemBlock)
   @assert block.ref > 0
   block.ref -= 1
   block 
end

"Free memory block if there are no more references to it"
function cleanup(block::MemBlock)
   if block.ref == 0
      free(block)
   end
end

function show(io::IO, pool::Pool)
   addr = pool.baseaddress
   blocksize = pool.blocksize
   nfirst = pool.firstfree.index
   println(io, "Pool(base = $addr, blocksize = $blocksize, first = $nfirst)")
end

function show(io::IO, block::MemBlock)
   print(io, "Block($(block.index))")
end