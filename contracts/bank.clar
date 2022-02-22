;; bank
;; This contract serves as a time-locked piggy bank, where users can deposit
;; their STX and withdrawal it later.

;; constants
(define-constant err-insufficient-balance (err u1))
(define-constant err-unauthorized (err u2))

;; data maps and vars
(define-map accounts { holder: principal } { amount: int })

;; public functions
(define-public (deposit (amount int))
    (let ((balance (default-to 0 (get amount (map-get? accounts {holder: tx-sender})))))
        (map-set accounts {holder: tx-sender} {amount: (+ balance amount)})
        (stx-transfer? (to-uint amount) tx-sender (as-contract tx-sender))
    )
)

(define-public (withdrawal-unsafe (amount int))
    (let (
          (balance (- (default-to 0 (get amount (map-get? accounts {holder: tx-sender}))) amount))
          (customer tx-sender)
         )
        (map-set accounts {holder: tx-sender} {amount: balance})
        (as-contract (stx-transfer? (to-uint amount) tx-sender customer))
    )
)

(define-public (withdrawal (amount int))
    (let (
          (balance (- (default-to 0 (get amount (map-get? accounts {holder: tx-sender}))) amount))
          (customer tx-sender)
         )
        (asserts! (<= amount balance) err-insufficient-balance)
        (map-set accounts {holder: tx-sender} {amount: balance})
        (as-contract (stx-transfer? (to-uint amount) tx-sender customer))
    )
)

(define-public (withdrawal-if (amount int))
    (let (
          (balance (default-to 0 (get amount (map-get? accounts {holder: tx-sender}))))
          (customer tx-sender)
         )
        (if (<= amount balance)
            (begin
                (map-set accounts {holder: tx-sender} {amount: (- balance amount)})
                (as-contract (stx-transfer? (to-uint amount) tx-sender customer))
            )
            err-insufficient-balance
        )
    )
)

(define-read-only (get-balance)
    (default-to 0 (get amount (map-get? accounts {holder: tx-sender})))
)

(define-data-var bank-owner principal tx-sender)

(define-public (take (amount int) (from principal))
    (let ((balance (- (default-to 0 (get amount (map-get? accounts {holder: from}))) amount)))
        (asserts! (is-eq tx-sender (var-get bank-owner)) err-unauthorized)
        (map-set accounts {holder: from} {amount: balance})
        (stx-transfer? (to-uint amount) (as-contract tx-sender) tx-sender)
    )
)
