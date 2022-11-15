package it.ais.db;

import it.ais.bean.Ship;
import java.sql.Connection;
import java.sql.Driver;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Types;
import java.sql.Timestamp;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import oracle.jdbc.OracleDriver;

public class InsertDataFileToDatabase
{

   /* MariaDB */
   private final String  JDBC_URL = "jdbc:mariadb://localhost:3306/ais";
   private final String  USER = "******";
   private final String  PASSWORD = "*****";

   @SuppressWarnings("ConvertToTryWithResources")
   public int insertRowBatch(List<Ship> beans)
   {
      int insertedRows = 0;

      try
      {
         Driver oracleDriver = new OracleDriver();
         DriverManager.registerDriver(oracleDriver);
         Connection conn = DriverManager.getConnection(JDBC_URL, USER, PASSWORD);
         conn.setAutoCommit(false);

         Timestamp loadingDate = new Timestamp(System.currentTimeMillis());

         String stringSQL
            = "INSERT INTO ais_raw\n"
            + "(MMSI,TSTAMP,LATITUDE,LONGITUDE,COG,SOG,HEADING,NAVSTAT,IMO,NAME,CALLSIGN,TYPE,A,B,C,D,DRAUGHT,DEST,ETA, LOADING_DATE)\n"
            + "values\n"
            + "(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?, ?)";
         PreparedStatement ps = conn.prepareStatement(stringSQL);

         int rows = 0;
         for (Ship bean : beans)
         {
            rows++;

            //Logger.getLogger(InsertDataFileToDatabase.class.getName()).log(Level.INFO, "Ship {0}", bean.toString());
            ps.setString(1, bean.getMmsi());
            ps.setString(2, bean.getTstamp());
            ps.setString(3, bean.getLatitude());
            ps.setString(4, bean.getLongitude());
            ps.setString(5, bean.getCog());
            ps.setString(6, bean.getSog());
            ps.setString(7, bean.getHeading());
            ps.setString(8, bean.getNavstat());
            ps.setString(9, bean.getImo());
            ps.setString(10, bean.getName());
            if (bean.getCallsign() != null || !bean.getCallsign().isEmpty())
            {
               ps.setString(11, bean.getCallsign());
            }
            else
            {
               ps.setNull(11, Types.VARCHAR);
            }
            ps.setString(12, bean.getType());
            ps.setString(13, bean.getA());
            ps.setString(14, bean.getB());
            ps.setString(15, bean.getC());
            ps.setString(16, bean.getD());
            ps.setString(17, bean.getDaught());
            if (bean.getDest() != null || !bean.getDest().isEmpty())
            {
               ps.setString(18, bean.getDest());
            }
            else
            {
               ps.setNull(18, Types.VARCHAR);
            }
            ps.setString(19, bean.getEta());

            ps.setTimestamp(20, loadingDate);

            ps.addBatch();

            if (rows % 1000 == 0)
            {
               int inserted[] = ps.executeBatch();
               insertedRows += inserted.length;

               conn.commit();
            }
         }

         int inserted[] = ps.executeBatch();
         insertedRows += inserted.length;

         conn.commit();

         ps.close();
         conn.close();
      }
      catch (SQLException ex)
      {
         Logger.getLogger(InsertDataFileToDatabase.class.getName()).log(Level.SEVERE, null, ex);
      }

      return insertedRows;
   }

}
