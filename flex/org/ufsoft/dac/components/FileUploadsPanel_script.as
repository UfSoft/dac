/**
 * @author vampas
 */

import mx.controls.Alert;
import com.newmediateam.fileIO.MultiFileUpload;
import mx.controls.Button;
import flash.net.FileFilter;

// Set the File Filters you wish to impose on the applicaton
//public var imageTypes:FileFilter = new FileFilter("Images (*.jpg; *.jpeg; *.gif; *.png)" ,"*.jpg; *.jpeg; *.gif; *.png");
public var videoTypes:FileFilter = new FileFilter("Flash Video Files (*.flv)","*.flv");
//public var documentTypes:FileFilter = new FileFilter("Documents (*.pdf), (*.doc), (*.rtf), (*.txt)",("*.pdf; *.doc; *.rtf, *.txt"));
public var audioTypes:FileFilter = new FileFilter("Audio Files (*.*)", "*.*");

// Place File Filters into the Array that is passed to the MultiFileUpload instance
public var filesToFilter:Array = new Array(audioTypes,videoTypes);

public var uploadDestination:String = "/upload";  // Modify this variable to match the  URL of your site

public function initFileUploads():void{
  var postVariables:URLVariables = new URLVariables;

  var multiFileUpload:MultiFileUpload = new MultiFileUpload(
    filesDG,
    browseBTN,
    clearButton,
    delButton,
    upload_btn,
    progressbar,
    uploadDestination,
    postVariables,
    60*1024*1024, // 60 Megabytes
    filesToFilter
  );
}

