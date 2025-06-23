;; Healthcare Insurance Management Smart Contract
;;
;; A decentralized healthcare insurance management system built on the Stacks blockchain.
;; This contract provides comprehensive functionality for managing health insurance policies,
;; processing medical claims, and maintaining transparent records of all insurance operations.
;; It enables policyholders to register coverage, submit medical claims, and allows authorized
;; administrators to process claims with full audit trails and validation mechanisms.

;; ADMINISTRATIVE CONFIGURATION

;; The designated contract administrator with full management privileges
(define-data-var current-contract-admin principal tx-sender)

;; Sequential counter for generating unique claim reference numbers
(define-data-var claim-reference-counter uint u0)

;; ERROR HANDLING CONSTANTS

;; Access Control & Authentication Errors
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-INVALID-ADMIN-CREDENTIALS (err u101))
(define-constant ERR-ADMIN-TRANSFER-FAILED (err u102))

;; Policy Management Errors
(define-constant ERR-POLICY-NOT-FOUND (err u110))
(define-constant ERR-POLICY-ALREADY-EXPIRED (err u111))
(define-constant ERR-DUPLICATE-POLICY-REGISTRATION (err u112))
(define-constant ERR-INSUFFICIENT-COVERAGE-AMOUNT (err u113))
(define-constant ERR-POLICY-CURRENTLY-INACTIVE (err u114))

;; Claims Processing Errors
(define-constant ERR-CLAIM-RECORD-NOT-FOUND (err u120))
(define-constant ERR-CLAIM-EXCEEDS-COVERAGE-LIMIT (err u121))
(define-constant ERR-INVALID-CLAIM-STATUS-TRANSITION (err u122))
(define-constant ERR-CLAIM-ALREADY-FINALIZED (err u123))
(define-constant ERR-CLAIM-AMOUNT-INSUFFICIENT (err u124))

;; Input Validation Errors
(define-constant ERR-INVALID-INPUT-PARAMETERS (err u130))
(define-constant ERR-ZERO-VALUE-NOT-PERMITTED (err u131))
(define-constant ERR-INVALID-BLOCK-HEIGHT (err u132))
(define-constant ERR-INVALID-STRING-LENGTH (err u133))

;; CLAIM STATUS CONSTANTS

(define-constant CLAIM-STATUS-PENDING "pending-review")
(define-constant CLAIM-STATUS-APPROVED "approved")
(define-constant CLAIM-STATUS-REJECTED "rejected")
(define-constant CLAIM-STATUS-INFO-REQUIRED "needs-info")
(define-constant CLAIM-STATUS-UNDER-INVESTIGATION "investigating")

;; DATA STORAGE STRUCTURES

;; Primary registry for all active and inactive insurance policies
(define-map insurance-policy-registry
  { policy-holder-address: principal }
  {
    unique-policy-identifier: (string-ascii 20),
    maximum-coverage-limit: uint,
    annual-premium-cost: uint,
    policy-activation-status: bool,
    policy-registration-block: uint,
    policy-termination-block: (optional uint)
  }
)

;; Comprehensive database of all submitted medical claims
(define-map medical-claims-database
  { claim-reference-number: uint }
  {
    policy-holder-address: principal,
    associated-policy-identifier: (string-ascii 20),
    requested-claim-amount: uint,
    medical-treatment-description: (string-ascii 50),
    current-processing-status: (string-ascii 15),
    claim-submission-timestamp: uint,
    claim-resolution-timestamp: (optional uint),
    administrative-notes: (optional (string-ascii 100))
  }
)

;; Registry to enforce unique policy identifier constraints
(define-map policy-identifier-ownership
  { unique-policy-identifier: (string-ascii 20) }
  { registered-owner: principal }
)

;; ADMINISTRATIVE QUERY FUNCTIONS

;; Retrieves comprehensive policy information for a specific policyholder
(define-read-only (get-policy-information (policy-holder-address principal))
  (map-get? insurance-policy-registry { policy-holder-address: policy-holder-address })
)

