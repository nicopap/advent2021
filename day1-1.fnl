(import-macros { : reduce } :fun-macros)
(local fun (require :fun))

(fn increases [lines]
  (fn count-increased [[acc last] current]
    (local count (+ acc (if (> current last) 1 0)))
    [count current])
  (local [increase-count _]
    (reduce [0 1000] lines
      (map tonumber)
      (with count-increased)))
  increase-count)

(local lines [])
(local input (io.input))
(each [line (input:lines)]
  (table.insert lines line))

(local count (increases lines))
(print count)
