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

;; (define-public (extend-rental (renter principal) (extra-duration uint))
;;   (match (map-get? rental-storage { renter: renter })
;;     entry (let ((new-expiration (+ (get expiration entry) extra-duration))
;;                 (cost (* (get space-allocated entry) PRICE-PER-UNIT)))
;;             (begin
;;               (try! (stx-transfer? cost renter tx-sender))
;;               (map-insert rental-storage { renter: renter }
;;                 { space-allocated: (get space-allocated entry), expiration: new-expiration, auto-renew: (get auto-renew entry), org-id: (get org-id entry) })
;;               (ok "Rental extended successfully"))))
;;     (err "No active rental found"))

;; (define-public (toggle-auto-renew (renter principal))
;;   (match (map-get? rental-storage { renter: renter })
;;     entry (begin
;;             (map-insert rental-storage { renter: renter }
;;               { space-allocated: (get space-allocated entry), expiration: (get expiration entry), auto-renew: (not (get auto-renew entry)), org-id: (get org-id entry) })
;;             (log-action "Toggle Auto-Renew" renter)
;;             (ok "Auto-renew status updated")))
;;     (err "No active rental found"))

(define-public (create-org (org-id uint) (owner principal) (settings (buff 256)) (payment-info (optional (buff 256))) (social-links (optional (buff 256))) (crm-config (optional (buff 256))) (additional-services (optional (buff 256))))
  (begin
    (map-insert org-settings { org-id: org-id } { owner: owner, settings: settings, payment-info: payment-info, social-links: social-links, crm-config: crm-config, additional-services: additional-services })
    (ok "Organization created successfully")))

;; (define-public (update-org-settings (org-id uint) (owner principal) (new-settings (buff 256)) (new-payment-info (optional (buff 256))) (new-social-links (optional (buff 256))) (new-crm-config (optional (buff 256))) (new-additional-services (optional (buff 256))))
;;   (match (map-get? org-settings { org-id: org-id })
;;     entry (if (is-eq (get owner entry) owner)
;;               (begin
;;                 (map-insert org-settings { org-id: org-id } { owner: owner, settings: new-settings, payment-info: new-payment-info, social-links: new-social-links, crm-config: new-crm-config, additional-services: new-additional-services })
;;                 (log-action "Update Organization Settings" owner)
;;                 (ok "Organization settings updated successfully"))
;;               (err "Unauthorized")))
;;     (err "Organization not found"))

(define-public (assign-role (user principal) (role (buff 32)))
  (begin
    (map-insert user-roles { user: user } { role: role })
    ;; (log-action "Assign Role" user)
    (ok "Role assigned successfully")))




(define-read-only (get-user-role (user principal))
  (map-get? user-roles { user: user }))

(define-read-only (get-audit-log (entry-id uint))
  (map-get? audit-log { entry-id: entry-id }))
