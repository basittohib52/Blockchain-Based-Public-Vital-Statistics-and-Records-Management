;; Genealogy Research Assistance Contract
;; Helps individuals access historical vital records for family research

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-RECORD-NOT-FOUND (err u501))
(define-constant ERR-INVALID-INPUT (err u502))
(define-constant ERR-ACCESS-DENIED (err u503))
(define-constant ERR-RESEARCH-LIMIT (err u504))
(define-constant ERR-INVALID-RELATIONSHIP (err u505))

;; Data Variables
(define-data-var next-research-id uint u1)
(define-data-var research-fee uint u1000000) ;; 1 STX in microSTX

;; Data Maps
(define-map research-requests
  { research-id: uint }
  {
    researcher: principal,
    subject-name: (string-ascii 100),
    subject-birth-date: (optional uint),
    subject-death-date: (optional uint),
    research-type: (string-ascii 50),
    relationship-to-subject: (string-ascii 100),
    purpose: (string-ascii 500),
    requested-records: (list 10 (string-ascii 50)),
    status: (string-ascii 20),
    submitted-date: uint,
    completed-date: (optional uint),
    fee-paid: uint,
    results-available: bool
  }
)

(define-map research-results
  { research-id: uint }
  {
    found-records: (list 20 uint),
    record-types: (list 20 (string-ascii 20)),
    summary: (string-ascii 1000),
    researcher-notes: (string-ascii 1000),
    confidence-level: uint,
    additional-leads: (string-ascii 500)
  }
)

(define-map authorized-researchers principal bool)
(define-map research-permissions
  { researcher: principal, subject-name: (string-ascii 100) }
  { permission-level: uint, granted-by: principal, expires: uint }
)

(define-map family-trees
  { tree-id: uint }
  {
    owner: principal,
    tree-name: (string-ascii 100),
    root-person: (string-ascii 100),
    members: (list 100 (string-ascii 100)),
    research-requests: (list 50 uint),
    is-public: bool,
    created-date: uint,
    last-updated: uint
  }
)

(define-map historical-records-index
  { record-type: (string-ascii 20), time-period: uint }
  { available-records: (list 1000 uint), last-indexed: uint }
)

(define-map access-log
  { research-id: uint, accessor: principal, timestamp: uint }
  { access-type: (string-ascii 50), authorized: bool }
)

(define-data-var next-tree-id uint u1)

;; Authorization Functions
(define-public (add-authorized-researcher (researcher principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-set authorized-researchers researcher true))
  )
)

(define-public (remove-authorized-researcher (researcher principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-delete authorized-researchers researcher))
  )
)

(define-read-only (is-authorized-researcher (researcher principal))
  (default-to false (map-get? authorized-researchers researcher))
)

(define-public (set-research-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (var-set research-fee new-fee))
  )
)

;; Research Request Functions
(define-public (submit-research-request
  (subject-name (string-ascii 100))
  (subject-birth-date (optional uint))
  (subject-death-date (optional uint))
  (research-type (string-ascii 50))
  (relationship-to-subject (string-ascii 100))
  (purpose (string-ascii 500))
  (requested-records (list 10 (string-ascii 50)))
)
  (let
    (
      (research-id (var-get next-research-id))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (fee (var-get research-fee))
    )
    (asserts! (> (len subject-name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len research-type) u0) ERR-INVALID-INPUT)
    (asserts! (> (len relationship-to-subject) u0) ERR-INVALID-INPUT)
    (asserts! (> (len purpose) u0) ERR-INVALID-INPUT)
    (asserts! (> (len requested-records) u0) ERR-INVALID-INPUT)

    ;; Validate relationship
    (asserts! (or
      (is-eq relationship-to-subject "SELF")
      (is-eq relationship-to-subject "CHILD")
      (is-eq relationship-to-subject "PARENT")
      (is-eq relationship-to-subject "SIBLING")
      (is-eq relationship-to-subject "GRANDCHILD")
      (is-eq relationship-to-subject "GRANDPARENT")
      (is-eq relationship-to-subject "DESCENDANT")
      (is-eq relationship-to-subject "RESEARCHER")
    ) ERR-INVALID-RELATIONSHIP)

    ;; Create research request
    (map-set research-requests
      { research-id: research-id }
      {
        researcher: tx-sender,
        subject-name: subject-name,
        subject-birth-date: subject-birth-date,
        subject-death-date: subject-death-date,
        research-type: research-type,
        relationship-to-subject: relationship-to-subject,
        purpose: purpose,
        requested-records: requested-records,
        status: "SUBMITTED",
        submitted-date: current-time,
        completed-date: none,
        fee-paid: u0,
        results-available: false
      }
    )

    ;; Increment research ID
    (var-set next-research-id (+ research-id u1))

    ;; Log the submission
    (map-set access-log
      { research-id: research-id, accessor: tx-sender, timestamp: current-time }
      { access-type: "SUBMISSION", authorized: true }
    )

    (ok research-id)
  )
)

