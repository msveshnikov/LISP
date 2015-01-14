
;	MaxSoft LISP Library v1.5+    (c) 1996-97
;	SUBR, FSUBR, MACRO definitions

(defun box (x1 y1 x2 y2 col &aux (i y1) (j x1))
(loop
   (loop
	(putpixel j i col)
	(if (= j x2) (return))
	(1+ j))
   (if (= i y2) (return t))
   (setq j x1)
   (1+ i)))

(defun copy-tree (l)
   (cond ((null l) nil)
	 ((atom l) l)
	 (t (cons (copy-tree (car l))
		  (copy-tree (cdr l))))))

(defun abs(x) (if (minusp x) (- x) x))

(defmacro let* (listv &rest body)
   (return (list (cons 'lambda (cons
		(cons '&aux listv) body)))) )

(defmacro when (cond &rest body)
	(list 'cond (cons cond body)))

(defmacro unless (cond &rest body)
	(list 'cond (cons (list 'not cond) body)))

(defun apply (fn l) 
    (eval (cons fn (mapcar (function (lambda (x) (list 'quote x))) l))))

(defun pairlis (key data alist)
   (if (null key) alist
      (cons (cons (car key)
		  (car data))
	    (pairlis (cdr key) (cdr data) alist))))

;(defun assoc (a alist)
;  (cond ((null alist) nil)
;	 ((equal (caar alist) a)
;	    (car alist))
;	 (t (assoc a (cdr alist)))))

(defun acons (x y a) (cons (cons x y) a))

(defmacro do (varlist excond &rest body &aux vars steps inits stepvars w) 
   (loop
	(if (atom varlist)
	  (return (cons 
	   (list 'lambda vars
		(cons 'loop
		   (cons (list 'if (first excond) (list 'return
			 (cons 'progn (cdr excond))))
		     (list (cons 'progn body)
			   (list 'bindlist stepvars steps)))))
	   inits)) )
	(setq w (pop varlist))
	(push (first w) vars)
	(push (second w) inits)
	(cond ((cddr w)
		 (push (third w) steps)
		 (push (first w) stepvars) )) ))

(defmacro do* (varlist excond &rest body &aux (inits (list '&aux)) steps w)
   (loop
	(if (atom varlist)
	   (return
	     (cons (list 'lambda (dreverse inits)
		(cons 'loop
		   (cons (list 'if (first excond) (list 'return 
				(cons 'progn (rest excond))))
			 (cons (cons 'progn body) (dreverse steps))))))))
	(push (setq w (pop varlist)) inits)
	(if (third w) (push (list 'setq (first w) (third w)) steps)) ))
			  
(deffun pfunc (x)
    (if (fboundp x)
	(pprint (cons 'lambda (car2 (car2 x))))
	nil ))

(defun copy-list (x) (if (null x) x
			(cons (car x) (copy-list (cdr x)))))

(defun append3* (args)
	(cond ((null args) nil)
	      (t (append (car args) (append3* (cdr args))))))
(defun append2 (&rest args) (append3* args))

(defmacro setqq (x y)
	(list 'setq x (list 'quote y)))

(defun prog2 (x1 x2 &rest x3) x2)

(defun индекс (x y fn)
   (cond ((null x) y)
	 (t (fn (car x) (индекс (cdr x) y fn)))))

(defun декартово (x y)
    (индекс x nil
	(function (lambda (u v)
	    (индекс y v
		(function (lambda (p q)
		    (cons (list u p) q ))))))))

(defun всеподмножества (x)
    (cond ((null x) '(nil))
	(t (индекс 
	    (всеподмножества (cdr x))
	    nil
	    (function (lambda (u v)
		(cons (cons (car x) u)
		      (cons u v))))))))

(defun pprint (x &optional (отступ 0)) 
	(установи отступ) 
	(pprint1 x отступ)
	(terpri)  t)

(defun pprint1 (l отступ)
    (cond
	((< (count l) 6)
	  (prin1 l))
	(t
	  (prin1 lpar)
	  (pprint1 (car l) отступ)
	  (pp-tail (cdr l) отступ) )))

(defun pp-tail (l отступ)
	(cond ((null l) (prin1 rpar))
	  (t (terpri)
             (установи (+ отступ 3))
	     (pprint1 (car l) (+ отступ 3))
	     (pp-tail (cdr l) отступ) )))

(sexpr maplist (lambda (f x)(cond
	((null x) nil)
	(t (cons (f x) (maplist f (cdr x)))) )))

(sexpr mapcar (lambda (f x) (cond
	((null x) nil)
	(t (cons (f (car x)) (mapcar f (cdr x)))) )))

(defun ! (n)
   (if (= n 0) 1
      (* n (! (- n 1)))))

(defun remove (x l &aux y) (loop
	(cond ((null l) (return (dreverse y)))
	      ((not (equal x (car l)))
		 (push (car l) y) ))
	(pop l) ))

(defun length (x &aux (u 0)) (loop
	(if (atom x) (return u))
	(pop x)  (1+ u) ))

(sexpr collect(lambda(l) (cond
	((null l) nil)
	(t (cons (car l)(collect (cond
		((member (car l) (cdr l))
		   (cons (car l) (removef (car l)(cdr l)) ))
		(t (cdr l))  )))) )))

(sexpr removef(lambda (x y) (cond
	((null y) nil)
	((equal x (car y)) (cdr y))
	(t (cons (car y) (removef x (cdr y)))) )))

(sexpr flatten(lambda (x) (cond
	((null x) nil)
	((atom x) (list x))
	(t (append (flatten (car x))
		   (flatten (cdr x)) )) )))

;(defun dreverse (x &aux u v) (loop
;	(if (null x) (return u))
;	(setq v x) (pop x)
;	(setq u (rplacd v u)) ))
; Скомпилирована в LISP.EXE 24.12.97

(sexpr forall(lambda(l p) (cond
	((null l) t)
	((p (car l)) (forall (cdr l) p)) )))
	
(sexpr listp(lambda (x) (cond
	((null x) t)
	((atom x) nil)
	((or (atom (car x)) (listp (car x)))
	   (listp (cdr x))) )))

(sexpr first2(lambda (x y) (cond
	((null y) (car x))
	((member (car y) x) (car y))
	(t (first2 x (cdr y))) )))

(sexpr rank(lambda(x y) (if (null x) nil
	(cons (first2 x y)
	   (rank (removef (first2 x y) x) y) ) )))

(defun put (a i p &aux (u (cons 1 (proplist a))) (v u)) (prog ()
a	(cond   ((null (cdr v)) (rplacd v (list i p)))
		((eq (car (setq v (cdr v))) i) 
		   (rplaca (cdr v) p))
		(t (pop v) (go a)) )
	(spropl a (cdr u))
	(return a) ))

(defun get (a i &aux (u (proplist a)) ) (loop
	(cond ((null u) (return nil))
	      ((eq (car u) i) (return (cadr u)))
	      (t (setq u (cddr u)) )) ))

(defun remprop (a i &aux (u (proplist a)) v)
   (cond ((eq (car u) i) (spropl a (cddr u)) (return i)))
   (loop
	(cond ((null u) (return nil))
	      ((= (car u) i) (rplacd v (cddr u)) (return i))
	      (t (setq v (cdr u))
		 (setq u (cddr u)) )) ))