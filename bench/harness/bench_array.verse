using { FastArray }
using { FastMath }

TestArrays:[][]int = array{array{}, array{7}, array{3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5}, array{1, 1, 1, 2, 1, 1}}

TestElements:[]int = array{1, 5, 7, 9, 3}

TestIndices:[]int = array{-1, 0, 1, 3, 5, 6, 10, 11, 12}

CheckArrays<public>()<transacts>:[]accuracy_report =
    FindReport := accuracy_report{Name := "Find"}
    RemoveFirstReport := accuracy_report{Name := "RemoveFirstElement"}
    ReplaceFirstReport := accuracy_report{Name := "ReplaceFirstElement"}
    RemoveReport := accuracy_report{Name := "RemoveElement"}
    SliceReport := accuracy_report{Name := "Slice"}
    InsertReport := accuracy_report{Name := "Insert"}
    ReplaceAllReport := accuracy_report{Name := "ReplaceAll"}
    for (Input : TestArrays):
        for (X : TestElements):
            In := "{Input.Length} elements, X={X}"
            FindReport.AddMatch(In, SameInt(option{Input.Find[X]}, option{Input.FastFind[X]}))
            RemoveFirstReport.AddMatch(In, SameArray(option{Input.RemoveFirstElement[X]}, option{Input.FastRemoveFirstElement[X]}))
            ReplaceFirstReport.AddMatch(In, SameArray(option{Input.ReplaceFirstElement[X, 0]}, option{Input.FastReplaceFirstElement[X, 0]}))
        for (I : TestIndices):
            In := "{Input.Length} elements, I={I}"
            RemoveReport.AddMatch(In, SameArray(option{Input.RemoveElement[I]}, option{Input.FastRemoveElement[I]}))
            InsertReport.AddMatch(In, SameArray(option{Input.Insert[I, array{8, 8}]}, option{Input.FastInsert[I, array{8, 8}]}))
            for (J : TestIndices):
                SliceReport.AddMatch("{In} J={J}", SameArray(option{Input.Slice[I, J]}, option{Input.FastSlice[I, J]}))
        for (Pattern : array{array{}, array{1}, array{1, 1}, array{5, 3}, array{4, 2}}):
            ReplaceAllReport.AddMatch("{Input.Length} elements, pattern of {Pattern.Length}", SameArray(option{Input.ReplaceAll(Pattern, array{0})}, option{Input.FastReplaceAll(Pattern, array{0})}))
    ConcatenateReport := accuracy_report{Name := "Concatenate"}
    for (Count := 0..6):
        Arrays := for (I := 1..Count) do TestArrays[Mod[I, TestArrays.Length]] or array{}
        ConcatenateReport.AddMatch("{Count} arrays", SameArray(option{Concatenate(Arrays)}, option{FastConcatenate(Arrays)}))
    ToStringReport := accuracy_report{Name := "ToString (int)"}
    for (X : TestInts):
        ToStringReport.AddMatch("{X}", if (ToString(X) = FastToString(X)) then true else false)
    array{FindReport, RemoveFirstReport, ReplaceFirstReport, RemoveReport, SliceReport, InsertReport, ReplaceAllReport, ConcatenateReport, ToStringReport}

# 1000 elements, 100 operations per block (25 for Concatenate and ReplaceAll, very slow on the BPVM): each operation walks the array.
array_inputs<public> := class:
    Values<public>:[]int
    Targets<public>:[]int
    Chunks<public>:[][]int
    Repeating<public>:[]int

MakeArrayInputs<public>()<transacts>:array_inputs =
    Values := for (I := 0..999) do Mod[I * 7919, 10007] or 0
    array_inputs:
        Values := Values
        Targets := for (K := 0..99, V := Values[K * 10]) do V
        Chunks := for (K := 0..99) do (Values.Slice[K * 10, K * 10 + 10] or array{})
        Repeating := for (I := 0..999) do Mod[I, 50] or 0

