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