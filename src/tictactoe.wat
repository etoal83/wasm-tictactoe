(module
  ;; ------
  ;;  BOARD REPRESENTATION
  ;; ------
  ;; Square index:
  ;; +---+---+---+
  ;; | 0 | 1 | 2 |
  ;; +---+---+---+
  ;; | 3 | 4 | 5 |
  ;; +---+---+---+
  ;; | 6 | 7 | 8 |
  ;; +---+---+---+
  ;;
  ;; Bit assignment:
  ;; - Board (i32)
  ;; (Unused 14 bits)| 8  7 6  5 4  3 2  1 0
  ;; 0000 0000 0000 0000 0000 0000 0000 0000
  ;;
  ;; (Unused 14 bits)|  8 7 6  5 4 3  2 1 0
  ;; 0000 0000 0000 00 000000 000000 000000
  ;;
  ;; - Mark (2 bits)
  ;; 0 = 00: Blank
  ;; 1 = 01: O
  ;; 2 = 10: X
  ;;
  ;; - Game status (i32)
  ;; 0000 0000 0000 0000 0000 0000 0000 0000
  ;;                                 |   |||
  ;;                                 |   |++-- 2 bits | 0: (reserved) / 1: O's turn / 2: X's turn / 3: Game is set
  ;;                                 +---+---- 4 bits | Turn count (0-9)
  ;; ------
  ;;  MEMORY LAYOUT
  ;; ------
  ;; - 40 bytes from offest [0]: Game board state up to 9 turns
  ;; 

  (memory $mem 1)
  (global $MEM_OFFSET_GAME_BOARD i32 (i32.const 0))
  (global $gameStatus (mut i32) (i32.const 0))

  ;; Get memory offset of the game board at turn N
  (func $offsetForGameBoard (param $turn i32) (result i32)
    (i32.add
      (global.get $MEM_OFFSET_GAME_BOARD)
      (i32.mul
        (i32.const 4)
        (local.get $turn)
      )
    )
  )

  ;; Query the current game status and game board in this turn
  (func $queryGameStatus (result i32 i32)
    (local $turn i32)
    (local.set $turn (call $getCurrentTurnCount))

    (global.get $gameStatus)
    (i32.load
      (call $offsetForGameBoard (local.get $turn))
    )
  )

  (func $getCurrentTurnMark (result i32)
    (i32.and
      (global.get $gameStatus)
      (i32.const 3)
    )
  )

  (func $getCurrentTurnCount (result i32)
    (i32.shr_u
      (i32.and (global.get $gameStatus) (i32.const 60)) ;; 111100
      (i32.const 2)
    )
  )

  (func $getCurrentGameBoard (result i32)
    (i32.load
      (call $offsetForGameBoard
        (i32.sub (call $getCurrentTurnCount) (i32.const 1))
      )
    )
  )

  ;; Advance turn by putting the mark at the given square index
  ;; return gameStatus with successful command, otherwise return 0 
  (func $advanceTurn (param $index i32) (result i32)
    (local $board i32)
    (local $currentTurnMark i32)
    (local $turn i32)
    (local $boardAfterSet i32)

    (local.set $currentTurnMark (call $getCurrentTurnMark))
    (local.set $turn (call $getCurrentTurnCount))
    (local.set $board (call $getCurrentGameBoard))
    (local.set $boardAfterSet
      (call $setMark (local.get $board) (local.get $index) (local.get $currentTurnMark))
    )

    (if (result i32)
      (local.get $boardAfterSet)
      (then
        ;; Store the resulted board
        (i32.store
          (call $offsetForGameBoard (local.get $turn))
          (local.get $boardAfterSet)
        )
        ;; Update game status
        (if (call $getWinner (local.get $boardAfterSet))
          (then
            (global.set $gameStatus
              (i32.or (global.get $gameStatus) (i32.const 3))
            )
          )
          (else
            (global.set $gameStatus
              (i32.add
                ;; Toggle turn mark
                (i32.xor (global.get $gameStatus) (i32.const 3))
                ;; Increment turn count
                (i32.const 4)
              )
            )
          )
        )
        (global.get $gameStatus)
      )
      (else
        (i32.const 0)
      )
    )
  )

  ;; Get the mark which has lines if exists, otherwise return 0 
  (func $getWinner (param $board i32) (result i32)
    (i32.or
      (call $isOLined (local.get $board))
      (i32.shl
        (call $isXLined (local.get $board))
        (i32.const 1)
      )
    )
  )

  ;; Check whether the mark O is lined
  (func $isOLined (param $board i32) (result i32)
    (i32.or
      (i32.or
        (i32.or
          ;; 0-1-2
          (i32.eq
            (i32.and (local.get $board) (i32.const 63))
            (i32.const 21)
          )
          ;; 3-4-5
          (i32.eq
            (i32.and (local.get $board) (i32.const 4032))
            (i32.const 1344)
          )
        )
        (i32.or
          ;; 6-7-8
          (i32.eq
            (i32.and (local.get $board) (i32.const 258048))
            (i32.const 86016)
          )
          ;; 0-3-6
          (i32.eq
            (i32.and (local.get $board) (i32.const 12483))
            (i32.const 4161)
          )
        )
      )
      (i32.or
        (i32.or
          ;; 1-4-7
          (i32.eq
            (i32.and (local.get $board) (i32.const 49932))
            (i32.const 16644)
          )
          ;; 2-5-8
          (i32.eq
            (i32.and (local.get $board) (i32.const 199728))
            (i32.const 66576)
          )
        )
        (i32.or
          ;; 0-4-8
          (i32.eq
            (i32.and (local.get $board) (i32.const 197379))
            (i32.const 65793)
          )
          ;; 2-4-6
          (i32.eq
            (i32.and (local.get $board) (i32.const 13104))
            (i32.const 4368)
          )
        )
      )
    )
  )

  ;; Check whether the mark X is lined
  (func $isXLined (param $board i32) (result i32)
    (i32.or
      (i32.or
        (i32.or
          ;; 0-1-2
          (i32.eq
            (i32.and (local.get $board) (i32.const 63))
            (i32.const 42)
          )
          ;; 3-4-5
          (i32.eq
            (i32.and (local.get $board) (i32.const 4032))
            (i32.const 2688)
          )
        )
        (i32.or
          ;; 6-7-8
          (i32.eq
            (i32.and (local.get $board) (i32.const 258048))
            (i32.const 172032)
          )
          ;; 0-3-6
          (i32.eq
            (i32.and (local.get $board) (i32.const 12483))
            (i32.const 8322)
          )
        )
      )
      (i32.or
        (i32.or
          ;; 1-4-7
          (i32.eq
            (i32.and (local.get $board) (i32.const 49932))
            (i32.const 33288)
          )
          ;; 2-5-8
          (i32.eq
            (i32.and (local.get $board) (i32.const 199728))
            (i32.const 133152)
          )
        )
        (i32.or
          ;; 0-4-8
          (i32.eq
            (i32.and (local.get $board) (i32.const 197379))
            (i32.const 131586)
          )
          ;; 2-4-6
          (i32.eq
            (i32.and (local.get $board) (i32.const 13104))
            (i32.const 8736)
          )
        )
      )
    )
  )

  ;; Set mark O/X at index onto the board and return the resulted board
  ;; otherwise return 0 for invalid operation
  (func $setMark (param $board i32) (param $index i32) (param $mark i32) (result i32)
    (if (result i32)
      ;; Validate the manipulation
      (i32.and
        (i32.and
          (call $isIndexInRange (local.get $index))
          (call $isValidMark (local.get $mark))
        )
        (call $isSquareBlank (local.get $board) (local.get $index))
      )
      (then
        (i32.or
          (local.get $board)
          (i32.shl
            (local.get $mark)
            (i32.mul (local.get $index) (i32.const 2))
          )
        )
      )
      (else
        (i32.const 0)
      )
    )
  )

  ;; Check the given index is in the range of [0, 8]
  (func $isIndexInRange (param $index i32) (result i32)
    (i32.and
      (i32.ge_u (local.get $index) (i32.const 0))
      (i32.le_u (local.get $index) (i32.const 8))
    )
  )

  ;; Check the given $mark is valid (either 1 or 2)
  (func $isValidMark (param $mark i32) (result i32)
    (i32.or
      (i32.eq (local.get $mark) (i32.const 1))
      (i32.eq (local.get $mark) (i32.const 2))
    )
  )

  ;; Check the square at $index is blank (whether the bits equal `00`)
  (func $isSquareBlank (param $board i32) (param $index i32) (result i32)
    (i32.eq
      (i32.and
        (local.get $board)
        (i32.shl
          (i32.const 3)
          (i32.mul (local.get $index) (i32.const 2))
        )
      )
      (i32.const 0)
    )
  )

  ;; Get minimum board representation as base state for deduplication
  ;; by checking over symmetries 
  (func $getBaseState (param $board i32) (result i32)
    (local $m i32)
    (local $r i32)
    (local $s i32)
    (local $base i32)
    (local.set $base (local.get $board))

    (block $exit
      ;; loop over mirrorings in $m = [0, 5)
      (loop $mloop
        (br_if $exit (i32.ge_u (local.get $m) (i32.const 5)))
        (local.set $s (local.get $board))
        (local.set $s (call $mirror (local.get $s) (local.get $m)))
        (local.set $m (i32.add (local.get $m) (i32.const 1)))
        (local.set $r (i32.const 0))
        ;; loop over rotations in $r = [0, 4) 
        (loop $rloop
          (if (i32.lt_u (local.get $s) (local.get $base))
            (then (local.set $base (local.get $s)))
          )
          (local.set $r (i32.add (local.get $r) (i32.const 1)))
          (br_if $mloop (i32.ge_u (local.get $r) (i32.const 4)))
          (local.set $s (call $rotate (local.get $s)))
          (br $rloop)
        )
      )
    )
    (return (local.get $base))
  )

  ;; Call mirroring by integer for iteration
  (func $mirror (param $source i32) (param $axis i32) (result i32)
    ;; axis = 1: vmirror
    (if (i32.eq (local.get $axis) (i32.const 1))
      (then
        (return (call $vmirror (local.get $source)))
      )
    )
    ;; axis = 2: hmirror
    (if (i32.eq (local.get $axis) (i32.const 2))
      (then
        (return (call $hmirror (local.get $source)))
      )
    )
    ;; axis = 3: dmirror
    (if (i32.eq (local.get $axis) (i32.const 3))
      (then
        (return (call $dmirror (local.get $source)))
      )
    )
    ;; axis = 4: amirror
    (if (i32.eq (local.get $axis) (i32.const 4))
      (then
        (return (call $amirror (local.get $source)))
      )
    )
    ;; else: do nothing
    (return (local.get $source))
  )

  ;; Vertical mirroring
  (func $vmirror (param $source i32) (result i32)
    (i32.add
      ;; Immutable middle row
      (i32.and (local.get $source) (i32.const 4032))
      (i32.add
        ;; Top row in source -> Bottom row in target
        (i32.shl
          (i32.and (local.get $source) (i32.const 63))
          (i32.const 12)
        )
        ;; Bottom row in source -> Top row in target
        (i32.shr_u
          (i32.and (local.get $source) (i32.const 258048))
          (i32.const 12)
        )
      )
    )
  )

  ;; Horizontal mirroring
  (func $hmirror (param $source i32) (result i32)
    (i32.add
      ;; Immutable middle column
      (i32.and (local.get $source) (i32.const 49932))
      (i32.add
        ;; Left column in source -> Right column in target
        (i32.shl
          (i32.and (local.get $source) (i32.const 12483))
          (i32.const 4)
        )
        ;; Right column in source -> Left column in target
        (i32.shr_u
          (i32.and (local.get $source) (i32.const 199728))
          (i32.const 4)
        )
      )
    )
  )

  ;; Diagonal mirroring
  (func $dmirror (param $source i32) (result i32)
    (i32.add
      ;; Immutable anti-diagonal elements
      (i32.and (local.get $source) (i32.const 13104))
      (i32.add
        (i32.add
          ;; Index 1 -> 5, 3 -> 7 (bitshift +8)
          (i32.shl
            (i32.and (local.get $source) (i32.const 204))
            (i32.const 8)
          ) 
          ;; Index 5 -> 1, 7 -> 3 (bitshift -8)
          (i32.shr_u
            (i32.and (local.get $source) (i32.const 52224))
            (i32.const 8)
          )
        )
        (i32.add
          ;; Index 0 -> 8 (bitshift +16)
          (i32.shl
            (i32.and (local.get $source) (i32.const 3))
            (i32.const 16)
          )
          ;; Index 8 -> 0 (bitshift -16)
          (i32.shr_u
            (i32.and (local.get $source) (i32.const 196608))
            (i32.const 16)
          )
        )
      )
    )
  )

  ;; Anti-diagonal mirroring
  (func $amirror (param $source i32) (result i32)
    (i32.add
      ;; Immutable diagonal elements
      (i32.and (local.get $source) (i32.const 197379))
      (i32.add
        (i32.add
          ;; Index 1 -> 3, 5 -> 7 (bitshift +4)
          (i32.shl
            (i32.and (local.get $source) (i32.const 3084))
            (i32.const 4)
          ) 
          ;; Index 3 -> 1, 7 -> 5 (bitshift -4)
          (i32.shr_u
            (i32.and (local.get $source) (i32.const 49344))
            (i32.const 4)
          )
        )
        (i32.add
          ;; Index 2 -> 6 (bitshift +8)
          (i32.shl
            (i32.and (local.get $source) (i32.const 48))
            (i32.const 8)
          )
          ;; Index 6 -> 2 (bitshift -8)
          (i32.shr_u
            (i32.and (local.get $source) (i32.const 12288))
            (i32.const 8)
          )
        )
      )
    )
  )

  ;; Anti-clockwise rotation by 90deg
  (func $rotate (param $source i32) (result i32)
    (i32.add
      (i32.add
        (i32.add
          ;; Index 0 -> 6 (bitshift +12)
          (i32.shl
            (i32.and (local.get $source) (i32.const 3))
            (i32.const 12)
          )
          ;; Index 8 -> 2 (bitshift -12)
          (i32.shr_u
            (i32.and (local.get $source) (i32.const 196608))
            (i32.const 12)
          )
        )
        (i32.add
          ;; Index 3 -> 7 (bitshift +8)
          (i32.shl
            (i32.and (local.get $source) (i32.const 192))
            (i32.const 8)
          )
          ;; Index 5 -> 1 (bitshift -8)
          (i32.shr_u
            (i32.and (local.get $source) (i32.const 3072))
            (i32.const 8)
          )
        )
      )
      (i32.add
        (i32.add
          ;; Index 1 -> 3, 6 -> 8 (bitshift +4)
          (i32.shl
            (i32.and (local.get $source) (i32.const 12300))
            (i32.const 4)
          )
          ;; Index 2 -> 0, 7 -> 5 (bitshift -4)
          (i32.shr_u
            (i32.and (local.get $source) (i32.const 49200))
            (i32.const 4)
          )
        )
        ;; Index 4 (no change)
        (i32.and (local.get $source) (i32.const 768))
      )
    )
  )

  (func $init
    (i32.store
      (call $offsetForGameBoard (i32.const 0))
      (i32.const 0)
    )
    (global.set $gameStatus (i32.const 5))
  )

  (start $init)

  (export "queryGameStatus" (func $queryGameStatus))
  (export "getCurrentTurnMark" (func $getCurrentTurnMark))
  (export "getCurrentTurnCount" (func $getCurrentTurnCount))
  (export "getCurrentGameBoard" (func $getCurrentGameBoard))
  (export "getWinner" (func $getWinner))
  (export "advanceTurn" (func $advanceTurn))
  (export "setMark" (func $setMark))
  (export "vmirror" (func $vmirror))
  (export "hmirror" (func $hmirror))
  (export "dmirror" (func $dmirror))
  (export "amirror" (func $amirror))
  (export "mirror"  (func $mirror))
  (export "rotate"  (func $rotate))
  (export "getBaseState" (func $getBaseState))
)

