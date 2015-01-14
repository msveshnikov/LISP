
(echo 3)
(defun list2 (&rest x) x)
(list2 1 2 3)

(defun cons2 (x &rest y) (print x)
			 (print y) (+ x 3) )
(cons2 12 'b 'c 'd)

(defun fn (x &optional (y (+ x 2)) (z 4) w)
	(list x y z w))

(fn 2)
(fn 2 5)
(fn 1 2 3 4)

((lambda (x &optional (y (+ x 2)) &aux (z y)) (list x y z)) 2)

(defun fn2 (x &optional y &rest z &aux w)
	(list x y z w))

(fn2 'a)
(fn2 'a 'b 'c 'd)