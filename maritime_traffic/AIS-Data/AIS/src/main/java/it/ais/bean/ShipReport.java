package it.ais.bean;

import java.sql.Timestamp;

public class ShipReport
{

   private String mmsi;

   private String tstampArr;

   private String tstampDep;

   private Timestamp loadingDateArr;

   private Timestamp loadingDateDep;

   public String getMmsi()
   {
      return mmsi;
   }

   public void setMmsi(String mmsi)
   {
      this.mmsi = mmsi;
   }

   public String getTstampArr()
   {
      return tstampArr;
   }

   public void setTstampArr(String tstampArr)
   {
      this.tstampArr = tstampArr;
   }

   public String getTstampDep()
   {
      return tstampDep;
   }

   public void setTstampDep(String tstampDep)
   {
      this.tstampDep = tstampDep;
   }

   public Timestamp getLoadingDateArr()
   {
      return loadingDateArr;
   }

   public void setLoadingDateArr(Timestamp loadingDateArr)
   {
      this.loadingDateArr = loadingDateArr;
   }

   public Timestamp getLoadingDateDep()
   {
      return loadingDateDep;
   }

   public void setLoadingDateDep(Timestamp loadingDateDep)
   {
      this.loadingDateDep = loadingDateDep;
   }

   @Override
   public String toString()
   {
      return "Ship{" + "mmsi=" + mmsi + ", tstampArr=" + tstampArr + ", tstampDep=" + tstampArr + ", loadingDateArr=" + loadingDateArr + ", loadingDateDep=" + loadingDateDep + '}';
   }

}
