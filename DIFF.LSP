
(defun ����७���1 (l x) 
  (cond ((atom l) (if (eq l x) 1 0))
        (t (funcall (get (first l) '�ந�������)
			(cdr l) x ))))

(put '+ '�ந������� '����७���+)
(put '* '�ந������� '����७���*)

(defun ����७���+ (l x)
	(list '+ (����७���1 (first l) x)
		 (����७���1 (second l) x)))

(defun ����७���* (l x) 
	(list '+
	  (list '* (����७���1 (first l) x)
		(second l))
	  (list '* (����७���1 (second l) x)
		(first l))))

(put '- '�ந������� '����७���-)

(defun ����७���- (l x)
	(list '- (����७���1 (first l) x)
		 (����७���1 (second l) x)))
    

(����७���1 '(+ x (* 3 x)) 'x)