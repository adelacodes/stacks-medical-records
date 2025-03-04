 
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

;; Confirms provider ownership of a file
(define-private (provider-owns-file? (file-id uint) (provider principal))
  (match (map-get? health-files { file-id: file-id })
    file-info (is-eq (get provider-principal file-info) provider)
    false
  )
)

;; Retrieves file size information
(define-private (file-volume (file-id uint))
  (default-to u0
    (get content-volume
      (map-get? health-files { file-id: file-id })
    )
  )
)

;; Validates single category formatting
(define-private (is-valid-category (category (string-ascii 32)))
  (and 
    (> (len category) u0)
    (< (len category) u33)
  )
)

;; Validates the entire category set
(define-private (validate-category-set (categories (list 10 (string-ascii 32))))
  (and
    (> (len categories) u0)  ;; At least one category required
    (<= (len categories) u10) ;; Maximum 10 categories allowed
    (is-eq (len (filter is-valid-category categories)) (len categories)) ;; All categories must pass validation
  )
)

;; User validation helper
(define-private (is-authorized-viewer? (viewer principal))
  (or
    (is-eq viewer system-admin) ;; System admin always has access
    ;; Additional authorization logic could be added here
  )
)

;; ========== FILE MANAGEMENT FUNCTIONS ==========

;; Creates a new medical file in the system
(define-public (create-file 
  (subject-identifier (string-ascii 64))       ;; Patient identifier
  (content-volume uint)                        ;; Size of file in bytes
  (clinical-summary (string-ascii 128))        ;; Clinical notes
  (categories (list 10 (string-ascii 32)))     ;; Classification categories
)
  (let
    (
      (file-id (+ (var-get records-count) u1))  ;; Generate sequential ID
    )
    ;; Input validation
    (asserts! (> (len subject-identifier) u0) IDENTIFIER_ERROR)
    (asserts! (< (len subject-identifier) u65) IDENTIFIER_ERROR)
    (asserts! (> content-volume u0) VOLUME_ERROR)
    (asserts! (< content-volume u1000000000) VOLUME_ERROR)
    (asserts! (> (len clinical-summary) u0) IDENTIFIER_ERROR)
    (asserts! (< (len clinical-summary) u129) IDENTIFIER_ERROR)
    (asserts! (validate-category-set categories) CATEGORY_ERROR)

    ;; Store the file metadata
    (map-insert health-files
      { file-id: file-id }
      {
        subject-identifier: subject-identifier,
        provider-principal: tx-sender,
        content-volume: content-volume,
        timestamp-block: block-height,
        clinical-summary: clinical-summary,
        categories: categories
      }
    )

    ;; Grant access to file creator
    (map-insert viewing-rights
      { file-id: file-id, viewer-principal: tx-sender }
      { access-enabled: true }
    )

    ;; Update system records
    (var-set records-count file-id)
    (ok file-id)
  )
)

;; Updates an existing file with new information
(define-public (modify-file 
  (file-id uint)                             ;; Target file ID
  (new-subject-identifier (string-ascii 64)) ;; Updated patient identifier
  (new-volume uint)                          ;; Updated size
  (new-summary (string-ascii 128))           ;; Updated clinical notes
  (new-categories (list 10 (string-ascii 32))) ;; Updated categories
)
  (let
    (
      (file-info (unwrap! (map-get? health-files { file-id: file-id }) NOT_FOUND_ERROR))
    )
    ;; Validation checks
    (asserts! (file-exists? file-id) NOT_FOUND_ERROR)
    (asserts! (is-eq (get provider-principal file-info) tx-sender) AUTH_FAILURE)
    (asserts! (> (len new-subject-identifier) u0) IDENTIFIER_ERROR)
    (asserts! (< (len new-subject-identifier) u65) IDENTIFIER_ERROR)
    (asserts! (> new-volume u0) VOLUME_ERROR)
    (asserts! (< new-volume u1000000000) VOLUME_ERROR)
    (asserts! (> (len new-summary) u0) IDENTIFIER_ERROR)
    (asserts! (< (len new-summary) u129) IDENTIFIER_ERROR)
    (asserts! (validate-category-set new-categories) CATEGORY_ERROR)

    ;; Update file metadata
    (map-set health-files
      { file-id: file-id }
      (merge file-info { 
        subject-identifier: new-subject-identifier, 
        content-volume: new-volume, 
        clinical-summary: new-summary, 
        categories: new-categories 
      })
    )
    (ok true)
  )
)

;; Removes a file from the system
(define-public (remove-file (file-id uint))
  (let
    (
      (file-info (unwrap! (map-get? health-files { file-id: file-id }) NOT_FOUND_ERROR))
    )
    ;; Validation
    (asserts! (file-exists? file-id) NOT_FOUND_ERROR)
    (asserts! (is-eq (get provider-principal file-info) tx-sender) AUTH_FAILURE)

    ;; Remove file and access records
    (map-delete health-files { file-id: file-id })
    (map-delete viewing-rights { file-id: file-id, viewer-principal: tx-sender })
    (ok true)
  )
)

