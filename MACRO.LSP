
(defun ���饭�� (l)
  (if (atom l) l
    (do (
		(१���� ()
		    (cons (���饭�� 
			(car ���⪨))
			१����))
		(���⪨ l (cdr ���⪨))
 	)
	((null ���⪨) १����)  )))
	
(pprint (macroexpand
  '(do  (
		(१���� ()
		    (cons (���饭�� 
			(car ���⪨))
			१����))
		(���⪨ l (cdr ���⪨))
	)
	((null ���⪨) १����)) ))

(���饭�� '(a b (c d) e (((f g h))) k))

(defun expt1 (x n)
    (do ((१���� x (* १���� x)) (ࠧ� n (- ࠧ� 1)))
	 ((= ࠧ� 1) १����)))
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