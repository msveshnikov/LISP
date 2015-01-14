
(equal (quote(a b)) (quote(a   b)))
(member (quote (a s.3))  (quote (3 4 2 1 (a s.3) 5 5)) )

(defun rev (x &optional y) (cond
	((null x) y)
	((atom (car x))
	   (rev (cdr x) (cons (car x) y)))
	(t
	   (rev (cdr x) (cons (rev (car x)) y) ) ) ))
(trace rev)
(rev '(a b ((c d) e)) )

(sexpr maplist2 (lambda (x f)(cond
	((null x)nil)
	(t (cons(f x)(maplist2 (cdr x)f))) )))

(maplist2 (quote (a b (c d)))
 	 (quote (lambda (y) (cons
		(car y)(quote w) ))) )

(sexpr mapcar2 (lambda (x f)
	(maplist2 x (function (lambda (x)
		(f (car x)) ))) ))

(mapcar2 (quote (a b (c d)))
	(quote (lambda (x)
		(cons x (quote w)) )) )

(sexpr fact2(lambda(x) (cond
	((eq x 1)1)
	(t (times x(fact2(difference x 1)))) )))

(fact2 7)

(memb (quote (a s.3))  (quote (3 4 2 1 (a s.3))) )

(equal (quote(a b)) (quote(a   b)))