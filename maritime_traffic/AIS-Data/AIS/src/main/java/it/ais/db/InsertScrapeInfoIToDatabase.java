package it.ais.db;

import it.ais.bean.ShipDetails;
import java.sql.Connection;
import java.sql.Driver;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.logging.Level;
import java.util.logging.Logger;
import oracle.jdbc.OracleDriver;

public class InsertScrapeInfoIToDatabase
{

   /* MariaDB */
   private final String  JDBC_URL = "jdbc:mariadb://localhost:3306/ais";
   private final String  USER = "******";
   private final String  PASSWORD = "*****";

   private void closeConnection(Connection conn)
   {
      try
      {
         if (conn != null)
         {
            conn.close();
         }
      }
      catch (SQLException ex)
      {
         Logger.getLogger(InsertScrapeInfoIToDatabase.class.getName()).log(Level.SEVERE, null, ex);
      }
   }

   private void closeStatement(PreparedStatement statement)
   {
      try
      {
         if (statement != null)
         {
            statement.close();
         }
      }
      catch (SQLException ex)
      {
         Logger.getLogger(InsertScrapeInfoIToDatabase.class.getName()).log(Level.SEVERE, null, ex);
      }
   }

   private void closeResultSet(ResultSet resultSet)
   {
      try
      {
         if (resultSet != null)
         {
            resultSet.close();
         }
      }
      catch (SQLException ex)
      {
         Logger.getLogger(InsertScrapeInfoIToDatabase.class.getName()).log(Level.SEVERE, null, ex);
      }
   }

   public ArrayList<String> selectDistinctShips()
   {
      ArrayList<String> mmsis = new ArrayList<>();

      Connection conn = null;
      PreparedStatement ps = null;
      ResultSet rs = null;
      try
      {
         Driver oracleDriver = new OracleDriver();
         DriverManager.registerDriver(oracleDriver);
         conn = DriverManager.getConnection(JDBC_URL, USER, PASSWORD);
         conn.setAutoCommit(false);

         String stringSQL
            = "select distinct MMSI from AIS_RAW\n"
            + "where TYPE >= 70 and TYPE <= 89 and\n"
            + "MMSI not in (select MMSI from SHIP_INFO)";
         ps = conn.prepareStatement(stringSQL);
         rs = ps.executeQuery();

         while (rs.next())
         {
            String mmsi = rs.getString("MMSI");

            mmsis.add(mmsi);
         }

         rs.close();
         ps.close();
         conn.close();
      }
      catch (SQLException ex)
      {
         Logger.getLogger(InsertScrapeInfoIToDatabase.class.getName()).log(Level.SEVERE, null, ex);
      }
      finally
      {
         closeConnection(conn);
         closeStatement(ps);
         closeResultSet(rs);
      }

      return mmsis;
   }
 
   @SuppressWarnings("ConvertToTryWithResources")
   public int insertShipDetails(ShipDetails bean)
   {
      int insertedRows = 0;

      Connection conn = null;
      PreparedStatement ps = null;
      try
      {
         Driver oracleDriver = new OracleDriver();
         DriverManager.registerDriver(oracleDriver);
         conn = DriverManager.getConnection(JDBC_URL, USER, PASSWORD);
         conn.setAutoCommit(false);

         String stringSQL
            = "insert into SHIP_INFO\n"
            + "(MMSI, IMO, NAME, TYPE, FLAG, GROSS_TONNAGE, DEADWEIGHT, LENGTH, WIDTH, YEAR)\n"
            + "values\n"
            + "(?,?,?,?,?,?,?,?,?,?)\n";
         ps = conn.prepareStatement(stringSQL);

         Logger.getLogger(InsertDataFileToDatabase.class.getName()).log(Level.INFO, "Ship {0}", bean.toString());

         ps.setString(1, bean.getMmsi());
         ps.setString(2, bean.getImo());
         ps.setString(3, bean.getName());
         ps.setString(4, bean.getType());
         ps.setString(5, bean.getFlag());
         ps.setString(6, bean.getGrossTonnage());
         ps.setString(7, bean.getDeadweight());
         ps.setString(8, bean.getLength());
         ps.setString(9, bean.getWidth());
         ps.setString(10, bean.getYear());

         ps.addBatch();

         int inserted[] = ps.executeBatch();
         insertedRows += inserted.length;

         conn.commit();

         ps.close();
         conn.close();
      }
      catch (SQLException ex)
      {
         Logger.getLogger(InsertScrapeInfoIToDatabase.class.getName()).log(Level.SEVERE, null, ex);
      }
      finally
      {
         closeConnection(conn);
         closeStatement(ps);
      }

      return insertedRows;
   }


}
