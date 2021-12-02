(import-macros { : reduce } :fun-macros)
(local view (require :fennelview))
(local vprint (fn [v] (print (view v))))
(local fun (require :fun))

(fn parse [line]
  (local (direction len) (string.match line "(%a*) (%d*)"))
  [direction (tonumber len)])

(fn move [ctx [dir len]]
  (match dir
    :forward { :horiz (+ ctx.horiz len) :depth ctx.depth }
    :down    { :horiz ctx.horiz         :depth (+ ctx.depth len) }
    :up      { :horiz ctx.horiz         :depth (- ctx.depth len) }))

(fn navigate [lines]
  (reduce { :horiz 0 :depth 0 } lines
          (map parse)
          (with move)))

(local lines [])
(local input (io.input))
(each [line (input:lines)]
  (table.insert lines line))

(local { : depth : horiz } (navigate lines))
(vprint (* depth horiz))
