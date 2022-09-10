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

  (export "vmirror" (func $vmirror))
  (export "hmirror" (func $hmirror))
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
