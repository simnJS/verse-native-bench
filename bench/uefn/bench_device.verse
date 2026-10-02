using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

bench_device := class(creative_device):

    @editable Iterations:int = 10000

    # The first round is a warm-up.
    @editable Rounds:int = 4

    # The correctness checks are slow (~100 s on the BPVM): enable them only when needed.
    @editable RunChecks:logic = false

    # Sleep(0.0) between two items commits the transaction and frees its memory.
    OnBegin<override>()<suspends>:void =
        if (RunChecks?):
            var Check:int = 0
            loop:
                if (Reports := RunCheck(Check)?):
                    for (Report : Reports):
                        Print(Report.Summary())
                    Sleep(0.0)
                    set Check += 1
                else:
                    break
        Inputs := MakeBenchInputs(Iterations)
        Sleep(0.0)
        for (Pass := 1..Rounds):
            var Acc:float = 0.0
            var Bench:int = 0
            loop:
                if (Result := RunBench(Bench, Inputs)?):
                    set Acc += Result
                    Sleep(0.0)
                    set Bench += 1
                else:
                    break
            Print("Round {Pass}: acc={Acc}")
