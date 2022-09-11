(module
  ;; ------
  ;;  Board representation
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
  ;; (Unused 14 bits)| 8  7 6  5 4  3 2  1 0
  ;; 0000 0000 0000 0000 0000 0000 0000 0000
  ;;
  ;; (Unused 14 bits)|  8 7 6  5 4 3  2 1 0
  ;; 0000 0000 0000 00 000000 000000 000000
  ;;
  ;; - 00: Blank
  ;; - 01: O
  ;; - 10: X
  ;;

  ;; Get minimum board representation as base state for deduplication
  ;; by checking over symmetries 
  (func $getBaseState (param $board i32) (result i32)
    (local $m i32)
    (local $r i32)
    (local $s i32)
    (local $base i32)
    (local.set $base (local.get $board))

    (block $exit
      (loop $mloop  ;; loop over mirrorings
        (br_if $exit (i32.ge_u (local.get $m) (i32.const 5)))
        (local.set $s (local.get $board))
        (local.set $s (call $mirror (local.get $s) (local.get $m)))
        (local.set $m (i32.add (local.get $m) (i32.const 1)))
        (local.set $r (i32.const 0))
        (loop $rloop  ;; loop over rotations
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

  (export "vmirror" (func $vmirror))
  (export "hmirror" (func $hmirror))
  (export "dmirror" (func $dmirror))
  (export "amirror" (func $amirror))
  (export "mirror"  (func $mirror))
  (export "rotate"  (func $rotate))
  (export "getBaseState" (func $getBaseState))
)

;; ;; Tests
;; (assert_return (invoke "vmirror" (i32.const 209100)) (i32.const 49395))
;; ;; □■□                 ■□■
;; ;; ■□□ ---(vmirror)--> ■□□
;; ;; ■□■                 □■□
;; (assert_return (invoke "hmirror" (i32.const 209100)) (i32.const 211980))
;; ;; □■□                 □■□
;; ;; ■□□ ---(hmirror)--> □□■
;; ;; ■□■                 ■□■
;; (assert_return (invoke "dmirror" (i32.const 209100)) (i32.const 64515))
;; ;; □■□                 ■□□
;; ;; ■□□ ---(dmirror)--> □□■
;; ;; ■□■                 ■■□
;; (assert_return (invoke "amirror" (i32.const 209100)) (i32.const 196860))
;; ;; □■□                 □■■
;; ;; ■□□ ---(amirror)--> ■□□
;; ;; ■□■                 □□■
;; (assert_return (invoke "rotate" (i32.const 209100)) (i32.const 246000))
;; ;; □■□                 □□■
;; ;; ■□□ ---(rotate)---> ■□□
;; ;; ■□■                 □■■
;; (assert_return (invoke "getBaseState" (i32.const 209100)) (i32.const 15375))
;; ;; □■□                 ■■□
;; ;; ■□□ --(BaseState)-> □□■
;; ;; ■□■                 ■□□
