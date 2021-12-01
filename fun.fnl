(import-macros { : reduce } :fun-macros)

(fn in? [tabl x] (reduce false tabl (break-with #(if (= $1 x) (values true :break) false))))
(comment (in? [1 1 1 1 3 3 3 3 3 5] 5)) ; => true

(fn any? [tabl f] (reduce false tabl (with #(or $1 (f $2)))))
(comment (any? [1 1 1 1 3 3 3 3 3] #(= (% $1 2) 0))) ; => false

(fn sumap [tabl f] (reduce 0 tabl (map f) (with +)))
(comment (sumap [1 2 3 4] #(* 3 $1))) ; => 30

(fn count [tabl f] (reduce 0 tabl (filter f) (map (fn [] 1)) (with +)))
(comment (count [1 2 3 4 5] #(= 0 (% $1 2)))) ; => 2

(fn find [tabl f]
  (reduce nil tabl
    (break-with #(if (f $1) (values $1 :break)))))
(comment (find [1 1 1 1 1 2 1 1 1 1 1 1 1 1 4] #(= (% $1 2) 0)))

{ : any?
  : sumap
  : count
  : find }
