(define-constant ERR_NOT_AUTHORIZED (err u200))
(define-constant ERR_INVALID_BUNDLE (err u201))
(define-constant ERR_BUNDLE_NOT_FOUND (err u202))
(define-constant ERR_BUNDLE_EXPIRED (err u203))
(define-constant ERR_BUNDLE_ALREADY_EXECUTED (err u204))
(define-constant ERR_EMPTY_BUNDLE (err u205))
(define-constant ERR_TOO_MANY_LISTINGS (err u206))

(define-constant MAX_BUNDLE_SIZE u10)

(define-map credit-bundles
  { bundle-id: uint }
  {
    creator: principal,
    listing-ids: (list 10 uint),
    total-cost: uint,
    expires-at: uint,
    executed: bool,
    created-at: uint
  }
)

(define-data-var next-bundle-id uint u1)
(define-data-var total-bundles-created uint u0)
(define-data-var total-bundles-executed uint u0)

(define-public (create-bundle (listing-ids (list 10 uint)) (duration uint))
  (let (
    (bundle-id (var-get next-bundle-id))
    (creator tx-sender)
    (bundle-size (len listing-ids))
  )
    (asserts! (> bundle-size u0) ERR_EMPTY_BUNDLE)
    (asserts! (<= bundle-size MAX_BUNDLE_SIZE) ERR_TOO_MANY_LISTINGS)
    
    (map-set credit-bundles
      { bundle-id: bundle-id }
      {
        creator: creator,
        listing-ids: listing-ids,
        total-cost: u0,
        expires-at: (+ stacks-block-height duration),
        executed: false,
        created-at: stacks-block-height
      }
    )
    
    (var-set next-bundle-id (+ bundle-id u1))
    (var-set total-bundles-created (+ (var-get total-bundles-created) u1))
    (ok bundle-id)
  )
)

(define-public (execute-bundle (bundle-id uint))
  (let ((bundle (map-get? credit-bundles { bundle-id: bundle-id })))
    (asserts! (is-some bundle) ERR_BUNDLE_NOT_FOUND)
    
    (let ((bundle-data (unwrap-panic bundle)))
      (asserts! (not (get executed bundle-data)) ERR_BUNDLE_ALREADY_EXECUTED)
      (asserts! (< stacks-block-height (get expires-at bundle-data)) ERR_BUNDLE_EXPIRED)
      
      (map-set credit-bundles
        { bundle-id: bundle-id }
        (merge bundle-data { executed: true })
      )
      
      (var-set total-bundles-executed (+ (var-get total-bundles-executed) u1))
      (ok true)
    )
  )
)

(define-read-only (get-bundle (bundle-id uint))
  (map-get? credit-bundles { bundle-id: bundle-id })
)

(define-read-only (get-bundle-stats)
  {
    total-bundles-created: (var-get total-bundles-created),
    total-bundles-executed: (var-get total-bundles-executed),
    next-bundle-id: (var-get next-bundle-id)
  }
)

(define-read-only (is-bundle-executable (bundle-id uint))
  (match (map-get? credit-bundles { bundle-id: bundle-id })
    bundle (and 
      (not (get executed bundle)) 
      (< stacks-block-height (get expires-at bundle))
    )
    false
  )
)
