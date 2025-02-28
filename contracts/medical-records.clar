 
;; Medical Database Management System
;; This smart contract manages medical information with privacy controls

;; Main Data Storage
(define-data-var records-count uint u0) ;; Keeps count of all medical files in the system

;; Core Data Structures for Information Storage
(define-map health-files
  { file-id: uint }
  {
    subject-identifier: (string-ascii 64),  ;; Patient identifier
    provider-principal: principal,          ;; Healthcare provider principal
    content-volume: uint,                   ;; Document size indicator
    timestamp-block: uint,                  ;; When the file was registered
    clinical-summary: (string-ascii 128),   ;; Clinical observations
    categories: (list 10 (string-ascii 32)) ;; Classification metadata
  }
)

(define-map viewing-rights
  { file-id: uint, viewer-principal: principal }
  { access-enabled: bool } ;; Controls who can view specific files
)

;; System Response Codes
(define-constant NOT_FOUND_ERROR (err u301))           ;; File does not exist
(define-constant DUPLICATE_ERROR (err u302))           ;; File already recorded
(define-constant IDENTIFIER_ERROR (err u303))          ;; Invalid identifier format
(define-constant VOLUME_ERROR (err u304))              ;; Invalid content volume
(define-constant AUTH_FAILURE (err u305))              ;; Authentication failure
(define-constant PROVIDER_ERROR (err u306))            ;; Invalid provider principal
(define-constant ADMIN_ONLY (err u300))                ;; Administrative restriction
(define-constant CATEGORY_ERROR (err u307))            ;; Invalid category format
(define-constant ACCESS_VIOLATION (err u308))          ;; Unauthorized access attempt

;; Administrative Constants
(define-constant system-admin tx-sender) ;; System administrator principal

;; Internal Utility Functions

;; Validates if a file exists in the system
(define-private (file-exists? (file-id uint))
  (is-some (map-get? health-files { file-id: file-id }))
)
