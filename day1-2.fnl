(import-macros { : reduce } :fun-macros)
(local fun (require :fun))

(fn increases [lines]
  (var scnd-last (table.remove lines 1))
  (var frst-last (table.remove lines 1))
  (fn sliding [elem]
    (local current (+ scnd-last frst-last elem))
    (set scnd-last frst-last)
    (set frst-last elem)
    current)
  (fn count-increased [[acc last] current]
    (local count (+ acc (if (> current last) 1 0)))
    [count current])
  (local [increase-count _]
    (reduce [0 1000] lines
      (map tonumber)
      (map sliding)
      (with count-increased)))
  increase-count)

(local lines [])
(local input (io.input))
(each [line (input:lines)]
  (table.insert lines line))

(local count (increases lines))
(print count)