BenchArraySearch<public>(Inputs:array_inputs)<transacts>:float =
    var Acc:int = 0
    profile("Native Find"):
        for (X : Inputs.Targets, I := Inputs.Values.Find[X]):
            set Acc += I
    profile("Fast Find"):
        for (X : Inputs.Targets, I := Inputs.Values.FastFind[X]):
            set Acc += I
    profile("Native RemoveFirstElement"):
        for (X : Inputs.Targets, R := Inputs.Values.RemoveFirstElement[X]):
            set Acc += R.Length
    profile("Fast RemoveFirstElement"):
        for (X : Inputs.Targets, R := Inputs.Values.FastRemoveFirstElement[X]):
            set Acc += R.Length
    profile("Native ReplaceFirstElement"):
        for (X : Inputs.Targets, R := Inputs.Values.ReplaceFirstElement[X, 0]):
            set Acc += R.Length
    profile("Fast ReplaceFirstElement"):
        for (X : Inputs.Targets, R := Inputs.Values.FastReplaceFirstElement[X, 0]):
            set Acc += R.Length
    Acc * 1.0

BenchArrayEdit<public>(Inputs:array_inputs)<transacts>:float =
    var Acc:int = 0
    profile("Native RemoveElement"):
        for (K := 0..99, R := Inputs.Values.RemoveElement[K * 10]):
            set Acc += R.Length
    profile("Fast RemoveElement"):
        for (K := 0..99, R := Inputs.Values.FastRemoveElement[K * 10]):
            set Acc += R.Length
    profile("Native Slice"):
        for (K := 0..99, R := Inputs.Values.Slice[K, K + 500]):
            set Acc += R.Length
    profile("Fast Slice"):
        for (K := 0..99, R := Inputs.Values.FastSlice[K, K + 500]):
            set Acc += R.Length
    profile("Native Insert"):
        for (K := 0..99, R := Inputs.Values.Insert[K * 10, array{1, 2, 3}]):
            set Acc += R.Length
    profile("Fast Insert"):
        for (K := 0..99, R := Inputs.Values.FastInsert[K * 10, array{1, 2, 3}]):
            set Acc += R.Length
    Acc * 1.0

BenchConcatenate<public>(Inputs:array_inputs)<transacts>:float =
    var Acc:int = 0
    profile("Native Concatenate"):
        for (K := 0..24):
            set Acc += Concatenate(Inputs.Chunks).Length
    profile("Fast Concatenate"):
        for (K := 0..24):
            set Acc += FastConcatenate(Inputs.Chunks).Length
    Acc * 1.0

BenchReplaceAll<public>(Inputs:array_inputs)<transacts>:float =
    var Acc:int = 0
    profile("Native ReplaceAll"):
        for (K := 0..24):
            set Acc += Inputs.Repeating.ReplaceAll(array{3, 4}, array{0}).Length
    profile("Fast ReplaceAll"):
        for (K := 0..24):
            set Acc += Inputs.Repeating.FastReplaceAll(array{3, 4}, array{0}).Length
    Acc * 1.0

BenchToString<public>(Ints:[]tuple(int, int))<transacts>:float =
    var Acc:int = 0
    profile("Native ToString (int)"):
        for (Pair : Ints):
            set Acc += ToString(Pair(0)).Length
    profile("Fast ToString (int)"):
        for (Pair : Ints):
            set Acc += FastToString(Pair(0)).Length
    Acc * 1.0

SameArray(Native:?[]int, Fast:?[]int)<computes>:logic =
    if (N := Native?, F := Fast?) then (if (N = F) then true else false)
    else if (Native? or Fast?) then false
    else true

SameInt(Native:?int, Fast:?int)<computes>:logic =
    if (N := Native?, F := Fast?) then (if (N = F) then true else false)
    else if (Native? or Fast?) then false
    else true
