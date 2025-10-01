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