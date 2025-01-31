;; ATLAS - Advanced Token with Layered Administration System
;; Implements an advanced fungible token with governance and vesting features

(define-fungible-token advanced-token)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-insufficient-balance (err u101))
(define-constant err-invalid-amount (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-already-initialized (err u104))

;; Data Variables
(define-data-var total-supply uint u0)
(define-data-var initialized bool false)
(define-data-var token-name (string-utf8 32) u"")
(define-data-var token-symbol (string-utf8 10) u"")
(define-data-var token-decimals uint u6)

;; Maps
(define-map allowed-operators 
  { operator: principal, owner: principal } 
  { allowed: bool })

(define-map vesting-schedules
  { beneficiary: principal }
  { total-amount: uint, 
    released-amount: uint,
    start-height: uint,
    duration: uint,
    cliff-duration: uint })

;; Initialize contract
(define-public (initialize 
    (name (string-utf8 32))
    (symbol (string-utf8 10))
    (decimals uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (not (var-get initialized)) err-already-initialized)
    (var-set token-name name)
    (var-set token-symbol symbol)
    (var-set token-decimals decimals)
    (var-set initialized true)
    (ok true)))

;; Mint tokens
(define-public (mint (amount uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> amount u0) err-invalid-amount)
    (try! (ft-mint? advanced-token amount recipient))
    (var-set total-supply (+ (var-get total-supply) amount))
    (ok true)))

;; Transfer tokens
(define-public (transfer (amount uint) (sender principal) (recipient principal))
  (begin
    (asserts! (or (is-eq tx-sender sender)
                  (get allowed (default-to { allowed: false }
                    (map-get? allowed-operators { operator: tx-sender, owner: sender }))))
        err-unauthorized)
    (asserts! (> amount u0) err-invalid-amount)
    (try! (ft-transfer? advanced-token amount sender recipient))
    (ok true)))

;; Approve operator
(define-public (approve-operator (operator principal))
  (begin
    (map-set allowed-operators
      { operator: operator, owner: tx-sender }
      { allowed: true })
    (ok true)))

;; Revoke operator
(define-public (revoke-operator (operator principal))
  (begin
    (map-set allowed-operators
      { operator: operator, owner: tx-sender }
      { allowed: false })
    (ok true)))

;; Create vesting schedule
(define-public (create-vesting-schedule 
    (beneficiary principal)
    (amount uint)
    (duration uint)
    (cliff-duration uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (>= duration cliff-duration) (err u105))
    (map-set vesting-schedules
      { beneficiary: beneficiary }
      { total-amount: amount,
        released-amount: u0,
        start-height: block-height,
        duration: duration,
        cliff-duration: cliff-duration })
    (ok true)))

;; Private function to calculate vested amount
(define-private (get-vested-amount (schedule {
    total-amount: uint,
    released-amount: uint,
    start-height: uint,
    duration: uint,
    cliff-duration: uint }))
  (let ((elapsed (- block-height (get start-height schedule))))
    (if (< elapsed (get cliff-duration schedule))
      u0
      (if (>= elapsed (get duration schedule))
        (get total-amount schedule)
        (/ (* (get total-amount schedule) elapsed) (get duration schedule))))))

