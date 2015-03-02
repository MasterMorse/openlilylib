%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
% This file is part of openLilyLib,                                           %
%                      ===========                                            %
% the community library project for GNU LilyPond                              %
% (https://github.com/openlilylib/openlilylib                                 %
%              -----------                                                    %
%                                                                             %
% openLilyLib is free software: you can redistribute it and/or modify         %
% it under the terms of the GNU General Public License as published by        %
% the Free Software Foundation, either version 3 of the License, or           %
% (at your option) any later version.                                         %
%                                                                             %
% openLilyLib is distributed in the hope that it will be useful,              %
% but WITHOUT ANY WARRANTY; without even the implied warranty of              %
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the               %
% GNU General Public License for more details.                                %
%                                                                             %
% You should have received a copy of the GNU General Public License           %
% along with openLilyLib. If not, see <http://www.gnu.org/licenses/>.         %
%                                                                             %
% openLilyLib is maintained by Urs Liska, ul@openlilylib.org                  %
% and others.                                                                 %
%       Copyright Urs Liska, 2015                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Maintain a list of already loaded modules.
% Modules are only loaded once to avoid potentially expensive re-parsing
#(define oll-loaded-libraries '())
#(define oll-loaded-modules '())


% Conditionally register and load a library when
% for the first time a module from that library is requested.
registerLibrary =
#(define-void-function (parser location lib)
   (string?)
   "Register a library with the configuration system
    if it hasn't been already loaded.
    If the library has an __init__.ily file
    this is loaded (library initialized) too."
   (if (not (member lib oll-loaded-libraries))
       (begin
        (oll:log "Registering library ~a" lib)
        (set! oll-loaded-libraries
              (append oll-loaded-libraries
                `(,lib)))
        (let* ((root #{ \getOption global.root-path #})
               (lib-init-file (string-join
                               `(,root ,lib "__init__.ily") "/")))
          (if (file-exists? lib-init-file)
              (begin
               (oll:log "initialize library \"~a\"" lib)
               (ly:parser-include-string parser
                 (format "\\include \"~a\"" lib-init-file))))))))

% Load module from an openLilyLib library
% A module may be an individual file or a whole library, this can also be
% designed by the individual library.
% The string argument to be given is the path to the module, starting from
% the root directory of openLilyLib. It can be either an actual file or a
% directory name indicating the module (the check is whether the last item
% contains a dot in its name). If there's no dot in the last element of the
% path we assume it is a directory and try to load a file "__main__.ily"
% inside that directory.
loadModule =
#(define-void-function (parser location path)(symbol-list?)
   "Load an openLilyLib module if it has not been already loaded."
   (let*
    ((module-path
      (append
       (let ((lib-str (symbol->string (first path))))
         (ly:message (format "lib-str: ~a" lib-str))
         (if (string=? "internal" lib-str)
             (list "_internal")
             (list lib-str)))
       (map
        (lambda (p)
          (symbol->string p))
        (cdr path))))
     (lib (first module-path))
     (module-name (last module-path))
     (module-basename
      (string-append
       #{ \getOption global.root-path #}
       (join-unix-path module-path)))
     (load-path
      (cond ((file-exists? (string-append module-basename ".ily"))
             (string-append module-basename ".ily"))
        ((file-exists? (string-append module-basename ".scm"))
         load-path)
        ((file-exists? (string-append module-basename "/__main__.ily"))
         (string-append module-basename "/__main__.ily"))
        (else '())))

     )
    (ly:message (format "Path: ~a" path))
    (ly:message (format "Lib: ~a" lib))
    (ly:message (format "module-path: ~a" module-path))
    (ly:message (format "module-basename: ~a" module-basename))
    (ly:message (format "load-path: ~a" load-path))
    (cond
     ((null? load-path)
      (oll:warn "module not found: ~a" path))
     ((member module-path oll-loaded-modules)
      (oll:log "module ~a already loaded. Skipping." load-path))
     ((list? load-path)
      (oll:warn "Loading of Scheme modules not supported yet. Requested: ~a" module-path))
     ((string? load-path)
      (begin
       (ly:message (format "try loading ~a" load-path))
       ;; first register/load the library
       #{ \registerLibrary #lib #}
       ;; then load the requested module
       (oll:log "load module ~a" path)
       (ly:parser-include-string parser
         (format "\\include \"~a\"" load-path))
       ;; finally add to loaded modulex
       (set! oll-loaded-modules
             (append! oll-loaded-modules `(,module-path))))))))

%{

      ;; try to load the file if it isn't already present
      (if (member module-path oll-loaded-modules)
          (oll:log "module ~a already loaded. Skipping." load-path)
          (if (file-exists? load-path)
              (begin
               ;(oll:log "Registering library ~a" (first path-list))
               ;; first register/load the library
               #{ \registerLibrary #(first path-list) #}
               ;; then load the requested module
               (oll:log "load module ~a" load-path)
               (ly:parser-include-string parser
                 (format "\\include \"~a\"" load-path))
               (set! oll-loaded-modules
                     (append! oll-loaded-modules `(,load-path))))
              (oll:warn "module not found: ~a" load-path)))))

%}