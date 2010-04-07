/**
 * @author vampas
 */

package org.ufsoft.dac.renderers {
  import flash.events.MouseEvent;
  import mx.controls.Button;
  import flash.net.FileReference;
  import flash.net.URLRequest;

  import net.zengrong.logging.Firebug;

  public class DownloadButton extends Button {

    private var fileRef:FileReference;
    private var urlReq:URLRequest;

    public function DownloadButton():void {
      super();
      this.label = null;
      this.addEventListener(MouseEvent.CLICK, onMouseClick);
    }

    override public function validateDisplayList():void {
      if (super.data.progress >= 100) {
        this.enabled = true;
      } else {
        this.enabled = false;
      }
      super.validateDisplayList();
    }

    public function onMouseClick(event:MouseEvent):void {
      Firebug.debug("Download button clicked");
      urlReq = new URLRequest(super.data.url);
      fileRef = new FileReference();
      try {
        fileRef.download(urlReq);
      } catch (error:Error) {
        trace("Unable to download file.");
      }
    }
  }
}
