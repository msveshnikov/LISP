
(defun дифференцируй1 (l x) 
  (cond ((atom l) (if (eq l x) 1 0))
        (t (funcall (get (first l) 'производная)
			(cdr l) x ))))

(put '+ 'производная 'дифференцируй+)
(put '* 'производная 'дифференцируй*)

(defun дифференцируй+ (l x)
	(list '+ (дифференцируй1 (first l) x)
		 (дифференцируй1 (second l) x)))

(defun дифференцируй* (l x) 
	(list '+
	  (list '* (дифференцируй1 (first l) x)
		(second l))
	  (list '* (дифференцируй1 (second l) x)
		(first l))))

(put '- 'производная 'дифференцируй-)

(defun дифференцируй- (l x)
	(list '- (дифференцируй1 (first l) x)
		 (дифференцируй1 (second l) x)))
    

(дифференцируй1 '(+ x (* 3 x)) 'x)