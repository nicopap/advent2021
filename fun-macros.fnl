(fn iter-help [seq v-in body]
  (local head (table.remove body 1))
  ; guards against `table.remove nil` which is an error
  (local head-fun (and head (table.remove head 1)))

  (match (and head-fun (tostring head-fun))
    :map
      (do
        (table.insert head v-in)
        `(let [v-out# ,head]
           ,(iter-help seq `v-out# body)))

    :flat-map
      (do
        (table.insert head v-in)
        `(each [_# v-out# (ipairs ,head)]
          ,(iter-help seq `v-out# body)))

    :filter
      (do
        (table.insert head v-in)
        `(if ,head ,(iter-help seq v-in body)))

    :enumerate
      `(do
        (var counter# (if counter# (+ counter# 1) 0))
        ,(iter-help seq [ `counter# v-in ] body))

    :with
      (do
        (table.insert head seq)
        (table.insert head v-in)
        `(set ,seq ,head))

    :break-with
      (do
        (table.insert head v-in)
        (table.insert head seq)
        `(let [(result# break?#) ,head]
           (set ,seq result#)
           (if break?# (lua "goto early_exit"))))

    nil
      `(table.insert ,seq ,v-in)

    (assert-compile false head-fun)))


(fn reduce* [acc input ...]
  "Transform a functional pipeline into imperative nested loops!

  the syntax is as follow:
  ```
  ; count elements in `tabl` where `pred` is true
  (reduce 0 tabl
    (filter pred)
    (map (fn [] 1))
    (op ...)
    (with +))

  ; Becomes:
  ; (do
  ;   (var out 0)
  ;   (each [_ v (ipairs tabl)]
  ;     (if (pred v)
  ;       (let [v1 ((fn [] 1) v)]
  ;         ...
  ;         (set out (+ out vn)))))
  ;   out)
  ```

  Arguments:
    1) `acc`: The accumulator
    2) `input`: The table to iterate
    3) `...`: The pipeline operators

  Where the pipeline operators are any of the following:
    - `map f`:
        `f` accepts an element and returns one

    - `flat-map f`:
        `f` accepts an element and returns a list

    - `filter f`:
        `f` accepts one elements and returns `false`
        for to filter out some and `true` when accepting them

    - `enumerate`:
        replace each `elem` with `[index elem]` where `index`
        is the position in the stream of the element, starting
        at 1

    - `with f`:
        `f: acc, elem -> acc` must be at the end of the pipeline,
        `f` is the reduction function, you may ignore `acc` for side effects

    - `break-with f`:
        `f: elem, acc -> acc | (ret true)` must be at the
        end of the pipeline, `f` is the reduction function,
        return `(value X)` where `X` is truthy to end the
        iteration early and return the provided `value`,
        otherwise, the return value is put into the
        accumulator
        WARNING: notice the arguments are swapped compared to
        `with`

  When the pipeline doesn't end with `with`, it will accumulate the elements
  in `acc`, so you better give it an empty table in that case."
  `(do (var output# ,acc)
     (each [_# v# (ipairs ,input)]
       ,(macroexpand (iter-help `output# `v# [...])))
     (lua "::early_exit::")
     output#))

(fn iter* [input ...]
  (reduce* [] input ...))


(fn concat [seq1 seq2]
  (each [_ elem (ipairs seq2)]
    (table.insert seq1 elem))
  seq1)

(fn .?*-predicate [tabl accessors]
  "Generate the 'and' bit of the .?* macro"
  (local predicate `(and))
  (var partial-path (list))
  (each [_ accessor (ipairs accessors)]
    (table.insert partial-path accessor)
    (table.insert predicate (concat `(. ,tabl) partial-path)))
  predicate)

(fn .?* [tabl ...]
  "Safe optics for tables. Similar to `.`, but returns nil instead of an error
   when an element is not here. Example:
   
   (local tabl {:a {:b {:c {:d 3}}}})
   (.? tabl :a :b :e :f)
   ; Becomes
   (let [tabl-x tabl]
     (if (and (. tabl-x :a) 
              (. tabl-x :a :b)
              (. tabl-x :a :b :e))
       (. tabl-x :a :b :e :f)
       nil))
   ; which returns `nil`"
  ; Trick: [...] copies ... into accessors, we then remove from it the last 
  ; element before passing it to `.?*-predicate`, because we don't want to
  ; check for truthyness of the last element.
  (local accessors [...])
  (table.remove accessors (length accessors))
  `(let [tabl# ,tabl]
     (if ,(.?*-predicate `tabl# accessors)
       (. tabl# ,...)
       nil)))

{ :reduce reduce* :iter iter* :.? .?* }
