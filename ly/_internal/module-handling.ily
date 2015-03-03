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
#(define-void-function (parser location lib)(string?)
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
               (init-file-list (append root (list lib "__init__.ily")))
               (lib-init-file (join-unix-path init-file-list)))
          (if (file-exists? lib-init-file)
              (begin
               (ly:message "start registering library ~a" lib-init-file)
               (oll:log "initialize library \"~a\"" lib)
               (ly:parser-include-string parser
                 (format "\\sourcefilename \"~A\" \\sourcefileline 0\n~A"
                   lib (ly:gulp-file lib)))
               ;(ly:parser-include-string parser
               ;  (format "\\include \"~a\"" lib-init-file))
               ))))))

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
    ((root #{ \getOption global.root-path #})
     (module-path
      ;; Create a path to the module by converting each symbol to a string
      ;; while treating the first element separately and massaging its
      ;; value if it should be 'internal' (the underscore of the directory
      ;; name can't be part of a symbol list).
      (append
       (let ((lib-str (symbol->string (first path))))
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
      (join-unix-path
       (append
        root module-path)))
     (load-path
      (cond
       ((file-exists?(string-append module-basename ".ily"))
        (string-append module-basename ".ily"))
       ((file-exists? (string-append module-basename "/__main__.ily"))
        (string-append module-basename "/__main__.ily"))
       (else "")))
     ) ; end let* bindings
    (ly:message "load path: ~a" load-path)

    ;; try to load the file if it isn't already present
    (if (member load-path oll-loaded-modules)
        (oll:log "module ~a already loaded. Skipping." load-path)
        (if (file-exists? load-path)
            (begin
             (ly:message "Do actually load ~a" load-path)
             ;; first register/load the library
             ;             #{ \registerLibrary #lib #}
             if (not (member lib oll-loaded-libraries))
             (begin
              (oll:log "Registering library ~a" lib)
              (set! oll-loaded-libraries
                    (append oll-loaded-libraries
                      `(,lib)))
              (let* ((init-file-list (append root (list lib "__init__.ily")))
                     (lib-init-file (join-unix-path init-file-list)))
                (if (file-exists? lib-init-file)
                    (begin
                     (ly:message "start registering library ~a" lib-init-file)
                     (oll:log "initialize library \"~a\"" lib)
                     ;(ly:parser-include-string parser
                     ;  (format "\\sourcefilename \"~A\" \\sourcefileline 0\n~A"
                     ;    lib-init-file (ly:gulp-file lib-init-file)))
                     (ly:parser-include-string parser
                       (format "\\include \"~a\"" lib-init-file))
                     )))             ;; then load the requested module
              (oll:log "load module ~a" load-path)
              (ly:parser-include-string parser
                (format "\\sourcefilename \"~A\" \\sourcefileline 0\n~A"
                  load-path (ly:gulp-file load-path)))
              (set! oll-loaded-modules
                    (append! oll-loaded-modules `(,load-path))))
             (oll:warn "module not found: ~a" (join-dot-path module-path)))))))
