package org.ufsoft.dac.conversions
{
  import flash.net.FileReference;
  import flash.net.URLRequest;

  import org.osflash.thunderbolt.Logger;


  [Bindable]
  [RemoteClass(alias='org.ufsoft.dac.conversions.Conversion')]
  public dynamic class Conversion extends Object
  {
    public var id:            uint;
    public var filename:      String;
    public var out_filename:  String;
    public var progress:      uint;
    public var converted:     Boolean;
    public var url:           String;

    private var fileRef:FileReference;
    private var urlReq:URLRequest;

    public function download():void {
      Logger.debug("Clicked. Downloading: ", this);
      /* Set up the URL request to download the file specified by the FILE_URL variable. */
      urlReq = new URLRequest(url);

      /* Define file reference object and add a bunch of event listeners. */
      fileRef = new FileReference();
      fileRef.download(urlReq);
    }
  }
}
