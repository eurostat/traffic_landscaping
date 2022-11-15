package it.ais;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.Reader;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.util.logging.Level;
import java.util.logging.Logger;

public class RemoveUnwantedCharsToFile
{

   @SuppressWarnings("ConvertToTryWithResources")
   public static void main(String[] args)
   {
      try
      {
         Logger.getLogger(RemoveUnwantedCharsToFile.class.getName()).log(Level.INFO, "Start RemoveUnwantedCharsToFile");

         String inputfileString = "AIS/files/downloaded/data.csv";

         File inputFile = new File(inputfileString);
         Logger.getLogger(LoadCSVFileIntoDatabase.class.getName()).log(Level.INFO, "File input {0}", inputfileString);

         File tempFile = File.createTempFile("buffer", ".tmp");
         FileWriter fw = new FileWriter(tempFile);

         Reader fr = new FileReader(inputFile);
         BufferedReader br = new BufferedReader(fr);

         while (br.ready())
         {
            String line = br.readLine();
            String newLine = line.replaceAll("\\\\", "-");
            fw.write(newLine + "\n");
         }

         fw.close();
         br.close();
         fr.close();

         Files.move(tempFile.toPath(), inputFile.toPath(), StandardCopyOption.REPLACE_EXISTING);
         Logger.getLogger(LoadCSVFileIntoDatabase.class.getName()).log(Level.INFO, "File input replaced");

         Logger.getLogger(RemoveUnwantedCharsToFile.class.getName()).log(Level.INFO, "End RemoveUnwantedCharsToFile");
      }
      catch (FileNotFoundException ex)
      {
         Logger.getLogger(RemoveUnwantedCharsToFile.class.getName()).log(Level.SEVERE, null, ex);
      }
      catch (IOException ex)
      {
         Logger.getLogger(RemoveUnwantedCharsToFile.class.getName()).log(Level.SEVERE, null, ex);
      }
   }

}
