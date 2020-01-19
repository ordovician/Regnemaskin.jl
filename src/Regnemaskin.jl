module Regnemaskin

module Allocator
include("allocator.jl")
include("datatypes.jl")
end

module MacroAssembler
# include("matrix-operations.jl")
include("z3-macro-assembler.jl")
end

module Simulator
include("z3-simulator.jl")
end

module Curta
include("curta-abacus.jl")
end

end # module
