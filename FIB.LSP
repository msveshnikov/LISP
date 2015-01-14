
(defun fib (n) (cond
	((= n 0) 0)
	((= n 1) 1)
	(t (+ (fib (- n 1))  (fib (- n 2)))) ))

(prog (i)
	(setq i 0)
A	(prin1 (fib i))  (prin1 blank)
	(1+ i)
	(if (= i 10) (return '|Ok!|) (go A)) )