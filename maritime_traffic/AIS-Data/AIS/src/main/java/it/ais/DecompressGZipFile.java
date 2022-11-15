package it.ais;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.zip.GZIPInputStream;

public class DecompressGZipFile
{

   public static void main(String[] args)
   {
      try
      {
         Logger.getLogger(DecompressGZipFile.class.getName()).log(Level.INFO, "Start DecompressGZipFile");

         Path source = Paths.get("AIS/files/downloaded/data.csv.gz");
         Path target = Paths.get("AIS/files/downloaded/data.csv");

         Logger.getLogger(DecompressGZipFile.class.getName()).log(Level.INFO, "File input {0}", source);
         Logger.getLogger(DecompressGZipFile.class.getName()).log(Level.INFO, "File output {0}", target);

         GZIPInputStream gis = new GZIPInputStream(new FileInputStream(source.toFile()));
         FileOutputStream fos = new FileOutputStream(target.toFile());

         byte[] buffer = new byte[1024];
         int len;
         while ((len = gis.read(buffer)) > 0)
         {
            fos.write(buffer, 0, len);
         }

         Logger.getLogger(DecompressGZipFile.class.getName()).log(Level.INFO, "End DecompressGZipFile");
      }
      catch (FileNotFoundException ex)
      {
         Logger.getLogger(DecompressGZipFile.class.getName()).log(Level.SEVERE, null, ex);
      }
      catch (IOException ex)
      {
         Logger.getLogger(DecompressGZipFile.class.getName()).log(Level.SEVERE, null, ex);
      }
   }

}