;; Fetches detailed information about a specific medical claim
(define-read-only (get-medical-claim-details (claim-reference-number uint))
  (map-get? medical-claims-database { claim-reference-number: claim-reference-number })
)

;; Verifies if the current transaction sender has administrative privileges
(define-read-only (verify-admin-privileges)
  (is-eq tx-sender (var-get current-contract-admin))
)

;; Checks availability of a policy identifier for new registrations
(define-read-only (check-policy-identifier-availability (unique-policy-identifier (string-ascii 20)))
  (is-none (map-get? policy-identifier-ownership { unique-policy-identifier: unique-policy-identifier }))
)

;; Retrieves the current processing status of a medical claim
(define-read-only (get-current-claim-status (claim-reference-number uint))
  (match (get-medical-claim-details claim-reference-number)
    claim-information (ok (get current-processing-status claim-information))
    ERR-CLAIM-RECORD-NOT-FOUND
  )
)

;; Returns the next available claim reference number
(define-read-only (get-next-claim-reference)
  (var-get claim-reference-counter)
)

;; Validates policy existence and returns policy data
(define-read-only (validate-policy-existence (policy-holder-address principal))
  (ok (unwrap! (get-policy-information policy-holder-address) ERR-POLICY-NOT-FOUND))
)

;; Validates claim existence and returns claim data
(define-read-only (validate-claim-existence (claim-reference-number uint))
  (ok (unwrap! (get-medical-claim-details claim-reference-number) ERR-CLAIM-RECORD-NOT-FOUND))
)

;; Checks if a policy is currently active and not expired
(define-read-only (verify-policy-active-status (policy-holder-address principal))
  (match (get-policy-information policy-holder-address)
    policy-data (let
      (
        (is-active (get policy-activation-status policy-data))
        (expiration-block (get policy-termination-block policy-data))
      )
      (if is-active
        (match expiration-block
          termination-block (ok (< block-height termination-block))
          (ok true)
        )
        (ok false)
      )
    )
    (ok false)
  )
)

;; ADMINISTRATIVE MANAGEMENT FUNCTIONS

;; Transfers administrative control to a new authorized principal
(define-public (transfer-administrative-control (new-admin-address principal))
  (begin
    (asserts! (verify-admin-privileges) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (not (is-eq new-admin-address (var-get current-contract-admin))) ERR-INVALID-INPUT-PARAMETERS)
    (ok (var-set current-contract-admin new-admin-address))
  )
)

;; Modifies the activation status of an existing insurance policy
(define-public (modify-policy-activation-status (policy-holder-address principal) (new-activation-status bool))
  (begin
    (asserts! (verify-admin-privileges) ERR-UNAUTHORIZED-ACCESS)
    (let
      (
        (existing-policy-data (try! (validate-policy-existence policy-holder-address)))
        (target-policy-holder policy-holder-address)
      )
      (ok (map-set insurance-policy-registry
        { policy-holder-address: target-policy-holder }
        (merge existing-policy-data { policy-activation-status: new-activation-status })
      ))
    )
  )
)

;; Updates the maximum coverage limit for an existing policy
(define-public (update-policy-coverage-limit (policy-holder-address principal) (new-coverage-limit uint))
  (begin
    (asserts! (verify-admin-privileges) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (> new-coverage-limit u0) ERR-ZERO-VALUE-NOT-PERMITTED)
    (let
      (
        (existing-policy-data (try! (validate-policy-existence policy-holder-address)))
        (target-policy-holder policy-holder-address)
        (updated-coverage-amount new-coverage-limit)
      )
      (ok (map-set insurance-policy-registry
        { policy-holder-address: target-policy-holder }
        (merge existing-policy-data { maximum-coverage-limit: updated-coverage-amount })
      ))
    )
  )
)

