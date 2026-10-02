using { FastMath }

TestInts:[]int = array{-1099511627776, -1000000007, -9, -7, -2, -1, 0, 1, 2, 7, 9, 1000000007, 1099511627776}

CheckIntMath<public>()<transacts>:[]accuracy_report =
    AbsReport := accuracy_report{Name := "Abs (int)"}
    MinMaxReport := accuracy_report{Name := "Min/Max (int)"}
    QuotientReport := accuracy_report{Name := "Quotient"}
    ModReport := accuracy_report{Name := "Mod"}
    ClampReport := accuracy_report{Name := "Clamp (int)"}
    for (X : TestInts):
        AbsReport.AddFloat("{X}", Abs(X) * 1.0, FastAbs(X) * 1.0)
        for (Y : TestInts):
            Input := "X={X} Y={Y}"
            MinMaxReport.AddFloat(Input, Min(X, Y) * 1.0, FastMin(X, Y) * 1.0)
            MinMaxReport.AddFloat(Input, Max(X, Y) * 1.0, FastMax(X, Y) * 1.0)
            QuotientReport.AddTripleResult(Input, IntResult(option{Quotient[X, Y]}), IntResult(option{FastQuotient[X, Y]}))
            ModReport.AddTripleResult(Input, IntResult(option{Mod[X, Y]}), IntResult(option{FastMod[X, Y]}))
            for (Z : TestInts):
                ClampReport.AddFloat("{Input} Z={Z}", Clamp(X, Y, Z) * 1.0, FastClamp(X, Y, Z) * 1.0)
    array{AbsReport, MinMaxReport, QuotientReport, ModReport, ClampReport}

BenchIntMath<public>(Pairs:[]tuple(int, int))<transacts>:float =
    var Acc:int = 0
    profile("Native Abs (int)"):
        for (Pair : Pairs):
            set Acc += Abs(Pair(0))
    profile("Fast Abs (int)"):
        for (Pair : Pairs):
            set Acc += FastAbs(Pair(0))
    profile("Native Min (int)"):
        for (Pair : Pairs):
            set Acc += Min(Pair(0), Pair(1))
    profile("Fast Min (int)"):
        for (Pair : Pairs):
            set Acc += FastMin(Pair(0), Pair(1))
    profile("Native Clamp (int)"):
        for (Pair : Pairs):
            set Acc += Clamp(Pair(0), -1000, 1000)
    profile("Fast Clamp (int)"):
        for (Pair : Pairs):
            set Acc += FastClamp(Pair(0), -1000, 1000)
    profile("Native Quotient"):
        for (Pair : Pairs, Q := Quotient[Pair(0), Pair(1)]):
            set Acc += Q
    profile("Fast Quotient"):
        for (Pair : Pairs, Q := FastQuotient[Pair(0), Pair(1)]):
            set Acc += Q
    profile("Native Mod"):
        for (Pair : Pairs, M := Mod[Pair(0), Pair(1)]):
            set Acc += M
    profile("Fast Mod"):
        for (Pair : Pairs, M := FastMod[Pair(0), Pair(1)]):
            set Acc += M
    Acc * 1.0
