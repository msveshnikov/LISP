
(echo 0)

(sexpr prove(lambda(l r s)(cond
	(l(prove1(car l)(cdr l) r s))
	(r(prove2(car r)(cdr r)s))
	(s(prove(caar s)(cdar s)(cdr s)))
	(t t) )))

(sexpr prove1(lambda(f l r s)(cond
	((atom f)(subt f l r s))
	(t(prove3(car f)(cdr f)l r s)) )))

(sexpr prove2(lambda (f r s)(cond
	((atom f)(subv nil f r nil nil s))
	(t(prove4(car f)(cdr f) r s)) )))

(sexpr prove3(lambda (op a l r s)(cond
	((eq op(quote not))
		(prove l(cons(car a)r)s) )
	(t(prove5 op (car a)(cadr a)l r s)) )))

(sexpr prove4(lambda(op a r s)(cond
	((eq op(quote not))(prove a r s))
	(t (prove6 op(car a)(cadr a)r s)) )))

(sexpr prove5(lambda(op f g l r s)
	(selectq op  (and  (prove1 f(cons g l)r s)
		      or   (prove1 f l r(cons(cons(cons g l)r)s))
		      imp  (prove1 g l r (cons(cons l(cons f r))s))  )
	(prove1 f(cons g l)r
		(cons(cons l (cons f(cons g r))) s)) ) ))

(sexpr prove6(lambda(op f g r s)
	(selectq op (or   (prove2 f (cons g r)s)
		     and  (prove2 f r (cons(cons nil(cons g r))s))
		     imp  (prove1 f nil(cons g r)s)  )
	(prove1 f nil (cons g r)
		(cons(cons(list g)(cons f r))s))   )))

(sexpr subt(lambda(x l r s)(cond
	((null l)(subv t x r nil nil s))
	(t(subt x(cdr l)
		(cons(list(quote not)
		(car l))r)s) ))))

(sexpr subv(lambda(v x r lx lf s)(cond
	(r(subv1 v x(sub v x(car r))
		(cdr r)lx lf s))
	((null lf)nil)
	(lx (subv nil(car lx)lf(cdr lx)nil s))
	(t(prove2(car lf)(cdr lf)s)))))
	
(sexpr subv1(lambda(v x f r lx lf s)
(cond((null f)(subv v x r lx lf s))
	((eq f t)(cond(s(prove(caar s)(cdar s)(cdr s)))
		(t t)))
	((atom f)(subv v x r (cons f lx)lf s))
	(t(subv v x r lx(cons f lf)s)) )))

(sexpr sub(lambda(v x f)(cond
	((eq x f)v)((atom f)f)
	(t(suba v x(car f)
		(sub v x(cadr f))(cddr f))))))

(sexpr suba(lambda(v x op f a)(cond
	((eq op (quote not))(neg f))
	(t (subb op f (sub v  x (car a)))) )))

(sexpr neg(lambda(f)(selectq f
	(nil t t nil)(list (quote not)f))))

(sexpr subb(lambda(op f g)(cond
	((eq f t)(cond
		((or (eq g t) (eq op (quote or))) t)
		((null g)    nil)
		(t g) ))
	((null f)(selectq op
		(or g and nil imp t)(neg g) ))
	((eq g t)(selectq op
		(or t imp t)f))
	((null g)(selectq op
		(or f and nil)
		(list(quote not )f)))
	(t(list op f g))  )))

(sexpr check(lambda(f) (prove2 f nil nil)))

(sexpr doit(lambda()(prog(a)
L	(prin1 (quote Высказывание:))
	(setq a(read))
	(cond ((eq a (quote ok))(return (quote OK!))))
	(print(check a))
	(go L)	)))

(echo 3)

(check (quote (or a(not a))))
(check (quote (or t nil )))
(check (quote  (equ(not(imp x y))(and x(not y)))  ))