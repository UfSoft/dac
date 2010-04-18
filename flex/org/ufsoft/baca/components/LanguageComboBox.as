/**
 * @author vampas
 */
package org.ufsoft.baca.components {

  import mx.core.Application;
  import mx.controls.ComboBox;
  import mx.collections.ArrayCollection;
  import mx.collections.ItemResponder;
  import mx.events.ListEvent;

  import mx.rpc.AsyncToken;
  import mx.rpc.events.ResultEvent;
  import mx.rpc.events.FaultEvent;

  import org.osflash.thunderbolt.Logger;

  import org.ufsoft.baca.i18n.*;

  public class LanguageComboBox extends ComboBox {

    private var locale:   Locale = Locale.getInstance();

    [Bindable]
    private var languages:ArrayCollection = new ArrayCollection();


    public function LanguageComboBox() {
      super();
      this.labelField = 'display_name';
      this.dataProvider = languages;
      this.addEventListener(ListEvent.CHANGE, selectionChanged);
      locale.addEventListener(TranslationEvent.LOADED, onTranslationLoadedEvent);

      var token:AsyncToken = Application.application.getRemoteService().get_languages();
      //Logger.info("Adding Token Responder", token);
      token.addResponder(new ItemResponder(gotLanguages, failedToGetLanguages, token));
    }

    private function gotLanguages(event:ResultEvent, token:AsyncToken):void {
      languages = event.result as ArrayCollection;
      this.dataProvider = languages;
      var current_locale:String = Application.application.locale.getLocale();
      Logger.info("Got Languages. Current Locale:", current_locale, 'Languages', languages);
      for each ( var language:Language in languages ) {
        if ( language.locale == current_locale) {
          this.selectedItem = language;
          break;
        }
      }
    }

    private function failedToGetLanguages(event:FaultEvent, token:AsyncToken):void {
      Logger.error("Failed to get Languages", event);
    }

    private function onTranslationLoadedEvent(event:TranslationEvent):void {
      for each ( var language:Language in languages ) {
        if ( language.locale == event.locale) {
          this.selectedItem = language;
          break;
        }
      }
    }

    private function selectionChanged(event:ListEvent):void {
      locale.load(this.selectedItem.locale);
    }
  }

}
