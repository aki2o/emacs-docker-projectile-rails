;;; docker-projectile-rails.el --- Let projectile-rails work under docker container

;; Copyright (C) 2017  Hiroaki Otsu

;; Author: Hiroaki Otsu <ootsuhiroaki@gmail.com>
;; Keywords: rails projectile docker
;; URL: https://github.com/aki2o/emacs-docker-projectile-rails
;; Version: 0.1.0
;; Package-Requires: ((projectile-rails "0.12.0") (docker "0.5.2"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; 
;; You'll be able to develop using projectile-rails when rails run under docker container.
;; 
;; For more infomation, see <https://github.com/aki2o/emacs-docker-projectile-rails/blob/master/README.md>

;;; Dependencies:
;; 
;; - projectile-rails.el ( see <https://github.com/asok/projectile-rails> )
;; - docker.el ( see <https://github.com/Silex/docker.el> )

;;; Installation:
;;
;; Put this to your load-path.
;; And put the following lines in your .emacs or site-start.el file.
;; 
;; (require 'docker-projectile-rails)
;; (docker-projectile-rails:activate)

;;; Configuration:
;; 
;; Nothing

;;; Customization:
;; 
;; [EVAL] (autodoc-document-lisp-buffer :type 'user-variable :prefix "docker-projectile-rails:" :docstring t)
;; 
;;  *** END auto-documentation

;;; API:
;; 
;; [EVAL] (autodoc-document-lisp-buffer :type 'macro :prefix "docker-projectile-rails:" :docstring t)
;; 
;;  *** END auto-documentation
;; [EVAL] (autodoc-document-lisp-buffer :type 'function :prefix "docker-projectile-rails:" :docstring t)
;; 
;;  *** END auto-documentation
;; [EVAL] (autodoc-document-lisp-buffer :type 'command :prefix "docker-projectile-rails:" :docstring t)
;; 
;;  *** END auto-documentation
;; [Note] Functions and variables other than listed above, Those specifications may be changed without notice.

;;; Tested On:
;; 
;; - Emacs ... GNU Emacs 24.5.1 (x86_64-apple-darwin14.5.0, NS apple-appkit-1348.17) of 2016-06-16 on 192.168.102.190
;; - docker ... Docker version 1.12.6, build 78d1802
;; - projectile-rails.el ... Version 0.12.0
;; - docker.el ... Version 0.5.2


;; Enjoy!!!


;;; Code:
(eval-when-compile (require 'cl))
(require 'projectile-rails)
(require 'docker-containers)
(require 'advice)

(defgroup docker-projectile-rails nil
  "Let projectile-rails work under docker container."
  :group 'convenience
  :prefix "docker-projectile-rails:")

(defcustom docker-projectile-rails:project-cache-file (concat user-emacs-directory ".docker-projectile-rails-project")
  "Filepath stores project configuration."
  :type 'string
  :group 'docker-projectile-rails)

(defcustom docker-projectile-rails:project-root-detect-function 'projectile-project-root
  "Function detect project root path for `current-buffer'."
  :type 'symbol
  :group 'docker-projectile-rails)


(defvar docker-projectile-rails:project-root nil)
(defvar docker-projectile-rails:project-cache-hash nil)


;;;;;;;;;;;
;; Cache

(defun docker-projectile-rails::project-cached-value (cache-name)
  (when docker-projectile-rails:project-root
    (plist-get (docker-projectile-rails::ensure-project-cache)
               cache-name)))

(defun docker-projectile-rails::ensure-project-cache ()
  (gethash docker-projectile-rails:project-root
           (or docker-projectile-rails:project-cache-hash
               (setq docker-projectile-rails:project-cache-hash
                     (or (docker-projectile-rails::load-project-cache-hash)
                         (make-hash-table :test 'equal))))))

(defun docker-projectile-rails::load-project-cache-hash ()
  (when (file-exists-p docker-projectile-rails:project-cache-file)
    (read (with-temp-buffer
            (insert-file-contents docker-projectile-rails:project-cache-file)
            (buffer-string)))))

(defun* docker-projectile-rails::store-project-cache (&key container)
  (when docker-projectile-rails:project-root
    (puthash docker-projectile-rails:project-root
             `(:container ,container)
             docker-projectile-rails:project-cache-hash)
    (with-temp-buffer
      (insert (prin1-to-string docker-projectile-rails:project-cache-hash))
      (write-file docker-projectile-rails:project-cache-file))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Config Docker Environment

(defun* docker-projectile-rails::select-container (&key (use-cache t))
  (or (when use-cache (docker-projectile-rails::project-cached-value :container))
      (let ((container (docker-read-container-name "Select Container: ")))
        (docker-projectile-rails::store-project-cache :container container)
        container)))

(defun docker-projectile-rails::collect-generators ()
  (let* ((container-name (docker-projectile-rails::select-container))
         (command (s-join " " `(,docker-command "exec" "-i" ,container-name "bundle" "exec" "rails" "g" "-h"))))
    (loop with generator-area = nil
          for line in (split-string (shell-command-to-string command) "\n")
          for line = (s-trim line)
          if (string= line "Please choose a generator below.")
          do (setq generator-area 1)
          else if (and generator-area
                       (not (string= line ""))
                       (not (string-match ":\\'" line)))
          collect `(,line . nil))))

;;;;;;;;;;;;
;; Advice

(defadvice projectile-rails--completion-in-region (around docker-projectile-rails:dockerrize disable)
  (let ((projectile-rails-generators (docker-projectile-rails::collect-generators)))
    ad-do-it))

(defadvice projectile-rails--generate-with-completion (after docker-projectile-rails:dockerrize disable)
  (let ((container-name (docker-projectile-rails::select-container)))
    (setq ad-return-value
          (format "%s exec -i %s %s" docker-command container-name ad-return-value))))

(defadvice rake--choose-command-prefix (after docker-projectile-rails:dockerrize activate)
  (let ((container-name (docker-projectile-rails::select-container)))
    (setq ad-return-value
          (format "%s exec -i %s %s" docker-command container-name ad-return-value))))


;;;;;;;;;;;;;;;;;;;
;; User Function

;;;###autoload
(defun docker-projectile-rails:activate ()
  "Activate docker-projectile-rails advices."
  (ad-enable-regexp "docker-projectile-rails:dockerrize")
  (ad-activate-regexp "docker-projectile-rails:dockerrize"))

;;;###autoload
(defun docker-projectile-rails:deactivate ()
  "Deactivate docker-projectile-rails advices."
  (ad-disable-regexp "docker-projectile-rails:dockerrize")
  (ad-deactivate-regexp "docker-projectile-rails:dockerrize"))

;;;###autoload
(defun docker-projectile-rails:configure-current-project ()
  "Configure project has `current-buffer'."
  (interactive)
  (let* ((docker-projectile-rails:project-root (or (when (functionp docker-projectile-rails:project-root-detect-function)
                                                     (funcall docker-projectile-rails:project-root-detect-function))
                                                   (error "Can't detect project root path for %s" (buffer-file-name))))
         (container (docker-projectile-rails::select-container)))
    (docker-projectile-rails::store-project-cache :container container)))


(provide 'docker-projectile-rails)
;;; docker-projectile-rails.el ends here