;; Payment Processing
(define-public (pay-research-fee (research-id uint))
  (let
    (
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (request (map-get? research-requests { research-id: research-id }))
      (fee (var-get research-fee))
    )
    (asserts! (is-some request) ERR-RECORD-NOT-FOUND)

    (let
      (
        (request-data (unwrap-panic request))
      )
      (asserts! (is-eq tx-sender (get researcher request-data)) ERR-NOT-AUTHORIZED)
      (asserts! (is-eq (get status request-data) "SUBMITTED") ERR-INVALID-INPUT)

      ;; Transfer fee to contract
      (try! (stx-transfer? fee tx-sender (as-contract tx-sender)))

      ;; Update request with payment
      (map-set research-requests
        { research-id: research-id }
        (merge request-data {
          fee-paid: fee,
          status: "PAID"
        })
      )

      ;; Log the payment
      (map-set access-log
        { research-id: research-id, accessor: tx-sender, timestamp: current-time }
        { access-type: "PAYMENT", authorized: true }
      )

      (ok true)
    )
  )
)

;; Research Processing Functions
(define-public (process-research-request
  (research-id uint)
  (found-records (list 20 uint))
  (record-types (list 20 (string-ascii 20)))
  (summary (string-ascii 1000))
  (researcher-notes (string-ascii 1000))
  (confidence-level uint)
  (additional-leads (string-ascii 500))
)
  (let
    (
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (request (map-get? research-requests { research-id: research-id }))
    )
    (asserts! (is-authorized-researcher tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-some request) ERR-RECORD-NOT-FOUND)
    (asserts! (<= confidence-level u100) ERR-INVALID-INPUT)

    (let
      (
        (request-data (unwrap-panic request))
      )
      (asserts! (is-eq (get status request-data) "PAID") ERR-INVALID-INPUT)

      ;; Create research results
      (map-set research-results
        { research-id: research-id }
        {
          found-records: found-records,
          record-types: record-types,
          summary: summary,
          researcher-notes: researcher-notes,
          confidence-level: confidence-level,
          additional-leads: additional-leads
        }
      )

      ;; Update request status
      (map-set research-requests
        { research-id: research-id }
        (merge request-data {
          status: "COMPLETED",
          completed-date: (some current-time),
          results-available: true
        })
      )

      ;; Log the completion
      (map-set access-log
        { research-id: research-id, accessor: tx-sender, timestamp: current-time }
        { access-type: "COMPLETION", authorized: true }
      )

      (ok true)
    )
  )
)

;; Results Access Functions
(define-public (access-research-results (research-id uint))
  (let
    (
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (request (map-get? research-requests { research-id: research-id }))
      (results (map-get? research-results { research-id: research-id }))
    )
    (asserts! (is-some request) ERR-RECORD-NOT-FOUND)
    (asserts! (is-some results) ERR-RECORD-NOT-FOUND)

    (let
      (
        (request-data (unwrap-panic request))
        (is-researcher (is-eq tx-sender (get researcher request-data)))
        (is-authorized (is-authorized-researcher tx-sender))
      )
      ;; Log access attempt
      (map-set access-log
        { research-id: research-id, accessor: tx-sender, timestamp: current-time }
        { access-type: "RESULTS_ACCESS", authorized: (or is-researcher is-authorized) }
      )

      ;; Return results if authorized
      (if (or is-researcher is-authorized)
        (ok {
          request: request,
          results: results
        })
        ERR-ACCESS-DENIED
      )
    )
  )
)

;; Family Tree Functions
(define-public (create-family-tree
  (tree-name (string-ascii 100))
  (root-person (string-ascii 100))
  (is-public bool)
)
  (let
    (
      (tree-id (var-get next-tree-id))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (> (len tree-name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len root-person) u0) ERR-INVALID-INPUT)

    ;; Create family tree
    (map-set family-trees
      { tree-id: tree-id }
      {
        owner: tx-sender,
        tree-name: tree-name,
        root-person: root-person,
        members: (list root-person),
        research-requests: (list),
        is-public: is-public,
        created-date: current-time,
        last-updated: current-time
      }
    )

    ;; Increment tree ID
    (var-set next-tree-id (+ tree-id u1))

    (ok tree-id)
  )
)

