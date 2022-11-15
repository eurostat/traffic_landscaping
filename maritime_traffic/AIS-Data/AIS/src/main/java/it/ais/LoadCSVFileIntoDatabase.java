package it.ais;

import com.opencsv.bean.CsvToBean;
import com.opencsv.bean.CsvToBeanBuilder;
import it.ais.bean.Ship;
import it.ais.db.InsertDataFileToDatabase;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class LoadCSVFileIntoDatabase
{

   @SuppressWarnings(
      {
         "ConvertToTryWithResources", "unchecked"
      })
   public static void main(String[] args)
   {
      try
      {
         Logger.getLogger(LoadCSVFileIntoDatabase.class.getName()).log(Level.INFO, "Start LoadCSVFileIntoDatabase");

         String fileString = "AIS/files/downloaded/data.csv";

         Logger.getLogger(LoadCSVFileIntoDatabase.class.getName()).log(Level.INFO, "File input {0}", fileString);

         FileReader fr = new FileReader(fileString);

         CsvToBeanBuilder<Ship> ctbb = new CsvToBeanBuilder<>(fr);
         ctbb.withType(Ship.class);
         ctbb.withThrowExceptions(true);
         CsvToBean<Ship> ctb = ctbb.build();
         List<Ship> beans = ctb.parse();

         fr.close();

         int size = beans.size();
         Logger.getLogger(LoadCSVFileIntoDatabase.class.getName()).log(Level.INFO, "Size {0}", size);

         InsertDataFileToDatabase db = new InsertDataFileToDatabase();
         int rows = db.insertRowBatch(beans);
         Logger.getLogger(LoadCSVFileIntoDatabase.class.getName()).log(Level.INFO, "Rows inserted {0}", rows);

         Logger.getLogger(LoadCSVFileIntoDatabase.class.getName()).log(Level.INFO, "End LoadCSVFileIntoDatabase");
      }
      catch (FileNotFoundException ex)
      {
         Logger.getLogger(LoadCSVFileIntoDatabase.class.getName()).log(Level.SEVERE, null, ex);
      }
      catch (IOException ex)
      {
         Logger.getLogger(LoadCSVFileIntoDatabase.class.getName()).log(Level.SEVERE, null, ex);
      }
   }

}