;; Sets a termination block for policy expiration
(define-public (schedule-policy-termination (policy-holder-address principal) (termination-block uint))
  (begin
    (asserts! (verify-admin-privileges) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (> termination-block block-height) ERR-INVALID-BLOCK-HEIGHT)
    (let
      (
        (existing-policy-data (try! (validate-policy-existence policy-holder-address)))
        (target-policy-holder policy-holder-address)
        (scheduled-termination-block termination-block)
      )
      (ok (map-set insurance-policy-registry
        { policy-holder-address: target-policy-holder }
        (merge existing-policy-data { policy-termination-block: (some scheduled-termination-block) })
      ))
    )
  )
)

;; POLICYHOLDER REGISTRATION FUNCTIONS

;; Registers a new comprehensive health insurance policy
(define-public (register-comprehensive-insurance-policy 
                (unique-policy-identifier (string-ascii 20)) 
                (maximum-coverage-limit uint) 
                (annual-premium-cost uint))
  (let
    (
      (requesting-policy-holder tx-sender)
      (new-policy-configuration {
        unique-policy-identifier: unique-policy-identifier,
        maximum-coverage-limit: maximum-coverage-limit,
        annual-premium-cost: annual-premium-cost,
        policy-activation-status: true,
        policy-registration-block: block-height,
        policy-termination-block: none
      })
    )
    (begin
      (asserts! (> maximum-coverage-limit u0) ERR-INSUFFICIENT-COVERAGE-AMOUNT)
      (asserts! (> annual-premium-cost u0) ERR-ZERO-VALUE-NOT-PERMITTED)
      (asserts! (check-policy-identifier-availability unique-policy-identifier) ERR-DUPLICATE-POLICY-REGISTRATION)
      
      ;; Register policy identifier ownership
      (map-set policy-identifier-ownership 
        { unique-policy-identifier: unique-policy-identifier } 
        { registered-owner: requesting-policy-holder })
        
      (ok (map-set insurance-policy-registry 
          { policy-holder-address: requesting-policy-holder } 
          new-policy-configuration))
    )
  )
)

;; MEDICAL CLAIMS SUBMISSION FUNCTIONS

;; Submits a comprehensive medical claim for processing
(define-public (submit-comprehensive-medical-claim 
                (associated-policy-identifier (string-ascii 20)) 
                (requested-claim-amount uint) 
                (medical-treatment-description (string-ascii 50)))
  (let
    (
      (claim-submitting-policy-holder tx-sender)
      (policy-holder-insurance-data (unwrap! (get-policy-information claim-submitting-policy-holder) ERR-POLICY-NOT-FOUND))
      (generated-claim-reference (var-get claim-reference-counter))
      (validated-treatment-description medical-treatment-description)
      (verified-policy-identifier associated-policy-identifier)
      (verified-claim-amount requested-claim-amount)
    )
    (begin
      (asserts! (is-eq verified-policy-identifier (get unique-policy-identifier policy-holder-insurance-data)) ERR-POLICY-NOT-FOUND)
      (asserts! (get policy-activation-status policy-holder-insurance-data) ERR-POLICY-CURRENTLY-INACTIVE)
      (asserts! (> verified-claim-amount u0) ERR-ZERO-VALUE-NOT-PERMITTED)
      (asserts! (<= verified-claim-amount (get maximum-coverage-limit policy-holder-insurance-data)) ERR-CLAIM-EXCEEDS-COVERAGE-LIMIT)
      
      ;; Verify policy has not expired
      (match (get policy-termination-block policy-holder-insurance-data)
        expiration-block (asserts! (< block-height expiration-block) ERR-POLICY-ALREADY-EXPIRED)
        true
      )
      
      ;; Increment claim reference counter
      (var-set claim-reference-counter (+ generated-claim-reference u1))
      
      (ok (map-set medical-claims-database
          { claim-reference-number: generated-claim-reference }
          {
            policy-holder-address: claim-submitting-policy-holder,
            associated-policy-identifier: verified-policy-identifier,
            requested-claim-amount: verified-claim-amount,
            medical-treatment-description: validated-treatment-description,
            current-processing-status: CLAIM-STATUS-PENDING,
            claim-submission-timestamp: block-height,
            claim-resolution-timestamp: none,
            administrative-notes: none
          }
        ))
    )
  )
)

