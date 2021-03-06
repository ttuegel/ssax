;-----------------------------------------------------------------------------
;   This is a test driver for SRFI-13 string manipulation functions,
;         to make sure they really work as intended
;
; IMPORT
; appropriate prelude: myenv.scm, myenv-bigloo.scm, myenv-scm.scm
;	depending on your system
; catch-error.scm -- for procedure, for-syntax
; srfi-13-local.scm if no native SRFI-13 support is available.
;
; See the Makefile in this directory, which shows how to run
; this code on a variery of Scheme systems.
;
; $Id$


		; make sure that the 'FORM' gave upon evaluation the
		; EXPECTED-RESULT
(cond-expand
  ((or bigloo gambit)
    (define-macro (expect form expected-result)
      `(begin
	 (display "evaluating ")
	 (write ',form)
	 (let ((real-result ,form))
	   (if (equal? real-result ,expected-result)
	     (cout "... gave the expected result: "
	       (lambda () (write real-result)) nl)
	     (error "... yielded: " real-result
	       " which differs from the expected result: " ,expected-result)
	     )))))
  (else
    (define-syntax expect
      (syntax-rules ()
	((expect form expected-result)
	  (begin
	    (display "evaluating ")
	    (write 'form)
	    (let ((real-result form))
	      (if (equal? real-result expected-result)
		(cout "... gave the expected result: "
		  (lambda () (write real-result)) nl)
		(error "... yielded: " real-result
		  " which differs from the expected result: " expected-result)
		))))))))



; Build a string out of components
; A component can be a string, a character, a number
; (converted into a character), symbols cr and lf
; We could've used a notation like "abc\n\t"
; Unfortunately, not all Scheme systems support C-like notation
; of Scheme strings
(define (s . components)
  (apply string-append
	 (map (lambda (component)
		(cond
		 ((string? component) component)
		 ((char? component) (string component))
		 ((number? component) (string (integer->char component)))
		 ((eq? 'lf component) (string #\newline))
		 ((eq? 'cr component) (string (integer->char 13)))
		 (else (error "bad component: " component))))
	      components)))

(cerr nl "Verifying string-xcopy! ..." nl)
(let ((sample (string-append "0123456789+")) ; A mutable string
      (txcopy
	(lambda (target to src from end)
	  (string-xcopy! target to src from end)
	  target)))
  (expect (txcopy "" 0 "" 0 0) "")
  (expect (txcopy "" 0 sample 0 0) "")
  (expect (txcopy sample 5 "" 0 0) sample)
  (expect (txcopy sample 0 sample 0 0) sample)
  (expect (txcopy sample 0 sample 0 1) sample)
  (expect (txcopy sample 0 sample 0 (string-length sample)) sample)
  (expect (txcopy sample 1 sample 1 (string-length sample)) sample)
  (expect (txcopy sample 10 sample 10 (string-length sample)) sample)
  (expect (txcopy (string-append sample) 1 sample 4 7) "0456456789+")
)


(cerr nl "Verifying string-concatenate-reverse ..." nl)
(let ((sample "0123456789+"))
  (expect (string-concatenate-reverse '() "" 0) "")
  (expect (string-concatenate-reverse '() sample 0) "")
  (expect (string-concatenate-reverse '() sample (string-length sample))
    sample)
  (assert (not (eq? sample		; the result must be a fresh string
	    (string-concatenate-reverse '() sample (string-length sample)))))
  (expect (string-concatenate-reverse (list sample) "" 0) sample)
  (assert (not (eq? sample
	    (string-concatenate-reverse (list sample) "" 0))))
  (expect (string-concatenate-reverse (list sample) sample 5)
    (string-append sample (substring sample 0 5)))
  (expect (string-concatenate-reverse (list sample "xyz") sample 5)
    (string-append "xyz" sample (substring sample 0 5)))
  (expect (string-concatenate-reverse (list sample "xyz") "abcd" 4)
    (string-append "xyz" sample "abcd"))
)

(cerr nl "Verifying string-concatenate-reverse/shared ..." nl)
(let ((sample "0123456789+"))
  (expect (string-concatenate-reverse/shared '()) "")
  (expect (string-concatenate-reverse/shared (list sample)) sample)
  (assert (eq? sample			; Return the original string
	    (string-concatenate-reverse/shared (list sample))))
  (expect (string-concatenate-reverse/shared (list sample "")) sample)
  (expect (string-concatenate-reverse/shared (list "" sample)) sample)
  (expect (string-concatenate-reverse/shared (list "abcd" sample "xyz"))
    (string-append "xyz" sample "abcd"))
)

(cerr nl "Verifying string-concatenate/shared ..." nl)
(let ((sample "0123456789+"))
  (expect (string-concatenate/shared '()) "")
  (expect (string-concatenate/shared (list sample)) sample)
  (assert (eq? sample
	    (string-concatenate/shared (list sample))))
  (expect (string-concatenate/shared (list sample "")) sample)
  (expect (string-concatenate/shared (list "" sample)) sample)
  (expect (string-concatenate/shared (list "abcd" sample "xyz"))
    (string-append "abcd" sample "xyz"))
)

(define (substring? pattern str) (string-contains str pattern))

(cerr nl "Verifying string-index, string-index-right and substring? ..." nl)
(let ()
  (expect (string-index "" #\a) #f)
  (expect (string-index "cbda" #\a) 3)
  (expect (string-index "cbdal" #\a) 3)
  (expect (string-index "acbdal" #\a) 0)
  (expect (string-index "acbdal" #\space) #f)
  (expect (string-index "acbd al" #\space) 4)

  (expect (string-index-right "" #\a) #f)
  (expect (string-index-right "adbc" #\a) 0)
  (expect (string-index-right "ladbc" #\a) 1)
  (expect (string-index-right "ladbca" #\a) 5)
  (expect (string-index-right "ladbca" #\space) #f)
  (expect (string-index-right "la dbca" #\space) 2)
  
  (expect (substring? "rat" "pirate") 2)
  (expect (substring? "e" "pirate") 5)
  (expect (substring? "k" "pirate") #f)
  (expect (substring? "pi" "pirate") 0)
  (expect (substring? "te" "pirate") 4)
  (expect (substring? "rat" "outrage") #f)
  (expect (substring? "pit" "pirate") #f)
  (expect (substring? "rate" "pirate") 2)
  (expect (substring? "aa" "aaaaaaa") 0)
  (expect (substring? "pirate" "pirate") 0)
  (expect (substring? "pirates" "pirate") #f)
  (expect (substring? "pirate" "pirates") 0)
  (expect (substring? "ages" "outrage") #f)
  (expect (substring? "" "outrage") 0)
)

(cerr nl "Verifying string-prefix? and string-suffix? ..." nl)
(let ()
  (expect (string-prefix? "pir" "pirate") #t)
  (expect (string-prefix? "rat" "outrage") #f)
  (expect (string-prefix? "pir" (s "pirate " 'lf) ) #t)
  (expect (string-prefix? " pir" (s "pirate " 'lf)) #f)
  (expect (string-prefix? " pir" (s " pirate " 'lf)) #t)
  (expect (string-prefix? "pirate" "pirate") #t)
  (expect (string-prefix? "" "pirate") #t)
  (expect (string-prefix? "" "") #t)
  (expect (string-prefix? "pirate" "") #f)
  (expect (string-prefix? "pirat" "pirate") #t)
  (expect (string-prefix? "pirate" "pirat") #f)
  (expect (string-prefix? (s 'cr "Z!@~#$Ll*()") (s 'cr "Z!@~#$Ll*()def")) #t)

  (expect (string-prefix-ci? "pir" "pirate") #t)
  (expect (string-prefix-ci? "pIr" "pirate") #t)
  (expect (string-prefix? "pIr" "pirate") #f)
  (expect (string-prefix-ci? "rat" "outrage") #f)
  (expect (string-prefix-ci? "pir" (s "piratE " 'lf)) #t)
  (expect (string-prefix-ci? " pir" (s "pirate " 'lf)) #f)
  (expect (string-prefix-ci? " pir" (s " PIRate " 'lf)) #t)
  (expect (string-prefix-ci? "pirate" "pirate") #t)
  (expect (string-prefix-ci? "" "pirate") #t)
  (expect (string-prefix-ci? "" "") #t)
  (expect (string-prefix-ci? "pirate" "") #f)
  (expect (string-prefix-ci? "PiRaT" "pIrAte") #t)
  (expect (string-prefix-ci? "pIrAte" "PiRaT") #f)
  (expect (string-prefix-ci? (s 'cr "z!@~#$lL*()")
			     (s 'cr "Z!@~#$Ll*()def")) #t)
  (expect (string-prefix? (s 'cr "z!@~#$lL*()") (s 'cr "Z!@~#$Ll*()def")) #f)

  (expect (string-suffix? "ate" "pirate") #t)
  (expect (string-suffix? "rag" "outrage") #f)
  (expect (string-suffix? "rage" "outrage") #t)
  (expect (string-suffix? "rage" (s 'lf " outrage")) #t)
  (expect (string-suffix? "rage" (s 'lf " out\\rage" 'lf)) #f)
  (expect (string-suffix? (s "rage" 'lf) (s 'lf " out\\rage" 'lf)) #t)
  (expect (string-suffix? "pirate" "pirate") #t)
  (expect (string-suffix? "" "pirate") #t)
  (expect (string-suffix? "" "") #t)
  (expect (string-suffix? "pirate" "") #f)
  (expect (string-suffix? "pirat" "pirate") #f)
  (expect (string-suffix? "irate" "pirate") #t)
  (expect (string-suffix? "pirate" "irate") #f)
  (expect (string-suffix? (s 'cr "Z!@~#$Ll*()")
			  (s "def" 'cr "Z!@~#$Ll*()")) #t)

  (expect (string-suffix-ci? "ate" "pirate") #t)
  (expect (string-suffix-ci? "ATE" "pirate") #t)
  (expect (string-suffix? "ATE" "pirate") #f)
  (expect (string-suffix-ci? "rag" "outrage") #f)
  (expect (string-suffix-ci? "rage" "outraGE") #t)
  (expect (string-suffix-ci? "RAGE" (s 'lf " outrage")) #t)
  (expect (string-suffix-ci? "rage" (s 'lf " out\\rage" 'lf)) #f)
  (expect (string-suffix-ci? (s "rAge" 'lf)  (s 'lf " out\\raGe" 'lf)) #t)
  (expect (string-suffix-ci? "pirate" "pirate") #t)
  (expect (string-suffix-ci? "" "pirate") #t)
  (expect (string-suffix-ci? "" "") #t)
  (expect (string-suffix-ci? "pirate" "") #f)
  (expect (string-suffix-ci? "Pirat" "pirate") #f)
  (expect (string-suffix-ci? "iRATe" "piRATE") #t)
  (expect (string-suffix-ci? "piRATE" "iRATe") #f)
  (expect (string-suffix-ci? (s 'cr "z!@~#$lL*()")
			     (s "def" 'cr "Z!@~#$Ll*()")) #t)
  (expect (string-suffix? (s 'cr "z!@~#$lL*()")
			  (s "def" 'cr "Z!@~#$Ll*()")) #f)
)

(cerr nl "Verifying string case-changing functions ..." nl)
(let ((add-nl (lambda (str) (string-append str (string #\newline)))))
  (expect (string-downcase "") "")
  (expect (string-downcase (add-nl "1234abcde!")) (add-nl "1234abcde!"))
  (expect (string-downcase "XYZ\\,%^") "xyz\\,%^")
  (expect (string-downcase (string-append (string #\return) "Z!@~#$Ll*()def"))
	  (string-append (string #\return) "z!@~#$ll*()def"))

  (expect (string-upcase "") "")
  (expect (string-upcase (add-nl "1234abcde!")) (add-nl "1234ABCDE!"))
  (expect (string-upcase "XYZ\\,%^") "XYZ\\,%^")
  (expect (string-upcase (string-append (string #\return) "Z!@~#$Ll*()def"))
	  (string-append (string #\return) "Z!@~#$LL*()DEF"))

  (let* ((test-str (string-copy "a123456789.,Z"))
         (test-str-clone (string-copy test-str)))
       (assert (not (eq? test-str test-str-clone)))
       (assert (equal? test-str test-str-clone))
       (assert (not (eq? (string-downcase test-str) (string-downcase test-str))))
       (assert (equal? (string-downcase test-str) (string-downcase test-str)))
       (assert (not (eq? (string-upcase test-str) (string-upcase test-str))))
       (assert (equal? (string-upcase test-str) (string-upcase test-str)))
       (string-downcase! test-str)
       (assert (not (equal? test-str test-str-clone)))
       (assert (equal? test-str (string-downcase test-str-clone)))
       (assert (equal? test-str (string-downcase test-str)))
       (string-upcase! test-str)
       (assert (not (equal? test-str test-str-clone)))
       (assert (equal? test-str (string-upcase test-str-clone)))
       (assert (equal? test-str (string-upcase test-str)))
      )
)


(cerr nl "Verifying string-null? ..." nl)
(let ()
  (assert (string-null? ""))
  (assert (not (string-null? " ")))
  (assert (not (string-null? "1 ")))
  (assert (not (string-null? (string (integer->char 0)))))
)


(cerr nl nl "All tests passed" nl)