;; ------
;;  SPEC TESTS
;; ------
;; ;; Game rules
;; ;; - unittests: setMark
;; ;;   - Mark O is successfully set to the square 0 in a board
;; (assert_return (invoke "setMark" (i32.const 0) (i32.const 0) (i32.const 1)) (i32.const 1))
;; ;;   - Mark X is unsuccessfully set to the square 4 because already marked by O
;; (assert_return (invoke "setMark" (i32.const 256) (i32.const 4) (i32.const 2)) (i32.const 0))
;; ;;   - Mark X is successfully set to the square 8 in a board
;; (assert_return (invoke "setMark" (i32.const 26214) (i32.const 8) (i32.const 2)) (i32.const 157286))
;; ;;   - Mark O is unsuccessfully set because index out of range
;; (assert_return (invoke "setMark" (i32.const 26214) (i32.const 9) (i32.const 1)) (i32.const 0))
;; ;;   - Invalid mark makes no operation
;; (assert_return (invoke "setMark" (i32.const 26214) (i32.const 8) (i32.const 3)) (i32.const 0))
;; ;; - unittests: getWinner
;; (assert_return (invoke "getWinner" (i32.const 74153)) (i32.const 1))
;; (assert_return (invoke "getWinner" (i32.const 137505)) (i32.const 2))
;; (assert_return (invoke "getWinner" (i32.const 149760)) (i32.const 0))

