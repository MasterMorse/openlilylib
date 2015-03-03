

% Shared variable that can hold any number of break sets.
% Selecting one set to apply makes it possible to manage different
% break sets, e.g. corresponding to different manuscripts
\registerOption comptools.break-sets #'()

#(ly:message "This is the comptools library init.")

% Register a named set of breaks that can be referenced later
registerBreakSet =
   #(define-void-function (parser location name)
   (symbol?)
   (let ((base-path `(comptools break-sets ,name)))
     #{ \setChildOption #base-path #'line-breaks #'() #}
     #{ \setChildOption #base-path #'page-breaks #'() #}
     #{ \setChildOption #base-path #'page-turns #'() #}))

setConditionalBreaks =
#(define-void-function (parser location set type breaks)
   (symbol? symbol? list?)
   #{ \setChildOption #`(comptools break-sets ,set) #type #breaks #})

