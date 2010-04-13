/**
 * @author vampas
 */
package org.ufsoft.dac.conversions {

  import net.zengrong.logging.Firebug;

  import flash.events.MouseEvent;
  import mx.containers.*;
  import mx.controls.*;
  import mx.core.Application;
  import mx.core.ScrollPolicy;
  import org.ufsoft.dac.conversions.Conversion;
  import org.ufsoft.dac.events.ConversionEvent;

  public class ConversionUI extends VBox {

      private var progressBar:ProgressBar;
      private var inName:Text;
      private var outName:Text;
      private var downloadButton:Button;

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

      // listeners
      Application.application.addEventListener(ConversionEvent.COMPLETE, conversionComplete);
      Application.application.addEventListener(ConversionEvent.UPDATED, conversionUpdated);
    }

    private function OnDownloadButtonClicked(event:Event):void{
      _conversion.download();
    }

    public function set conversion(value:Conversion):void {
      Firebug.debug("ConversionUI setting conversion", String(value));
      _conversion = value;
      inName.text = _conversion.filename;
      outName.text = _conversion.out_filename;
      downloadButton.enabled = _conversion.converted;
      progressBar.setProgress(_conversion.progress, 100);
    }

    public function get conversion():Conversion {
      Firebug.debug("ConversionUI getting conversion");
      return _conversion;
    }

    private function conversionComplete(event:ConversionEvent):void {
      if (event.conversion.id == _conversion.id ) {
        downloadButton.enabled = true;
      }
    }

    private function conversionUpdated(event:ConversionEvent):void {
      if (event.conversion.id == _conversion.id ) {
        Firebug.debug("ConversionUI.conversionUpdated", String(event));
        progressBar.setProgress(event.conversion.progress, 100);
        inName.text = _conversion.filename;
        outName.text = _conversion.out_filename;
        Firebug.debug("ConversionUI._conversion", String(_conversion));
      }
    }
  }
}
