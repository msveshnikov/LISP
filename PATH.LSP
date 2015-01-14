
(sexpr p(lambda(x s)(cond
	((null s)(cons x nil))
	((eq x (caar s))(cons x
		(p (cdar s)(cdr s)) ))
	(t (p x (cdr s)))  )))

(sexpr step(lambda (l a i s m j)(cond
	((memb a j)(p a s))
	((null l)(cond ((null j)nil)
	(t(step m a j s nil nil)) ))
	((memb (cdar l)i)(cond
		((memb (caar l)i)
			(step (cdr l) a i s m j))
		((memb (caar l)j)
			(step (cdr l) a i s m j))
		(t(step (cdr l) a i
			(cons (car l)s) m
			(cons (caar l) j) )) ))
	((memb (caar l) i)(cond
		((memb (cdar l)j)
			(step (cdr l) a i s m j))
		(t(step (cdr l) a i (cons
			(cons (cdar l) (caar l)) s)
			m (cons (cdar l) j) )) ))
	(t(step (cdr l) a i s 
		(cons (car l) m) j)) )))

(sexpr path1(lambda(l a b)(cond
	((eq a b)(cons a nil))
	(t (step l a (cons b nil) nil nil nil )) )))

(path1	(quote (
	(o.d)(p.q)(n.m)
	(g.d)(h.d)(h.e)(h.q)
	(d.c)(c.m)(c.k)(a.f)
	(b.e)(q.r)(m.l)(e.i)(i.r)
	(i.t)(r.s)(f.k)(f.j)(l.k)(l.u) ))
	(quote a)(quote t) )

(sexpr path (lambda (l a b)
(prog (i j s m x y z)
	(setq i (cons b nil))
	(cond ((eq a b)(return i)))
a	
	(cond ((null l)(go d)))

	(setq z (car l))
	(setq l (cdr l))
	(setq x (car z))
	(setq y (cdr z))

	(cond ((memb y i)(go c))
	      ((memb x i)(go b)) )
	(setq m(cons z m))
(go a)
b	(setq z(cons y x))
	(setq y x)
	(setq x (car z))
c	(cond ((memb x j)(go a)))
	(cond ((memb x i)(go a)))
	(setq s (cons z s))
	(cond ((eq x a) (go e)))
	(setq j (cons x j))
(go a)
d	(cond ((null j) (return nil)))
	(setq l m)
	(setq i j)
	(setq m nil)
	(setq j nil)
(go a)
e	(setq z nil)
f	(cond ((null s) (return (cons x z))))
	(setq y (car s))
	(setq s (cdr s))
	(cond ((eq x(car y)) (go g)))
(go f)
g	(setq z (cons x z))
	(setq x (cdr y)) (go f)	 )))

(path	(quote (
	(o.d)(p.q)(n.m)
	(g.d)(h.d)(h.e)(h.q)(h.q)
	(d.c)(c.m)(c.k)(a.f)
	(b.e)(q.r)(m.l)(e.i)(i.r)
	(i.t)(r.s)(f.k)(f.j)(l.k)(l.u) ))
	(quote a)(quote t) )