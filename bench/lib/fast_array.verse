FastArray<public> := module:

    # Find builds the list of every position before keeping the first one; first stops at the first match.
    (Input:[]t where t:subtype(comparable)).FastFind<public>(ElementToFind:t)<computes><decides>:int =
        first(Index -> Element : Input, Element = ElementToFind). Index

    (Input:[]t where t:subtype(comparable)).FastRemoveFirstElement<public>(ElementToRemove:t)<computes><decides>:[]t =
        Input.FastRemoveElement[Input.FastFind[ElementToRemove]]

    (Input:[]t where t:subtype(comparable)).FastReplaceFirstElement<public>(ElementToReplace:t, ElementToReplaceWith:t)<computes><decides>:[]t =
        Input.ReplaceElement[Input.FastFind[ElementToReplace], ElementToReplaceWith]

    # Walks the elements instead of reading them back by index.
    (Input:[]t where t:type).FastRemoveElement<public>(IndexToRemove:int)<computes><decides>:[]t =
        0 <= IndexToRemove < Input.Length
        for (Index -> Element : Input, Index <> IndexToRemove) do Element

    (Input:[]t where t:type).FastSlice<public>(StartIndex:int, StopIndex:int)<computes><decides>:[]t =
        0 <= StartIndex <= StopIndex <= Input.Length
        for (Index := StartIndex..StopIndex - 1, Element := Input[Index]) do Element

    (Input:[]t where t:type).FastInsert<public>(InsertionIndex:int, ElementsToInsert:[]t)<computes><decides>:[]t =
        0 <= InsertionIndex <= Input.Length
        Before := for (Index -> Element : Input, Index < InsertionIndex) do Element
        After := for (Index -> Element : Input, Index >= InsertionIndex) do Element
        Before + ElementsToInsert + After

    # Concatenate recursively splits the list in two with Slice; a single pass is enough.
    FastConcatenate<public>(Arrays:[][]t where t:type)<computes>:[]t =
        for (Array : Arrays, Element : Array) do Element

    (Input:[]t where t:subtype(comparable)).FastReplaceAll<public>(ElementsToReplace:[]t, Replacement:[]t)<transacts>:[]t =
        PatternLength := ElementsToReplace.Length
        if (PatternLength = 0):
            return Input
        var Result:[]t = array{}
        var Start:int = 0
        var Index:int = 0
        loop:
            if (Index > Input.Length - PatternLength):
                break
            if (Head := ElementsToReplace[0], Input[Index] = Head, MatchesAt[Input, ElementsToReplace, Index]):
                if (Before := Input.Slice[Start, Index]):
                    set Result += Before + Replacement
                set Index += PatternLength
                set Start = Index
            else:
                set Index += 1
        if (Rest := Input.Slice[Start]) then Result + Rest else Result

    MatchesAt(Input:[]t, Pattern:[]t, At:int where t:subtype(comparable))<computes><decides>:void =
        not (first(Offset -> Expected : Pattern, not (Input[At + Offset] = Expected)). Offset)
