package org.ufsoft.dac.components.uploads
{
  import mx.containers.*;
  import mx.controls.*;
  import mx.rpc.events.AbstractEvent;
  import flash.net.FileReference;
  import flash.events.*;
  import flash.net.URLRequest;
  import mx.events.FlexEvent;
  import mx.core.ScrollPolicy;

  public class FileUpload extends VBox
  {
    private var bar:ProgressBar;
    private var _file:FileReference;
    private var nameText:Text;
    private var _uploaded:Boolean;
    private var _uploading:Boolean;
    private var _bytesUploaded:uint;
    private var _uploadUrl:String;
    private var button:Button;

    // constructor
    public function FileUpload(file:FileReference,uploadUrl:String)
    {
      super();
      // initialize variables
      _file = file;
      _uploadUrl = uploadUrl;
      _uploaded = false;
      _uploading = false;
      _bytesUploaded = 0;

      // set styles
      setStyle("backgroundColor","#eeeeee");
      setStyle("paddingBottom","10");
      setStyle("paddingTop","10");
      setStyle("paddingLeft","10");
      verticalScrollPolicy = ScrollPolicy.OFF;

      // set event listeners
      _file.addEventListener(Event.COMPLETE,OnUploadComplete);
      _file.addEventListener(ProgressEvent.PROGRESS,OnUploadProgressChanged);
      _file.addEventListener(HTTPStatusEvent.HTTP_STATUS,OnHttpError);
      _file.addEventListener(IOErrorEvent.IO_ERROR,OnIOError);
      _file.addEventListener(SecurityErrorEvent.SECURITY_ERROR,OnSecurityError);

      // add controls
      var hbox:HBox = new HBox();

      nameText = new Text();
      nameText.text = _file.name + "-" + FormatSize(_file.size);

      this.addChild(nameText);

      bar = new ProgressBar();
      bar.mode = ProgressBarMode.MANUAL;
      bar.label = "Uploaded 0%";
      bar.width = 275;
      hbox.addChild(bar);

      button = new Button();
      button.label = "Remove";

      hbox.addChild(button);
      button.addEventListener(MouseEvent.CLICK,OnRemoveButtonClicked);
      this.addChild(hbox);
    }
    private function OnRemoveButtonClicked(event:Event):void{
      if(_uploading)
        _file.cancel();
      this.dispatchEvent(new FileUploadEvent(this,"FileRemoved"));
    }

    private function OnUploadComplete(event:Event):void{
      _uploading = false;
      _uploaded = true;
      this.dispatchEvent(new FileUploadEvent(this,"UploadComplete"));
    }

    private function OnHttpError(event:HTTPStatusEvent):void{
      this.dispatchEvent(event);
    }

    private function OnIOError(event:IOErrorEvent):void{
      this.dispatchEvent(event);
    }

    private function OnSecurityError(event:SecurityErrorEvent):void{
      this.dispatchEvent(event);
    }

    // handles the progress change of the upload
    private function OnUploadProgressChanged(event:ProgressEvent):void{
      var bytesUploaded:uint = event.bytesLoaded - _bytesUploaded;
      _bytesUploaded = event.bytesLoaded;
      bar.setProgress(event.bytesLoaded,event.bytesTotal);
      bar.label = "Uploaded " + FormatPercent(bar.percentComplete) + "%";
      this.dispatchEvent(new FileUploadProgressChangedEvent(this,bytesUploaded,"UploadProgressChanged"));
    }

    // get whether the file is uploading
    public function get IsUploading():Boolean{
      return _uploading;
    }

    // get whether the file has been uploaded
    public function get IsUploaded():Boolean{
      return _uploaded;
    }

    // get the number of bytes uploaded
    public function get BytesUploaded():uint{
      return _bytesUploaded;
    }

    // get the upload url
    public function get UploadUrl():String{
      return _uploadUrl;
    }

    // set the upload url
    public function set UploadUrl(uploadUrl:String):void{
      _uploadUrl = uploadUrl;
    }

    // gets the size of the file
    public function get FileSize():uint{
      var size:uint = 0;
      try{
        size = _file.size;
      }
      catch (err:Error) {
        size = 0;
      }
      return size;
    }

    // upload the file
    public function Upload():void{
      _uploading = true;
      _bytesUploaded = 0;
      _file.upload(new URLRequest(_uploadUrl));
    }

    // cancels the upload of a file
    public function CancelUpload():void{
      _uploading = false;
      _file.cancel();
    }

    // helper function to format the file size
    public static function FormatSize(size:uint):String{
      if(size < 1024)
            return PadSize(int(size*100)/100) + " bytes";
        if(size < 1048576)
            return PadSize(int((size / 1024)*100)/100) + "KB";
        if(size < 1073741824)
           return PadSize(int((size / 1048576)*100)/100) + "MB";
         return PadSize(int((size / 1073741824)*100)/100) + "GB";
    }

    // helper function to format the percent
    public static function FormatPercent(percent:Number):String{
      percent = int(percent);
      return String(percent);
    }

    // helper function to pad the right side of the file size
    public static function PadSize(size:Number):String{
      var temp:String = String(size);
      var index:int = temp.lastIndexOf(".");
      if(index == -1)
        return temp + ".00";
      else if(index == temp.length - 2)
        return temp + "0";
      else
        return temp;
    }

  }
}
