(echo 0)

(setq *����⢨�* '(/ * - + := : d))

(defun �⠩ ()
   ((lambda (x)
      (if (eq x '!) nil
	 (cons x (�⠩))))
    (read)))

(defun ��������� (��ॢ� �⥪ ��ࠦ����)
(cond
   ((null ��ࠦ����)
      (if (car �⥪)
	(�८�ࠧ� ��ॢ� �⥪ ��ࠦ����)
	(car ��ॢ�)))
   ((atom ��ࠦ����) ��ࠦ����)
   ((atom (car ��ࠦ����))
      (cond
	((not (member (car ��ࠦ����) *����⢨�*))
	   (���������
	      (cons (car ��ࠦ����) ��ॢ�)
	      �⥪
	      (cdr ��ࠦ����)))
	((���� (car ��ࠦ����) (car �⥪))
	   (��������� 
	      ��ॢ�
	      (cons (car ��ࠦ����) �⥪)
	      (cdr ��ࠦ����)))
	(t (�८�ࠧ� ��ॢ� �⥪ ��ࠦ����))))
   (t (���������
            (cons (��������� nil '(nil) (car ��ࠦ����))
            	  ��ॢ�)
            �⥪
            (cdr ��ࠦ����)))))
            
(defun �८�ࠧ� (��ॢ� �⥪ ��ࠦ����)
   (���������
      (cons (list (car �⥪)
      		  (cadr ��ॢ�)
      		  (car ��ॢ�))
      	    (cddr ��ॢ�))
      (cdr �⥪)
      ��ࠦ����))
      
(defun ���� (p q)
   (or (null q)
      (member q (member p *����⢨�*))))

;(��������� nil '(nil) '(a + b * c))
;(��������� nil '(nil) '(a + b + c * f))

(defun ���᫨ (x &optional ���祭��)
(cond
   ((numberp x) x)
   ((atom x)
      (if (setq ���祭�� (get x '���祭��))
 	(���᫨ ���祭��)
	x))
   (t (�ਬ��� (first x)
	(mapcar (function ���᫨)
		(cdr x))))))

(defun �ਬ��� (������ args 
	&optional (op (get ������ 'fn)))
   (if op (apply op args)
	(list op
	   (���᫨ (first args))
	   (���᫨ (second args)))))

(defmacro def����⢨� (ᨬ��� ��ࠬ ⥫�)
	(list 'put (list 'quote ᨬ���) ''fn
	   (list 'quote (list 'lambda ��ࠬ ⥫�))))

(defmacro def�ந������� (ᨬ��� ��ࠬ ⥫�)
	(list 'put (list 'quote ᨬ���) ''�ந�������
	   (list 'quote (list 'lambda ��ࠬ ⥫�))))

(def����⢨� + (x y)
   (cond ((zerop x) y)
	 ((zerop y) x)
	 ((and (numberp x) (numberp y))
		(+ x y))
	 (t (list '+ x y))))

(def����⢨� - (x y)
   (cond ((zerop y) x)
	 ((and (numberp x) (numberp y))
		(- x y))
	 (t (list '- x y))))

(def����⢨� * (x y)
   (cond ((= x 1) y)
         ((= y 1) x)
         ((or (zerop x) (zerop y)) 0)
	 ((and (numberp x) (numberp y))
		(* x y))
	 (t (list '* x y))))

(def����⢨� / (x y)
   (cond ((zerop x) 0)
         ((zerop y) 'inf)
         ((equal x y) 1)
	 ((and (numberp x) (numberp y))
		(/ x y))
	 (t (list '/ x y))))
	 
(def����⢨� : (x y) y)

(def����⢨� := (x y)
(cond ((not (numberp x))
	(put x '���祭�� y) y)
      (t (prin1 '|����� ��᢮��� ���祭�� |) x) ))

(def����⢨� d (l x)
    (���᫨ (����७���1 l x)))

(defun ����७���1 (l x) 
  (cond ((atom l) (if (eq l x) 1 0))
        (t (funcall (get (first l) '�ந�������)
			(cdr l) x ))))

(def�ந������� + (l x)
	(list '+ (����७���1 (first l) x)
		 (����७���1 (second l) x)))

(def�ந������� * (l x) 
	(list '+
	  (list '* (����७���1 (first l) x)
		(second l))
	  (list '* (����७���1 (second l) x)
		(first l))))

(def�ந������� / (l x) 
    (list '/
	(list '-
	  (list '* (����७���1 (first l) x)
		(second l))
	  (list '* (����७���1 (second l) x)
		(first l)) )
	(list '* (second l) (second l)) ))

(def�ந������� - (l x)
	(list '- (����७���1 (first l) x)
		 (����७���1 (second l) x)))
    
(defun ����-᪮��� (x)
   (if (atom x)
   	x
   	(append2
   	   (����-y (first x) (second x))
   	   (list (first x))
   	   (����-y (first x) (third x)))))
   	   
(defun ����-y (������ ��ࠦ���� 
		&optional (x (����-᪮��� ��ࠦ����)))
(if (or (atom x)
	(���� ������ (second x)))
    (list x)
    x))

(defun macsyma (&optional ��ࠦ����)
   (prin1 '|MacSyma:|)
   (loop
      (terpri)
      (prin1 '|<= |)
      (setq ��ࠦ���� (�⠩))
      (when (equal ��ࠦ���� '(end))
	(return '|Welcome again|))
      (prin1 '|=> |)
      (prin1 (����-᪮��� (���᫨ (��������� nil '(nil) ��ࠦ����)))) ))