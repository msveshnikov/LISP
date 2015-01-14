
(pprint '(list (car x) (cons (car y) (cdr z))))
(pprint '(cond ((null x) nil) (t (cons (car x) (cdr y)))))
(pprint (function pprint1) 10)