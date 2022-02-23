;; bank
;; This contract serves as a simple piggy bank, where users can deposit STX
;; and withdrawal it later. It serves as an example program to demonstrate
;; features of the check-checker.

;; constants
(define-constant err-insufficient-balance (err u1))
(define-constant err-unauthorized (err u2))

;; data maps and vars
(define-map accounts { holder: principal } { amount: int })

;; public functions
(define-public (deposit (amount uint))
    (let ((balance (default-to 0 (get amount (map-get? accounts {holder: tx-sender})))))
        ;; A user should be allowed to specify any amount to deposit, and the
        ;; `stx-transfer?` will fail and rollback all operations if the sender
        ;; does not have enough STX, so it is safe to allow the unchecked data
        ;; here.
        ;; #[allow(unchecked_data)]
        (map-set accounts {holder: tx-sender} {amount: (+ balance (to-int amount))})
        (stx-transfer? amount tx-sender (as-contract tx-sender))
    )
)

;; This unsafe implementation of withdrawal forgets to include a check on the
;; amount. See the tests for what can happen!
(define-public (withdrawal-unsafe (amount uint))
    (let (
          (balance (- (default-to 0 (get amount (map-get? accounts {holder: tx-sender}))) (to-int amount)))
          (customer tx-sender)
         )
         ;; `balance` is tainted by the untrusted input, `amount`, so the
         ;; check-checker reports a warning when it is written into a map.
        (map-set accounts {holder: tx-sender} {amount: balance})
        ;; `amount` is untrusted input, so it is dangerous to use it in a
        ;; `stx_transfer?` call.
        (as-contract (stx-transfer? amount tx-sender customer))
    )
)

(define-public (withdrawal (amount uint))
    (let (
          (balance (default-to 0 (get amount (map-get? accounts {holder: tx-sender}))))
          (customer tx-sender)
         )
        ;; This `asserts!` is a check on `amount`, allowing it to be used
        ;; without warnings from the check-checker.
        (asserts! (>= balance (to-int amount)) err-insufficient-balance)
        (map-set accounts {holder: tx-sender} {amount: (- balance (to-int amount))})
        (as-contract (stx-transfer? amount tx-sender customer))
    )
)

(define-public (withdrawal-if (amount uint))
    (let (
          (balance (default-to 0 (get amount (map-get? accounts {holder: tx-sender}))))
          (customer tx-sender)
         )
        ;; Here is another example of a way to check the untrusted input.
        (if (<= (to-int amount) balance)
            (begin
                (map-set accounts {holder: tx-sender} {amount: (- balance (to-int amount))})
                (as-contract (stx-transfer? amount tx-sender customer))
            )
            err-insufficient-balance
        )
    )
)

(define-read-only (get-balance)
    (default-to 0 (get amount (map-get? accounts {holder: tx-sender})))
)

(define-data-var bank-owner principal tx-sender)

(define-public (take (amount uint) (from principal))
    (let ((balance (- (default-to 0 (get amount (map-get? accounts {holder: from}))) (to-int amount))))
        ;; When the `trusted_sender` option is enabled, the check on
        ;; `tx-sender` below tells the check-checker that this is a trusted
        ;; sender, so we trust all inputs. If you disable this option (in
        ;; Clarinet.toml) you will see warnings on the uses below.
        (asserts! (is-eq tx-sender (var-get bank-owner)) err-unauthorized)
        (map-set accounts {holder: from} {amount: balance})
        (stx-transfer? amount (as-contract tx-sender) tx-sender)
    )
)
