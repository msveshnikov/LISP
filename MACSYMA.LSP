(echo 0)

(setq *действия* '(/ * - + := : d))

(defun читай ()
   ((lambda (x)
      (if (eq x '!) nil
	 (cons x (читай))))
    (read)))

(defun анализируй (дерево стек выражение)
(cond
   ((null выражение)
      (if (car стек)
	(преобразуй дерево стек выражение)
	(car дерево)))
   ((atom выражение) выражение)
   ((atom (car выражение))
      (cond
	((not (member (car выражение) *действия*))
	   (анализируй
	      (cons (car выражение) дерево)
	      стек
	      (cdr выражение)))
	((старше (car выражение) (car стек))
	   (анализируй 
	      дерево
	      (cons (car выражение) стек)
	      (cdr выражение)))
	(t (преобразуй дерево стек выражение))))
   (t (анализируй
            (cons (анализируй nil '(nil) (car выражение))
            	  дерево)
            стек
            (cdr выражение)))))
            
(defun преобразуй (дерево стек выражение)
   (анализируй
      (cons (list (car стек)
      		  (cadr дерево)
      		  (car дерево))
      	    (cddr дерево))
      (cdr стек)
      выражение))
      
(defun старше (p q)
   (or (null q)
      (member q (member p *действия*))))

;(анализируй nil '(nil) '(a + b * c))
;(анализируй nil '(nil) '(a + b + c * f))

(defun вычисли (x &optional значение)
(cond
   ((numberp x) x)
   ((atom x)
      (if (setq значение (get x 'значение))
 	(вычисли значение)
	x))
   (t (примени (first x)
	(mapcar (function вычисли)
		(cdr x))))))

(defun примени (операция args 
	&optional (op (get операция 'fn)))
   (if op (apply op args)
	(list op
	   (вычисли (first args))
	   (вычисли (second args)))))

(defmacro defдействие (символ парам тело)
	(list 'put (list 'quote символ) ''fn
	   (list 'quote (list 'lambda парам тело))))

(defmacro defпроизводная (символ парам тело)
	(list 'put (list 'quote символ) ''производная
	   (list 'quote (list 'lambda парам тело))))

(defдействие + (x y)
   (cond ((zerop x) y)
	 ((zerop y) x)
	 ((and (numberp x) (numberp y))
		(+ x y))
	 (t (list '+ x y))))

(defдействие - (x y)
   (cond ((zerop y) x)
	 ((and (numberp x) (numberp y))
		(- x y))
	 (t (list '- x y))))

(defдействие * (x y)
   (cond ((= x 1) y)
         ((= y 1) x)
         ((or (zerop x) (zerop y)) 0)
	 ((and (numberp x) (numberp y))
		(* x y))
	 (t (list '* x y))))

(defдействие / (x y)
   (cond ((zerop x) 0)
         ((zerop y) 'inf)
         ((equal x y) 1)
	 ((and (numberp x) (numberp y))
		(/ x y))
	 (t (list '/ x y))))
	 
(defдействие : (x y) y)

(defдействие := (x y)
(cond ((not (numberp x))
	(put x 'значение y) y)
      (t (prin1 '|Нельзя присвоить значение |) x) ))

(defдействие d (l x)
    (вычисли (дифференцируй1 l x)))

(defun дифференцируй1 (l x) 
  (cond ((atom l) (if (eq l x) 1 0))
        (t (funcall (get (first l) 'производная)
			(cdr l) x ))))

(defпроизводная + (l x)
	(list '+ (дифференцируй1 (first l) x)
		 (дифференцируй1 (second l) x)))

(defпроизводная * (l x) 
	(list '+
	  (list '* (дифференцируй1 (first l) x)
		(second l))
	  (list '* (дифференцируй1 (second l) x)
		(first l))))

(defпроизводная / (l x) 
    (list '/
	(list '-
	  (list '* (дифференцируй1 (first l) x)
		(second l))
	  (list '* (дифференцируй1 (second l) x)
		(first l)) )
	(list '* (second l) (second l)) ))

(defпроизводная - (l x)
	(list '- (дифференцируй1 (first l) x)
		 (дифференцируй1 (second l) x)))
    
(defun снять-скобки (x)
   (if (atom x)
   	x
   	(append2
   	   (снять-y (first x) (second x))
   	   (list (first x))
   	   (снять-y (first x) (third x)))))
   	   
(defun снять-y (оператор выражение 
		&optional (x (снять-скобки выражение)))
(if (or (atom x)
	(старше оператор (second x)))
    (list x)
    x))

(defun macsyma (&optional выражение)
   (prin1 '|MacSyma:|)
   (loop
      (terpri)
      (prin1 '|<= |)
      (setq выражение (читай))
      (when (equal выражение '(end))
	(return '|Welcome again|))
      (prin1 '|=> |)
      (prin1 (снять-скобки (вычисли (анализируй nil '(nil) выражение)))) ))