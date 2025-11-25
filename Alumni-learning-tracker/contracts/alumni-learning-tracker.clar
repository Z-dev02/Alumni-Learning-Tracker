;; Alumni Learning Tracker - Token-incentivized lifelong learning platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-amount (err u104))
(define-constant err-course-inactive (err u105))
(define-constant err-insufficient-points (err u106))
(define-constant err-invalid-rating (err u107))

;; Data Variables
(define-data-var total-courses uint u0)
(define-data-var total-completions uint u0)
(define-data-var platform-fee uint u5) ;; 5% platform fee
(define-data-var total-rewards-distributed uint u0)

;; Data Maps
(define-map courses
    { course-id: uint }
    {
        title: (string-ascii 100),
        reward-amount: uint,
        active: bool,
        difficulty-level: uint,
        category: (string-ascii 50)
    }
)

(define-map alumni-profiles
    { alumni: principal }
    {
        total-points: uint,
        courses-completed: uint,
        registered: bool,
        reputation-score: uint,
        achievements: uint
    }
)

(define-map course-completions
    { alumni: principal, course-id: uint }
    { completed: bool, completion-time: uint }
)

(define-map course-ratings
    { course-id: uint }
    { total-ratings: uint, rating-sum: uint, average-rating: uint }
)

(define-map alumni-badges
    { alumni: principal, badge-id: uint }
    { earned: bool, earned-at: uint }
)

(define-map learning-streaks
    { alumni: principal }
    { current-streak: uint, longest-streak: uint, last-activity: uint }
)

;; Read-only functions
;; #[allow(unchecked_data)]
(define-read-only (get-course (course-id uint))
    (map-get? courses { course-id: course-id })
)

;; #[allow(unchecked_data)]
(define-read-only (get-alumni-profile (alumni principal))
    (map-get? alumni-profiles { alumni: alumni })
)

(define-read-only (get-total-courses)
    (ok (var-get total-courses))
)

(define-read-only (get-total-completions)
    (ok (var-get total-completions))
)

(define-read-only (get-total-rewards-distributed)
    (ok (var-get total-rewards-distributed))
)

;; #[allow(unchecked_data)]
(define-read-only (has-completed-course (alumni principal) (course-id uint))
    (default-to false (get completed (map-get? course-completions { alumni: alumni, course-id: course-id })))
)

;; #[allow(unchecked_data)]
(define-read-only (get-course-rating (course-id uint))
    (map-get? course-ratings { course-id: course-id })
)

;; #[allow(unchecked_data)]
(define-read-only (get-learning-streak (alumni principal))
    (map-get? learning-streaks { alumni: alumni })
)

;; #[allow(unchecked_data)]
(define-read-only (get-completion-info (alumni principal) (course-id uint))
    (map-get? course-completions { alumni: alumni, course-id: course-id })
)

;; #[allow(unchecked_data)]
(define-read-only (has-badge (alumni principal) (badge-id uint))
    (default-to false (get earned (map-get? alumni-badges { alumni: alumni, badge-id: badge-id })))
)

(define-read-only (get-platform-fee)
    (ok (var-get platform-fee))
)

;; #[allow(unchecked_data)]
(define-read-only (calculate-course-fee (reward-amount uint))
    (ok (/ (* reward-amount (var-get platform-fee)) u100))
)

;; Public functions
;; #[allow(unchecked_data)]
(define-public (register-alumni)
    (let ((existing-profile (map-get? alumni-profiles { alumni: tx-sender })))
        (if (is-some existing-profile)
            err-already-exists
            (begin
                (map-set alumni-profiles
                    { alumni: tx-sender }
                    { total-points: u0, courses-completed: u0, registered: true, reputation-score: u100, achievements: u0 }
                )
                (map-set learning-streaks
                    { alumni: tx-sender }
                    { current-streak: u0, longest-streak: u0, last-activity: u0 }
                )
                (ok true)
            )
        )
    )
)

