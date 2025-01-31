(define-map rental-storage
  { renter: principal }
  { space-allocated: uint, expiration: uint, auto-renew: bool, org-id: (optional uint) })

(define-map org-settings
  { org-id: uint }
  { owner: principal, settings: (buff 256), payment-info: (optional (buff 256)), social-links: (optional (buff 256)), crm-config: (optional (buff 256)), additional-services: (optional (buff 256)) })

(define-map audit-log
  { entry-id: uint }
  { action: (buff 256), actor: principal, timestamp: uint })

(define-map user-roles
  { user: principal }
  { role: (buff 32) })

(define-constant PRICE-PER-UNIT u100) ;; Price per unit of storage (in microSTX)

;; (define-private (log-action (action (buff 256)) (actor principal))
;;   (map-insert audit-log { entry-id: (stacks-block-height) } { action: action, actor: actor, timestamp: (stacks-block-height) }))

(define-public (rent-space (renter principal) (units uint) (duration uint) (auto-renew bool) (org-id (optional uint)))
  (let ((cost (* units PRICE-PER-UNIT)))
    (begin
      (try! (stx-transfer? cost renter tx-sender))
      (map-insert rental-storage { renter: renter }
        { space-allocated: units, expiration: (+ block-height duration), auto-renew: auto-renew, org-id: org-id })
      (ok "Space rented successfully"))))

(define-read-only (get-rental-details (renter principal))
  (map-get? rental-storage { renter: renter }))

(define-public (release-space (renter principal))
  (begin
    (map-delete rental-storage { renter: renter })
    (ok "Space released successfully")))

(define-read-only (is-rental-active (renter principal))
  (match (map-get? rental-storage { renter: renter })
    entry (>= (get expiration entry) block-height)
    false))
