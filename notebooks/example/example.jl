using ComputableDAGs

using ComputableDAGs: compute

@compute_task T0 1 () -> begin
    #sleep(1.0e-3)
    return "T0_data"
end
@compute_task T1 1 (_) -> begin
    #sleep(1.0e-3)
    return "T1_data"
end
@compute_task T2 2 (_, _) -> begin
    #sleep(1.0e-3)
    return "T2_data"
end
@compute_task T3 2 (_) -> begin
    #sleep(1.0e-3)
    return "T3_data"
end
@compute_task T4 2 (_) -> begin
    #sleep(1.0e-3)
    return "T4_data"
end
@compute_task T5 2 (_) -> begin
    #sleep(1.0e-3)
    return "T5_data"
end
@compute_task T6 2 (_, _) -> begin
    #sleep(1.0e-3)
    return "T6_data"
end
@compute_task T7 2 (_) -> begin
    #sleep(1.0e-3)
    return "T7_data"
end
@compute_task T8 3 (_, _, _) -> begin
    #sleep(1.0e-3)
    return "T8_data"
end

# Full graph: (task - inputs)
# T8 - T5, T6, T7
# T7 - T4
# T6 - T2, T3
# T5 - T2
# T4 - T1
# T3 - T1
# T2 - T1, T0
# T1 - T0
# T0 - Ø

# Three devices in this example:
# D0: T2, T5
# D1: T1, T3, T6, T8
# D2: T0, T4, T7

# 7 inter device transports:
# Transport 0: D2 -> D1 (T0 - T1)
# Transport 1: D2 -> D0 (T0 - T2)
# Transport 2: D1 -> D2 (T1 - T4)
# Transport 3: D1 -> D0 (T1 - T2)
# Transport 4: D0 -> D1 (T2 - T6)
# Transport 5: D0 -> D1 (T5 - T8)
# Transport 6: D2 -> D1 (T7 - T8)

# this example has the following PAIRs in use:
# D0 -> D1: Transport4, Transport5
# D0 -> D2: Ø
# D1 -> D0: Transport3
# D1 -> D2: Transport2
# D2 -> D0: Transport1
# D2 -> D1: Transport0, Transport6

N = 100000
socket_type = "tcp"
