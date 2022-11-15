package it.ais;

import java.util.logging.Level;
import java.util.logging.Logger;

public class ProcessPipeline
{

   public static void main(String[] args)
   {
      //1. DownloadGZipFileFromURL
      Logger.getLogger(ProcessPipeline.class.getName()).log(Level.INFO, null, "Start process DownloadGZipFileFromURL");
      DownloadGZipFileFromURL.main(null);
      Logger.getLogger(ProcessPipeline.class.getName()).log(Level.INFO, null, "End process DownloadGZipFileFromURL");

      //2. DecompressGZipFile
      Logger.getLogger(ProcessPipeline.class.getName()).log(Level.INFO, null, "Start process DecompressGZipFile");
      DecompressGZipFile.main(null);
      Logger.getLogger(ProcessPipeline.class.getName()).log(Level.INFO, null, "End process DecompressGZipFile");

      //3. RemoveUnwantedCharsToFile
      Logger.getLogger(ProcessPipeline.class.getName()).log(Level.INFO, null, "Start process RemoveUnwantedCharsToFile");
      RemoveUnwantedCharsToFile.main(null);
      Logger.getLogger(ProcessPipeline.class.getName()).log(Level.INFO, null, "End process RemoveUnwantedCharsToFile");

      //4. LoadCSVFileIntoDatabase
      Logger.getLogger(ProcessPipeline.class.getName()).log(Level.INFO, null, "Start process LoadCSVFileIntoDatabase");
      LoadCSVFileIntoDatabase.main(null);
      Logger.getLogger(ProcessPipeline.class.getName()).log(Level.INFO, null, "End process LoadCSVFileIntoDatabase");

      //5. RemoveLoadedCSVFile
      Logger.getLogger(ProcessPipeline.class.getName()).log(Level.INFO, null, "Start process RemoveLoadedCSVFile");
      RemoveLoadedCSVFile.main(null);
      Logger.getLogger(ProcessPipeline.class.getName()).log(Level.INFO, null, "End process RemoveLoadedCSVFile");

      //5. MoveGZipFileToLoadedFolder
      Logger.getLogger(ProcessPipeline.class.getName()).log(Level.INFO, null, "Start process MoveGZipFileToLoadedFolder");
      MoveGZipFileToLoadedFolder.main(null);
      Logger.getLogger(ProcessPipeline.class.getName()).log(Level.INFO, null, "End process MoveGZipFileToLoadedFolder");

      //6. ScrapeShipInfoFromVesselFinder
      Logger.getLogger(ProcessPipeline.class.getName()).log(Level.INFO, null, "Start process ScrapeShipInfoFromVesselFinder");
      ScrapeShipInfoFromVesselFinder.main(null);
      Logger.getLogger(ProcessPipeline.class.getName()).log(Level.INFO, null, "End process ScrapeShipInfoFromVesselFinder");
   }

}
