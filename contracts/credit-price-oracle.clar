(define-constant ERR_NOT_AUTHORIZED (err u300))
(define-constant ERR_INVALID_PRICE (err u301))
(define-constant ERR_NO_PRICE_DATA (err u302))

(define-constant MAX_PRICE_HISTORY u50)
(define-constant VOLATILITY_WINDOW u10)

(define-map price-records
  { record-id: uint }
  {
    price-per-credit: uint,
    volume: uint,
    timestamp: uint,
    block-height: uint
  }
)

(define-map market-metrics
  { metric-key: (string-ascii 20) }
  { value: uint }
)

(define-data-var next-record-id uint u1)
(define-data-var total-volume-traded uint u0)
(define-data-var authorized-recorder principal tx-sender)

(define-public (record-trade-price (price-per-credit uint) (volume uint))
  (let (
    (record-id (var-get next-record-id))
  )
    (asserts! (is-eq tx-sender (var-get authorized-recorder)) ERR_NOT_AUTHORIZED)
    (asserts! (> price-per-credit u0) ERR_INVALID_PRICE)
    (asserts! (> volume u0) ERR_INVALID_PRICE)
    
    (map-set price-records
      { record-id: record-id }
      {
        price-per-credit: price-per-credit,
        volume: volume,
        timestamp: stacks-block-height,
        block-height: stacks-block-height
      }
    )
    
    (var-set next-record-id (+ record-id u1))
    (var-set total-volume-traded (+ (var-get total-volume-traded) volume))
    (unwrap-panic (update-market-average))
    (ok record-id)
  )
)

(define-private (update-market-average)
  (let (
    (recent-count (if (< (var-get next-record-id) MAX_PRICE_HISTORY) (var-get next-record-id) MAX_PRICE_HISTORY))
    (start-id (if (<= (var-get next-record-id) MAX_PRICE_HISTORY)
                u1
                (- (var-get next-record-id) MAX_PRICE_HISTORY)))
  )
    (let ((avg (calculate-weighted-average start-id recent-count)))
      (map-set market-metrics
        { metric-key: "avg-price" }
        { value: avg }
      )
      (ok true)
    )
  )
)

(define-private (calculate-weighted-average (start-id uint) (count uint))
  (let (
    (sum (fold + (map get-price-volume-product (generate-range start-id count)) u0))
    (total-vol (fold + (map get-volume (generate-range start-id count)) u0))
  )
    (if (> total-vol u0)
      (/ sum total-vol)
      u0
    )
  )
)

(define-private (get-price-volume-product (id uint))
  (match (map-get? price-records { record-id: id })
    record (* (get price-per-credit record) (get volume record))
    u0
  )
)

(define-private (get-volume (id uint))
  (match (map-get? price-records { record-id: id })
    record (get volume record)
    u0
  )
)

(define-private (generate-range (start uint) (count uint))
  (map + (list u0 u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20 u21 u22 u23 u24 u25 u26 u27 u28 u29 u30 u31 u32 u33 u34 u35 u36 u37 u38 u39 u40 u41 u42 u43 u44 u45 u46 u47 u48 u49)
       (list start start start start start start start start start start start start start start start start start start start start start start start start start start start start start start start start start start start start start start start start start start start start start start start start start start))
)

(define-read-only (get-market-price)
  (default-to u0 (get value (map-get? market-metrics { metric-key: "avg-price" })))
)

(define-read-only (get-price-record (record-id uint))
  (map-get? price-records { record-id: record-id })
)

(define-read-only (get-oracle-stats)
  {
    total-records: (- (var-get next-record-id) u1),
    total-volume: (var-get total-volume-traded),
    current-market-price: (get-market-price)
  }
)

(define-public (set-authorized-recorder (new-recorder principal))
  (begin
    (asserts! (is-eq tx-sender (var-get authorized-recorder)) ERR_NOT_AUTHORIZED)
    (var-set authorized-recorder new-recorder)
    (ok true)
  )
)
