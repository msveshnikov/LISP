
(csetq c1 '(nil))
(prog (i)
(setq i 1)
a
(nconc c1 (list i))
(1+ i)
(if (< i 100) (go a)) )