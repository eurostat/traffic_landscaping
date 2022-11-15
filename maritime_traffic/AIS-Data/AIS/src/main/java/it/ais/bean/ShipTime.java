package it.ais.bean;

import java.sql.Timestamp;

public class ShipTime
{

   private String mmsi;

   private String tstamp;

   private Timestamp loadingDate;

   private String navstat;

   private String latitude;

   private String longitude;

   public String getMmsi()
   {
      return mmsi;
   }

   public void setMmsi(String mmsi)
   {
      this.mmsi = mmsi;
   }

   public String getTstamp()
   {
      return tstamp;
   }

   public void setTstamp(String tstamp)
   {
      this.tstamp = tstamp;
   }

   public Timestamp getLoadingDate()
   {
      return loadingDate;
   }

   public void setLoadingDate(Timestamp loadingDate)
   {
      this.loadingDate = loadingDate;
   }

   public String getNavstat()
   {
      return navstat;
   }

   public void setNavstat(String navstat)
   {
      this.navstat = navstat;
   }

   public String getLatitude()
   {
      return latitude;
   }

   public void setLatitude(String latitude)
   {
      this.latitude = latitude;
   }

   public String getLongitude()
   {
      return longitude;
   }

   public void setLongitude(String longitude)
   {
      this.longitude = longitude;
   }

}
