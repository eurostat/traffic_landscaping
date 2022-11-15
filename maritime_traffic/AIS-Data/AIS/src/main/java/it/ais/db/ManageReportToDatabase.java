package it.ais.db;

import it.ais.bean.ShipReport;
import it.ais.bean.ShipTime;
import java.sql.Connection;
import java.sql.Driver;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.logging.Level;
import java.util.logging.Logger;
import oracle.jdbc.OracleDriver;

public class ManageReportToDatabase
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
         Logger.getLogger(ManageReportToDatabase.class.getName()).log(Level.SEVERE, null, ex);
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
         Logger.getLogger(ManageReportToDatabase.class.getName()).log(Level.SEVERE, null, ex);
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
         Logger.getLogger(ManageReportToDatabase.class.getName()).log(Level.SEVERE, null, ex);
      }
   }

   public void truncateTableReportTime()
   {
      Connection conn = null;
      try
      {
         Driver oracleDriver = new OracleDriver();
         DriverManager.registerDriver(oracleDriver);
         conn = DriverManager.getConnection(JDBC_URL, USER, PASSWORD);
         conn.setAutoCommit(false);

         String stringSQL
            = "truncate table AIS_RAW_REPORT_TIME";
         Statement s = conn.createStatement();
         s.execute(stringSQL);
      }
      catch (SQLException ex)
      {
         Logger.getLogger(ManageReportToDatabase.class.getName()).log(Level.SEVERE, null, ex);
      }
      finally
      {
         closeConnection(conn);
      }
   }

   public void truncateTableReportCoords()
   {
      Connection conn = null;
      try
      {
         Driver oracleDriver = new OracleDriver();
         DriverManager.registerDriver(oracleDriver);
         conn = DriverManager.getConnection(JDBC_URL, USER, PASSWORD);
         conn.setAutoCommit(false);

         String stringSQL
            = "truncate table AIS_RAW_REPORT_COORDS";
         Statement s = conn.createStatement();
         s.execute(stringSQL);
      }
      catch (SQLException ex)
      {
         Logger.getLogger(ManageReportToDatabase.class.getName()).log(Level.SEVERE, null, ex);
      }
      finally
      {
         closeConnection(conn);
      }
   }

   public ArrayList<String> selectDistinctShip()
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
            = "select distinct MMSI from AIS_RAW where TYPE >= 70 and TYPE <= 89";
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
         Logger.getLogger(ManageReportToDatabase.class.getName()).log(Level.SEVERE, null, ex);
      }
      finally
      {
         closeConnection(conn);
         closeStatement(ps);
         closeResultSet(rs);
      }

      return mmsis;
   }

   public ArrayList<ShipTime> findShip(String mmsi)
   {
      ArrayList<ShipTime> ships = new ArrayList<>();

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
            = "select MMSI, TSTAMP, LOADING_DATE, LATITUDE, LONGITUDE, NAVSTAT\n"
            + "from AIS_RAW\n"
            + "where MMSI = ?\n"
            + "order by TSTAMP, LOADING_DATE";
         ps = conn.prepareStatement(stringSQL);

         ps.setString(1, mmsi);

         rs = ps.executeQuery();

         while (rs.next())
         {
            ShipTime ship = new ShipTime();

            ship.setMmsi(rs.getString("MMSI"));
            ship.setTstamp(rs.getString("TSTAMP"));
            ship.setLoadingDate(rs.getTimestamp("LOADING_DATE"));
            ship.setLatitude(rs.getString("LATITUDE"));
            ship.setLongitude(rs.getString("LONGITUDE"));
            ship.setNavstat(rs.getString("NAVSTAT"));

            ships.add(ship);
         }

         rs.close();
         ps.close();
         conn.close();
      }
      catch (SQLException ex)
      {
         Logger.getLogger(ManageReportToDatabase.class.getName()).log(Level.SEVERE, null, ex);
      }
      finally
      {
         closeConnection(conn);
         closeStatement(ps);
         closeResultSet(rs);
      }

      return ships;
   }

   @SuppressWarnings("ConvertToTryWithResources")
   public int insertRowTime(ShipReport bean)
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
            = "insert into AIS_RAW_REPORT_TIME\n"
            + "(MMSI,TSTAMP_ARR,LOADING_DATE_ARR,TSTAMP_DEP,LOADING_DATE_DEP)\n"
            + "values\n"
            + "(?,?,?,?,?)\n";
         ps = conn.prepareStatement(stringSQL);

         Logger.getLogger(InsertDataFileToDatabase.class.getName()).log(Level.INFO, "Ship {0}", bean.toString());

         ps.setString(1, bean.getMmsi());
         ps.setString(2, bean.getTstampArr());
         ps.setTimestamp(3, bean.getLoadingDateArr());
         ps.setString(4, bean.getTstampDep());
         ps.setTimestamp(5, bean.getLoadingDateDep());

         ps.addBatch();

         int inserted[] = ps.executeBatch();
         insertedRows += inserted.length;

         conn.commit();

         ps.close();
         conn.close();
      }
      catch (SQLException ex)
      {
         Logger.getLogger(ManageReportToDatabase.class.getName()).log(Level.SEVERE, null, ex);
      }
      finally
      {
         closeConnection(conn);
         closeStatement(ps);
      }

      return insertedRows;
   }

   @SuppressWarnings("ConvertToTryWithResources")
   public int insertRowCoords(ShipReport bean)
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
            = "insert into AIS_RAW_REPORT_COORDS\n"
            + "(MMSI,TSTAMP_ARR,LOADING_DATE_ARR,TSTAMP_DEP,LOADING_DATE_DEP)\n"
            + "values\n"
            + "(?,?,?,?,?)\n";
         ps = conn.prepareStatement(stringSQL);

         Logger.getLogger(InsertDataFileToDatabase.class.getName()).log(Level.INFO, "Ship {0}", bean.toString());

         ps.setString(1, bean.getMmsi());
         ps.setString(2, bean.getTstampArr());
         ps.setTimestamp(3, bean.getLoadingDateArr());
         ps.setString(4, bean.getTstampDep());
         ps.setTimestamp(5, bean.getLoadingDateDep());

         ps.addBatch();

         int inserted[] = ps.executeBatch();
         insertedRows += inserted.length;

         conn.commit();

         ps.close();
         conn.close();
      }
      catch (SQLException ex)
      {
         Logger.getLogger(ManageReportToDatabase.class.getName()).log(Level.SEVERE, null, ex);
      }
      finally
      {
         closeConnection(conn);
         closeStatement(ps);
      }

      return insertedRows;
   }

}
