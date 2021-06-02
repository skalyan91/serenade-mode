
(defvar serenade-builtin-command-map 
  (ht( "press" nil  ) 
     ( "close tab" 'delete-window  ) 
     ( "save" 'save-buffer  ) 
     ( "create tab" 'split-window-right-and-focus  ) 
     ( "next tab" 'next-buffer  ) 
     ( "previous tab" 'previous-buffer) 
     ( "switch tab" nil  ) 
     ( "open file list" 'spacemacs-layouts/non-restricted-buffer-list-helm) 
     ( "open file" nil  ) 
     ( "undo" 'undo  ) 
     ( "redo" 'redo  ) 
     ( "scroll" 'zz-scroll-half-page-down  ) 
     ( "style" nil) 
     ( "go to definition" 'spacemacs/jump-to-definition  ) 
     ( "debugger toggle breakpoint" nil) 
     ( "debugger start" nil  ) 
     ( "debugger pause" nil  ) 
     ( "debugger stop" nil  ) 
     ( "debugger show hover" nil) 
     ( "debugger continue" nil  ) 
     ( "debugger step into" nil  ) 
     ( "debugger step over" nil) 
     ( "debugger inline breakpoint" nil)  ))



(provide 'serenade-builtin-commands)
