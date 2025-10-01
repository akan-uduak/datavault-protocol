;; Title: DataVault Protocol
;;
;; Summary: Decentralized Data Marketplace on Bitcoin Layer 2
;;
;; Description: DataVault Protocol enables secure peer-to-peer trading of encrypted data assets
;; on the Stacks blockchain. This trustless marketplace allows data providers to monetize their
;; datasets while buyers gain verifiable access through cryptographic keys. The protocol implements
;; automated escrow, reputation tracking, and encrypted credential management to facilitate seamless
;; data commerce with Bitcoin-level security. Platform fees are transparently distributed, and all
;; transactions are permanently recorded on-chain for auditability and dispute resolution.

;; ============================================================================
;; Constants
;; ============================================================================

(define-constant marketplace-owner tx-sender)
(define-constant error-unauthorized-owner (err u100))
(define-constant error-listing-not-found (err u101))
(define-constant error-asset-already-listed (err u102))
(define-constant error-insufficient-stx-balance (err u103))
(define-constant error-unauthorized-access (err u104))
(define-constant error-invalid-asset-price (err u105))
(define-constant error-invalid-input (err u106))

;; ============================================================================
;; Data Structures
;; ============================================================================

(define-map data-asset-listings
  { data-asset-id: uint }
  {
    asset-owner: principal,
    asset-price: uint,
    asset-description: (string-ascii 256),
    asset-category: (string-ascii 64),
    listing-active-status: bool,
    listing-creation-timestamp: uint,
  }
)

(define-map marketplace-user-profiles
  { marketplace-user: principal }
  {
    user-total-sales: uint,
    user-reputation-score: uint,
    user-last-activity-timestamp: uint,
  }
)

(define-map marketplace-transactions
  {
    asset-buyer: principal,
    purchased-asset-id: uint,
  }
  {
    transaction-timestamp: uint,
    transaction-amount: uint,
    asset-seller: principal,
  }
)

;; Storage of asset access keys (encrypted off-chain)
(define-map data-access-credentials
  { data-asset-id: uint }
  { encrypted-access-key: (string-ascii 512) }
)

;; ============================================================================
;; Data Variables
;; ============================================================================

(define-data-var asset-id-counter uint u1)
(define-data-var marketplace-fee-percentage uint u2) ;; 2% platform fee
(define-data-var total-marketplace-transactions uint u0)

;; ============================================================================
;; Input Validation Functions
;; ============================================================================

(define-private (is-valid-description (description (string-ascii 256)))
  (and
    (not (is-eq description ""))
    (<= (len description) u256)
  )
)

(define-private (is-valid-category (category (string-ascii 64)))
  (and
    (not (is-eq category ""))
    (<= (len category) u64)
  )
)

(define-private (is-valid-access-key (key (string-ascii 512)))
  (and
    (not (is-eq key ""))
    (<= (len key) u512)
  )
)

;; ============================================================================
;; Private Helper Functions
;; ============================================================================

(define-private (calculate-marketplace-fee (asset-price uint))
  (/ (* asset-price (var-get marketplace-fee-percentage)) u100)
)

(define-private (process-stx-transfer
    (sender-address principal)
    (recipient-address principal)
    (transfer-amount uint)
  )
  (stx-transfer? transfer-amount sender-address recipient-address)
)

;; ============================================================================
;; Public Functions - Asset Management
;; ============================================================================

;; Create a new data asset listing
;; @desc: Lists a new encrypted data asset for sale on the marketplace
;; @param asset-price: Price in microSTX for the data asset
;; @param asset-description: Human-readable description of the dataset
;; @param asset-category: Category classification for the asset
;; @param encrypted-access-key: Encrypted credentials for accessing the data
;; @returns: (response uint uint) - The new asset ID on success
(define-public (create-data-asset-listing
    (asset-price uint)
    (asset-description (string-ascii 256))
    (asset-category (string-ascii 64))
    (encrypted-access-key (string-ascii 512))
  )
  (let ((new-asset-id (var-get asset-id-counter)))
    ;; Input validation
    (asserts! (> asset-price u0) error-invalid-asset-price)
    (asserts! (is-valid-description asset-description) error-invalid-input)
    (asserts! (is-valid-category asset-category) error-invalid-input)
    (asserts! (is-valid-access-key encrypted-access-key) error-invalid-input)
    (asserts!
      (not (default-to false
        (get listing-active-status
          (map-get? data-asset-listings { data-asset-id: new-asset-id })
        )))
      error-asset-already-listed
    )

    ;; Create listing
    (map-set data-asset-listings { data-asset-id: new-asset-id } {
      asset-owner: tx-sender,
      asset-price: asset-price,
      asset-description: asset-description,
      asset-category: asset-category,
      listing-active-status: true,
      listing-creation-timestamp: stacks-block-height,
    })

    ;; Store encrypted access credentials
    (map-set data-access-credentials { data-asset-id: new-asset-id } { encrypted-access-key: encrypted-access-key })

    ;; Increment counter
    (var-set asset-id-counter (+ new-asset-id u1))
    (ok new-asset-id)
  )
)

