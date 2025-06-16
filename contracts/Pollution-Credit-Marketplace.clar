(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INSUFFICIENT_CREDITS (err u101))
(define-constant ERR_INVALID_AMOUNT (err u102))
(define-constant ERR_LISTING_NOT_FOUND (err u103))
(define-constant ERR_CANNOT_BUY_OWN_LISTING (err u104))
(define-constant ERR_LISTING_EXPIRED (err u105))
(define-constant ERR_COMPANY_NOT_REGISTERED (err u106))
(define-constant ERR_COMPANY_ALREADY_REGISTERED (err u107))
(define-constant ERR_INVALID_PRICE (err u108))

(define-map companies
  { company: principal }
  {
    name: (string-ascii 50),
    industry: (string-ascii 30),
    credits: uint,
    registered-at: uint
  }
)

(define-map credit-listings
  { listing-id: uint }
  {
    seller: principal,
    amount: uint,
    price-per-credit: uint,
    expires-at: uint,
    active: bool
  }
)

(define-map credit-transactions
  { transaction-id: uint }
  {
    buyer: principal,
    seller: principal,
    amount: uint,
    price-per-credit: uint,
    timestamp: uint
  }
)

(define-data-var next-listing-id uint u1)
(define-data-var next-transaction-id uint u1)
(define-data-var total-credits-issued uint u0)
(define-data-var total-credits-traded uint u0)

(define-public (register-company (name (string-ascii 50)) (industry (string-ascii 30)))
  (let ((company tx-sender))
    (asserts! (is-none (map-get? companies { company: company })) ERR_COMPANY_ALREADY_REGISTERED)
    (map-set companies
      { company: company }
      {
        name: name,
        industry: industry,
        credits: u0,
        registered-at: stacks-block-height
      }
    )
    (ok true)
  )
)

(define-public (issue-credits (company principal) (amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (is-some (map-get? companies { company: company })) ERR_COMPANY_NOT_REGISTERED)
    (let ((current-data (unwrap-panic (map-get? companies { company: company }))))
      (map-set companies
        { company: company }
        (merge current-data { credits: (+ (get credits current-data) amount) })
      )
      (var-set total-credits-issued (+ (var-get total-credits-issued) amount))
      (ok true)
    )
  )
)

(define-public (create-listing (amount uint) (price-per-credit uint) (duration uint))
  (let (
    (listing-id (var-get next-listing-id))
    (seller tx-sender)
    (company-data (map-get? companies { company: seller }))
  )
    (asserts! (is-some company-data) ERR_COMPANY_NOT_REGISTERED)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (> price-per-credit u0) ERR_INVALID_PRICE)
    (asserts! (>= (get credits (unwrap-panic company-data)) amount) ERR_INSUFFICIENT_CREDITS)
    
    (let ((current-company-data (unwrap-panic company-data)))
      (map-set companies
        { company: seller }
        (merge current-company-data { credits: (- (get credits current-company-data) amount) })
      )
    )
    
    (map-set credit-listings
      { listing-id: listing-id }
      {
        seller: seller,
        amount: amount,
        price-per-credit: price-per-credit,
        expires-at: (+ stacks-block-height duration),
        active: true
      }
    )
    
    (var-set next-listing-id (+ listing-id u1))
    (ok listing-id)
  )
)

(define-public (buy-credits (listing-id uint) (amount uint))
  (let (
    (listing (map-get? credit-listings { listing-id: listing-id }))
    (buyer tx-sender)
    (buyer-data (map-get? companies { company: buyer }))
  )
    (asserts! (is-some listing) ERR_LISTING_NOT_FOUND)
    (asserts! (is-some buyer-data) ERR_COMPANY_NOT_REGISTERED)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    
    (let ((listing-data (unwrap-panic listing)))
      (asserts! (get active listing-data) ERR_LISTING_NOT_FOUND)
      (asserts! (< stacks-block-height (get expires-at listing-data)) ERR_LISTING_EXPIRED)
      (asserts! (not (is-eq buyer (get seller listing-data))) ERR_CANNOT_BUY_OWN_LISTING)
      (asserts! (>= (get amount listing-data) amount) ERR_INSUFFICIENT_CREDITS)
      
      (let (
        (total-cost (* amount (get price-per-credit listing-data)))
        (remaining-amount (- (get amount listing-data) amount))
        (transaction-id (var-get next-transaction-id))
        (current-buyer-data (unwrap-panic buyer-data))
      )
        
        (try! (stx-transfer? total-cost buyer (get seller listing-data)))
        
        (map-set companies
          { company: buyer }
          (merge current-buyer-data { credits: (+ (get credits current-buyer-data) amount) })
        )
        
        (if (is-eq remaining-amount u0)
          (map-set credit-listings
            { listing-id: listing-id }
            (merge listing-data { active: false, amount: u0 })
          )
          (map-set credit-listings
            { listing-id: listing-id }
            (merge listing-data { amount: remaining-amount })
          )
        )
        
        (map-set credit-transactions
          { transaction-id: transaction-id }
          {
            buyer: buyer,
            seller: (get seller listing-data),
            amount: amount,
            price-per-credit: (get price-per-credit listing-data),
            timestamp: stacks-block-height
          }
        )
        
        (var-set next-transaction-id (+ transaction-id u1))
        (var-set total-credits-traded (+ (var-get total-credits-traded) amount))
        (ok transaction-id)
      )
    )
  )
)

(define-public (cancel-listing (listing-id uint))
  (let ((listing (map-get? credit-listings { listing-id: listing-id })))
    (asserts! (is-some listing) ERR_LISTING_NOT_FOUND)
    (let ((listing-data (unwrap-panic listing)))
      (asserts! (is-eq tx-sender (get seller listing-data)) ERR_NOT_AUTHORIZED)
      (asserts! (get active listing-data) ERR_LISTING_NOT_FOUND)
      
      (let ((seller-data (unwrap-panic (map-get? companies { company: tx-sender }))))
        (map-set companies
          { company: tx-sender }
          (merge seller-data { credits: (+ (get credits seller-data) (get amount listing-data)) })
        )
      )
      
      (map-set credit-listings
        { listing-id: listing-id }
        (merge listing-data { active: false, amount: u0 })
      )
      (ok true)
    )
  )
)

(define-read-only (get-company (company principal))
  (map-get? companies { company: company })
)

(define-read-only (get-listing (listing-id uint))
  (map-get? credit-listings { listing-id: listing-id })
)

(define-read-only (get-transaction (transaction-id uint))
  (map-get? credit-transactions { transaction-id: transaction-id })
)

(define-read-only (get-marketplace-stats)
  {
    total-credits-issued: (var-get total-credits-issued),
    total-credits-traded: (var-get total-credits-traded),
    next-listing-id: (var-get next-listing-id),
    next-transaction-id: (var-get next-transaction-id)
  }
)

(define-read-only (is-listing-active (listing-id uint))
  (match (map-get? credit-listings { listing-id: listing-id })
    listing (and (get active listing) (< stacks-block-height (get expires-at listing)))
    false
  )
)
