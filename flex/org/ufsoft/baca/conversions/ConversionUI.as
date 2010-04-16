/**
 * @author vampas
 */
package org.ufsoft.baca.conversions {

  import org.osflash.thunderbolt.Logger;

  import flash.events.MouseEvent;
  import flash.net.FileReference;
  import flash.net.URLRequest;
  import mx.containers.*;
  import mx.controls.*;
  import mx.core.Application;
  import mx.core.ScrollPolicy;
  import mx.messaging.Consumer;
  import mx.messaging.events.MessageEvent;
  import mx.messaging.events.MessageFaultEvent;
  import org.ufsoft.baca.conversions.Conversion;

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
      topHBox.setStyle("paddingBottom","2");
      topHBox.setStyle("paddingTop","2");
      topHBox.setStyle("marginBottom","0");

      topHBox.percentWidth = 100;

      var inNameLabel:Text = new Text();
      inNameLabel.htmlText = "<b>IN:</b>";
      inNameLabel.setStyle("paddingRight","0");
      topHBox.addChild(inNameLabel)
      inName = new Text();
      inNameLabel.setStyle("paddingLeft","0");
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
      downloadButton.addEventListener(MouseEvent.CLICK, OnDownloadButtonClicked);

      this.addChild(topHBox);

      progressBar = new ProgressBar();
      progressBar.label = "";
      progressBar.mode = ProgressBarMode.MANUAL;
      progressBar.percentWidth = 100;
      progressBar.labelPlacement="right"
      this.addChild(progressBar);

      var bottomHBox:HBox = new HBox();
      bottomHBox.setStyle("paddingBottom","2");
      bottomHBox.setStyle("paddingTop","2");
      bottomHBox.setStyle("marginTop","0");

      var outNameLabel:Text = new Text();
      outNameLabel.htmlText = "<b>OUT:</b>";
      outNameLabel.setStyle("paddingRight","0");
      bottomHBox.addChild(outNameLabel);
      outName = new Text();
      outName.setStyle("paddingLeft","0");
      bottomHBox.addChild(outName);
      this.addChild(bottomHBox);
    }

    private function OnDownloadButtonClicked(event:Event):void{
      Logger.debug("Clicked. Downloading: ", _conversion);
      /* Set up the URL request to download the file specified by the FILE_URL variable. */
      var urlReq:URLRequest = new URLRequest(_conversion.url);

      /* Define file reference object and add a bunch of event listeners. */
      var fileRef:FileReference = new FileReference();
      fileRef.download(urlReq);
    }

    public function set conversion(value:Conversion):void {
      Logger.info("ConversionUI setting conversion", String(value));
      _conversion = value;
      if ( consumer == null && _conversion.converted != true ) {
        consumer = Application.application.getConsumer('conversions', String(_conversion.id));
        consumer.addEventListener(MessageEvent.MESSAGE, updatedConversionEvent);
        consumer.subscribe();
      }
      inName.htmlText = "<i>" + _conversion.filename + "</i>";
      outName.htmlText = "<i>" + _conversion.out_filename + "</i>";
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