;; Update the price of an existing asset listing
;; @desc: Allows asset owner to modify the sale price
;; @param data-asset-id: ID of the asset to update
;; @param updated-price: New price in microSTX
;; @returns: (response bool uint) - Success status
(define-public (update-asset-price
    (data-asset-id uint)
    (updated-price uint)
  )
  (let ((asset-listing (unwrap! (map-get? data-asset-listings { data-asset-id: data-asset-id })
      error-listing-not-found
    )))
    ;; Validation
    (asserts! (< data-asset-id (var-get asset-id-counter)) error-invalid-input)
    (asserts! (is-eq (get asset-owner asset-listing) tx-sender)
      error-unauthorized-owner
    )
    (asserts! (> updated-price u0) error-invalid-asset-price)

    ;; Update price
    (map-set data-asset-listings { data-asset-id: data-asset-id }
      (merge asset-listing { asset-price: updated-price })
    )
    (ok true)
  )
)

;; Deactivate an asset listing
;; @desc: Removes an asset from active marketplace listings
;; @param data-asset-id: ID of the asset to deactivate
;; @returns: (response bool uint) - Success status
(define-public (deactivate-asset-listing (data-asset-id uint))
  (let ((asset-listing (unwrap! (map-get? data-asset-listings { data-asset-id: data-asset-id })
      error-listing-not-found
    )))
    ;; Validation
    (asserts! (< data-asset-id (var-get asset-id-counter)) error-invalid-input)
    (asserts! (is-eq (get asset-owner asset-listing) tx-sender)
      error-unauthorized-owner
    )

    ;; Deactivate listing
    (map-set data-asset-listings { data-asset-id: data-asset-id }
      (merge asset-listing { listing-active-status: false })
    )
    (ok true)
  )
)

;; ============================================================================
;; Public Functions - Transactions
;; ============================================================================

;; Purchase a data asset
;; @desc: Executes the purchase of a data asset with automatic fee distribution
;; @param data-asset-id: ID of the asset to purchase
;; @returns: (response bool uint) - Transaction success status
(define-public (purchase-data-asset (data-asset-id uint))
  (let (
      (asset-listing (unwrap! (map-get? data-asset-listings { data-asset-id: data-asset-id })
        error-listing-not-found
      ))
      (purchase-price (get asset-price asset-listing))
      (asset-seller (get asset-owner asset-listing))
      (platform-fee-amount (calculate-marketplace-fee purchase-price))
      (seller-payout-amount (- purchase-price platform-fee-amount))
    )
    ;; Validation
    (asserts! (< data-asset-id (var-get asset-id-counter)) error-invalid-input)
    (asserts! (get listing-active-status asset-listing) error-listing-not-found)
    (asserts! (is-eq false (is-eq tx-sender asset-seller))
      error-unauthorized-access
    )

    ;; Execute payments
    (try! (process-stx-transfer tx-sender asset-seller seller-payout-amount))
    (try! (process-stx-transfer tx-sender marketplace-owner platform-fee-amount))

    ;; Record transaction
    (map-set marketplace-transactions {
      asset-buyer: tx-sender,
      purchased-asset-id: data-asset-id,
    } {
      transaction-timestamp: stacks-block-height,
      transaction-amount: purchase-price,
      asset-seller: asset-seller,
    })

    ;; Update seller statistics
    (let ((seller-profile (default-to {
        user-total-sales: u0,
        user-reputation-score: u0,
        user-last-activity-timestamp: u0,
      }
        (map-get? marketplace-user-profiles { marketplace-user: asset-seller })
      )))
      (map-set marketplace-user-profiles { marketplace-user: asset-seller } {
        user-total-sales: (+ (get user-total-sales seller-profile) u1),
        user-reputation-score: (get user-reputation-score seller-profile),
        user-last-activity-timestamp: stacks-block-height,
      })
    )

    ;; Update global transaction counter
    (var-set total-marketplace-transactions
      (+ (var-get total-marketplace-transactions) u1)
    )
    (ok true)
  )
)

;; Retrieve encrypted access credentials for purchased asset
;; @desc: Returns the encrypted access key for a data asset (buyer only)
;; @param data-asset-id: ID of the purchased asset
;; @returns: (response (string-ascii 512) uint) - Encrypted access credentials
(define-public (retrieve-asset-access-key (data-asset-id uint))
  (let (
      (purchase-record (unwrap!
        (map-get? marketplace-transactions {
          asset-buyer: tx-sender,
          purchased-asset-id: data-asset-id,
        })
        error-unauthorized-access
      ))
      (access-credentials (unwrap!
        (map-get? data-access-credentials { data-asset-id: data-asset-id })
        error-listing-not-found
      ))
    )
    ;; Validation
    (asserts! (< data-asset-id (var-get asset-id-counter)) error-invalid-input)

    ;; Return encrypted key
    (ok (get encrypted-access-key access-credentials))
  )
)
