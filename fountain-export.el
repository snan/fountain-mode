;;; fountain-export.el --- Export engine for Fountain Mode

;; Copyright (C) 2014  Paul Rankin

;; Author: Paul Rankin <paul@tilk.co>
;; Keywords: wp

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; 

;;; Code:

(defgroup fountain-export ()
  "Options for exporting Fountain files."
  :prefix 'fountain-export-
  :group 'fountain)

;;; customizable variables =============================================

(defcustom fountain-export-buffer
  "*Fountain Export*"
  "Buffer name to use when not exporting a file."
  :type 'string
  :group 'fountain-export)

(defcustom fountain-export-temp-buffer
  "*Fountain Temp Buffer*"
  "Buffer name to use for temporary export work."
  :type 'string
  :group 'fountain-export)

(defcustom fountain-export-pdf-process-buffer
  "*Fountain PDF Process*"
  "Buffer name to use for PDF conversion messages."
  :type 'string
  :group 'fountain-export)

(defcustom fountain-export-default-command
  'fountain-export-buffer-to-pdf-via-html
  "\\<fountain-mode-map>Default function to call with \\[fountain-export-default]."
  :type '(radio (function-item fountain-export-buffer-to-pdf-via-html)
                (function-item fountain-export-buffer-to-html))
  :group 'fountain-export)

(defcustom fountain-export-inline-style nil
  "If non-nil, use inline styles.
Otherwise, use an external stylesheet file."
  :type 'boolean
  :group 'fountain-export)

(defcustom fountain-export-page-size
  "us-letter"
  "Paper size to use on export."
  :type '(radio (string :tag "US Letter" "us-letter")
                (string :tag "A4" "a4"))
  :group 'fountain-export)

(defcustom fountain-export-font
  '("Courier"
    "Courier New")
  "List of font names to use when exporting, by priority."
  :type '(repeat (string :tag "Font"))
  :group 'fountain-export)

(defcustom fountain-export-bold-scene-headings nil
  "If non-nil, bold scene headings on export."
  :type 'boolean
  :group 'fountain-export)

(defcustom fountain-export-underline-scene-headings nil
  "If non-nil, underline scene headings on export."
  :type 'boolean
  :group 'fountain-export)

(defcustom fountain-export-double-space-scene-headings nil
  "If non-nil, double space before scene headings on export."
  :type 'boolean
  :group 'fountain-export)

(defcustom fountain-export-prepare-html nil
  "If non-nil, auto-indent HTML elements during export.
This if off by default because it can take a long time for a
minimal benefit."
  :type 'boolean
  :group 'fountain-export)

(defcustom fountain-export-convert-quotes nil
  "If non-nil, replace TeX-style quotes with \"smart-quotes\".

\`\`foobar\'\'

will be exported as

&ldquo;foobar&rdquol;"
  :type 'boolean
  :group 'fountain-export)

(defcustom fountain-export-pdf-via-html-command
  "prince %s --verbose"
  "Shell command string to convert HTML file to PDF."
  :type 'string
  :group 'fountain-export)

(defcustom fountain-export-style-template
  "@page {
    size: ${page-size};
    margin-top: 1in;
    margin-right: 1in;
    margin-bottom: 0.5in;
    margin-left: 1.5in;
}

#title_page {
    page: title;
}

#screenplay {
    counter-reset: page 1;
    page: screenplay;
    prince-page-group: start;
}

@page screenplay {
    @top-right-corner {
        font-family: ${font};
        font-size: 12pt;
        content: counter(page)\".\";
        vertical-align: bottom;
        padding-bottom: 1em;
    }
}

@page screenplay:first {
    @top-right-corner {
        content: normal;
    }
    @top-left {
        content: normal;
    }
}

h1,h2,h3,h4,h5,h6 {
    font-weight: normal;
    font-size: 12pt;
}

body {
    font-family: ${font};
    font-size: 12pt;
    line-height: 1;
}

em {
    font-style: italic;
}

strong {
    font-weight: bold;
}

span.underline {
    text-decoration: underline;
}

.strikethrough {
    text-line-through-style: solid;
}

.page-break {
    page-break-after: always;
}

h2, h3, h4, h5, h6 {
    prince-bookmark-level: none;
}

#screenplay {
    width: 6in;
    margin: 0 auto;
}

.centered {
    text-align: center;
    margin-left: 0;
    width: 100%;
}

p {
    margin-top: 1em;
    margin-bottom: 1em;
    margin-left: 0;
    width: auto;
    orphans: 2;
    widows: 2;
}

.scene-heading {
    font-weight: ${scene-bold};
    text-decoration: ${scene-underline};
    margin-top: ${scene-spacing};
    page-break-after: avoid;
}

.action {
    page-break-inside: avoid;
}

.character {
    margin-bottom: 0;
    margin-left: 2in;
    width: 4in;
    page-break-after: avoid;
}

.paren {
    margin-top: 0;
    margin-bottom: 0;
    margin-left: 1.6in;
    text-indent: -0.6em;
    width: 2in;
    page-break-before: avoid;
    page-break-inside: avoid;
    page-break-after: avoid;
}

.dialog {
    margin-top: 0;
    margin-bottom: 0;
    margin-left: 1in;
    width: 3.5in;
    page-break-before: avoid;
    page-break-inside: avoid;
}

.trans {
    margin-top: 1em;
    margin-bottom: 1em;
    margin-left: 4in;
    width: 2in;
    page-break-before: avoid;
}

.note {
    display: none
}

.section {
    display: none;
}

.synopsis {
    display: none;
}"
  "Styles template for exporting to HTML, and PDF via HTML."
  :type 'string
  :group 'fountain-export)

(defcustom fountain-export-html-head-template
  "<!DOCTYPE html>
<!-- Created with Emacs ${emacs-version} running Fountain Mode ${fountain-version} -->
<html>
<head>
"
  "HTML template inserted into export buffer.
See `fountain-export-format-template'."
  :type 'string
  :group 'fountain-export)

;;; internal functions =================================================

(defun fountain-export-fontify-buffer ()
  "If `font-lock-mode' is enables, fontify entire buffer."
  (if font-lock-mode
      (let ((font-lock-maximum-decoration t)
            (job (make-progress-reporter "Fontifying..." 0 100))
            (chunk (/ (buffer-size) 100))
            (n 0))
        (font-lock-refresh-defaults)
        (goto-char (point-min))
        (while (not (eobp))
          (let ((limit (+ (point) chunk)))
            (jit-lock-fontify-now (point) limit)
            (goto-char limit)
            (progress-reporter-update job n)
            (setq n (+ n 1))))
        (progress-reporter-done job))
    (error "Font Lock is not active")))

(defun fountain-export-strip-comments (&optional buffer)
  "Strips BUFFER of all text with `fountain-comment' face."
  (with-current-buffer (or buffer (current-buffer))
    (goto-char (point-min))
    (while (null (eobp))
      (if (eq (face-at-point) 'fountain-comment)
          (let ((m (point)))
            (goto-char (next-single-property-change
                        (point) 'face nil (point-max)))
            (delete-region m (point)))
        (goto-char (next-single-property-change
                    (point) 'face nil (point-max)))))))

(defun fountain-export-get-name (buffer ext)
  "If BUFFER is visiting a file, concat file name base and EXT.
Otherwise return `fountain-export-buffer'"
  (if (buffer-file-name buffer)
      (concat (file-name-base (buffer-file-name buffer)) ext)
    fountain-export-buffer))

(defun fountain-export-underline (s)
  "Replace underlined text in S with HTML underline span tags."
  (replace-regexp-in-string "_\\(.+\\)_"
                            "<span class=\"underline\">\\1</span>"
                            s t))

(defun fountain-export-bold (s)
  "Replace bold text in S with HTML strong tags."
  (replace-regexp-in-string "\\*\\*\\(.+\\)\\*\\*"
                            "<strong>\\1</strong>"
                            s t))

(defun fountain-export-italic (s)
  "Replace italic text in S with HTML italic tags."
  (replace-regexp-in-string "\\*\\(.+\\)\\*"
                            "<em>\\1</em>"
                            s t))

(defun fountain-export-filter (s)
  "Escape special characters and replace newlines."
  (let* ((s (s-replace-all '(("&" . "&amp;")
                             ("<" . "&lt;")
                             (">" . "&gt;")
                             ("\\\s" . "&nbsp;")
                             ("\\\-" . "&#8209;")
                             ("\\_" . "&#95;")
                             ("\\*" . "&#42;")
                             ("\n" . "<br>")) s))
         (s (if fountain-export-convert-quotes
                (s-replace-all '(("\\`" . "&#96;")
                                 ("\\'" . "&apos;")
                                 ("``" . "&ldquo;")
                                 ("''" . "&rdquo;")
                                 ("`" . "&lsquo;")
                                 ("'" . "&rsquo;")) s)
              s)))
    s))

(defun fountain-export-create-html-element (substring)
  "Return a HTML element with face and substring of SUBSTRING.
Stylesheet class is taken from face, while content is taken from
of SUBSTRING.

If face is `fountain-comment', return nil."
  (let* ((class
          (if (get-text-property 0 'face substring)
              (let* ((s (symbol-name (get-text-property 0 'face substring)))
                     (s (s-chop-suffix "-highlight" s))
                     (s (s-chop-prefix "fountain-" s))) s)
            "action"))
         (tag (cond ((string= class "scene-heading")
                     "h2")
                    ((string= class "character")
                     "h3")
                    ("p")))
         (content
          (let* ((s (substring-no-properties substring))
                 (s (fountain-export-filter s))
                 (s (fountain-export-bold s))
                 (s (fountain-export-italic s))
                 (s (fountain-export-underline s)))
            s)))
    (format "<%s class=\"%s\">%s</%s>\n"
            tag class content tag)))

(defun fountain-export-format-template (template sourcebuf)
  "Format TEMPLATE according to the following list.

Internal function, will not work outside of
`fountain-export-html'."
  (let ((htmlfile (fountain-export-get-name sourcebuf ".html"))
        (cssfile (fountain-export-get-name sourcebuf ".css"))
        (page-size fountain-export-page-size)
        (font
         (let (list)
           (dolist (font fountain-export-font (s-join "," list))
             (setq list
                   (append list
                           (list (concat "'" font "'")))))))
        (scene-bold
         (if fountain-export-bold-scene-headings
             "bold" "normal"))
        (scene-underline
         (if fountain-export-underline-scene-headings
             "underline" "none"))
        (scene-spacing
         (if fountain-export-double-space-scene-headings
             "2em" "1em")))
    (s-format template 'aget
              `(("fountain-version" . ,fountain-version)
                ("emacs-version" . ,emacs-version)
                ("htmlfile" . ,htmlfile)
                ("cssfile" . ,cssfile)
                ("page-size" . ,page-size)
                ("font" . ,font)
                ("scene-bold" . ,scene-bold)
                ("scene-underline" . ,scene-underline)
                ("scene-spacing" . ,scene-spacing)))))

(defun fountain-export-parse-buffer (destbuf &optional buffer)
  "Find face changes in BUFFER then insert elements into DESTBUF.
First, find the next face property change from point, then pass
substring between point and change to
`fountain-export-create-html-element', then insert the newly
created HTML element to DESTBUF."
  (let ((job (make-progress-reporter "Parsing..." 0 100)))
    (with-current-buffer (or buffer (current-buffer))
      (goto-char (point-min))
      (while (null (eobp))
        (skip-chars-forward "\n")
        (let* ((index (point))
               (limit (save-excursion
                        (re-search-forward "\n\s?\n\\|\\'" nil t)
                        (match-beginning 0)))
               (change (next-single-property-change index 'face nil limit)))
          (when change
            (let* ((s (buffer-substring index change))
                   (element (fountain-export-create-html-element s)))
              (when element
                (with-current-buffer destbuf
                  (with-silent-modifications
                    (insert element)))))
            (goto-char change)))
        ;; (unless (looking-at ".\\|\\'")
        ;;   (forward-char 1))
        (progress-reporter-update
         job (truncate (* (/ (float (point)) (buffer-size)) 100)))))))

(defun fountain-export-prepare-html ()
  ;; internal function, don't call externally
  (sgml-mode)
  (let ((sgml-unclosed-tags '("link" "br"))
        (job (make-progress-reporter "Preparing HTML..." 0 100)))
    (goto-char (point-min))
    (while (null (eobp))
      (indent-according-to-mode)
      (forward-line 1)
      (progress-reporter-update
       job (truncate (* (/ (float (point)) (point-max)) 100))))
    (progress-reporter-done job)))

(defun fountain-export-html-1 ()
  ;; internal function, don't call externally
  ;; use `fountain-export-buffer-to-html' instead
  (let* ((sourcebuf (current-buffer))
         (tempbuf (get-buffer-create
                   fountain-export-temp-buffer))
         (destbuf (get-buffer-create
                   (fountain-export-get-name sourcebuf ".html")))
         complete)
    (unwind-protect
        (progn
          ;; fontify the buffer
          (fountain-export-fontify-buffer)
          ;; create a temp buffer with source stripped comments
          (with-current-buffer tempbuf
            (erase-buffer)
            (insert-buffer-substring sourcebuf)
            (fountain-export-strip-comments))
          ;; insert HTML head
          (with-current-buffer destbuf
            (with-silent-modifications
              (erase-buffer)
              (insert (fountain-export-format-template
                       fountain-export-html-head-template sourcebuf))
              ;; (if fountain-export-inline-style
              (insert "<style type=\"text/css\">"
                      (fountain-export-format-template
                       fountain-export-style-template sourcebuf)
                      "</style>")
              ;; close head and open body
              (insert "</head>\n<body>\n")
              (insert "<div id=\"screenplay\">\n")))
          ;; parse the temp buffer
          (fountain-export-parse-buffer destbuf tempbuf)
          ;; close HTML tags
          (with-current-buffer destbuf
            (with-silent-modifications
              (insert "</div>\n</body>\n</html>")
              (if fountain-export-prepare-html
                  (fountain-export-prepare-html))))
          ;; signal completion and kill buffers
          (font-lock-refresh-defaults)
          (kill-buffer tempbuf)
          (setq complete t)
          destbuf)
      ;; if errors occur, kill the unsaved buffer
      (unless complete
        (kill-buffer destbuf)))))

;;; Menu Functions =====================================================

(defun fountain-toggle-export-bold-scene-headings ()
  "Toggle `fountain-export-bold-scene-headings'"
  (interactive)
  (setq fountain-export-bold-scene-headings
        (null fountain-export-bold-scene-headings))
  (message "Scene headings will now export %s"
           (if fountain-export-bold-scene-headings
               "bold" "normal")))

(defun fountain-toggle-export-underline-scene-headings ()
  "Toggle `fountain-export-underline-scene-headings'"
  (interactive)
  (setq fountain-export-underline-scene-headings
        (null fountain-export-underline-scene-headings))
  (message "Scene headings will now export %s"
           (if fountain-export-underline-scene-headings
               "underlined" "normal")))

(defun fountain-toggle-export-double-space-scene-headings ()
  "Toggle `fountain-export-double-space-scene-headings'"
  (interactive)
  (setq fountain-export-double-space-scene-headings
        (null fountain-export-double-space-scene-headings))
  (message "Scene headings will now export %s"
           (if fountain-export-double-space-scene-headings
               "double-spaced" "single-spaced")))

;;; Interactive Functions ==============================================

(defun fountain-export-default ()
  "Call the function defined in `fountain-export-default-command'"
  (interactive)
  (funcall fountain-export-default-command))

(defun fountain-export-buffer-to-html (&optional buffer)
  "Export BUFFER to HTML file, then switch to HTML buffer."
  (interactive)
  (with-current-buffer
      (or buffer (current-buffer))
    (save-excursion
      (save-restriction
        (widen)
        (let ((destbuf (fountain-export-html-1))
              (outputdir (if (buffer-file-name buffer)
                             (expand-file-name (file-name-directory
                                                (buffer-file-name
                                                 buffer))))))
          (with-current-buffer destbuf
            (if outputdir
                (write-file outputdir)))
          (if (called-interactively-p 'interactive)
              (switch-to-buffer-other-window destbuf))
          destbuf)))))

(defun fountain-export-buffer-to-pdf-via-html (&optional buffer)
  "Export BUFFER to HTML file, then convert HTML to PDF."
  (interactive)
  (let* ((buffer (or buffer (current-buffer)))
         (file (shell-quote-argument (buffer-file-name (fountain-export-buffer-to-html
                                                        buffer))))
         (command (format fountain-export-pdf-via-html-command file)))
    (async-shell-command command fountain-export-pdf-process-buffer)))

(defun fountain-export-region-to-html (start end)
  "Export the region to HTML file, then switch to HTML buffer."
  (interactive "r")
  (save-excursion
    (let ((destbuf (save-restriction
                     (narrow-to-region start end)
                     (fountain-export-html-1)))
          (outputdir (if (buffer-file-name)
                         (expand-file-name (file-name-directory
                                            (buffer-file-name))))))
      (with-current-buffer destbuf
        (if outputdir
            (write-file outputdir t)))
      (switch-to-buffer-other-window destbuf)
      destbuf)))

(provide 'fountain-export)
;;; fountain-export.el ends here
