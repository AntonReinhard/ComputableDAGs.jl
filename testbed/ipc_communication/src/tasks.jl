using ComputableDAGs

using ComputableDAGs: compute

using Random

function gen_data(task_number, length)
    RNG = Xoshiro(task_number)

    return rand(RNG, UInt8, length)
end

function setup_tasks(length)
    return global DATA = [gen_data(TN, length) for TN in 0:8]
end

@compute_task T0 1 () -> begin
    return DATA[1]
end
@compute_task T1 1 (_) -> begin
    return DATA[2]
end
@compute_task T2 2 (_, _) -> begin
    return DATA[3]
end
@compute_task T3 2 (_) -> begin
    return DATA[4]
end
@compute_task T4 2 (_) -> begin
    return DATA[5]
end
@compute_task T5 2 (_) -> begin
    return DATA[6]
end
@compute_task T6 2 (_, _) -> begin
    return DATA[7]
end
@compute_task T7 2 (_) -> begin
    return DATA[8]
end
@compute_task T8 3 (_, _, _) -> begin
    return DATA[9]
end
