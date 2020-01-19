import Base: read, write, div # to avoid conflict with Base.read and Base.write

export Reg, r1, r2, load, store, mul, add, sub, reset
export memory, intape, outtape, readpos
export input
export runprogram, gridview

using DelimitedFiles

# It reads 8 bit instructions. 6 bits are used to refer to memory address.

@enum Reg r1=1 r2

"""
    gridview(offset, n, m)
Returns a n x m matrix view of Z3 main memory starting at address `offset`.
What is the purpose of this? While doing matrix math it can be hard to inspect the
memory and see if we got the right result if we are just looking at it as a
linear list of values. This allows us to look at a section of the memory as an matrix.
"""
function gridview(offset::Integer, rows::Integer, cols::Integer)
    n = rows * cols
    page = @view memory[offset:(offset + n)]
    reshape(page, (rows, cols))
end

"""
    runprogram(programfile, inputfile)
Run a program defined in file `programfile` and read input data from file name
`inputfile`
"""
function runprogram(programfile::AbstractString, inputfile::AbstractString)
    intape = readdlm(inputfile, eltype(intape))
    include(programfile)
    foreach(println, outtape)
end

"""
    reset()
Not a Z3 instruction. Just resets the state of the computer
"""
function reset()
    global memory = zeros(Int, 40) # Z3 had 64 words of memory
    global intape = zeros(Int, 0)  # Where `read()` gets input. 
                                   # Read get data from this one.
    global outtape = zeros(Int, 0) # Where output are appended by `write()`.
    global readpos = 0             # Position of data on intape just read    
end

reset() # First initial reset

"""
    set_input(values)
Allow you to simulate what is supposed to be on the input punched tape, or typed
in on keyboard. Don't mistake this for the program input.
"""
function input(values::AbstractVector)
    global intape = values
end

input() = intape

"""
    read()
Read input from keyboard or tape.
- instruction `Lu`
- opcode `01 110 000`
"""
function read()
    global readpos += 1
    if readpos < 0 || readpos > length(intape)
        error("reached end of intput!")
    end
    memory[Int(r1)] = intape[readpos]
end

"""
    write()
Write output to display or tape
- instruction `Ld`
- opcode `01 111 000`
"""
function write()
   push!(outtape, memory[Int(r1)]) 
end

"""
    load(r, address)
Load number at memory location `address` into register `r`. In the Z3
there was I believe no choice in register. You would load to R1 always or
somehow it knew that you had already loaded there and would load into R2 instead.

- instruction `Pr z`
- opcode `11 zzz zzz`
"""
load(r::Reg, x::Integer) = memory[Int(r)] = memory[x]

"""
    store(r, address)
Store number at memory location `address` into register `r`.
- instruction `Ps z`
- opcode `10 zzz zzz`
"""
store(r::Reg, x::Integer) = memory[x] = memory[Int(r)]


"""
    mul()
Multiply numbers. R1 = R1 * R2
- instruction `Lm`
- opcode `10 zzz zzz`
"""
mul() = memory[Int(r1)] = memory[Int(r1)] * memory[Int(r2)] 

"""
    div()
Divide numbers. R1 = R1 / R2
- instruction `Li`
- opcode `10 010 000`
"""
div() = memory[Int(r1)] = memory[Int(r1)] / memory[Int(r2)]

"""
    add()
Add numbers in register R1 and R2. R1 = R1 + R2
- instruction `Ls1`
- opcode `10 100 000`
"""
add() = memory[Int(r1)] = memory[Int(r1)] + memory[Int(r2)]

"""
    sub()
Substract R2 from R1 and store result in R1. R1 = R1 - R2
- instruction `Ls2`
- opcode `10 101 000`
"""
sub() = memory[Int(r1)] = memory[Int(r1)] - memory[Int(r2)]

### Instruction later added to Z3 not present on Z1

"""
    sqrt()
Square root of R1 and store in R1.
- instruction `Lw`
- opcode `10 011 000`
"""
sqrt() = memory[Int(r1)] = sqrt(memory[Int(r1)])



############

