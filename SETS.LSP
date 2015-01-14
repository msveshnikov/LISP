(echo 3)

(defun is (x) x)
(defun mapdef (f g)
   (function (lambda (h y)
      (if (null y) nil
	(f (h  (g y)) 
	   (funcall (mapdef f g) h (cdr y)))))))

(defun mapcar1 (f l)
    (funcall (mapdef 'cons 'car)
	f l))

(defun maplist1 (f l)
    (funcall (mapdef 'cons 'is)	f l))
	
(mapcar1 'numberp '(a 1 2 cd e 3))
(maplist1 '(lambda(x) (cons (first x)(second x))) '(a 1 2 cd e 3))

(defun mapcan1 (f l)
    (funcall (mapdef 'nconc 'car) f l))

(defun mapcon1 (f l)
    (funcall (mapdef 'nconc 'is) f l))

(mapcon1 'copy-list '(a b c d e))
(mapcan1 '(lambda(x) (if (numberp x) (list t) nil))
	 '(1 2 мимо 3 c 4 a s 5))
(defun последний (x)
	(if (= (входит-ли x) 0)
	   (list (car x))
	   nil))
(csetq последовательность '(в х о д и т  л и  з н а к   в  х в о с т ))
(defun входит-ли (x) 
	(if (member (car x) (cdr x)) 1 0))
(mapcon1 'последний последовательность)

(defmacro copy-listq (x)
   (cond ((null x) nil)
	(t (list 'cons
		(list 'quote (car x))
		(list 'copy-listq (cdr x))))))

(copy-listq (a b c))

(defun plus+ (x) (function (lambda (y)  (+ x y))))
(csetq plus3 (plus+ 3))
(funcall plus3 5)

(defun nat (x)
   (function (lambda () (1+ x))))

(csetq next (nat 0))
(funcall next)
(csetq source (nat 100))
(funcall next)
(funcall source)
(funcall next)
(funcall source)

(defun проба (x)
   (mapcar (function (lambda (y) (cons y x)))
	   '(a b c)))
(проба 2)

(декартово '(a b c) '(1 2 3))

(всеподмножества '(a b c))

(defun обобщение (x y fn)
   (cond ((null x) y)
         (t (fn (car x) (обобщение (cdr x) y fn)))))

(defun copy-list2 (x) (обобщение x nil 'cons))
(defun append3 (x y)  (обобщение x y 'cons))
(defun сортируй2 (x y) (обобщение x y (function вставь)))

(defun вставь (a l)
   (cond ((null l) (list a))
	 ((< a (car l))  (cons a l))
	 (t (cons (car l) (вставь a (cdr l))))))

(csetq n '(a b c))
(eq    n (copy-list2 n))
(equal n (copy-list2 n))
(append3 '(a b c) '(d e f))
(сортируй2 '(1 3 5 7 9 11 15) '(2 4 6))

(defun композиция (f g)
    (function (lambda(x) (f (g x)))))

(композиция 'car 'cdr)

(funcall (композиция 'car 'cdr) '(a b c))

(defun вертушка (f g)
   (function (lambda (x y)
      (f (g x y) (g y x)))))

(csetq x '(a b))
(csetq y '(1 2))

(funcall (вертушка '* '+) 2 3)

(funcall (вертушка 'append 'декартово) x y)

(defun трижды (fn)
    (function (lambda (x)
       (fn (fn (fn x))))))

(defun луковица (ядро)
	(funcall (трижды (трижды 'list)) ядро))

(луковица 'луковица)
	
(defun ! (n) (факториал 'факториал n))

(defun факториал (f n)
   (if (0? n) 1
      (* n (f f (- n 1)))))

(! 6)