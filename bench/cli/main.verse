Iterations:int = 10000

# The first round is a warm-up.
Rounds:int = 4

# On the BPVM, Main is a single transaction that keeps every allocation:
# CommitPoint commits it after each check and each bench.
Main(Args:[]string, Env:[string]string)<suspends>:void =
    var Check:int = 0
    loop:
        if (Reports := RunCheck(Check)?):
            for (Report : Reports):
                Print(Report.Summary())
            BenchRuntime.CommitPoint()
            set Check += 1
        else:
            break
    Inputs := MakeBenchInputs(Iterations)
    BenchRuntime.CommitPoint()
    for (Pass := 1..Rounds):
        var Acc:float = 0.0
        var Bench:int = 0
        loop:
            if (Result := RunBench(Bench, Inputs)?):
                set Acc += Result
                BenchRuntime.CommitPoint()
                set Bench += 1
            else:
                break
        Print("Round {Pass}: acc={Acc}")
