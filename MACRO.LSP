
(defun обращение (l)
  (if (atom l) l
    (do (
		(результат ()
		    (cons (обращение 
			(car остатки))
			результат))
		(остатки l (cdr остатки))
 	)
	((null остатки) результат)  )))
	
(pprint (macroexpand
  '(do  (
		(результат ()
		    (cons (обращение 
			(car остатки))
			результат))
		(остатки l (cdr остатки))
	)
	((null остатки) результат)) ))

(обращение '(a b (c d) e (((f g h))) k))

(defun expt1 (x n)
    (do ((результат x (* результат x)) (разы n (- разы 1)))
	 ((= разы 1) результат)))
(expt1 2 5)

(pprint (macroexpand
   '(do* ((x 0 (+ x 1))  (y x (+ x 2)))
	((atom z) (print 1000))
	(print 'body!)	)))

(pprint (macroexpand
   '(let* ((x 'k) (y) (z (cons x y)))
	(print x)
	(pprint z) )))

(let* ((x 'k) (y) (z (cons x y)))
	(print x)
	(pprint z) )