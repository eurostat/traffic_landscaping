package it.ais;

import java.io.File;
import java.util.logging.Level;
import java.util.logging.Logger;

public class RemoveLoadedCSVFile
{

   @SuppressWarnings("ConvertToTryWithResources")
   public static void main(String[] args)
   {
      Logger.getLogger(RemoveLoadedCSVFile.class.getName()).log(Level.INFO, "Start RemoveLoadedCSVFile");

      String fileString = "AIS/files/downloaded/data.csv";

      File file = new File(fileString);
      Logger.getLogger(RemoveLoadedCSVFile.class.getName()).log(Level.INFO, "File to remove {0}", fileString);

      if (file.exists())
      {
         boolean removed = file.delete();
         Logger.getLogger(LoadCSVFileIntoDatabase.class.getName()).log(Level.INFO, "File removed {0}", removed);
      }

      Logger.getLogger(RemoveLoadedCSVFile.class.getName()).log(Level.INFO, "End RemoveLoadedCSVFile");
   }

}