;; Changes the provider associated with a file
(define-public (transfer-ownership (file-id uint) (new-provider principal))
  (let
    (
      (file-info (unwrap! (map-get? health-files { file-id: file-id }) NOT_FOUND_ERROR))
    )
    ;; Validation
    (asserts! (file-exists? file-id) NOT_FOUND_ERROR)
    (asserts! (is-eq (get provider-principal file-info) tx-sender) AUTH_FAILURE)

    ;; Update provider information
    (map-set health-files
      { file-id: file-id }
      (merge file-info { provider-principal: new-provider })
    )
    (ok true)
  )
)

;; Authorizes a user to access a specific file
(define-public (authorize-access 
  (file-id uint)               
  (viewer principal)           
)
  (let
    (
      (file-info (unwrap! (map-get? health-files { file-id: file-id }) NOT_FOUND_ERROR))
    )
    ;; Validation
    (asserts! (file-exists? file-id) NOT_FOUND_ERROR)
    (asserts! (is-eq (get provider-principal file-info) tx-sender) AUTH_FAILURE)
    (asserts! (is-authorized-viewer? viewer) ACCESS_VIOLATION)

    ;; Grant access permission
    (map-insert viewing-rights
      { file-id: file-id, viewer-principal: viewer }
      { access-enabled: true }
    )
    (ok true)
  )
)

;; ========== INFORMATION RETRIEVAL FUNCTIONS ==========

;; Retrieves complete file information
(define-public (get-file-details (file-id uint))
  (let
    (
      (file-info (unwrap! (map-get? health-files { file-id: file-id }) NOT_FOUND_ERROR))
    )
    (ok file-info)
  )
)

;; Gets system statistics
(define-public (get-system-stats)
  (ok (var-get records-count))
)

;; Retrieves subject identifier from file
(define-public (get-subject-id (file-id uint))
  (let
    (
      (file-info (unwrap! (map-get? health-files { file-id: file-id }) NOT_FOUND_ERROR))
    )
    (ok (get subject-identifier file-info))
  )
)

;; Retrieves provider information for file
(define-public (get-file-provider (file-id uint))
  (let
    (
      (file-info (unwrap! (map-get? health-files { file-id: file-id }) NOT_FOUND_ERROR))
    )
    (ok (get provider-principal file-info))
  )
)

;; Retrieves file creation timestamp
(define-public (get-file-timestamp (file-id uint))
  (let
    (
      (file-info (unwrap! (map-get? health-files { file-id: file-id }) NOT_FOUND_ERROR))
    )
    (ok (get timestamp-block file-info))
  )
)

;; Retrieves file size information
(define-public (get-file-size (file-id uint))
  (let
    (
      (file-info (unwrap! (map-get? health-files { file-id: file-id }) NOT_FOUND_ERROR))
    )
    (ok (get content-volume file-info))
  )
)

;; Retrieves file clinical summary
(define-public (get-file-summary (file-id uint))
  (let
    (
      (file-info (unwrap! (map-get? health-files { file-id: file-id }) NOT_FOUND_ERROR))
    )
    (ok (get clinical-summary file-info))
  )
)

;; Retrieves all categories for a file
(define-public (get-file-categories (file-id uint))
  (let
    (
      (file-info (unwrap! (map-get? health-files { file-id: file-id }) NOT_FOUND_ERROR))
    )
    (ok (get categories file-info))
  )
)

;; Counts the number of categories for a file
(define-public (count-file-categories (file-id uint))
  (let
    (
      (file-info (unwrap! (map-get? health-files { file-id: file-id }) NOT_FOUND_ERROR))
    )
    (ok (len (get categories file-info)))
  )
)


;; ========== ACCESS MANAGEMENT FUNCTIONS ==========

;; Verifies if a user has access to a specific file
(define-public (verify-access (file-id uint) (viewer-principal principal))
  (let
    (
      (access-info (unwrap! (map-get? viewing-rights { file-id: file-id, viewer-principal: viewer-principal }) ACCESS_VIOLATION))
    )
    (ok (get access-enabled access-info))
  )
)

;; Alternative access check functions (these perform the same validation with different names)
(define-public (check-viewer-access (file-id uint) (viewer-principal principal))
  (let
    (
      (access-info (unwrap! (map-get? viewing-rights { file-id: file-id, viewer-principal: viewer-principal }) ACCESS_VIOLATION))
    )
    (ok (get access-enabled access-info))
  )
)


(define-public (get-access-status (file-id uint) (viewer-principal principal))
  (let
    (
      (access-info (unwrap! (map-get? viewing-rights { file-id: file-id, viewer-principal: viewer-principal }) ACCESS_VIOLATION))
    )
    (ok (get access-enabled access-info))
  )
)

(define-public (has-viewing-permission (file-id uint) (viewer-principal principal))
  (let
    (
      (access-info (unwrap! (map-get? viewing-rights { file-id: file-id, viewer-principal: viewer-principal }) ACCESS_VIOLATION))
    )
    (ok (get access-enabled access-info))
  )
)

(define-public (is-viewer-authorized (file-id uint) (viewer-principal principal))
  (let
    (
      (access-info (unwrap! (map-get? viewing-rights { file-id: file-id, viewer-principal: viewer-principal }) ACCESS_VIOLATION))
    )
    (ok (get access-enabled access-info))
  )
)
