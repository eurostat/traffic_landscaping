package it.ais;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.logging.Level;
import java.util.logging.Logger;

public class MoveGZipFileToLoadedFolder
{

   public static void main(String[] args)
   {
      try
      {
         Logger.getLogger(MoveGZipFileToLoadedFolder.class.getName()).log(Level.INFO, "Start MoveGZipFileToLoaded");

         LocalDateTime date = LocalDateTime.now();
         DateTimeFormatter dtf = DateTimeFormatter.ofPattern("yyyy_MM_dd_HH_mm");

         String dateFormatted = dtf.format(date);

         String fromFile = "AIS/files/downloaded/data.csv.gz";
         String toFile = "AIS/files/loaded/" + dateFormatted + "_data.csv.gz";

         Logger.getLogger(MoveGZipFileToLoadedFolder.class.getName()).log(Level.INFO, "File source {0}", fromFile);
         Logger.getLogger(MoveGZipFileToLoadedFolder.class.getName()).log(Level.INFO, "File target {0}", toFile);

         Path source = Paths.get(fromFile);
         Path target = Paths.get(toFile);

         Files.move(source, target);

         Logger.getLogger(MoveGZipFileToLoadedFolder.class.getName()).log(Level.INFO, "End MoveGZipFileToLoaded");
      }
      catch (IOException ex)
      {
         Logger.getLogger(MoveGZipFileToLoadedFolder.class.getName()).log(Level.SEVERE, null, ex);
      }
   }

}
