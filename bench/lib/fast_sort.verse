FastSort<public> := module:

    # Stable bottom-up merge sort. Less is called from Verse instead of through the native's
    # per-comparison callback. Needs <transacts> (the native is <computes>) for its local buffers.
    FastSortBy<public>(Items:[]t, Less(Left:t, Right:t)<computes><decides>:void where t:type)<transacts>:[]t =
        Count := Items.Length
        var Source:[]t = Items
        var Target:[]t = Items
        var Width:int = 1
        loop:
            if (Width >= Count) then break
            var Start:int = 0
            loop:
                if (Start >= Count) then break
                Middle := Min(Start + Width, Count)
                End := Min(Start + 2 * Width, Count)
                var I:int = Start
                var J:int = Middle
                for (K := Start..End - 1):
                    if (I < Middle, Left := Source[I], not (J < End, Right := Source[J], Less[Right, Left])):
                        if (set Target[K] = Left) {}
                        set I += 1
                    else if (Right := Source[J]):
                        if (set Target[K] = Right) {}
                        set J += 1
                set Start = End
            set Source = Target
            set Width *= 2
        Source

    # Same algorithm for the common case of ascending floats, with the comparison inlined.
    FastSortFloats<public>(Items:[]float)<transacts>:[]float =
        Count := Items.Length
        var Source:[]float = Items
        var Target:[]float = Items
        var Width:int = 1
        loop:
            if (Width >= Count) then break
            var Start:int = 0
            loop:
                if (Start >= Count) then break
                Middle := Min(Start + Width, Count)
                End := Min(Start + 2 * Width, Count)
                var I:int = Start
                var J:int = Middle
                for (K := Start..End - 1):
                    if (I < Middle, Left := Source[I], not (J < End, Right := Source[J], Right < Left)):
                        if (set Target[K] = Left) {}
                        set I += 1
                    else if (Right := Source[J]):
                        if (set Target[K] = Right) {}
                        set J += 1
                set Start = End
            set Source = Target
            set Width *= 2
        Source