;; #[allow(unchecked_data)]
(define-public (create-course (title (string-ascii 100)) (reward-amount uint) (difficulty-level uint) (category (string-ascii 50)))
    (let ((new-course-id (+ (var-get total-courses) u1)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (> reward-amount u0) err-invalid-amount)
        (map-set courses
            { course-id: new-course-id }
            { 
                title: title, 
                reward-amount: reward-amount, 
                active: true,
                difficulty-level: difficulty-level,
                category: category
            }
        )
        (map-set course-ratings
            { course-id: new-course-id }
            { total-ratings: u0, rating-sum: u0, average-rating: u0 }
        )
        (var-set total-courses new-course-id)
        (ok new-course-id)
    )
)

;; #[allow(unchecked_data)]
(define-public (deactivate-course (course-id uint))
    (let ((course (unwrap! (map-get? courses { course-id: course-id }) err-not-found)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set courses
            { course-id: course-id }
            (merge course { active: false })
        )
        (ok true)
    )
)

;; #[allow(unchecked_data)]
(define-public (reactivate-course (course-id uint))
    (let ((course (unwrap! (map-get? courses { course-id: course-id }) err-not-found)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set courses
            { course-id: course-id }
            (merge course { active: true })
        )
        (ok true)
    )
)

;; #[allow(unchecked_data)]
(define-public (update-course-reward (course-id uint) (new-reward uint))
    (let ((course (unwrap! (map-get? courses { course-id: course-id }) err-not-found)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (> new-reward u0) err-invalid-amount)
        (map-set courses
            { course-id: course-id }
            (merge course { reward-amount: new-reward })
        )
        (ok true)
    )
)

;; #[allow(unchecked_data)]
(define-public (complete-course (course-id uint))
    (let (
        (course (unwrap! (map-get? courses { course-id: course-id }) err-not-found))
        (alumni-profile (unwrap! (map-get? alumni-profiles { alumni: tx-sender }) err-unauthorized))
        (already-completed (has-completed-course tx-sender course-id))
        (current-height stacks-block-height)
    )
        (asserts! (not already-completed) err-already-exists)
        (asserts! (get active course) err-course-inactive)
        (map-set course-completions
            { alumni: tx-sender, course-id: course-id }
            { completed: true, completion-time: current-height }
        )
        (map-set alumni-profiles
            { alumni: tx-sender }
            {
                total-points: (+ (get total-points alumni-profile) (get reward-amount course)),
                courses-completed: (+ (get courses-completed alumni-profile) u1),
                registered: true,
                reputation-score: (+ (get reputation-score alumni-profile) u10),
                achievements: (get achievements alumni-profile)
            }
        )
        (var-set total-completions (+ (var-get total-completions) u1))
        (var-set total-rewards-distributed (+ (var-get total-rewards-distributed) (get reward-amount course)))
        (update-learning-streak tx-sender current-height)
        (ok (get reward-amount course))
    )
)

;; #[allow(unchecked_data)]
(define-public (rate-course (course-id uint) (rating uint))
    (let (
        (course (unwrap! (map-get? courses { course-id: course-id }) err-not-found))
        (rating-data (unwrap! (map-get? course-ratings { course-id: course-id }) err-not-found))
        (has-completed (has-completed-course tx-sender course-id))
        (new-total (+ (get total-ratings rating-data) u1))
        (new-sum (+ (get rating-sum rating-data) rating))
    )
        (asserts! has-completed err-unauthorized)
        (asserts! (<= rating u5) err-invalid-rating)
        (asserts! (> rating u0) err-invalid-rating)
        (map-set course-ratings
            { course-id: course-id }
            {
                total-ratings: new-total,
                rating-sum: new-sum,
                average-rating: (/ new-sum new-total)
            }
        )
        (ok true)
    )
)

;; Private functions
;; #[allow(unchecked_data)]
(define-private (update-learning-streak (alumni principal) (current-height uint))
    (let (
        (streak-data (default-to 
            { current-streak: u0, longest-streak: u0, last-activity: u0 }
            (map-get? learning-streaks { alumni: alumni })
        ))
        (last-activity (get last-activity streak-data))
        (current-streak (get current-streak streak-data))
        (longest-streak (get longest-streak streak-data))
        (new-streak (if (and (> last-activity u0) (<= (- current-height last-activity) u144))
            (+ current-streak u1)
            u1
        ))
    )
        (map-set learning-streaks
            { alumni: alumni }
            {
                current-streak: new-streak,
                longest-streak: (if (> new-streak longest-streak) new-streak longest-streak),
                last-activity: current-height
            }
        )
    )
)

;; #[allow(unchecked_data)]
(define-public (award-badge (alumni principal) (badge-id uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-some (map-get? alumni-profiles { alumni: alumni })) err-not-found)
        (map-set alumni-badges
            { alumni: alumni, badge-id: badge-id }
            { earned: true, earned-at: stacks-block-height }
        )
        (ok true)
    )
)

;; #[allow(unchecked_data)]
(define-public (update-platform-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (<= new-fee u20) err-invalid-amount) ;; Max 20% fee
        (var-set platform-fee new-fee)
        (ok true)
    )
)

;; #[allow(unchecked_data)]
(define-public (boost-reputation (alumni principal) (boost-amount uint))
    (let ((profile (unwrap! (map-get? alumni-profiles { alumni: alumni }) err-not-found)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set alumni-profiles
            { alumni: alumni }
            (merge profile { reputation-score: (+ (get reputation-score profile) boost-amount) })
        )
        (ok true)
    )
)

;; #[allow(unchecked_data)]
(define-public (increment-achievements (alumni principal))
    (let ((profile (unwrap! (map-get? alumni-profiles { alumni: alumni }) err-not-found)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set alumni-profiles
            { alumni: alumni }
            (merge profile { achievements: (+ (get achievements profile) u1) })
        )
        (ok true)
    )
)