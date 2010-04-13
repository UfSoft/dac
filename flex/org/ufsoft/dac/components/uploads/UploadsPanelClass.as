package org.ufsoft.dac.components.uploads
{
  // Code behind for FlashFileUpload.mxml
  import mx.core.Application;
  import flash.net.navigateToURL;
  import flash.system.fscommand;
  import mx.skins.ProgrammaticSkin;
  import mx.rpc.events.AbstractEvent;
  import mx.controls.*;
  import mx.containers.*;
  import flash.net.FileReferenceList;
  import flash.net.FileFilter;
  import flash.external.*;
  import flash.utils.*
  import mx.events.FlexEvent;
  import flash.events.*;
  import flash.net.URLRequest;
  import org.ufsoft.dac.components.uploads.*;


  public class UploadsPanelClass extends Panel
  {
    private var fileRefList:FileReferenceList;
    private var fileRefListener:Object;
    private var _totalSize:Number;
    private var _uploadedBytes:Number;
    private var _currentUpload:FileUpload;
    private var _uploadFileSize:Number;
    private var _totalUploadSize:Number;
    private var _fileTypeDescription:String;
    private var _fileTypes:String;

    // all controls in the mxml file must be public variables in the code behind
    public var fileContainer:VBox;
    public var fileUploadBox:VBox;
    public var uploadStats:HBox;
    public var totalFiles:Text;
    public var totalSize:Text;
    public var totalProgressBar:ProgressBar;
    public var browseButton:Button;
    public var clearButton:Button;
    public var uploadButton:Button;
    public var cancelButton:Button;
    public var mytext:Text;

    // Variables
    public var uploadPage:String            = "/upload";
    /*public var UploadFileSizeLimit:Number   = new Number(1800000);
    public var TotalUploadSizeLimit:Number  = new Number(2097152);*/
    public var UploadFileSizeLimit:Number   = new Number(0);
    public var TotalUploadSizeLimit:Number  = new Number(0);

    private var videoTypes:FileFilter = new FileFilter("Flash Video Files (*.flv)","*.flv");
    //public var documentTypes:FileFilter = new FileFilter("Documents (*.pdf), (*.doc), (*.rtf), (*.txt)",("*.pdf; *.doc; *.rtf, *.txt"));
    private var audioTypes:FileFilter = new FileFilter("Audio Files (*.*)", "*.*");

    // Place File Filters into the Array that is passed to the MultiFileUpload instance
    private var filesToFilter:Array = new Array(audioTypes,videoTypes);



    // constructor
    public function UploadsPanelClass()
    {
      super();
      addEventListener (FlexEvent.CREATION_COMPLETE, OnLoad);


    }

    private function OnLoad(event:Event):void{
      // instantiate and initialize variables
      fileRefList = new FileReferenceList();
      _totalSize = 0;
      _uploadedBytes = 0;

      // hook up our event listeners
      fileRefList.addEventListener(Event.SELECT,OnSelect);
      browseButton.addEventListener(MouseEvent.CLICK,OnAddFilesClicked);
      clearButton.addEventListener(MouseEvent.CLICK,OnClearFilesClicked);
      uploadButton.addEventListener(MouseEvent.CLICK,OnUploadFilesClicked);
      cancelButton.addEventListener(MouseEvent.CLICK,OnCancelClicked);

      _uploadFileSize = UploadFileSizeLimit;
      /*var temp:String = fileSizeLimit;
      if(temp != null && temp != "") {
          _uploadFileSize = new Number(temp);
      } else {
          _uploadFileSize = 0;
      }*/

      _totalUploadSize = TotalUploadSizeLimit;

      /*temp = totalUploadSize;
      if(temp != null && temp != "") {
          _totalUploadSize = new Number(temp);
      } else {
          _totalUploadSize = 0;
      }

      _fileTypeDescription = Application.application.parameters.fileTypeDescription;
      _fileTypes = Application.application.parameters.fileTypes;
       */
    }

    // brings up file browse dialog when add file button is pressed
    private function OnAddFilesClicked(event:Event):void{
      fileRefList.browse(filesToFilter);
    }

    // fires when the clear files button is clicked
    private function OnClearFilesClicked(event:Event):void{
      // cancels an upload if there is a file being uploaded
      if(_currentUpload != null)
        _currentUpload.CancelUpload();
      // clears all the files
      fileUploadBox.removeAllChildren();
      // reset the labels
      SetLables();
      // reinitialize the variables;
      _uploadedBytes = 0;
      _totalSize = 0;
      _currentUpload == null;
    }

    // fires when the upload upload button is clicked
    private function OnUploadFilesClicked(event:Event):void{
      // get all the files to upload
      var fileUploadArray:Array = fileUploadBox.getChildren();
      // initialize a helper boolean variable
      var fileUploading:Boolean = false;
      _currentUpload = null;

      // set the button visibility
      uploadButton.visible = false;
      cancelButton.visible = true;
      // go through the files to check if they have been uploaded and get the first that hasn't
      for(var x:uint=0;x<fileUploadArray.length;x++)
      {
        // find a file that hasn't been uploaded and start it
        if(!FileUpload(fileUploadArray[x]).IsUploaded)
        {
          fileUploading = true;
          // set the current upload and start the upload
          _currentUpload = FileUpload(fileUploadArray[x]);
          _currentUpload.Upload();
          break;
        }
      }
      // if all files have been uploaded
      if(!fileUploading)
      {
        OnCancelClicked(null);
        // get the javascript complete funtion to call
        /*var completeFunction:String = Application.application.parameters.completeFunction;
        // if a complete function is passed in, set in flashvars
        if(completeFunction != null && completeFunction != "")
          navigateToURL(new URLRequest("javascript:"+completeFunction),"_self");*/
      }
    }

    // fired when the cancel button is clicked
    private function OnCancelClicked(event:Event):void{
      // if there is a file being uploaded then cancel it and adjust the uploaded bytes variable to reflect the cancel
      if(_currentUpload != null)
      {
        _currentUpload.CancelUpload();
        _uploadedBytes -= _currentUpload.BytesUploaded;
        _currentUpload = null;
      }
      // reset the labels and set the button visibility
      SetLables();
      uploadButton.visible = true;
      cancelButton.visible = false;
    }

    // fired when files have been selected in the file browse dialog
    private function OnSelect(event:Event):void{
      // get the page to upload to, set in flashvars

      var tempSize:Number = _totalSize;

      // add each file that was selected
      for(var i:uint=0;i<fileRefList.fileList.length;i++)
      {
        // create new FileUpload and add handlers then add it to the fileuploadbox
        if(_uploadFileSize > 0 && fileRefList.fileList[i].size > _uploadFileSize)
            OnFileSizeLimitReached(fileRefList.fileList[i].name);
        if(_totalUploadSize > 0 && tempSize + fileRefList.fileList[i].size > _totalUploadSize)
        {
            OnTotalFileSizeLimitReached();
            break;
        }

        if((_uploadFileSize == 0 || fileRefList.fileList[i].size < _uploadFileSize) && (_totalUploadSize == 0 || tempSize + fileRefList.fileList[i].size < _totalUploadSize))
        {
            var fu:FileUpload = new FileUpload(fileRefList.fileList[i],uploadPage);
            fu.percentWidth = 100;
            fu.addEventListener("FileRemoved",OnFileRemoved);
            fu.addEventListener("UploadComplete",OnFileUploadComplete);
            fu.addEventListener("UploadProgressChanged",OnFileUploadProgressChanged);
            fu.addEventListener(HTTPStatusEvent.HTTP_STATUS,OnHttpError);
            fu.addEventListener(IOErrorEvent.IO_ERROR,OnIOError);
            fu.addEventListener(SecurityErrorEvent.SECURITY_ERROR,OnSecurityError);
            fileUploadBox.addChild(fu);
            tempSize += fileRefList.fileList[i].size;
        }
      }
      // reset labels
      SetLables();
    }

    // fired when a the remove file button is clicked
    private function OnFileRemoved(event:FileUploadEvent):void{
      _uploadedBytes -= FileUpload(event.Sender).BytesUploaded;
      fileUploadBox.removeChild(FileUpload(event.Sender));
      SetLables();
      if(_currentUpload == FileUpload(event.Sender))
        OnUploadFilesClicked(null);
    }

    // fired when a file has finished uploading
    private function OnFileUploadComplete(event:FileUploadEvent):void{
      _currentUpload == null;
      setTimeout(OnUploadFilesClicked, 10, null);
    }

    private function OnTotalFileSizeLimitReached():void{
        Alert.show("The total file size limit has been reached.");
    }

    private function OnFileSizeLimitReached(fileName:String):void{
        Alert.show("The file '" + fileName + "' is too large and will not be added.");
    }

    //  error handlers
    private function OnHttpError(event:HTTPStatusEvent):void{
      Alert.show("There has been an HTTP Error: status code " + event.status);
    }
    private function OnIOError(event:IOErrorEvent):void{
      Alert.show("There has been an I/O Error: " + event.text);
    }

    private function OnSecurityError(event:SecurityErrorEvent):void{
      Alert.show("There has been a Security Error: " + event.text);
    }

    // fired when upload progress changes
    private function OnFileUploadProgressChanged(event:FileUploadProgressChangedEvent):void{
      _uploadedBytes += event.BytesUploaded;
      SetProgressBar();
    }

    // sets the progress bar and label
    private function SetProgressBar():void{
      totalProgressBar.setProgress(_uploadedBytes,_totalSize);
      totalProgressBar.label = "Uploaded " + FileUpload.FormatPercent(totalProgressBar.percentComplete) + "% - "
        + FileUpload.FormatSize(_uploadedBytes) + " of " + FileUpload.FormatSize(_totalSize);
    }

    // sets the labels
    private function SetLables():void{
      var fileUploadArray:Array = fileUploadBox.getChildren();
      if(fileUploadArray.length > 0)
      {
        totalFiles.text = String(fileUploadArray.length);
        _totalSize = 0;
        for(var x:uint=0;x<fileUploadArray.length;x++)
        {
          _totalSize += FileUpload(fileUploadArray[x]).FileSize;
        }
        totalSize.text = FileUpload.FormatSize(_totalSize);
        SetProgressBar();
        clearButton.visible = uploadButton.visible = totalProgressBar.visible =  uploadStats.visible = true;
      }
      else
      {
        clearButton.visible = uploadButton.visible = totalProgressBar.visible = uploadStats.visible = false;
      }
    }
  }
}