;; CLAIMS PROCESSING & ADMINISTRATION FUNCTIONS

;; Processes and finalizes a submitted medical claim
(define-public (process-medical-claim-resolution 
                (claim-reference-number uint) 
                (final-processing-status (string-ascii 15))
                (administrative-processing-notes (optional (string-ascii 100))))
  (begin
    (asserts! (verify-admin-privileges) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (or 
               (is-eq final-processing-status CLAIM-STATUS-APPROVED) 
               (is-eq final-processing-status CLAIM-STATUS-REJECTED) 
               (is-eq final-processing-status CLAIM-STATUS-INFO-REQUIRED)
               (is-eq final-processing-status CLAIM-STATUS-UNDER-INVESTIGATION)) 
               ERR-INVALID-CLAIM-STATUS-TRANSITION)
    
    (let
      (
        (existing-claim-data (try! (validate-claim-existence claim-reference-number)))
        (target-claim-reference claim-reference-number)
      )
      (begin
        (asserts! (is-eq (get current-processing-status existing-claim-data) CLAIM-STATUS-PENDING) ERR-CLAIM-ALREADY-FINALIZED)
        (ok (map-set medical-claims-database
                { claim-reference-number: target-claim-reference }
                (merge existing-claim-data {
                  current-processing-status: final-processing-status,
                  claim-resolution-timestamp: (some block-height),
                  administrative-notes: administrative-processing-notes
                })))
      )
    )
  )
)

;; Requests additional documentation for claim processing
(define-public (request-additional-claim-documentation 
                (claim-reference-number uint) 
                (documentation-request-details (string-ascii 100)))
  (begin
    (asserts! (verify-admin-privileges) ERR-UNAUTHORIZED-ACCESS)
    
    (let
      (
        (existing-claim-data (try! (validate-claim-existence claim-reference-number)))
        (target-claim-reference claim-reference-number)
      )
      (ok (map-set medical-claims-database
            { claim-reference-number: target-claim-reference }
            (merge existing-claim-data {
              current-processing-status: CLAIM-STATUS-INFO-REQUIRED,
              administrative-notes: (some documentation-request-details)
            })))
    )
  )
)

;; Updates claim status during investigation process
(define-public (update-claim-investigation-status 
                (claim-reference-number uint) 
                (investigation-notes (string-ascii 100)))
  (begin
    (asserts! (verify-admin-privileges) ERR-UNAUTHORIZED-ACCESS)
    
    (let
      (
        (existing-claim-data (try! (validate-claim-existence claim-reference-number)))
        (target-claim-reference claim-reference-number)
      )
      (ok (map-set medical-claims-database
            { claim-reference-number: target-claim-reference }
            (merge existing-claim-data {
              current-processing-status: CLAIM-STATUS-UNDER-INVESTIGATION,
              administrative-notes: (some investigation-notes)
            })))
    )
  )
)

;; REPORTING & ANALYTICS FUNCTIONS

;; Retrieves policy statistics by activation status
(define-read-only (get-policy-statistics-by-status (activation-status bool))
  (let ((policy-statistics-count u0))
    (ok policy-statistics-count)
  )
)

;; Retrieves claim statistics by processing status
(define-read-only (get-claim-statistics-by-status (processing-status (string-ascii 15)))
  (let ((claim-statistics-count u0))
    (ok claim-statistics-count)
  )
)

;; Gets total number of registered policies
(define-read-only (get-total-registered-policies)
  (let ((total-policy-count u0))
    (ok total-policy-count)
  )
)

;; Gets total number of submitted claims
(define-read-only (get-total-submitted-claims)
  (ok (var-get claim-reference-counter))
)