(define-public (add-family-member
  (tree-id uint)
  (member-name (string-ascii 100))
)
  (let
    (
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (tree (map-get? family-trees { tree-id: tree-id }))
    )
    (asserts! (is-some tree) ERR-RECORD-NOT-FOUND)
    (asserts! (> (len member-name) u0) ERR-INVALID-INPUT)

    (let
      (
        (tree-data (unwrap-panic tree))
      )
      (asserts! (is-eq tx-sender (get owner tree-data)) ERR-NOT-AUTHORIZED)

      (let
        (
          (current-members (get members tree-data))
          (updated-members (unwrap-panic (as-max-len? (append current-members member-name) u100)))
        )
        ;; Update family tree
        (map-set family-trees
          { tree-id: tree-id }
          (merge tree-data {
            members: updated-members,
            last-updated: current-time
          })
        )

        (ok true)
      )
    )
  )
)

(define-public (link-research-to-tree
  (tree-id uint)
  (research-id uint)
)
  (let
    (
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (tree (map-get? family-trees { tree-id: tree-id }))
      (request (map-get? research-requests { research-id: research-id }))
    )
    (asserts! (is-some tree) ERR-RECORD-NOT-FOUND)
    (asserts! (is-some request) ERR-RECORD-NOT-FOUND)

    (let
      (
        (tree-data (unwrap-panic tree))
        (request-data (unwrap-panic request))
      )
      (asserts! (is-eq tx-sender (get owner tree-data)) ERR-NOT-AUTHORIZED)
      (asserts! (is-eq tx-sender (get researcher request-data)) ERR-NOT-AUTHORIZED)

      (let
        (
          (current-requests (get research-requests tree-data))
          (updated-requests (unwrap-panic (as-max-len? (append current-requests research-id) u50)))
        )
        ;; Update family tree
        (map-set family-trees
          { tree-id: tree-id }
          (merge tree-data {
            research-requests: updated-requests,
            last-updated: current-time
          })
        )

        (ok true)
      )
    )
  )
)

;; Historical Records Indexing
(define-public (index-historical-records
  (record-type (string-ascii 20))
  (time-period uint)
  (available-records (list 1000 uint))
)
  (let
    (
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (is-authorized-researcher tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> (len record-type) u0) ERR-INVALID-INPUT)
    (asserts! (> time-period u0) ERR-INVALID-INPUT)

    ;; Create or update index
    (map-set historical-records-index
      { record-type: record-type, time-period: time-period }
      {
        available-records: available-records,
        last-indexed: current-time
      }
    )

    (ok true)
  )
)

;; Search Functions
(define-read-only (search-historical-records
  (record-type (string-ascii 20))
  (time-period uint)
)
  (map-get? historical-records-index { record-type: record-type, time-period: time-period })
)

(define-read-only (get-family-tree (tree-id uint))
  (map-get? family-trees { tree-id: tree-id })
)

(define-read-only (get-research-request (research-id uint))
  (map-get? research-requests { research-id: research-id })
)

(define-read-only (get-research-results (research-id uint))
  (map-get? research-results { research-id: research-id })
)

;; Permission Management
(define-public (grant-research-permission
  (researcher principal)
  (subject-name (string-ascii 100))
  (permission-level uint)
  (expires uint)
)
  (begin
    (asserts! (is-authorized-researcher tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (<= permission-level u5) ERR-INVALID-INPUT)

    (map-set research-permissions
      { researcher: researcher, subject-name: subject-name }
      {
        permission-level: permission-level,
        granted-by: tx-sender,
        expires: expires
      }
    )

    (ok true)
  )
)

(define-read-only (check-research-permission
  (researcher principal)
  (subject-name (string-ascii 100))
)
  (let
    (
      (permission (map-get? research-permissions { researcher: researcher, subject-name: subject-name }))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (match permission
      perm (and
        (> (get expires perm) current-time)
        (>= (get permission-level perm) u1)
      )
      false
    )
  )
)

;; Statistics Functions
(define-read-only (get-total-research-requests)
  (- (var-get next-research-id) u1)
)

(define-read-only (get-total-family-trees)
  (- (var-get next-tree-id) u1)
)

(define-read-only (get-current-research-fee)
  (var-get research-fee)
)

(define-read-only (get-access-log (research-id uint) (accessor principal) (timestamp uint))
  (map-get? access-log { research-id: research-id, accessor: accessor, timestamp: timestamp })
)

;; Contract Balance Functions
(define-read-only (get-contract-balance)
  (stx-get-balance (as-contract tx-sender))
)

(define-public (withdraw-fees (amount uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (as-contract (stx-transfer? amount tx-sender recipient))
  )
)
