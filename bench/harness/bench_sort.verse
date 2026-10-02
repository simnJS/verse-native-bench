using { /UnrealEngine.com/Temporary }
using { FastSort }

LessFloat(Left:float, Right:float)<computes><decides>:void = Left < Right

LessByKey(Left:tuple(int, int), Right:tuple(int, int))<computes><decides>:void = Left(0) < Right(0)

# NaN is left out: with it, Less is not a strict weak ordering and any two correct sorts may differ.
CheckSort<public>()<transacts>:[]accuracy_report =
    Generic := accuracy_report{Name := "SortBy (float)"}
    Inlined := accuracy_report{Name := "SortBy (float, inline comparison)"}
    Stable := accuracy_report{Name := "SortBy (stability)"}
    for (Items : SortCases()):
        Native := SortBy(Items, LessFloat)
        CompareSorted(Generic, Native, FastSortBy(Items, LessFloat))
        CompareSorted(Inlined, Native, FastSortFloats(Items))
    for (Keys : KeyCases()):
        Pairs := for (I -> Key : Keys) { (Key, I) }
        Native := for (Pair : SortBy(Pairs, LessByKey)) do Pair(1) * 1.0
        Fast := for (Pair : FastSortBy(Pairs, LessByKey)) do Pair(1) * 1.0
        CompareSorted(Stable, Native, Fast)
    array{Generic, Inlined, Stable}

CompareSorted(Report:accuracy_report, Native:[]float, Fast:[]float)<transacts>:void =
    Report.AddFloat("n={Native.Length} length", Native.Length * 1.0, Fast.Length * 1.0)
    for (I -> N : Native, F := Fast[I]):
        Report.AddFloat("n={Native.Length} i={I}", N, F)

BenchSort<public>(Floats:[]float)<transacts>:float =
    Batches := for (B := 0..49) do (for (I := 0..199, F := Floats[B * 200 + I]) do F)
    var Acc:float = 0.0
    profile("Native SortBy"):
        for (Batch : Batches):
            Sorted := SortBy(Batch, LessFloat)
            if (First := Sorted[0]) then set Acc += First
    profile("Fast SortBy"):
        for (Batch : Batches):
            Sorted := FastSortBy(Batch, LessFloat)
            if (First := Sorted[0]) then set Acc += First
    profile("Inlined SortBy"):
        for (Batch : Batches):
            Sorted := FastSortFloats(Batch)
            if (First := Sorted[0]) then set Acc += First
    Acc

SortCases()<computes>:[][]float =
    Shuffled := for (Count : array{0, 1, 2, 3, 7, 16, 33, 100, 257}) do ScrambledFloats(Count)
    Sorted := for (I := 0..99) do I * 1.0
    Reversed := for (I := 0..99) do (99 - I) * 1.0
    Equal := for (I := 0..49) do 5.0
    Sawtooth := for (I := 0..99, Tooth := Mod[I, 10]) do Tooth * 1.0
    Shuffled + array{Sorted, Reversed, Equal, Sawtooth, array{0.0, -0.0, -1.0e300, Inf, -Inf, 1.0e-300}}

ScrambledFloats(Count:int)<computes>:[]float =
    for (I := 0..Count - 1, Value := Mod[I * 7919 + 104729, 997]) do Value * 0.5 - 100.0

# Few distinct keys, so stability decides most of the order.
KeyCases()<computes>:[][]int =
    array{
        for (I := 0..199, Key := Mod[I * 31, 7]) do Key,
        for (I := 0..63, Key := Mod[I, 2]) do Key,
        for (I := 0..20) do 3}
