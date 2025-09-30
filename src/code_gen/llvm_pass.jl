using LLVM

function create_register_flush_pass()
    pass = FunctionPass(
        "RegisterFlush", func -> begin
            mod = LLVM.parent(func)
            ctx = context(mod)

            bb_count = length(blocks(func))

            # only apply to large functions
            if bb_count < 1000
                return false
            end

            # insert register pressure relief code
            for bb in blocks(func)
                # get instructions in block
                insts = collect(instructions(bb))

                # insert memory operations to spill registers
                if length(insts) < 50
                    continue
                end
                # Insert a memory barrier or volatile load/store
                builder = Builder(ctx)
                position!(builder, first(insts))
            end

            return true
        end
    )

    return pass
end

# Override the optimization pipeline
function custom_optimize!(mod::LLVM.Module, tm::TargetMachine)
    # Create pass manager
    pm = ModulePassManager()

    # Add your custom pass
    add!(pm, create_register_flush_pass())

    # Add standard optimizations but at lower levels
    add!(pm, LLVM.API.LLVMAddConstantPropagationPass())
    add!(pm, LLVM.API.LLVMAddInstructionCombiningPass())

    # Run the pipeline
    return run!(pm, mod)
end
