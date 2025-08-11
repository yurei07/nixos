{ pkgs, ... }:
{
  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style.name = "adwaita-dark";
  };

  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 20;
  };

  gtk = {
    enable = true;
    
    theme = {
      name = "Orchis-Purple-Dark";
      package = pkgs.orchis-theme;
    };

    cursorTheme = {
      name = "Bibata-Modern-Classic";
      size = 20;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-cursor-theme-name = "Bibata-Modern-Classic";
    };
    
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

    xdg.configFile = {
    "gtk-3.0/gtk.css".text = ''
      @define-color base      #161318;
      @define-color mantle    #1c1720;
      @define-color crust     #0f0c12;
      @define-color text      #E6E1FF;
      @define-color subtext   #CFC7E8;
      @define-color mauve     #BFA7FF;   
      @define-color blue      #6E5CF0;
      @define-color teal      #4AAE9C;
      @define-color red       #D84A6D;
      @define-color yellow    #D8B064;
      @define-color green     #6BBF85;
      @define-color peach     #E98A6A;
      @define-color overlay0  #645983;
      @define-color surface2  #2B2740;

      /* Основной фон/текст */
      window, .window, .dialog, .popover {
        background-color: @base;
        color: @text;
      }

      headerbar, .header-bar {
        background-color: @mantle;
        color: @text;
      }

      /* Кнопки: активные / отмеченные */
      button:active, button:checked,
      .button:active, .button:checked {
        background-image: none;
        background-color: @mauve;
        color: @base;
      }

      /* Поля ввода, текстовые области */
      entry, textview, .entry, .textview {
        background-color: @crust;
        color: @text;
        border-radius: 6px;
      }

      /* Выделение текста */
      entry selection, textview selection,
      .entry selection, .textview selection {
        background-color: @mauve;
        color: @base;
      }

      /* Scrollbar slider (ползунок) */
      scrollbar slider {
        background-color: rgba(191,167,255,0.18); /* mauve с прозрачностью */
        border-radius: 6px;
      }

      /* Tooltip */
      tooltip {
        background-color: @overlay0;
        color: @text;
      }

      /* Акцентные элементы (например, активная вкладка/табы) */
      .notebook tab:selected, .notebook tab:active {
        background-color: @mauve;
        color: @base;
      }
    '';

    "gtk-4.0/gtk.css".text = ''
      /* Та же палитра для GTK4 */
      @define-color base      #161318;
      @define-color mantle    #1c1720;
      @define-color crust     #0f0c12;
      @define-color text      #E6E1FF;
      @define-color subtext   #CFC7E8;
      @define-color mauve     #BFA7FF;
      @define-color blue      #6E5CF0;
      @define-color teal      #4AAE9C;
      @define-color red       #D84A6D;
      @define-color yellow    #D8B064;
      @define-color green     #6BBF85;
      @define-color peach     #E98A6A;
      @define-color overlay0  #645983;
      @define-color surface2  #2B2740;

      /* Фон и текст */
      window, dialog, popover {
        background-color: @base;
        color: @text;
      }

      headerbar, .header-bar {
        background-color: @mantle;
        color: @text;
      }

      button:checked, button:active, .button:checked, .button:active {
        background: @mauve;
        color: @base;
      }

      entry, textview, .entry, .textview {
        background-color: @crust;
        color: @text;
      }

      entry selection, textview selection, .entry selection, .textview selection {
        background-color: @mauve;
        color: @base;
      }

      scrollbar slider {
        background-color: rgba(191,167,255,0.18); /* mauve + alpha */
        border-radius: 6px;
      }

      tooltip {
        background-color: @overlay0;
        color: @text;
      }

      notebook tab:selected, notebook tab:active {
        background-color: @mauve;
        color: @base;
      }
    '';
  };
}
