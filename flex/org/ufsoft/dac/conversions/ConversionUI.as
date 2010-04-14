/**
 * @author vampas
 */
package org.ufsoft.dac.conversions {

  import org.osflash.thunderbolt.Logger;

  import flash.events.MouseEvent;
  import mx.containers.*;
  import mx.controls.*;
  import mx.core.Application;
  import mx.core.ScrollPolicy;
  import mx.messaging.Consumer;
  import mx.messaging.events.MessageEvent;
  import mx.messaging.events.MessageFaultEvent;
  import org.ufsoft.dac.conversions.Conversion;

  public class ConversionUI extends VBox {

      private var progressBar:ProgressBar;
      private var inName:Text;
      private var outName:Text;
      private var downloadButton:Button;
      private var consumer:Consumer;

      protected var _conversion:Conversion;

      [Embed(source='/assets/disk.png')]
      [Bindable] private var enabledIcon:Class;
      [Embed(source='/assets/disk-grey.png')]
      [Bindable] private var disabledIcon:Class;

    public function ConversionUI() {
      super()

      // set styles
      setStyle("backgroundColor","#eeeeee");
      setStyle("paddingBottom","10");
      setStyle("paddingTop","10");
      setStyle("paddingLeft","10");
      setStyle("paddingRight","10");
      this.percentWidth = 100;
      verticalScrollPolicy = ScrollPolicy.OFF;
      horizontalScrollPolicy = ScrollPolicy.OFF;

      // add controls

      var topHBox:HBox = new HBox();
      topHBox.percentWidth = 100;

      inName = new Text()
      topHBox.addChild(inName)

      var spacer:Spacer = new Spacer();
      spacer.percentWidth = 100;
      topHBox.addChild(spacer);

      downloadButton = new Button();
      downloadButton.setStyle("icon", enabledIcon);
      downloadButton.setStyle("disabledIcon", disabledIcon);
      downloadButton.toolTip = "Download";
      downloadButton.enabled = false;
      topHBox.addChild(downloadButton);
      downloadButton.addEventListener(MouseEvent.CLICK,OnDownloadButtonClicked);

      this.addChild(topHBox);

      progressBar = new ProgressBar();
      progressBar.label = "";
      progressBar.mode = ProgressBarMode.MANUAL;
      progressBar.percentWidth = 100;
      progressBar.labelPlacement="right"
      this.addChild(progressBar);

      outName = new Text();
      this.addChild(outName);
    }

    private function OnDownloadButtonClicked(event:Event):void{
      _conversion.download();
    }

    public function set conversion(value:Conversion):void {
      Logger.info("ConversionUI setting conversion", String(value));
      _conversion = value;
      if ( consumer == null && _conversion.converted != true ) {
        consumer = Application.application.getConsumer('conversions', String(_conversion.id));
        consumer.addEventListener(MessageEvent.MESSAGE, updatedConversionEvent);
        consumer.subscribe();
      }
      inName.text = _conversion.filename;
      outName.text = _conversion.out_filename;
      downloadButton.enabled = _conversion.converted;
      progressBar.setProgress(_conversion.progress, 100);

    }

    public function get conversion():Conversion {
      Logger.info("ConversionUI getting conversion");
      return _conversion;
    }

    private function updatedConversionEvent(event:MessageEvent):void {
      Logger.info("ConversionUI.updatedConversionEvent", event.message);
      var conversion:Conversion = event.message.body as Conversion;
      _conversion = conversion;
      progressBar.setProgress(_conversion.progress, 100);
      downloadButton.enabled = _conversion.converted;
      if ( _conversion.converted ) {
        downloadButton.enabled = true;
        consumer.unsubscribe();
      }
    }
  }
}
