
(defun ackerman (m n)
   (cond ((= m 0) (+ n 1))
         ((= n 0) (ackerman (- m 1) 1))
	 (t (ackerman (- m 1)
		(ackerman m (- n 1))))))

(ackerman 2 2)

(ackerman 3 2)