;; ;; Symmetric operations
;; ;; □■□                 ■□■
;; ;; ■□□ ---(vmirror)--> ■□□
;; ;; ■□■                 □■□
;; (assert_return (invoke "vmirror" (i32.const 209100)) (i32.const 49395))

;; ;; □■□                 □■□
;; ;; ■□□ ---(hmirror)--> □□■
;; ;; ■□■                 ■□■
;; (assert_return (invoke "hmirror" (i32.const 209100)) (i32.const 211980))

;; ;; □■□                 ■□□
;; ;; ■□□ ---(dmirror)--> □□■
;; ;; ■□■                 ■■□
;; (assert_return (invoke "dmirror" (i32.const 209100)) (i32.const 64515))

;; ;; □■□                 □■■
;; ;; ■□□ ---(amirror)--> ■□□
;; ;; ■□■                 □□■
;; (assert_return (invoke "amirror" (i32.const 209100)) (i32.const 196860))

;; ;; □■□                 □□■
;; ;; ■□□ ---(rotate)---> ■□□
;; ;; ■□■                 □■■
;; (assert_return (invoke "rotate" (i32.const 209100)) (i32.const 246000))

;; ;; □■□                 ■■□
;; ;; ■□□ --(BaseState)-> □□■
;; ;; ■□■                 ■□□
;; (assert_return (invoke "getBaseState" (i32.const 209100)) (i32.const 15375))
