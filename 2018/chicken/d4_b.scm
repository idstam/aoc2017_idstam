(use utils)
(use srfi-1)
(use srfi-13)
(use srfi-69)
(use vector-lib)

(define (cleanTokens line)
	(string-tokenize line)
)

(define (lines->tokens lines acc)
	(if (null-list? lines)
		acc
		(lines->tokens (cdr lines) (append acc (list(cleanTokens (car lines)))))
		)
)
(define (number-between num start end)
	(if (>= num start)
		(if (<= num end)
			#t
		)
		#f
	)
)
(define (string-less s1 s2)
    (print (list "string-less" s1 s2 (= -1 (string-compare3 s1 s2))))
	(<  (string-compare3 s1 s2) 0)
)

(define (tokens->minute tokens)
	(define token (string-translate (string-translate (second tokens) "]") ":" " "))
	
	(define ret (string->number (string-trim (second (string-tokenize token)) #\0) ))
	(if (not ret)
		0
		ret
	)
)
(define (make-guards-table tokensList guardsTable)
	(if (null-list? tokensList)
		guardsTable
		(begin 
			;Create new guard item if needed
			(if (= (string-compare3 (third (car tokensList)) "Guard") 0)
				(if (not (hash-table-exists? guardsTable (fourth (car tokensList) )))
					(begin
						(hash-table-set! guardsTable (fourth (car tokensList)) 0 )
					)
				)					
			)
			(make-guards-table (cdr tokensList) guardsTable)
		)
	)
)


(define (make-guards-table-b tokensList guardsTableB)
	(if (null-list? tokensList)
		guardsTableB
		(begin 
			(define empty-time-vector (vector 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ))

			;Create new guard item if needed
			(if (= (string-compare3 (third (car tokensList)) "Guard") 0)
				(if (not (hash-table-exists? guardsTableB (fourth (car tokensList) )))
					(begin
						(hash-table-set! guardsTableB (fourth (car tokensList)) empty-time-vector )
					)
				)					
			)
			(make-guards-table-b (cdr tokensList)  guardsTableB)
		)
	)
)

(define (tokens->sleepRecords tokensList sleepRecords lastGuard lastMin)
	(if (null-list? tokensList)
		(begin 			
			sleepRecords
		)
		(begin
			(if (= (string-compare3 (third (car tokensList)) "Guard") 0)
				(tokens->sleepRecords (cdr tokensList) sleepRecords (fourth (car tokensList)) 0)	
			
				(if (= (string-compare3 (third (car tokensList)) "falls") 0)
					(tokens->sleepRecords (cdr tokensList) sleepRecords lastGuard (tokens->minute (car tokensList)))					
					(if (= (string-compare3 (third (car tokensList)) "wakes") 0)
						(begin
							(define sleepRecord (list lastGuard lastMin (tokens->minute (car tokensList)) (- (tokens->minute (car tokensList)) lastMin) ))					
							(tokens->sleepRecords (cdr tokensList) (append sleepRecords (list sleepRecord)) lastGuard 0 )	
						)
					)
				)
			)
		)
	)
)

(define (guard-sleep-times sleepRecords guardsTable)
	(if (null-list? sleepRecords)
		guardsTable
		(begin
			(define guard (first (car sleepRecords)))
			(define sleepTime (hash-table-ref/default guardsTable guard 0))
			(define newSleepTime (+ sleepTime (fourth (car sleepRecords))))
			(hash-table-set! guardsTable guard newSleepTime)
			(guard-sleep-times (cdr sleepRecords) guardsTable)	
		)
	)
)
(define (max-sleep-time sleepTimes keys maxGuard max)
	(if (null-list? keys)
		(list maxGuard max)
		(begin
			(define sleepTime (hash-table-ref/default sleepTimes (car keys) 0))
			(if (> sleepTime max)
				(max-sleep-time sleepTimes (cdr keys) (car keys) sleepTime)
				(max-sleep-time sleepTimes (cdr keys) maxGuard max)
			)
		)
	)
)

(define (fill-time-vector timeVector start end)
	(if (= start end)
		timeVector
		(begin
			(define tmp (vector-ref timeVector start))			
			(vector-set! timeVector start (+ 1 tmp))
			(fill-time-vector timeVector (+ 1 start) end)
		)
	)
)
(define (set-guard-minutes guard sleepMinutes sleepRecords)
	(if (null-list? sleepRecords)
		sleepMinutes
		(begin 
			(if (= 0(string-compare3 (first (car sleepRecords)) guard ))
				(fill-time-vector sleepMinutes (second (car sleepRecords)) (third (car sleepRecords)))
			)
			(set-guard-minutes guard sleepMinutes (cdr sleepRecords))
		)
	)
)
(define (most-minute-count guardMinutes)
	(vector-fold (lambda (index len x) 
					(max x len)
				 )
			 0 guardMinutes)
	
)
(define (most-minute guardMinutes i count)
	(if (= i (vector-length guardMinutes))
		#f
		(if (= count (vector-ref guardMinutes i))
			i
			(most-minute guardMinutes (+ 1 i) count)
		)
	)
)

(define (max-most-minute-count guardsTableB keys max maxGuard)
	(if (null-list? keys)
		(list maxGuard max)
		(begin
			(define mmc (most-minute-count (hash-table-ref guardsTableB (car keys) )))
			(if (> mmc max)
				(max-most-minute-count guardsTableB (cdr keys) mmc (car keys))
				(max-most-minute-count guardsTableB (cdr keys) max maxGuard)
			)
		)
	)
)


(define (guard-sleep-times-b sleepRecords guardsTableB)
	(if (null-list? sleepRecords)
		guardsTableB
		(begin		
			(define guard (car (car sleepRecords)))
			(define sleepTime (hash-table-ref guardsTableB guard))
			(define newSleepTime (fill-time-vector sleepTime (second (car sleepRecords)) (third (car sleepRecords))))
			(hash-table-set! guardsTableB guard newSleepTime)
			(guard-sleep-times-b (cdr sleepRecords) guardsTableB)	
		)
	)
)
(define (set-all-guard-minutes guardsTableB guardKeys sleepRecords)
	(if (null-list? guardKeys)
		guardsTableB
		(begin
			(define guard (car guardKeys))
			(define guardVectorIn (hash-table-ref guardsTableB guard))
			(define guardVectorOut (set-guard-minutes guard guardVectorIn sleepRecords))
			(hash-table-set! guardsTableB guard guardVectorOut)
			(set-all-guard-minutes guardsTableB (cdr guardKeys) sleepRecords)
		)
	)
)

(define (main args)

	(define lines (sort (read-lines "d4data.txt") string-less)  )
	(define tokens (lines->tokens lines (list)))
	(define guardsTable (make-guards-table tokens (make-hash-table)))
	(define sleepRecords (tokens->sleepRecords tokens (list) "-" 0 ))
	(define sleepTimes (guard-sleep-times sleepRecords guardsTable))
	(define sleeper (max-sleep-time sleepTimes (hash-table-keys sleepTimes) "-" 0))
	(define empty-time-vector (vector 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ))
	(define guardMinutes (set-guard-minutes (car sleeper) empty-time-vector sleepRecords))
	
	(print (list "Sleeper:" sleeper))

	(define guardsTableB (make-guards-table-b tokens (make-hash-table)))
	(define sleepTimesB (guard-sleep-times-b sleepRecords guardsTableB))
	(define allGuardMinutes (set-all-guard-minutes guardsTableB (hash-table-keys guardsTableB) sleepRecords))
	
	(define mmc (max-most-minute-count guardsTableB (hash-table-keys guardsTableB) 0 "-"))
	(define minute (most-minute (hash-table-ref guardsTableB (first mmc)) 0 (second mmc)))
	(print mmc)
	(print minute)
	; (print
	;  	(vector-for-each (lambda (i x) (display (list i x)) (newline))
	; 	 (hash-table-ref guardsTableB "#99"))
	;  )



	;(display (hash-table-keys guardsTable))
	;(println (tokens->minute (car tokens)))
	; 1901 * 16 

)