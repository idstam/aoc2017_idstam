(use utils)
(use srfi-1)
(use srfi-13)
(use srfi-69)

(define (println s)
	(display s)
	(display "\n")
)

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
	(= -1 (string-compare3 s1 s2))
)

(define (tokens->minute tokens)
	(define token (string-translate (string-translate (second tokens) "]") ":" " "))
	(cdr (string-tokenize token))
)
(define (make-guards-table tokensList guardsTable)
	(if (null-list? tokensList)
		guardsTable
		(begin 
			;Create new guard item if needed
			(if (= (string-compare3 (third (car tokensList)) "Guard") 0)
				(if (not (hash-table-exists? guardsTable (fourth (car tokensList) )))
					(begin
						(hash-table-set! guardsTable (fourth (car tokensList)) (make-hash-table) )
					)
				)					
			)
			(make-guards-table (cdr tokensList) guardsTable)
		)
	)
)
(define (scan-data tokensList guardsTable lastGuard lastMin)
	(if (null-list? tokensList)
		guardsTable
		(begin
			(if (= (string-compare3 (third (car tokensList)) "Guard") 0)
				(scan-data (cdr tokensList) guardsTable (fourth (car tokensList)) 0)	
			)
			(if (= (string-compare3 (third (car tokensList)) "falls") 0)
				(scan-data (cdr tokensList) guardsTable lastGuard (tokens->minute (car tokensList)))	
			)
			(if (= (string-compare3 (third (car tokensList)) "wakes") 0)
				(begin
					(define sleepRecord (list lastGuard lastMin (- (tokens->minute (car tokensList)) 1) ))
					(println sleepRecord)
					(scan-data (cdr tokensList) guardsTable lastGuard 0 )	
				)
			)
		)
	)
)

(define (main args)

	(define lines (sort (read-lines "d4data.txt") string-less)  )
	(define tokens (lines->tokens lines (list)))
	(define guardsTable (make-guards-table tokens (make-hash-table)))
	(display (scan-data tokens guardsTable "-" 0 ))
	;(display (hash-table-keys guardsTable))
	;(println (tokens->minute (car tokens)))
	

)