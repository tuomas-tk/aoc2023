DECLARE FUNCTION contains! (win$, own$)
DECLARE FUNCTION findChar! (l$, c$)

OPEN "C:\INPUT.TXT" FOR INPUT AS #1
CLS

DIM duplicates(300) AS LONG
ticketId = 1
sum = 0
ticketCount& = 0
DO
        LINE INPUT #1, line$
        length = LEN(line$)
        winI = findChar(line$, ":") + 1
        ownI = findChar(line$, "|") + 1
        win$ = MID$(line$, winI, ownI - winI - 1)
        own$ = MID$(line$, ownI)
        count = LEN(own$) / 3
        winningCount = 0
        FOR k = 1 TO count
                ticket$ = MID$(own$, (k - 1) * 3 + 2, 2)
                wasFound = contains(win$, ticket$)
                IF wasFound > 0 THEN
                        winningCount = winningCount + 1
                END IF
        NEXT
        IF winningCount > 0 THEN
                sum = sum + 2 ^ (winningCount - 1)
                FOR k = 1 TO winningCount
                        duplicates(ticketId + k) = duplicates(ticketId + k) + 1 + duplicates(ticketId)
                NEXT
        END IF
        ticketCount& = ticketCount& + 1 + duplicates(ticketId)
        PRINT "Ticket"; ticketId; "with"; duplicates(ticketId); "duplicates.     Total"; ticketCount&
        ticketId = ticketId + 1
LOOP UNTIL (EOF(1))

PRINT
PRINT "Part 1:"; sum
PRINT "Part 2:"; ticketCount&

FUNCTION contains! (win$, own$)
        length = LEN(win$)
        FOR k = 1 TO (length / 3)
                IF MID$(win$, (k - 1) * 3 + 2, 2) = own$ THEN
                        contains = 1
                        EXIT FOR
                END IF
        NEXT
END FUNCTION

FUNCTION findChar (l$, c$)
        length = LEN(l$)
        FOR k = 1 TO length
                char$ = MID$(l$, k, 1)
                IF char$ = c$ THEN
                        findChar = k
                        EXIT FOR
                END IF
        NEXT
END FUNCTION

